import XCTest

/// Read-only evidence for the build 14 App Review repair. The contact draft is
/// never sent, and these checks never create a contributor account.
final class AppReviewSafetyUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testContactAndTermsWithoutSignIn() throws {
        let app = XCUIApplication()
        app.launchEnvironment = ["PA_ROUTE": "account"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 30))
        Thread.sleep(forTimeInterval: 3)

        let contact = app.buttons["Contact developer"]
        XCTAssertTrue(reach(contact, in: app), "Contact developer is unavailable from Account")
        snapshot("safety-account")
        contact.tap()
        XCTAssertTrue(app.navigationBars["Contact Austin Humphrey"].waitForExistence(timeout: 10))
        let multilineMessage = app.textViews["Message to developer"]
        let message = multilineMessage.waitForExistence(timeout: 2) ? multilineMessage : app.textFields["Message to developer"]
        XCTAssertTrue(message.waitForExistence(timeout: 5))
        let send = app.buttons["Send to developer"]
        XCTAssertTrue(send.exists)
        XCTAssertFalse(send.isEnabled, "An empty contact message must not send")
        XCTAssertTrue(app.textFields["Reply email, optional"].exists)
        snapshot("safety-contact-empty")

        message.tap()
        message.typeText("Controlled review validation draft. This message is not sent.")
        XCTAssertTrue(send.isEnabled, "A valid contact draft is blocked before sign-in")
        snapshot("safety-contact-draft-not-sent")
        app.buttons["Done"].tap()

        let terms = app.buttons["Community Terms and EULA"]
        XCTAssertTrue(reach(terms, in: app))
        terms.tap()
        XCTAssertTrue(app.navigationBars["Community Terms and EULA"].waitForExistence(timeout: 10))
        let zeroTolerance = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "zero tolerance")).firstMatch
        XCTAssertTrue(reach(zeroTolerance, in: app))
        snapshot("safety-terms-zero-tolerance")
        app.buttons["Done"].tap()
        XCTAssertFalse(app.buttons["Delete account"].exists, "Read-only safety screens created an account")
        app.terminate()
    }

    @MainActor
    func testOldConsentDoesNotAcceptNewAgreement() throws {
        let app = XCUIApplication()
        app.launchEnvironment = ["PA_PITCH": "slider"]
        app.launchArguments = ["-pa.community.guidelinesAccepted", "YES", "-pa.community.ageConfirmed", "YES"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 30))
        Thread.sleep(forTimeInterval: 3)
        let write = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Write a note")).firstMatch
        XCTAssertTrue(reach(write, in: app, strokes: 60))
        write.tap()

        for label in ["I accept the Community Terms and EULA", "I confirm I am 18 or older"] {
            let toggle = app.switches.matching(NSPredicate(format: "label BEGINSWITH %@", label)).firstMatch
            XCTAssertTrue(toggle.waitForExistence(timeout: 5), "Missing fresh consent: \(label)")
            XCTAssertTrue(reach(toggle, in: app, strokes: 6))
            XCTAssertEqual(toggle.value as? String, "0", "Old consent incorrectly accepted \(label)")
            snapshot(label.contains("18") ? "safety-fresh-adult-consent" : "safety-fresh-terms-consent")
        }
        app.terminate()
    }

    @MainActor
    private func reach(_ element: XCUIElement, in app: XCUIApplication, strokes: Int = 16) -> Bool {
        reachSafely(element, in: app, strokes: strokes)
    }

    @MainActor
    private func snapshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    @MainActor
    private func fullyVisible(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        guard element.exists && element.isHittable else { return false }
        let top = app.navigationBars.firstMatch.exists ? app.navigationBars.firstMatch.frame.maxY + 4 : app.frame.minY + 24
        let bar = app.tabBars.firstMatch
        let bottom = bar.exists ? bar.frame.minY - 8 : app.frame.maxY - 24
        return element.frame.minY >= top && element.frame.maxY <= bottom
    }

    @MainActor
    private func reachSafely(_ element: XCUIElement, in app: XCUIApplication, strokes: Int) -> Bool {
        for _ in 0..<strokes {
            if fullyVisible(element, in: app) { return true }
            let top = app.navigationBars.firstMatch.exists ? app.navigationBars.firstMatch.frame.maxY + 4 : app.frame.minY + 24
            let scrollBack = element.exists && element.frame.minY < top
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: scrollBack ? 0.3 : 0.78))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: scrollBack ? 0.78 : 0.3))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.3)
        }
        return fullyVisible(element, in: app)
    }

}
