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
        Stop(name: "atlas", env: ["PA_TAB": "atlas"], pages: 28),
        Stop(name: "index", env: ["PA_TAB": "index"], pages: 30),
        Stop(name: "grips", env: ["PA_TAB": "grips"], pages: 64),
        Stop(name: "craftsmen", env: ["PA_TAB": "craftsmen"], pages: 16),
        Stop(name: "sources", env: ["PA_TAB": "sources"], pages: 40),
        Stop(name: "specimen", env: ["PA_ROUTE": "pitch/four-seam"], pages: 60),
        Stop(name: "basic", env: ["PA_ROUTE": "repertoire/split-finger-fastball"], pages: 18),
        Stop(name: "craftsman", env: ["PA_ROUTE": "craftsmen/greg-maddux"], pages: 12),
        Stop(name: "learn", env: ["PA_ROUTE": "learn"], pages: 10),
        Stop(name: "wing", env: ["PA_ROUTE": "learn/spin"], pages: 16),
        Stop(name: "boundary", env: ["PA_ROUTE": "learn/arm-health"], pages: 10),
        Stop(name: "lost", env: ["PA_ROUTE": "lost-pitches"], pages: 44),
        Stop(name: "lostdetail", env: ["PA_ROUTE": "lost-pitches/rube-foster-fadeaway"], pages: 14),
        Stop(name: "about", env: ["PA_ROUTE": "about"], pages: 18),
        Stop(name: "account", env: ["PA_ROUTE": "account"], pages: 8),
        Stop(name: "support", env: ["PA_ROUTE": "support"], pages: 8),
        Stop(name: "compare", env: ["PA_ROUTE": "compare?a=slider&b=sweeper"], pages: 8),
        Stop(name: "compareflight", env: ["PA_ROUTE": "compare?a=slider&b=sweeper&view=movement"], pages: 6),
        Stop(name: "sandbox", env: ["PA_ROUTE": "sandbox?tilt=225&pitch=slider"], pages: 12),
        Stop(name: "movement", env: ["PA_ROUTE": "movement-map"], pages: 8),
        Stop(name: "note", env: ["PA_ROUTE": "sandbox", "PA_NOTE": "stitches"], pages: 2),
        Stop(name: "notes", env: ["PA_NOTE": "index"], pages: 3),
        Stop(name: "softball", env: ["PA_ROUTE": "softball"], pages: 16),
        Stop(name: "fastpitch", env: ["PA_ROUTE": "softball/fastpitch"], pages: 12),
        Stop(name: "slowpitch", env: ["PA_ROUTE": "softball/slowpitch"], pages: 10),
        Stop(name: "sbpitch", env: ["PA_ROUTE": "softball/pitch/riseball"], pages: 16),
        Stop(name: "sbcraftsman", env: ["PA_ROUTE": "softball/craftsmen/cat-osterman"], pages: 12),
        Stop(name: "flightlab", env: ["PA_ROUTE": "softball/flight-lab"], pages: 18),
        Stop(name: "inspect", env: ["PA_INSPECT": "four-seam"], pages: 6),
        Stop(name: "inspectpair", env: ["PA_INSPECT": "four-seam", "PA_INSPECT_WITH": "slider"], pages: 8),
    ]

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    /// PA_TYPE=ax5 photographs the tour at the largest accessibility text size.
    static var typeSizeArguments: [String] {
        guard ProcessInfo.processInfo.environment["PA_TYPE"] == "ax5" else { return [] }
        return ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
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

    /// The Flight Lab's throw: the ball mid-flight, then down. Runs with the tour
    /// only when PA_SHOTS names "flightthrow".
    @MainActor
    func testFlightLabThrow() throws {
        let raw = ProcessInfo.processInfo.environment["PA_SHOTS"] ?? "all"
        try XCTSkipUnless(raw.split(separator: ",").contains("flightthrow"), "PA_SHOTS does not name flightthrow")
        let app = XCUIApplication()
        app.launchEnvironment = ["PA_ROUTE": "softball/flight-lab"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 30))
        Thread.sleep(forTimeInterval: 3)
        let throwButton = app.buttons["Throw →"]
        for _ in 0..<4 where !throwButton.isHittable { scrollOnePage(app) }
        app.buttons["Slow"].tap()
        throwButton.tap()
        for (i, wait) in [0.9, 1.2, 6.0].enumerated() {
            Thread.sleep(forTimeInterval: wait)
            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            attachment.name = String(format: "flightthrow-%02d", i + 1)
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        app.terminate()
    }

    /// The App Review path in docs/APP-REVIEW-NOTES.md, walked as a reviewer
    /// would from a cold launch: Atlas → Study this grip → the four-seam page →
    /// Write a note, then the Discussion drawer. It turns the two contribution
    /// gates on (stored on the device only) and proves both composers and their
    /// submit buttons are there. It never taps a submit button. Runs only when
    /// PA_SHOTS names "reviewpath".
    @MainActor
    func testReviewerPath() throws {
        let raw = ProcessInfo.processInfo.environment["PA_SHOTS"] ?? "all"
        try XCTSkipUnless(raw.split(separator: ",").contains("reviewpath"), "PA_SHOTS does not name reviewpath")
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 30))
        Thread.sleep(forTimeInterval: 3)
        func snap(_ name: String) {
            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            attachment.name = "reviewpath-\(name)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        func reach(_ element: XCUIElement, strokes: Int = 60) -> Bool {
            for _ in 0..<strokes where !(element.exists && element.isHittable) { scrollOnePage(app) }
            return element.exists && element.isHittable
        }
        // the button style sets the label in capitals, so match without case
        let study = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Study this grip")).firstMatch
        XCTAssertTrue(study.waitForExistence(timeout: 10), "Study this grip → is not on Atlas")
        study.tap()
        Thread.sleep(forTimeInterval: 2)
        snap("01-specimen")

        let write = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Write a note")).firstMatch
        XCTAssertTrue(reach(write), "Write a note never came into reach on the four-seam page")
        snap("02-field-notes")
        write.tap()
        Thread.sleep(forTimeInterval: 1)
        // The gate shows until it is accepted once on the device; a reviewer's
        // fresh install sees it, a simulator that accepted before does not.
        for gate in ["I accept the community guidelines", "I confirm I am 17 or older"] {
            let toggle = app.switches.matching(NSPredicate(format: "label BEGINSWITH %@", gate)).firstMatch
            guard toggle.waitForExistence(timeout: 2) else { continue }
            _ = reach(toggle, strokes: 4)
            if toggle.value as? String != "1" {
                toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
            }
            XCTAssertEqual(toggle.value as? String, "1", "Gate did not turn on: \(gate)")
        }
        let fileNote = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "File field note")).firstMatch
        XCTAssertTrue(reach(fileNote, strokes: 8), "File field note is not in the composer")
        snap("03-field-note-composer")

        let drawer = app.buttons["discussion-drawer"]
        XCTAssertTrue(reach(drawer), "The Discussion drawer never came into reach")
        drawer.tap()
        Thread.sleep(forTimeInterval: 1)
        let name = app.textFields["Your name"]
        XCTAssertTrue(reach(name, strokes: 6), "Your name is not in the discussion composer")
        let filePost = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "File post")).firstMatch
        XCTAssertTrue(reach(filePost, strokes: 6), "File post is not in the discussion composer")
        snap("04-discussion-composer")
        app.terminate()
    }

    /// The compare tray never covers the tab bar, and the list scrolls its last
    /// row clear of the tray. Picks one pitch on the Index (a local choice, no
    /// network) and photographs the top and the end. Runs only when PA_SHOTS
    /// names "tray"; PA_TYPE=ax5 runs it at the largest text size.
    @MainActor
    func testTrayClearsTheTabBar() throws {
        let raw = ProcessInfo.processInfo.environment["PA_SHOTS"] ?? "all"
        try XCTSkipUnless(raw.split(separator: ",").contains("tray"), "PA_SHOTS does not name tray")
        let app = XCUIApplication()
        app.launchEnvironment = ["PA_TAB": "index"]
        app.launchArguments += Self.typeSizeArguments
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 30))
        Thread.sleep(forTimeInterval: 3)
        let compare = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Compare ")).firstMatch
        for _ in 0..<12 where !(compare.exists && compare.isHittable) { scrollOnePage(app) }
        XCTAssertTrue(compare.isHittable, "No Compare button came into reach on the Index")
        compare.tap()
        Thread.sleep(forTimeInterval: 1)
        let tray = app.otherElements["Selected pitches"]
        XCTAssertTrue(tray.waitForExistence(timeout: 5), "The tray did not show after choosing a pitch")
        let bar = app.tabBars.firstMatch
        XCTAssertLessThanOrEqual(tray.frame.maxY, bar.frame.minY + 1, "The tray runs over the tab bar")
        func snap(_ name: String) {
            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            attachment.name = "tray-\(name)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        snap("01-chosen")
        var previous: Data?
        for _ in 0..<80 {
            let png = XCUIScreen.main.screenshot().pngRepresentation
            if png == previous { break }
            previous = png
            // above the tray: at the largest sizes it fills the lower quarter
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.55))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.12)))
        }
        snap("02-end")
        XCTAssertLessThanOrEqual(tray.frame.maxY, bar.frame.minY + 1, "The tray runs over the tab bar at the end")
        app.terminate()
    }

    /// A first launch with no network: PA_OFFLINE (DEBUG builds only) refuses
    /// every request the app makes as "not connected". The bundled atlas still
    /// opens, a specimen still reads, and both community surfaces say the server
    /// didn't answer instead of sitting blank. Uninstall the app first for a true
    /// first launch. Runs only when PA_SHOTS names "offline".
    @MainActor
    func testOfflineFirstLaunch() throws {
        let raw = ProcessInfo.processInfo.environment["PA_SHOTS"] ?? "all"
        try XCTSkipUnless(raw.split(separator: ",").contains("offline"), "PA_SHOTS does not name offline")
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment = ["PA_OFFLINE": "1"]
        app.launchArguments += Self.typeSizeArguments
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 30), "The app never showed its tab bar offline")
        Thread.sleep(forTimeInterval: 3)
        func snap(_ name: String) {
            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            attachment.name = "offline-\(name)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        func reach(_ element: XCUIElement, strokes: Int = 60) -> Bool {
            for _ in 0..<strokes where !(element.exists && element.isHittable) { scrollOnePage(app) }
            return element.exists && element.isHittable
        }
        func labelled(_ text: String) -> XCUIElement {
            app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
        }
        snap("01-atlas")

        let study = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Study this grip")).firstMatch
        XCTAssertTrue(study.waitForExistence(timeout: 10), "Study this grip → is not on Atlas offline")
        study.tap()
        Thread.sleep(forTimeInterval: 2)
        snap("02-specimen")

        let notesFailed = labelled("Couldn't load the field notes.")
        XCTAssertTrue(reach(notesFailed), "The field notes never said they couldn't load")
        XCTAssertTrue(labelled("The server didn't answer.").exists, "The field notes failure gave no reason")
        snap("03-field-notes-offline")

        let drawer = app.buttons["discussion-drawer"]
        XCTAssertTrue(reach(drawer), "The Discussion drawer never came into reach")
        drawer.tap()
        let postsFailed = labelled("Could not load the discussion.")
        XCTAssertTrue(postsFailed.waitForExistence(timeout: 15), "The discussion never said it couldn't load")
        _ = reach(postsFailed, strokes: 6)
        snap("04-discussion-offline")

        for tab in ["Index", "Grips", "Craftsmen", "Sources"] {
            app.tabBars.buttons[tab].tap()
            Thread.sleep(forTimeInterval: 1.5)
            snap("05-\(tab.lowercased())")
        }
        app.terminate()
    }

    @MainActor
    private func capture(_ stop: Stop) {
        let app = XCUIApplication()
        app.launchEnvironment = stop.env
        app.launchArguments += Self.typeSizeArguments
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 30), "\(stop.name): the app never showed its tab bar")
        // The launch gate fades after ~1.1s; give the push and first paint room too.
        Thread.sleep(forTimeInterval: 3)

        var previous: Data?
        let started = Date()
        for page in 1...stop.pages {
            // the run's log keeps these lines: a page that turns slowly shows here
            print(String(format: "TOUR %@ page %02d at %.1fs", stop.name, page, Date().timeIntervalSince(started)))
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
