import XCTest
@testable import PitchAtlas

/// The Shape map, pinned to pages/MovementMapPage.test.tsx and the geometry of
/// sections/MovementMap.tsx (web 47e21e6). The drawing is the pitcher's view from
/// the mound, and every word about the viewpoint has to say so.
final class ShapeMapTests: XCTestCase {
    private let store = PitchStore()

    func testNamesThePitchersViewForEitherHandNeverTheCatchers() {
        let rhp = ShapeMap.mapLabel(hand: .right)
        XCTAssertTrue(rhp.contains("as a right-handed pitcher sees them from the mound"))
        let lhp = ShapeMap.mapLabel(hand: .left)
        XCTAssertTrue(lhp.contains("as a left-handed pitcher sees them from the mound"))
        XCTAssertTrue(ShapeMap.heroSub.contains("as the pitcher sees it from the mound"))
        for words in [rhp, lhp, ShapeMap.heroSub, ShapeMap.scrollHint, ShapeMap.footnote] {
            XCTAssertFalse(words.lowercased().contains("catcher"))
        }
    }

    /// A right-hander's arm side on the right, mirrored for a left-hander: the poles
    /// and the dots move together.
    func testArmSideMirrorsWithTheHand() throws {
        func xs(_ hand: Handedness, _ dir: HorizontalDir) -> [CGFloat] {
            ShapeMap.dots(store.pitches, hand: hand).filter { $0.entry.motion.horizontalDir == dir }.map(\.point.x)
        }
        XCTAssertEqual(ShapeMap.poles(hand: .right).right, "ARM")
        XCTAssertEqual(ShapeMap.poles(hand: .right).left, "GLOVE")
        XCTAssertEqual(ShapeMap.poles(hand: .left).right, "GLOVE")
        XCTAssertEqual(ShapeMap.poles(hand: .left).left, "ARM")
        let armR = xs(.right, .armSide), gloveR = xs(.right, .gloveSide)
        let armL = xs(.left, .armSide), gloveL = xs(.left, .gloveSide)
        XCTAssertFalse(armR.isEmpty); XCTAssertFalse(gloveR.isEmpty)
        XCTAssertGreaterThan(try XCTUnwrap(armR.min()), try XCTUnwrap(gloveR.max()))
        XCTAssertLessThan(try XCTUnwrap(armL.max()), try XCTUnwrap(gloveL.min()))
    }

    /// Every filed pitch has exactly one dot, and two pitches that break the same way
    /// fan apart (38 apart, the dots' 19-point hit circles just meeting).
    func testEveryFiledPitchHasOneDotAndNoneSitOnAnother() {
        let dots = ShapeMap.dots(store.pitches, hand: .right)
        XCTAssertEqual(dots.map(\.entry.slug), store.pitches.map(\.slug))
        for (i, a) in dots.enumerated() {
            for b in dots[(i + 1)...] {
                XCTAssertGreaterThanOrEqual(hypot(a.point.x - b.point.x, a.point.y - b.point.y), 37.9,
                                            "\(a.entry.slug) and \(b.entry.slug) overlap")
            }
        }
    }

    /// The fan: the first pitch in a direction sits on its zone, the next six ring it
    /// at 38, every 60° starting from 60° (the site's (i % 6)·π/3), and the ring after
    /// that at 62.
    func testTheFanAroundAZone() {
        XCTAssertEqual(ShapeMap.fan(0), CGVector(dx: 0, dy: 0))
        XCTAssertEqual(ShapeMap.fan(1).dx, 38 * cos(.pi / 3), accuracy: 1e-9)
        XCTAssertEqual(ShapeMap.fan(1).dy, 38 * sin(.pi / 3), accuracy: 1e-9)
        XCTAssertEqual(ShapeMap.fan(2).dx, 38 * cos(2 * .pi / 3), accuracy: 1e-9)
        XCTAssertEqual(ShapeMap.fan(6).dx, 38, accuracy: 1e-9)
        XCTAssertEqual(ShapeMap.fan(7).dx, 62 * cos(.pi / 3), accuracy: 1e-9)
        XCTAssertEqual(ShapeMap.zone(.ride, .armSide, hand: .right), CGPoint(x: 320 + 180, y: 250 - 132))
        XCTAssertEqual(ShapeMap.zone(.ride, .armSide, hand: .left), CGPoint(x: 320 - 180, y: 250 - 132))
    }

    /// The marker speaks the site's aria-label: name, family, the shape words.
    func testEachDotSaysWhatItIs() throws {
        let fourSeam = try XCTUnwrap(store.pitch(slug: "four-seam"))
        let words = ShapeMap.shapeWords(fourSeam)
        XCTAssertTrue(["rides", "drops", "holds flat"].contains { words.hasPrefix($0) })
        XCTAssertEqual(ShapeMap.markerLabel(fourSeam),
                       "\(fourSeam.canonical.name). \(fourSeam.canonical.family.label), \(words). Open specimen.")
    }
}
