import XCTest
import Supabase
@testable import PitchAtlas

/// Findings from the 1.2 whole-branch review of the community layer, each pinned
/// before its fix. Web truth: components/sections/DiscussionForum.tsx and
/// hooks/useDiscussion.ts at 47e21e6.
final class CommunityReviewFixTests: XCTestCase {
    /// A post or reply files under the handle the contributor typed (the site's
    /// required "Your name" field, defaulting to the profile's handle) — never a
    /// name made from their email address.
    func testADiscussionPostFilesUnderTheHandleTypedNeverTheEmail() {
        XCTAssertEqual(DiscussionHandle.initial(current: "", profileName: nil), "")
        XCTAssertEqual(DiscussionHandle.initial(current: "", profileName: "Slinger"), "Slinger")
        XCTAssertEqual(DiscussionHandle.initial(current: "Typed", profileName: "Slinger"), "Typed")
        XCTAssertEqual(DiscussionHandle.label, "Your name")
        XCTAssertEqual(DiscussionHandle.caption, "A handle is enough. No real name required.")
        XCTAssertThrowsError(try NewDiscussionPost.validated(topicKey: "slider", displayName: "A", body: "Holds.", parentID: nil)) {
            XCTAssertEqual($0 as? CommunityServiceError,
                           .invalidDiscussionPost("Add a name (2+ characters) so people know who is talking."))
        }
    }

