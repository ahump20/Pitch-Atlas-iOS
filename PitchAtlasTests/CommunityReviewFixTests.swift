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

    /// A refresh that fails for any reason but a missing session keeps the stored
    /// session: a launch offline must not drop the block filter or show an
    /// anonymous contributor the sign-in path that would orphan their record.
    func testOnlyAMissingSessionSignsOutOnRefresh() {
        XCTAssertFalse(AuthSessionStore.keepsStoredSession(after: AuthError.sessionMissing))
        XCTAssertTrue(AuthSessionStore.keepsStoredSession(after: URLError(.notConnectedToInternet)))
        XCTAssertTrue(AuthSessionStore.keepsStoredSession(after: URLError(.timedOut)))
    }
}
