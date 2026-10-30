import SwiftUI
import XCTest
@testable import PitchAtlas

/// BrandMark.tsx and `.rfx-holo`: the lockup the site prints in its masthead and
/// footer, and the foil its holo words wear.
final class BrandMarkTests: XCTestCase {
    /// MARK_PX and WORDMARK_SIZE: sm in the masthead, md in the footer.
    func testLockupSizesAreTheSites() {
        XCTAssertEqual(BrandLockup.Size.sm.mark, 32)
        XCTAssertEqual(BrandLockup.Size.sm.word, 20)
        XCTAssertEqual(BrandLockup.Size.md.mark, 44)
        XCTAssertEqual(BrandLockup.Size.md.word, 30)
    }

    /// Six stitch pairs down each side of the seam, tucked toward the ball's center:
    /// y = 39 + 4.4i, drifting |i − 2.5| × 0.5 inward.
    func testDiamondStitchesFollowTheSitesSeam() {
        let stitches = BrandDiamondMark.stitches
        XCTAssertEqual(stitches.count, 12)
        XCTAssertEqual(stitches[0].from.x, 36.75, accuracy: 1e-9)
        XCTAssertEqual(stitches[0].from.y, 39, accuracy: 1e-9)
        XCTAssertEqual(stitches[0].to.x, 40.75, accuracy: 1e-9)
        XCTAssertEqual(stitches[0].to.y, 37.5, accuracy: 1e-9)
        XCTAssertEqual(stitches[5].from.x, 60.5 - 0.25, accuracy: 1e-9)
        XCTAssertEqual(stitches[11].from.x, 59.25, accuracy: 1e-9)
        XCTAssertEqual(stitches[11].from.y, 61, accuracy: 1e-9)
    }

    /// `.rfx-holo` at rest (its reduced-motion frame): --foil-type drawn at 300% of
    /// the words from position 0, so a run shows the ramp's first third — never the
    /// whole ramp squeezed into one word.
    func testHoloTypeShowsTheRampsFirstThird() {
        let aspect: CGFloat = 4
        let ends = PitchAtlasMaterials.holoTypeEndpoints(aspect: aspect)
        let (sx, sy) = (ends.start.x * aspect, ends.start.y)
        let (dx, dy) = (ends.end.x * aspect - sx, ends.end.y - sy)
        func ramp(_ x: CGFloat, _ y: CGFloat) -> CGFloat {
            ((x * aspect - sx) * dx + (y - sy) * dy) / (dx * dx + dy * dy)
        }
        let left = ramp(0, 0.5), right = ramp(1, 0.5)
        XCTAssertEqual(left, 0.016, accuracy: 0.01)
        XCTAssertEqual(right - left, 1.0 / 3.0, accuracy: 0.02)
    }
}