    /// Saving the handle must not ask for the updated profile back. profiles is
    /// readable column by column (is_admin is hidden), so a "return the row"
    /// update is refused with "permission denied" and the post never files —
    /// what the 2026-10-30 production release gate showed as "Sign in before
    /// doing that." The site's client sends return=minimal.
    func testSavingTheHandleAsksForNoRowBack() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [RecordingURLProtocol.self]
        RecordingURLProtocol.requests = []
        let client = SupabaseClient(
            supabaseURL: try XCTUnwrap(URL(string: "https://example.supabase.co")),
            supabaseKey: "test-key",
            options: SupabaseClientOptions(global: .init(session: URLSession(configuration: config)))
        )
        try? await CommunityService(client: client).setDisplayName("Release gate", userID: "user-1")
        let update = try XCTUnwrap(RecordingURLProtocol.requests.first { $0.httpMethod == "PATCH" })
        XCTAssertEqual(update.url?.path, "/rest/v1/profiles")
        let prefer = update.value(forHTTPHeaderField: "Prefer") ?? ""
        XCTAssertFalse(prefer.contains("return=representation"), "Prefer: \(prefer)")
    }

    /// Every write mints or reuses a session before it runs, so a privilege or
    /// row-security refusal is never fixed by signing in; telling an anonymous
    /// contributor to sign in sends them down the path that orphans their record.
    /// Only a real missing or expired login asks for sign-in.
    func testARefusedWriteNeverAsksAnAnonymousContributorToSignIn() {
        func message(_ text: String) -> String {
            CommunityService.userMessage(for: NSError(domain: "PostgREST", code: 42501,
                                                      userInfo: [NSLocalizedDescriptionKey: text]))
        }
        let fallback = "Could not save that just now. Try again."
        XCTAssertEqual(message("permission denied for table profiles"), fallback)
        XCTAssertEqual(message("new row violates row-level security policy for table \"discussion_posts\""), fallback)
        XCTAssertEqual(message("JWT expired"), "Sign in before doing that.")
        XCTAssertEqual(message("auth_required"), "Sign in before doing that.")
    }

    /// Two report retries must receive one anonymous identity, even while signup
    /// is suspended. Completion must not cache an identity across later calls.
    @MainActor
    func testConcurrentWriteIntentsShareOneSessionOperation() async throws {
        let store = AuthSessionStore()
        let started = expectation(description: "session operation started")
        let secondJoined = expectation(description: "second caller joined")
        var calls = 0
        var response: CheckedContinuation<String, Error>?
        let operation: @MainActor () async throws -> String = {
            calls += 1
            started.fulfill()
            return try await withCheckedThrowingContinuation { response = $0 }
        }
        let first = Task { @MainActor in try await store.ensureSessionForWrite(operation: operation) }
        await fulfillment(of: [started], timeout: 2)
        let second = Task { @MainActor in
            secondJoined.fulfill()
            return try await store.ensureSessionForWrite(operation: operation)
        }
        await fulfillment(of: [secondJoined], timeout: 2)
        try XCTUnwrap(response).resume(returning: "shared-contributor")
        let firstID = try await first.value
        let secondID = try await second.value
        XCTAssertEqual(firstID, "shared-contributor")
        XCTAssertEqual(secondID, firstID)
        XCTAssertEqual(calls, 1, "Concurrent writes must not mint competing accounts")
        let laterID = try await store.ensureSessionForWrite { "current-contributor" }
        XCTAssertEqual(laterID, "current-contributor", "A completed task must not cache an old account")
    }

    /// All waiters receive the same failure, and the next write can retry.
    @MainActor
    func testFailedSharedSessionOperationAllowsAFreshRetry() async throws {
        let store = AuthSessionStore()
        let started = expectation(description: "failing operation started")
        let secondJoined = expectation(description: "second caller joined")
        var calls = 0
        var response: CheckedContinuation<String, Error>?
        let operation: @MainActor () async throws -> String = {
            calls += 1
            started.fulfill()
            return try await withCheckedThrowingContinuation { response = $0 }
        }
        let first = Task { @MainActor in try await store.ensureSessionForWrite(operation: operation) }
        await fulfillment(of: [started], timeout: 2)
        let second = Task { @MainActor in
            secondJoined.fulfill()
            return try await store.ensureSessionForWrite(operation: operation)
        }
        await fulfillment(of: [secondJoined], timeout: 2)
        try XCTUnwrap(response).resume(throwing: URLError(.notConnectedToInternet))
        for task in [first, second] {
            do {
                _ = try await task.value
                XCTFail("A failed signup must fail every waiting write")
            } catch {
                XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
            }
        }
        XCTAssertEqual(calls, 1)
        let retryID = try await store.ensureSessionForWrite {
            calls += 1
            return "retry-contributor"
        }
        XCTAssertEqual(retryID, "retry-contributor")
        XCTAssertEqual(calls, 2)
    }

    /// Leaving one screen must not cancel another screen's shared signup.
    @MainActor
    func testCancellingOneSessionWaiterDoesNotCancelAnother() async throws {
        let store = AuthSessionStore()
        let started = expectation(description: "session operation started")
        let secondJoined = expectation(description: "second caller joined")
        var response: CheckedContinuation<String, Error>?
        var calls = 0
        let operation: @MainActor () async throws -> String = {
            calls += 1
            started.fulfill()
            let id: String = try await withCheckedThrowingContinuation { response = $0 }
            try Task.checkCancellation()
            return id
        }
        let first = Task { @MainActor in try await store.ensureSessionForWrite(operation: operation) }
        await fulfillment(of: [started], timeout: 2)
        let second = Task { @MainActor in
            secondJoined.fulfill()
            return try await store.ensureSessionForWrite(operation: operation)
        }
        await fulfillment(of: [secondJoined], timeout: 2)
        first.cancel()
        try XCTUnwrap(response).resume(returning: "shared-contributor")
        let secondID = try await second.value
        _ = try await first.value
        XCTAssertEqual(secondID, "shared-contributor")
        XCTAssertEqual(calls, 1)
    }

    /// Apple must choose link/sign-in only after signup settles. New writes must
    /// not mint an account while that transition owns the session.
    @MainActor
    func testAccountTransitionWaitsForSignupAndRejectsNewWrites() async throws {
        let store = AuthSessionStore()
        let signupStarted = expectation(description: "signup started")
        let transitionRequested = expectation(description: "account transition requested")
        let transitionStarted = expectation(description: "account transition started")
        var signupResponse: CheckedContinuation<String, Error>?
        var transitionResponse: CheckedContinuation<Void, Never>?
        var signupFinished = false
        let signup = Task { @MainActor in
            try await store.ensureSessionForWrite {
                signupStarted.fulfill()
                let id: String = try await withCheckedThrowingContinuation { signupResponse = $0 }
                signupFinished = true
                return id
            }
        }
        await fulfillment(of: [signupStarted], timeout: 2)
        let transition = Task { @MainActor in
            transitionRequested.fulfill()
            try await store.withAuthTransition {
                XCTAssertTrue(signupFinished, "Claim/sign-out must not run ahead of signup")
                transitionStarted.fulfill()
                await withCheckedContinuation { transitionResponse = $0 }
            }
        }
        await fulfillment(of: [transitionRequested], timeout: 2)
        XCTAssertTrue(store.isWorking)
        do {
            _ = try await store.ensureSessionForWrite { XCTFail("Must not start another signup"); return "wrong" }
            XCTFail("A write during an account transition must remain retryable")
        } catch {
            XCTAssertEqual(error as? CommunityServiceError, .sessionStartFailed)
        }
        try XCTUnwrap(signupResponse).resume(returning: "anonymous-contributor")
        await fulfillment(of: [transitionStarted], timeout: 2)
        let signupID = try await signup.value
        XCTAssertEqual(signupID, "anonymous-contributor")
        try XCTUnwrap(transitionResponse).resume()
        try await transition.value
        XCTAssertFalse(store.isWorking)
        let nextID = try await store.ensureSessionForWrite { "current-account" }
        XCTAssertEqual(nextID, "current-account")
    }

    /// A failed signup does not strand Apple sign-in or sign-out behind the gate.
    @MainActor
    func testFailedSignupStillReleasesAccountTransition() async throws {
        let store = AuthSessionStore()
        let signupStarted = expectation(description: "signup started")
        let transitionRequested = expectation(description: "account transition requested")
        var response: CheckedContinuation<String, Error>?
        let signup = Task { @MainActor in
            try await store.ensureSessionForWrite {
                signupStarted.fulfill()
                return try await withCheckedThrowingContinuation { response = $0 }
            }
        }
        await fulfillment(of: [signupStarted], timeout: 2)
        let transition = Task { @MainActor in
            transitionRequested.fulfill()
            return try await store.withAuthTransition { "signed-in-account" }
        }
        await fulfillment(of: [transitionRequested], timeout: 2)
        try XCTUnwrap(response).resume(throwing: URLError(.notConnectedToInternet))
        do { _ = try await signup.value; XCTFail("Signup should fail") } catch {}
        let result = try await transition.value
        XCTAssertEqual(result, "signed-in-account")
        XCTAssertFalse(store.isWorking)
    }

    /// A cancelled queued callback must not mutate the account or strand the
    /// following callback; cancelling it must not cancel the active operation.
    @MainActor
    func testCancelledAccountTransitionReleasesTheNextWaiter() async throws {
        let store = AuthSessionStore()
        let firstStarted = expectation(description: "first transition started")
        let secondQueued = expectation(description: "second transition queued")
        let thirdQueued = expectation(description: "third transition queued")
        var response: CheckedContinuation<Void, Never>?
        var operations: [String] = []
        let first = Task { @MainActor in
            try await store.withAuthTransition {
                operations.append("first")
                firstStarted.fulfill()
                await withCheckedContinuation { response = $0 }
            }
        }
        await fulfillment(of: [firstStarted], timeout: 2)
        let second = Task { @MainActor in
            secondQueued.fulfill()
            try await store.withAuthTransition { operations.append("cancelled") }
        }
        await fulfillment(of: [secondQueued], timeout: 2)
        let third = Task { @MainActor in
            thirdQueued.fulfill()
            try await store.withAuthTransition { operations.append("third") }
        }
        await fulfillment(of: [thirdQueued], timeout: 2)
        second.cancel()
        try XCTUnwrap(response).resume()
        try await first.value
        do { try await second.value; XCTFail("Cancelled transition should throw") }
        catch { XCTAssertTrue(error is CancellationError) }
        try await third.value
        XCTAssertEqual(operations, ["first", "third"])
        XCTAssertFalse(store.isWorking)
    }

    @MainActor
    func testFailedAccountTransitionReleasesWrites() async throws {
        let store = AuthSessionStore()
        do {
            try await store.withAuthTransition { throw URLError(.notConnectedToInternet) }
            XCTFail("Account operation should fail")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }
        XCTAssertFalse(store.isWorking)
        let id = try await store.ensureSessionForWrite { "retry-account" }
        XCTAssertEqual(id, "retry-account")
    }

    func testOnlyTheConfiguredCallbackRouteStartsAuthentication() throws {
        for link in ["pitchatlas://auth-callback?code=example", "pitchatlas://auth-callback/#access_token=example"] {
            XCTAssertTrue(AuthSessionStore.isAuthCallback(try XCTUnwrap(URL(string: link))))
        }
        for link in ["pitchatlas://account", "pitchatlas://pitch/slider", "pitchatlas://auth-callback/pitch", "https://auth-callback?code=example"] {
            XCTAssertFalse(AuthSessionStore.isAuthCallback(try XCTUnwrap(URL(string: link))))
        }
    }

    @MainActor
    func testContentDeepLinksDoNotStartAuthOrSetAnAuthError() async throws {
        let store = AuthSessionStore()
        store.handle(url: try XCTUnwrap(URL(string: "pitchatlas://account")))
        store.handle(url: try XCTUnwrap(URL(string: "pitchatlas://pitch/slider")))
        await Task.yield()
        XCTAssertFalse(store.isWorking)
        XCTAssertNil(store.errorMessage)
        XCTAssertNil(store.userID)
    }

    /// A refresh that fails for any reason but a missing session keeps the stored
    /// session: a launch offline must not drop the block filter or show an
    /// anonymous contributor the sign-in path that would orphan their record.
    func testOnlyAMissingSessionSignsOutOnRefresh() {
        XCTAssertFalse(AuthSessionStore.keepsStoredSession(after: AuthError.sessionMissing))
        XCTAssertTrue(AuthSessionStore.keepsStoredSession(after: URLError(.notConnectedToInternet)))
        XCTAssertTrue(AuthSessionStore.keepsStoredSession(after: URLError(.timedOut)))
    }
}

/// Records every request and answers 204, so a test can read what was sent.
final class RecordingURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requests: [URLRequest] = []
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.requests.append(request)
        let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: "HTTP/1.1", headerFields: [:])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data())
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
