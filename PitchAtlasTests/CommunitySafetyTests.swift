import XCTest
@testable import PitchAtlas

final class CommunitySafetyTests: XCTestCase {
    func testAnUpgradeNeverReusesSeventeenPlusOrOldGuidelineConsent() throws {
        let suite = "CommunitySafetyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: "pa.community.guidelinesAccepted")
        defaults.set(true, forKey: "pa.community.ageConfirmed")
        XCTAssertFalse(CommunityConsent.canContribute(in: defaults))
        defaults.set(true, forKey: CommunityConsent.termsKey)
        XCTAssertFalse(CommunityConsent.canContribute(in: defaults))
        defaults.set(true, forKey: CommunityConsent.adultKey)
        XCTAssertTrue(CommunityConsent.canContribute(in: defaults))
        defaults.set(false, forKey: CommunityConsent.termsKey)
        XCTAssertFalse(CommunityConsent.canContribute(in: defaults))
    }

    @MainActor
    func testHiddenContentPersistsWithoutASessionAndKeepsKindsSeparate() throws {
        let suite = "CommunitySafetyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let content = HiddenCommunityContent(defaults: defaults)
        content.hide("same-id", kind: .post)
        content.hide("same-id", kind: .post)
        content.hide("note-2", kind: .note)
        content.hide("image-3", kind: .media)
        content.hide("", kind: .post)
        XCTAssertEqual(content.postIDs, ["same-id"])
        XCTAssertFalse(content.noteIDs.contains("same-id"))
        let relaunched = HiddenCommunityContent(defaults: defaults)
        XCTAssertEqual(relaunched.postIDs, ["same-id"])
        XCTAssertEqual(relaunched.noteIDs, ["note-2"])
        XCTAssertEqual(relaunched.mediaIDs, ["image-3"])
    }

    func testHidingAReplyPreservesItsParentAndSiblingButHidingParentRemovesItsThread() {
        var parent = post("parent")
        parent.replies = [post("reply-hidden", parent: "parent"), post("reply-visible", parent: "parent")]
        let sibling = post("other-parent")
        let replyHidden = CommunityVisibility.visibleDiscussionPosts(
            [parent, sibling], hiddenAuthorIDs: [], hiddenPostIDs: ["reply-hidden"]
        )
        XCTAssertEqual(replyHidden.map(\.id), ["parent", "other-parent"])
        XCTAssertEqual(replyHidden[0].replies.map(\.id), ["reply-visible"])
        let parentHidden = CommunityVisibility.visibleDiscussionPosts(
            [parent, sibling], hiddenAuthorIDs: [], hiddenPostIDs: ["parent"]
        )
        XCTAssertEqual(parentHidden.map(\.id), ["other-parent"])
        XCTAssertTrue(parentHidden.flatMap(\.replies).isEmpty)
    }

    @MainActor
    func testFailedReportsSurviveRelaunchAndRetryRemovesOnlyTheDeliveredReport() async throws {
        let suite = "CommunitySafetyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let content = HiddenCommunityContent(defaults: defaults)
        let first = content.queueReport("post-1", kind: .post, reason: "Harassment")
        let failure = await content.deliverReport(first.id) { _ in
            throw URLError(.notConnectedToInternet)
        }
        XCTAssertEqual(failure, .failed)
        let second = content.queueReport("note-2", kind: .note, reason: "Unsafe advice")
        let relaunched = HiddenCommunityContent(defaults: defaults)
        XCTAssertEqual(relaunched.pendingReports, [first, second])
        XCTAssertTrue(relaunched.sendingReportIDs.isEmpty)
        let success = await relaunched.deliverReport(first.id) { report in
            XCTAssertEqual(report, first)
        }
        XCTAssertEqual(success, .sent)
        let afterRetry = HiddenCommunityContent(defaults: defaults)
        XCTAssertEqual(afterRetry.pendingReports, [second])
        XCTAssertTrue(afterRetry.postIDs.contains("post-1"))
        XCTAssertTrue(afterRetry.noteIDs.contains("note-2"))
    }

