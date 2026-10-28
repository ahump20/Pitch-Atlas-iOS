import XCTest

/// Diagnostic only (branch diag/home-scroll, never merged): the tour's strokes
/// leave the home at its top. Each case relaunches the home, strokes it one way,
/// and names a screenshot with where the lede sat before, right after, and two
/// seconds after the stroke — the result rides out in the attachment name.
final class HomeScrollDiagnosticsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = true
        let raw = ProcessInfo.processInfo.environment["PA_SHOTS"] ?? ""
        try XCTSkipUnless(raw.contains("homediag"), "diagnostic runs only on a homediag tour")
    }

    @MainActor
    func testHomeScrollStrokes() {
        // Round 2: every case strokes the right edge as the tour does; each switches
        // one piece of the hero card off (PA_DIAG_HERO) while the film plays.
        let flags = ["baseline", "notilt", "nolean", "noclip", "noedge", "nofocus", "nocontext", "notilt,nolean,noclip,noedge,nofocus,nocontext"]
        let strokes: [(String, (XCUIApplication) -> Void)] = flags.map { flag in
            (flag, { app in Self.drag(app, x: 0.94, hold: true) })
        }
        for (name, stroke) in strokes {
            let app = XCUIApplication()
            app.launchEnvironment = ["PA_TAB": "atlas", "PA_DIAG_HERO": name]
            app.launch()
            _ = app.tabBars.firstMatch.waitForExistence(timeout: 30)
            Thread.sleep(forTimeInterval: 3)
            let lede = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'A grip to inspect'")).firstMatch
            let scrolls = app.scrollViews.count
            let y0 = Self.y(lede)
            stroke(app)
            let y1 = Self.y(lede)
            Thread.sleep(forTimeInterval: 2)
            let y2 = Self.y(lede)
            let shot = XCUIScreen.main.screenshot()
            let attachment = XCTAttachment(screenshot: shot)
            attachment.name = "diag2-\(name.replacingOccurrences(of: ",", with: "+"))-sv\(scrolls)-y0_\(y0)-y1_\(y1)-y2_\(y2)"
            attachment.lifetime = .keepAlways
            add(attachment)
            app.terminate()
        }
    }

    private static func y(_ element: XCUIElement) -> String {
        element.exists ? String(Int(element.frame.minY)) : "gone"
    }

    private static func drag(_ app: XCUIApplication, x: CGFloat, hold: Bool) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: 0.78))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: 0.28))
        if hold {
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.3)
        } else {
            start.press(forDuration: 0.01, thenDragTo: end)
        }
    }
}
