import XCTest

/// The home scrolls while the hero film plays. The hero card's hand-tilt used to
/// take every stroke on the home, on the card or beside it, so the page never
/// left its top (diag/home-scroll, runs 40666220785 and 40668248341). Runs with
/// every tour that photographs the home.
final class HomeScrollUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        let raw = ProcessInfo.processInfo.environment["PA_SHOTS"] ?? ""
        let stops = Set(raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
        try XCTSkipUnless(stops.isEmpty || stops.contains("all") || stops.contains("atlas"),
                          "the home is not on this tour (\(raw))")
    }

    @MainActor
    func testAStrokeOnTheHeroCardScrollsTheHome() {
        assertStrokeScrolls(fromX: 0.5, label: "on the hero card")
    }

    @MainActor
    func testAStrokeBesideTheHeroCardScrollsTheHome() {
        assertStrokeScrolls(fromX: 0.94, label: "beside the hero card")
    }

    @MainActor
    private func assertStrokeScrolls(fromX x: CGFloat, label: String) {
        let app = XCUIApplication()
        app.launchEnvironment = ["PA_TAB": "atlas"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 30), "the app never showed its tab bar")
        let lede = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'A grip to inspect'")).firstMatch
        XCTAssertTrue(lede.waitForExistence(timeout: 15), "the home's lede never showed")
        // let the hero film start, as a reader would find it
        Thread.sleep(forTimeInterval: 2)
        let before = lede.frame.minY
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: 0.78))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: 0.28))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.3)
        let after = lede.exists ? lede.frame.minY : -CGFloat.infinity
        XCTAssertLessThan(after, before - 100, "a stroke \(label) left the home in place (lede \(before) → \(after))")
        app.terminate()
    }
}
