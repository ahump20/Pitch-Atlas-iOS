import XCTest

/// The App Store preview: six real screens, scrolled at a reading pace, while
/// `simctl io recordVideo` films the simulator. Each segment prints a
/// "PA_PREVIEW <name> <start|end> <unix time>" line so the recording can be cut
/// to the moments the app is on screen. Runs only when PA_SHOTS names "preview".
final class AppPreviewUITests: XCTestCase {
    @MainActor
    func testPreviewTour() throws {
        let raw = ProcessInfo.processInfo.environment["PA_SHOTS"] ?? "all"
        try XCTSkipUnless(raw.split(separator: ",").contains("preview"), "PA_SHOTS does not name preview")
        segment("atlas", env: [:]) { app in
            hold(1.6); drift(app, 0.30); hold(1.0); drift(app, 0.30); hold(1.0)
        }
        segment("specimen", env: ["PA_ROUTE": "pitch/four-seam"]) { app in
            hold(2.2); drift(app, 0.30); hold(1.4)
        }
        segment("flightlab", env: ["PA_ROUTE": "softball/flight-lab"]) { app in
            hold(1.2)
            let throwButton = app.buttons["Throw →"]
            for _ in 0..<12 where !throwButton.isHittable { drift(app, 0.12, settle: 0.15) }
            hold(0.6); throwButton.tap(); hold(4.2)
        }
        segment("softball", env: ["PA_ROUTE": "softball"]) { app in
            hold(1.6); drift(app, 0.30); hold(1.4)
        }
        segment("compare", env: ["PA_ROUTE": "compare?a=slider&b=sweeper"]) { app in
            hold(2.6); drift(app, 0.25); hold(1.2)
        }
        segment("index", env: ["PA_TAB": "index"]) { app in
            hold(1.4); drift(app, 0.30); hold(1.4)
        }
    }

    private func segment(_ name: String, env: [String: String], _ body: (XCUIApplication) -> Void) {
        let app = XCUIApplication()
        app.launchEnvironment = env
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 30), "\(name) never showed the tab bar")
        hold(1.5)  // let the first frame settle before the cut begins
        print("PA_PREVIEW \(name) start \(Date().timeIntervalSince1970)")
        body(app)
        print("PA_PREVIEW \(name) end \(Date().timeIntervalSince1970)")
        app.terminate()
    }

    private func hold(_ seconds: TimeInterval) { Thread.sleep(forTimeInterval: seconds) }

    /// Scrolls `fraction` of the screen height, slowly, on the right edge so no
    /// tap lands on a control.
    private func drift(_ app: XCUIApplication, _ fraction: CGFloat, settle: TimeInterval = 0.4) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.7))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.7 - fraction))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: 300, thenHoldForDuration: 0.2)
        hold(settle)
    }
}