    @MainActor
    func testQueuedReportsKeepDistinctKindsAndDoNotOverwriteAnUnsentReason() throws {
        let suite = "CommunitySafetyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let content = HiddenCommunityContent(defaults: defaults)
        let original = content.queueReport("same-id", kind: .post, reason: "  Harassment  ")
        let duplicate = content.queueReport("same-id", kind: .post, reason: "Replacement")
        let media = content.queueReport("same-id", kind: .media, reason: nil)
        XCTAssertEqual(duplicate, original)
        XCTAssertEqual(original.reason, "Harassment")
        XCTAssertEqual(content.pendingReports, [original, media])
        XCTAssertNotEqual(original.id, media.id)
        XCTAssertEqual(HiddenCommunityContent(defaults: defaults).pendingReports, [original, media])
    }

    @MainActor
    func testAnAlreadyDeliveredReportCannotClaimAnotherSuccessfulSend() async throws {
        let suite = "CommunitySafetyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let content = HiddenCommunityContent(defaults: defaults)
        let report = content.queueReport("post-1", kind: .post, reason: nil)
        _ = await content.deliverReport(report.id) { _ in }
        let repeated = await content.deliverReport(report.id) { _ in
            XCTFail("A delivered report must not be sent twice")
        }
        XCTAssertEqual(repeated, .noPendingReport)
        XCTAssertTrue(content.pendingReports.isEmpty)
        XCTAssertTrue(content.postIDs.contains("post-1"))
    }

    func testHidingMediaFiltersPostAndReplyAttachmentsWithoutRemovingText() {
        var parent = post("parent")
        parent.media = [media("hidden-image", post: "parent"), media("visible-image", post: "parent")]
        var reply = post("reply", parent: "parent")
        reply.media = [media("hidden-reply-image", post: "reply")]
        parent.replies = [reply]
        let visible = CommunityVisibility.visibleDiscussionPosts(
            [parent], hiddenAuthorIDs: [], hiddenMediaIDs: ["hidden-image", "hidden-reply-image"]
        )
        XCTAssertEqual(visible[0].body, parent.body)
        XCTAssertEqual(visible[0].media.map(\.id), ["visible-image"])
        XCTAssertEqual(visible[0].replies.map(\.id), ["reply"])
        XCTAssertTrue(visible[0].replies[0].media.isEmpty)
    }

    func testPersonalHidingDoesNotBypassBlockedAuthorFiltering() {
        let visible = CommunityVisibility.visibleDiscussionPosts(
            [post("personal"), post("blocked", author: "blocked-author"), post("kept")],
            hiddenAuthorIDs: ["blocked-author"], hiddenPostIDs: ["personal"]
        )
        XCTAssertEqual(visible.map(\.id), ["kept"])
    }

    func testContactValidationTrimsInputAllowsNoEmailAndBoundsMessage() throws {
        let request = try SafetyContactRequest.validated(message: "  Please review this activity.\n", replyEmail: " \n")
        XCTAssertEqual(request.message, "Please review this activity.")
        XCTAssertNil(request.replyEmail)
        XCTAssertThrowsError(try SafetyContactRequest.validated(message: "too short", replyEmail: ""))
        XCTAssertNoThrow(try SafetyContactRequest.validated(message: String(repeating: "a", count: 4_000), replyEmail: ""))
        XCTAssertThrowsError(try SafetyContactRequest.validated(message: String(repeating: "a", count: 4_001), replyEmail: ""))
        XCTAssertThrowsError(try SafetyContactRequest.validated(message: "Please review this activity.", replyEmail: "invalid"))
        XCTAssertThrowsError(try SafetyContactRequest.validated(message: "Please review this activity.", replyEmail: "two words@example.com"))
    }

