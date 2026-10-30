import XCTest
import UIKit
@testable import PitchAtlas

final class ScrollProgressTests: XCTestCase {
    func testProgressClampsBetweenZeroAndOne() {
        let c = ScrollProgressController()
        c.update(progress: -0.4); XCTAssertEqual(c.progress, 0)
        c.update(progress: 1.7); XCTAssertEqual(c.progress, 1)
        c.update(progress: 0.42); XCTAssertEqual(c.progress, 0.42, accuracy: 1e-9)
    }

    func testRapidChangesStayInsideTheClamp() {
        let c = ScrollProgressController()
        for v in stride(from: -2.0, through: 2.0, by: 0.05) {
            c.update(progress: v)
            XCTAssert((0...1).contains(c.progress))
        }
    }

    func testProgressFromMetrics() {
        XCTAssertEqual(ScrollProgressController.progress(contentTop: -250, contentHeight: 1500, viewport: 1000), 0.5, accuracy: 1e-9)
        XCTAssertEqual(ScrollProgressController.progress(contentTop: 10, contentHeight: 1500, viewport: 1000), 0)
        XCTAssertEqual(ScrollProgressController.progress(contentTop: -100, contentHeight: 600, viewport: 1000), 1,
                       "content shorter than the screen reads as fully seen once moved")
    }

    func testNoBlazeArtShipsInTheBundle() {
        for name in ["BlazeIdle", "BlazeChasing", "BlazeSniffing", "BlazeCaught", "BlazeConcerned", "BlazeNapping", "BlazeStill"] {
            XCTAssertNil(UIImage(named: name, in: Bundle(for: PitchStore.self), with: nil), name)
        }
    }
}
