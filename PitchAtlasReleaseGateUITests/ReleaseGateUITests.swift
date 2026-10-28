import XCTest

/// Pre-archive release gate, run manually via the PitchAtlasReleaseGate
/// scheme. This drives the REAL app UI against PRODUCTION Supabase, so it is
/// deliberately not part of the PitchAtlas scheme CI runs:
///
///   xcodebuild test -project PitchAtlas.xcodeproj \
///     -scheme PitchAtlasReleaseGate \
///     -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
///
/// It proves the anonymous write path end to end — mint-on-write, the
/// column-scoped insert, RETURNING id — by filing one honest, clearly
/// labeled gate post. The post and its throwaway anonymous account are
/// removed right afterward by the in-app account deletion step of the gate
/// (Atlas → Account & Safety → Delete account), which doubles as the
/// 5.1.1(v) proof.
final class ReleaseGateUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAnonymousDiscussionPostSubmitsEndToEnd() throws {
        let app = XCUIApplication()
        // DEBUG QA hook: open straight onto the slider specimen.
        app.launchEnvironment["PA_PITCH"] = "slider"
        app.launch()

        // The discussion drawer sits far down the specimen page, under the field
        // notes chapter. Swipe until its bar is on screen and tappable, then
        // open it.
        //
        // Do NOT use app.swipeUp(): it starts at screen center, which on this
        // page is the interactive 3D specimen stage — the drag orbits the ball
        // and the page never scrolls. Start each stroke low, below the stage.
        func scrollUpOnePage() {
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.82))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.18))
            start.press(forDuration: 0.05, thenDragTo: end)
        }

        let discussionTab = app.buttons["discussion-drawer"]
        var swipes = 0
        while !(discussionTab.exists && discussionTab.isHittable), swipes < 40 {
            scrollUpOnePage()
            swipes += 1
        }
        XCTAssertTrue(
            discussionTab.exists && discussionTab.isHittable,
            "The discussion drawer never became tappable after \(swipes) swipes"
        )
        discussionTab.tap()

        let field = app.textFields["File a grip cue, breakdown, image, or clip. Keep it about the pitch."]
        if !(field.exists && field.isHittable) {
            scrollUpOnePage()
        }
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Discussion composer field not found")
        field.tap()
        field.typeText(
            "Release gate for build 11: verifying the anonymous discussion path end to end. This post deletes with its test account in a moment."
        )

        let submit = app.buttons["File post"]
        XCTAssertTrue(submit.waitForExistence(timeout: 5), "File post button not found")
        if !submit.isHittable {
            scrollUpOnePage()
        }
        submit.tap()

        // "Filed ✓" is the success line; the failure path writes a different
        // message, so this is the real server-accepted signal.
        XCTAssertTrue(
            app.staticTexts["Filed ✓"].waitForExistence(timeout: 20),
            "The post was not accepted by the server within 20s"
        )
    }
}
