import XCTest

/// Pre-archive release gate, run manually via the PitchAtlasReleaseGate
/// scheme. This drives the REAL app UI against PRODUCTION Supabase, so it is
/// deliberately not part of the PitchAtlas scheme CI runs:
///
///   xcodebuild test -project PitchAtlas.xcodeproj \
///     -scheme PitchAtlasReleaseGate \
///     -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
///
/// It proves the anonymous write path end to end — mint-on-write, the handle
/// saved to the profile, the column-scoped inserts, RETURNING id — by filing
/// one clearly labeled field note, discussion post and reply under the handle
/// "Release gate". They and their throwaway anonymous account are removed by
/// the test's own teardown, through the in-app account deletion
/// (Account & Safety → Delete account), which doubles as the 5.1.1(v) proof.
final class ReleaseGateUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAnonymousContributionsFileEndToEnd() throws {
        let app = XCUIApplication()
        // DEBUG QA hook: open straight onto the slider specimen.
        app.launchEnvironment["PA_PITCH"] = "slider"
        app.launch()

        // Do NOT use app.swipeUp(): it starts at screen center, which on this
        // page is the interactive 3D specimen stage — the drag orbits the ball
        // and the page never scrolls. Start each stroke low, below the stage.
        func scrollUpOnePage() {
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.82))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.18))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        func reach(_ element: XCUIElement, strokes: Int = 40) -> Bool {
            for _ in 0..<strokes where !(element.exists && element.isHittable) { scrollUpOnePage() }
            return element.exists && element.isHittable
        }
        // Both contribution gates (guidelines, 17+) show until accepted once on
        // this device.
        func acceptGates() {
            for gate in ["I accept the community guidelines", "I confirm I am 17 or older"] {
                let toggle = app.switches.matching(NSPredicate(format: "label BEGINSWITH %@", gate)).firstMatch
                guard toggle.waitForExistence(timeout: 3) else { continue }
                _ = reach(toggle, strokes: 4)
                if toggle.value as? String != "1" {
                    toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
                }
                XCTAssertEqual(toggle.value as? String, "1", "Gate did not turn on: \(gate)")
            }
        }
        // A multi-line field takes Return as a new line, so each composer gets
        // its long text first and its single-line name last, ended with Return:
        // that closes the keyboard, which otherwise covers the file button and
        // takes the tap.
        func typeName(_ field: XCUIElement) {
            field.tap()
            field.typeText("Release gate\n")
            XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3), "The keyboard never went away")
        }

        // Whatever happens below, delete the throwaway anonymous account (and
        // what it filed) through the app's own Account & Safety screen.
        addTeardownBlock { @MainActor in Self.deleteGateAccount() }

        // 1. A field note, filed under the handle typed.
        let write = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Write a note")).firstMatch
        XCTAssertTrue(reach(write), "Write a note never came into reach on the slider page")
        write.tap()
        acceptGates()
        // The note's fields expose only their placeholders to accessibility.
        func placeholder(_ text: String) -> XCUIElement {
            app.textFields.matching(NSPredicate(format: "placeholderValue BEGINSWITH %@", text)).firstMatch
        }
        let tweak = placeholder("Thumb tucked deeper")
        XCTAssertTrue(reach(tweak, strokes: 4), "The tweak field not found")
        tweak.tap()
        tweak.typeText("Release gate for build 13: a test note that deletes with its test account.")
        typeName(placeholder("e.g. RHP_threequarter"))
        let fileNote = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "File field note")).firstMatch
        XCTAssertTrue(reach(fileNote, strokes: 6), "File field note not found")
        fileNote.tap()
        XCTAssertTrue(
            app.staticTexts["Sent for review ✓ · it stays private until approved."].waitForExistence(timeout: 20),
            "The field note was not accepted by the server within 20s"
        )

        // 2. A discussion post.
        let drawer = app.buttons["discussion-drawer"]
        XCTAssertTrue(reach(drawer), "The discussion drawer never became tappable")
        drawer.tap()
        acceptGates()
        let field = app.textFields["File a grip cue, breakdown, image, or clip. Keep it about the pitch."]
        XCTAssertTrue(reach(field, strokes: 4), "Discussion composer field not found")
        field.tap()
        field.typeText(
            "Release gate for build 13: verifying the anonymous discussion path end to end. This post deletes with its test account in a moment."
        )
        let handle = app.textFields["Your name"]
        typeName(handle)
        let submit = app.buttons["File post"]
        XCTAssertTrue(reach(submit, strokes: 4), "File post button not found")
        submit.tap()
        // "Filed ✓" is the success line; the failure path writes a different
        // message, so this is the real server-accepted signal.
        XCTAssertTrue(app.staticTexts["Filed ✓"].waitForExistence(timeout: 20),
                      "The post was not accepted by the server within 20s")

        // 3. The post shows under the handle typed (its reply button names the
        // author), and a reply to it files.
        let replyTo = app.buttons["Reply to Release gate"]
        XCTAssertTrue(reach(replyTo, strokes: 6), "The post never showed under the handle Release gate")
        replyTo.tap()
        let reply = app.textFields["Reply to Release gate…"]
        XCTAssertTrue(reply.waitForExistence(timeout: 5), "The reply field never opened")
        reply.tap()
        reply.typeText("Release gate reply for build 13.")
        // The reply composer repeats the name field (same handle, already
        // "Release gate"); Return in that copy closes the keyboard unchanged.
        let names = app.textFields.matching(identifier: "Your name")
        let replyName = names.element(boundBy: names.count - 1)
        replyName.tap()
        replyName.typeText("\n")
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3), "The keyboard never went away")
        let fileReply = app.buttons.matching(NSPredicate(format: "label == %@", "Reply")).firstMatch
        XCTAssertTrue(reach(fileReply, strokes: 6), "The reply's file button not found")
        fileReply.tap()
        XCTAssertTrue(app.staticTexts["Reply filed ✓"].waitForExistence(timeout: 20),
                      "The reply was not accepted by the server within 20s")

        // PA_GATE_HOLD seconds before teardown, so the rows can be read on the
        // server while they exist.
        if let hold = ProcessInfo.processInfo.environment["PA_GATE_HOLD"].flatMap(Double.init) {
            print("PA_GATE_HOLD start \(Date().timeIntervalSince1970)")
            Thread.sleep(forTimeInterval: hold)
        }
    }

    /// Relaunches onto Account & Safety (the anonymous session survives the
    /// relaunch in the keychain) and deletes the account. If no account was
    /// ever minted there is nothing to delete.
    @MainActor
    static func deleteGateAccount() {
        let app = XCUIApplication()
        app.terminate()
        app.launchEnvironment = ["PA_ROUTE": "account"]
        app.launch()
        let delete = app.buttons["Delete account"]
        guard delete.waitForExistence(timeout: 15) else { return }
        for _ in 0..<6 where !delete.isHittable {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)))
        }
        delete.tap()
        let confirm = app.alerts["Delete this account?"].buttons["Delete"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "The delete confirmation never showed")
        confirm.tap()
        XCTAssertTrue(app.alerts["Account deleted"].waitForExistence(timeout: 20),
                      "The gate account was not deleted; remove it by hand before release")
    }
}
