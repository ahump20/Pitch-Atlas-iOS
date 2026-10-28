import XCTest

/// The screenshot tour: opens each screen the way a pitchatlas:// link would and
/// photographs it top to bottom, so every screen can be checked against the same
/// page on pitch-atlas.com. Run by .github/workflows/screenshots.yml through the
/// PitchAtlasScreenshots scheme — never by the PitchAtlas scheme. PA_SHOTS
/// (passed as TEST_RUNNER_PA_SHOTS) names the stops to run, comma-separated;
/// unset or "all" runs the whole tour. Read-only: nothing here writes anywhere.
final class ScreenshotTourUITests: XCTestCase {

    struct Stop {
        let name: String
        let env: [String: String]
        /// The most pages to photograph; the walk also stops when a page repeats.
        let pages: Int
    }

    static let tour: [Stop] = [
        Stop(name: "atlas", env: ["PA_TAB": "atlas"], pages: 14),
        Stop(name: "index", env: ["PA_TAB": "index"], pages: 16),
        Stop(name: "grips", env: ["PA_TAB": "grips"], pages: 12),
        Stop(name: "craftsmen", env: ["PA_TAB": "craftsmen"], pages: 10),
        Stop(name: "sources", env: ["PA_TAB": "sources"], pages: 10),
        Stop(name: "specimen", env: ["PA_ROUTE": "pitch/four-seam"], pages: 24),
        Stop(name: "basic", env: ["PA_ROUTE": "repertoire/sinker"], pages: 12),
        Stop(name: "craftsman", env: ["PA_ROUTE": "craftsmen/greg-maddux"], pages: 12),
        Stop(name: "learn", env: ["PA_ROUTE": "learn"], pages: 8),
        Stop(name: "wing", env: ["PA_ROUTE": "learn/spin"], pages: 12),
        Stop(name: "lost", env: ["PA_ROUTE": "lost-pitches"], pages: 10),
        Stop(name: "lostdetail", env: ["PA_ROUTE": "lost-pitches/rube-foster-fadeaway"], pages: 12),
        Stop(name: "about", env: ["PA_ROUTE": "about"], pages: 8),
        Stop(name: "account", env: ["PA_ROUTE": "account"], pages: 8),
        Stop(name: "compare", env: ["PA_ROUTE": "compare?a=slider&b=sweeper"], pages: 8),
    ]

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    @MainActor
    func testTour() throws {
        let raw = ProcessInfo.processInfo.environment["PA_SHOTS"] ?? "all"
        let wanted = Set(raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
        let stops = wanted.contains("all") || wanted.isEmpty ? Self.tour : Self.tour.filter { wanted.contains($0.name) }
        XCTAssertFalse(stops.isEmpty, "PA_SHOTS=\(raw) names no stop on the tour")
        for stop in stops {
            XCTContext.runActivity(named: stop.name) { _ in capture(stop) }
        }
    }

    @MainActor
    private func capture(_ stop: Stop) {
        let app = XCUIApplication()
        app.launchEnvironment = stop.env
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 30), "\(stop.name): the app never showed its tab bar")
        // The launch gate fades after ~1.1s; give the push and first paint room too.
        Thread.sleep(forTimeInterval: 3)

        var previous: Data?
        for page in 1...stop.pages {
            let shot = XCUIScreen.main.screenshot()
            let png = shot.pngRepresentation
            if png == previous { break }
            previous = png
            let attachment = XCTAttachment(screenshot: shot)
            attachment.name = String(format: "%@-%02d", stop.name, page)
            attachment.lifetime = .keepAlways
            add(attachment)
            scrollOnePage(app)
        }
        app.terminate()
    }

    /// Half a screen per stroke, held at the end so the page doesn't coast.
    /// Strokes run down the right edge: a stroke through the 3D specimen stage
    /// turns the ball instead of scrolling the page.
    private func scrollOnePage(_ app: XCUIApplication) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.78))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.28))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.3)
        Thread.sleep(forTimeInterval: 0.7)
    }
}
