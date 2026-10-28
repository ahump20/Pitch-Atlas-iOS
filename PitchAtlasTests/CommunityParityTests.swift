import XCTest
@testable import PitchAtlas

/// The community layer reads and writes what pitch-atlas.com does (web main
/// 47e21e6: lib/discussion.ts, lib/community.ts, FieldNotes.tsx,
/// DiscussionForum.tsx), and says the web's words when it can't.
final class CommunityParityTests: XCTestCase {

    // MARK: One key per topic, in the web's format

    func testCommunityTopicKeysUseTheWebFormats() {
        XCTAssertEqual(CommunityTopic.specimen(slug: "four-seam").key, "four-seam")
        XCTAssertEqual(CommunityTopic.repertoire(id: "gyroball").key, "repertoire:gyroball")
        XCTAssertEqual(CommunityTopic.lost(slug: "shine-ball").key, "lost:shine-ball")
        XCTAssertEqual(CommunityTopic.learn(slug: "grip-pressure").key, "learn:grip-pressure")
        XCTAssertEqual(CommunityTopic.softball(slug: "riseball").key, "softball:riseball")
    }

    func testFieldNotesOpenOnlyOnASpecimen() {
        XCTAssertTrue(CommunityTopic.specimen(slug: "four-seam").allowsFieldNotes)
        XCTAssertEqual(CommunityTopic.specimen(slug: "four-seam").fieldNoteSlug, "four-seam")
        for topic: CommunityTopic in [.repertoire(id: "gyroball"), .lost(slug: "shine-ball"), .learn(slug: "x"), .softball(slug: "riseball")] {
            XCTAssertFalse(topic.allowsFieldNotes, "\(topic.key) should carry discussion only")
            XCTAssertNil(topic.fieldNoteSlug)
        }
    }

    func testBoundaryOnlyLearnWingsNeverGetADiscussion() {
        let store = PitchStore()
        XCTAssertFalse(store.knowledge.isEmpty)
        XCTAssertTrue(store.knowledge.contains { !$0.allowsDiscussion }, "the bundle should carry a boundary-only wing")
        for wing in store.knowledge {
            if wing.allowsDiscussion {
                XCTAssertEqual(CommunityTopic.learnWing(wing)?.key, "learn:\(wing.slug)")
            } else {
                XCTAssertNil(CommunityTopic.learnWing(wing), "\(wing.slug) is boundary-only and must stop at education")
            }
        }
    }

    // MARK: Moderated reads

