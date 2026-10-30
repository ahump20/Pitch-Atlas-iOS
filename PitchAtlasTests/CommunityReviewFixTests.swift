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