    func testContactRequestUsesPrivateRPCParametersAndPreservesReplyAddress() throws {
        let request = try SafetyContactRequest.validated(message: "Please review this activity.", replyEmail: " reader@example.com ")
        let encoded = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: String])
        XCTAssertEqual(encoded, ["p_message": "Please review this activity.", "p_reply_email": "reader@example.com"])
    }

    func testContactMessageLimitsMatchServerUnicodeScalarCounts() throws {
        let composed = String(repeating: "e\u{301}", count: 5)
        XCTAssertEqual(composed.count, 5)
        XCTAssertEqual(composed.unicodeScalars.count, 10)
        XCTAssertTrue(SafetyContactRequest.hasValidMessageLength(" \(composed)\n"))
        XCTAssertNoThrow(try SafetyContactRequest.validated(message: composed, replyEmail: ""))
        XCTAssertThrowsError(try SafetyContactRequest.validated(message: String(composed.dropLast()), replyEmail: ""))

        let family = "👨‍👩‍👧‍👦"
        let maximum = String(repeating: family, count: 571) + "abc"
        XCTAssertEqual(maximum.unicodeScalars.count, 4_000)
        XCTAssertNoThrow(try SafetyContactRequest.validated(message: maximum, replyEmail: ""))
        XCTAssertFalse(SafetyContactRequest.hasValidMessageLength(maximum + "d"))
        XCTAssertThrowsError(try SafetyContactRequest.validated(message: maximum + "d", replyEmail: ""))
    }

    func testContactMessageClampPreservesWholeEmojiAndCombiningCharacters() {
        let family = "👨‍👩‍👧‍👦"
        let beforeEmoji = String(repeating: "a", count: 3_996)
        XCTAssertEqual(SafetyContactRequest.boundedMessage(beforeEmoji + family), beforeEmoji)

        let combined = "e\u{301}"
        let exactFit = String(repeating: "a", count: 3_998) + combined
        XCTAssertEqual(SafetyContactRequest.boundedMessage(exactFit + "z"), exactFit)
        XCTAssertEqual(SafetyContactRequest.boundedMessage(exactFit).unicodeScalars.count, 4_000)
        let beforeCombined = String(repeating: "a", count: 3_999)
        XCTAssertEqual(SafetyContactRequest.boundedMessage(beforeCombined + combined), beforeCombined)
        XCTAssertTrue(SafetyContactRequest.boundedMessage("e" + String(repeating: "\u{301}", count: 4_000)).isEmpty)
    }

    func testContactReplyEmailLimitMatchesServerUnicodeScalarCount() {
        let atLimit = String(repeating: "e\u{301}", count: 121) + "@example.com"
        XCTAssertEqual(atLimit.unicodeScalars.count, 254)
        XCTAssertNoThrow(try SafetyContactRequest.validated(message: "Please review this activity.", replyEmail: atLimit))
        XCTAssertThrowsError(try SafetyContactRequest.validated(message: "Please review this activity.", replyEmail: "a" + atLimit))
    }

    func testContactFailureNeverExposesServerTextOrClaimsDelivery() {
        let error = NSError(domain: "service", code: 500, userInfo: [NSLocalizedDescriptionKey: "private server detail"])
        XCTAssertEqual(SafetyContactRequest.userMessage(for: error), "Message did not send. Your text is still here; try again.")
        let rateLimit = NSError(domain: "service", code: 429, userInfo: [NSLocalizedDescriptionKey: "rate_limit: internal detail"])
        XCTAssertEqual(SafetyContactRequest.userMessage(for: rateLimit), "Too many messages. Try again in an hour.")
    }

    private func post(_ id: String, author: String = "author", parent: String? = nil) -> DiscussionPost {
        DiscussionPost(id: id, topicKey: "four-seam", authorID: author, displayName: author,
                       parentID: parent, body: "A pitching note.", createdAt: "2026-11-04T12:00:00Z")
    }

    private func media(_ id: String, post: String) -> DiscussionMedia {
        DiscussionMedia(id: id, postID: post, storagePath: "test/\(id).jpg", kind: "image", width: 10, height: 10)
    }
}