    func testFieldNotesParamsEncodeTheFunctionArgument() throws {
        let data = try JSONEncoder().encode(FieldNotesParams(pitchSlug: "four-seam"))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])
        XCTAssertEqual(object, ["p_pitch_slug": "four-seam"])
    }

    func testOneUnreadableRowDropsOutWithoutEmptyingTheList() throws {
        let posts = Data("""
        [
          {"id":"p1","topic_key":"four-seam","author_id":"a1","display_name":"One","parent_id":null,"body":"Kept.","created_at":"2026-10-27T19:23:45.123456+00:00"},
          {"id":"p2","topic_key":"four-seam","author_id":"a2","display_name":"Two","parent_id":null,"created_at":"2026-10-27T19:24:00+00:00"}
        ]
        """.utf8)
        let decodedPosts = try JSONDecoder().decode([LossyRow<DiscussionPost>].self, from: posts).compactMap(\.value)
        XCTAssertEqual(decodedPosts.map(\.id), ["p1"])

        let goodNote = fieldNoteJSON(id: "n1", authorID: "\"a1\"")
        let notes = Data("[\(goodNote), {\"id\":\"n2\",\"pitch_slug\":\"four-seam\",\"author_id\":\"a2\",\"display_name\":\"Two\"}]".utf8)
        let decodedNotes = try JSONDecoder().decode([LossyRow<CommunityFieldNote>].self, from: notes).compactMap(\.value)
        XCTAssertEqual(decodedNotes.map(\.id), ["n1"])
    }

    func testARowFromADeletedAccountStaysReadable() throws {
        let note = try JSONDecoder().decode(CommunityFieldNote.self, from: Data(fieldNoteJSON(id: "n1", authorID: "null").utf8))
        XCTAssertNil(note.authorID)
        XCTAssertEqual(CommunityVisibility.visibleFieldNotes([note], hiddenAuthorIDs: ["someone"]).map(\.id), ["n1"])

        let post = try JSONDecoder().decode(DiscussionPost.self, from: Data("""
        {"id":"p1","topic_key":"four-seam","author_id":null,"display_name":"Gone","parent_id":null,"body":"Still here.","created_at":"2026-10-27T19:23:45+00:00"}
        """.utf8))
        XCTAssertNil(post.authorID)
        XCTAssertEqual(CommunityVisibility.visibleDiscussionPosts([post], hiddenAuthorIDs: ["someone"]).map(\.id), ["p1"])
        XCTAssertFalse(CommunityVisibility.viewerIsAuthor(post.authorID, viewerID: "someone"))
    }

    // MARK: The thread

    func testThreadPutsRepliesUnderTheirPostLikeTheWeb() {
        let rows = [
            post("root-1", at: "2026-10-27T10:00:00+00:00"),
            post("reply-1a", parent: "root-1", at: "2026-10-27T10:05:00+00:00"),
            post("root-2", at: "2026-10-27T11:00:00+00:00"),
            post("reply-1b", parent: "root-1", at: "2026-10-27T12:00:00+00:00"),
            post("orphan", parent: "gone", at: "2026-10-27T13:00:00+00:00"),
        ]
        let thread = CommunityThread.build(rows)
        XCTAssertEqual(thread.map(\.id), ["root-2", "root-1"], "top-level posts read newest first")
        XCTAssertEqual(thread[1].replies.map(\.id), ["reply-1a", "reply-1b"], "replies read oldest first")
        XCTAssertTrue(thread[0].replies.isEmpty)
        XCTAssertFalse(thread.flatMap { [$0.id] + $0.replies.map(\.id) }.contains("orphan"), "a reply with no visible parent has no context")
    }

    func testBlockingHidesAnAuthorsRepliesAndTheirWholeThread() {
        var visibleRoot = post("root-1", author: "visible")
        visibleRoot.replies = [post("reply-ok", author: "visible", parent: "root-1"), post("reply-blocked", author: "blocked", parent: "root-1")]
        var blockedRoot = post("root-2", author: "blocked")
        blockedRoot.replies = [post("reply-under-blocked", author: "visible", parent: "root-2")]

        let visible = CommunityVisibility.visibleDiscussionPosts([visibleRoot, blockedRoot], hiddenAuthorIDs: ["blocked"])
        XCTAssertEqual(visible.map(\.id), ["root-1"])
        XCTAssertEqual(visible[0].replies.map(\.id), ["reply-ok"])
    }

    func testBatchesSplitAtTheWebsHundred() {
        XCTAssertEqual(CommunityService.batchSize, 100)
        XCTAssertEqual(CommunityService.batches(Array(0..<250)).map(\.count), [100, 100, 50])
        XCTAssertEqual(CommunityService.batches([Int]()).count, 0)
        XCTAssertEqual(CommunityService.batches(Array(0..<100)).map(\.count), [100])
    }

    func testTimeAgoReadsPostgresTimestampsAndNeverInventsOne() throws {
        let stamp = "2026-10-27T19:23:45.123456+00:00"
        let filed = try XCTUnwrap(CommunityTime.parse(stamp))
        XCTAssertEqual(CommunityTime.ago(stamp, now: filed.addingTimeInterval(30)), "just now")
        XCTAssertEqual(CommunityTime.ago(stamp, now: filed.addingTimeInterval(90)), "1m ago")
        XCTAssertEqual(CommunityTime.ago(stamp, now: filed.addingTimeInterval(2 * 3600 + 5)), "2h ago")
        XCTAssertEqual(CommunityTime.ago(stamp, now: filed.addingTimeInterval(3 * 86_400)), "3d ago")
        XCTAssertNotNil(CommunityTime.parse("2026-10-27T19:23:45+00:00"))
        XCTAssertNotNil(CommunityTime.parse("2026-10-27T19:23:45.5Z"))
        XCTAssertEqual(
            CommunityTime.parse("2026-10-27T19:23:45.999999+00:00")?.timeIntervalSince(filed) ?? -1,
            0.876,
            accuracy: 0.001
        )
        XCTAssertNil(CommunityTime.ago("not a date"))
    }

    // MARK: Who owns what

    func testViewerIsAuthorNeedsBothIdsToMatch() {
        XCTAssertTrue(CommunityVisibility.viewerIsAuthor("me", viewerID: "me"))
        XCTAssertFalse(CommunityVisibility.viewerIsAuthor("them", viewerID: "me"))
        XCTAssertFalse(CommunityVisibility.viewerIsAuthor(nil, viewerID: "me"))
        XCTAssertFalse(CommunityVisibility.viewerIsAuthor("me", viewerID: nil))
        XCTAssertFalse(CommunityVisibility.viewerIsAuthor(nil, viewerID: nil))
    }

    /// The server prints a uuid lowercase and compares storage folders and
    /// author ids as text, so the app's id has to match it character for character.
    func testUserIdMatchesHowTheServerPrintsIt() throws {
        let id = try XCTUnwrap(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F"))
        XCTAssertEqual(AuthSessionStore.idString(id), "e621e1f8-c36c-495a-93fc-0c247a3e6e5f")
        XCTAssertTrue(CommunityVisibility.viewerIsAuthor("e621e1f8-c36c-495a-93fc-0c247a3e6e5f", viewerID: AuthSessionStore.idString(id)))
    }

    func testDeleteGuardMatchesTheWeb() {
        XCTAssertTrue(CommunityVisibility.canDeletePost(replyAuthorIDs: [], viewerID: "me"))
        XCTAssertTrue(CommunityVisibility.canDeletePost(replyAuthorIDs: ["me", nil], viewerID: "me"), "your own replies and orphaned ones don't block")
        XCTAssertFalse(CommunityVisibility.canDeletePost(replyAuthorIDs: ["me", "them"], viewerID: "me"))
        XCTAssertEqual(
            CommunityServiceError.deleteBlockedByReplies.errorDescription,
            "That post has replies from other contributors, so it cannot be deleted."
        )
    }

    // MARK: Writes stay inside the column grants

    func testReplyAndMediaReportStayInsideTheirGrants() throws {
        let reply = try NewDiscussionPost.validated(topicKey: "four-seam", displayName: "Tester", body: "Same here.", parentID: "post-1")
        XCTAssertEqual(try encodedKeys(reply), ["topic_key", "display_name", "body", "parent_id"])

        let mediaReport = CommunityReport(noteID: nil, postID: nil, mediaID: "media-1", reason: nil)
        XCTAssertEqual(try encodedKeys(mediaReport), ["media_id"])
        XCTAssertTrue(try encodedKeys(mediaReport).isSubset(of: ["post_id", "media_id", "reason"]))
    }

    func testReportReasonIsOptionalAndShort() {
        XCTAssertNil(CommunityReport.cleanReason("   \n"), "an empty reason is stored as NULL, not ''")
        XCTAssertEqual(CommunityReport.cleanReason("  spam  "), "spam")
        XCTAssertEqual(CommunityReport.cleanReason(String(repeating: "x", count: 400))?.count, CommunityReport.reasonLimit)
        XCTAssertEqual(CommunityPanel.noteReportReasons.map(\.value), ["abusive-unsafe", "off-topic", "spam"])
    }

    // MARK: The web's words

    func testTaggedTriggerMessagesShowTheServerSentence() {
        func message(_ raw: String) -> String {
            CommunityService.userMessage(for: NSError(domain: "PostgREST", code: 0, userInfo: [NSLocalizedDescriptionKey: raw]))
        }
        XCTAssertEqual(message("rate_limit: too many posts in a short time"), "Too many posts in a short time.")
        XCTAssertEqual(message("content_blocked: that word is not allowed here."), "That word is not allowed here.")
        XCTAssertEqual(message("media_blocked: video is too long\nDETAIL: 61s"), "Video is too long.")
        XCTAssertEqual(message("too_deep:"), "Replies can only go one level deep.")
        XCTAssertEqual(message("invalid_parent:   "), "That reply target is no longer available.")
        XCTAssertEqual(message("rate_limit: slow down!"), "Slow down!")
        XCTAssertNil(CommunityService.taggedMessage(in: "permission denied for table field_notes"))
        XCTAssertEqual(
            message("weak_tier_requires_note"),
            "A relayed or untested claim needs a short source note - say where it came from."
        )
    }

    func testOutageCopyIsTheWebsAndCarriesNoServerText() {
        XCTAssertEqual(CommunityPanel.outageReason, "The server didn't answer.")
    }

    // MARK: Helpers

    private func post(_ id: String, author: String = "author", parent: String? = nil, at createdAt: String = "2026-10-27T10:00:00+00:00") -> DiscussionPost {
        DiscussionPost(id: id, topicKey: "four-seam", authorID: author, displayName: author, parentID: parent, body: "Body.", createdAt: createdAt)
    }

    private func fieldNoteJSON(id: String, authorID: String) -> String {
        """
        {"id":"\(id)","pitch_slug":"four-seam","author_id":\(authorID),"display_name":"Tester","tweak":"Thumb under the horseshoe.","player_level":"college-plus","arm_slot":"three-quarter","velocity_band":null,"intent":"more-movement","claimed_result_kind":"worked-in-bullpen","claimed_result_note":null,"sample_size":null,"evidence_url":null,"evidence_label":null,"source_tier":"community-firsthand","note":null,"adoption_count":0,"helpful_count":0,"base_rank":0,"created_at":"2026-10-27T19:23:45.123456+00:00"}
        """
    }

    private func encodedKeys<T: Encodable>(_ value: T) throws -> Set<String> {
        let data = try JSONEncoder().encode(value)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        return Set(object.keys)
    }
}
