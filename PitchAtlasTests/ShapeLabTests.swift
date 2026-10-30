import XCTest
@testable import PitchAtlas

/// Shape Lab, pinned to the site's own tests: src/lib/sandbox.test.ts and the logic
/// half of src/pages/SandboxPage.test.tsx (web 47e21e6).
final class ShapeLabTests: XCTestCase {
    private let store = PitchStore()

    // MARK: sandbox.test.ts

    func testPureBackspinReadsAsRideWithNoSideShape() {
        let r = ShapeLab.buildBreak(tiltDegrees: 0)
        XCTAssertEqual(r.verticalShape, .ride)
        XCTAssertEqual(r.horizontalDir, HorizontalDir.none)
        XCTAssertTrue(r.shapeNote.lowercased().contains("ride"))
    }

    func testPureTopspinReadsAsDrop() {
        let r = ShapeLab.buildBreak(tiltDegrees: 180)
        XCTAssertEqual(r.verticalShape, .drop)
        XCTAssertEqual(r.horizontalDir, HorizontalDir.none)
    }

    func testSideTiltMapsToSideShapeWithoutMagnitude() {
        XCTAssertEqual(ShapeLab.buildBreak(tiltDegrees: 90).horizontalDir, .armSide)
        XCTAssertEqual(ShapeLab.buildBreak(tiltDegrees: 270).horizontalDir, .gloveSide)
        XCTAssertEqual(ShapeLab.buildBreak(tiltDegrees: 90).shapeNote,
                       "Pure arm-side run. The pitch slides toward the throwing arm side.")
    }

    func testBlendedTiltReadsAsABlendedShape() {
        let r = ShapeLab.buildBreak(tiltDegrees: 45)
        XCTAssertEqual(r.verticalShape, .ride)
        XCTAssertEqual(r.horizontalDir, .armSide)
        XCTAssertEqual(r.shapeNote, "Blended shape: ride with arm-side run.")
        XCTAssertEqual(ShapeLab.buildBreak(tiltDegrees: 225).shapeNote, "Blended shape: drop with glove-side sweep.")
    }

    func testFormatsATiltInDegreesAsAClock() {
        XCTAssertEqual(ShapeLab.tiltClock(0), "12:00")
        XCTAssertEqual(ShapeLab.tiltClock(90), "3:00")
        XCTAssertEqual(ShapeLab.tiltClock(180), "6:00")
        XCTAssertEqual(ShapeLab.tiltClock(270), "9:00")
        XCTAssertEqual(ShapeLab.tiltClock(45), "1:30")
        XCTAssertEqual(ShapeLab.tiltClock(345), "11:30")
    }

    /// buildBreak's axis: (cos, −sin, 0), so the schematic turns with the clock.
    func testSpinAxisTurnsWithTheClock() {
        let axis = ShapeLab.buildBreak(tiltDegrees: 90).spinAxis
        XCTAssertEqual(axis.x, 0, accuracy: 1e-9)
        XCTAssertEqual(axis.y, -1, accuracy: 1e-9)
        XCTAssertEqual(axis.z, 0)
        XCTAssertEqual(ShapeLab.buildBreak(tiltDegrees: 0).spinAxis.x, 1, accuracy: 1e-9)
    }

    // MARK: SandboxPage.test.tsx — the link's state

    func testFallsBackToTheStockTiltForInvalidInput() {
        for raw in [nil, "", "NaN", "Infinity", "-15", "360", "16", "15.5", "90junk", "1e2", "0xF"] {
            XCTAssertEqual(ShapeLab.parseTilt(raw), 0, "\(raw ?? "nil") falls back to 12:00")
        }
        for tilt in [0, 15, 90, 225, 345] {
            XCTAssertEqual(ShapeLab.parseTilt(String(tilt)), tilt)
        }
    }

    func testKeepsAMissingOrUnknownReferenceUnselected() {
        for raw in [nil, "", "missing", "__proto__"] {
            XCTAssertNil(ShapeLab.reference(raw, store: store))
        }
        XCTAssertEqual(ShapeLab.reference("slider", store: store)?.slug, "slider")
    }

    func testPresetsAreTheSitesSixAndOneLightsAtATime() {
        XCTAssertEqual(ShapeLab.presets.map(\.label),
                       ["12:00 ride", "3:00 run", "6:00 drop", "9:00 sweep", "Ride + run", "Drop + sweep"])
        XCTAssertEqual(ShapeLab.presets.map(\.tilt), [0, 90, 180, 270, 45, 225])
        XCTAssertEqual(ShapeLab.presets.filter { $0.tilt == 225 }.map(\.label), ["Drop + sweep"])
        XCTAssertTrue(ShapeLab.presets.filter { $0.tilt == 105 }.isEmpty, "a slider stop between presets lights none")
    }

    // MARK: SandboxPage.test.tsx — where the viewer stands

    /// 3:00 run lands on the right, 9:00 sweep on the left; ride above, drop below.
    func testThreeOClockRunLandsOnTheRight() {
        XCTAssertEqual(ShapePlot.offset(ShapeLab.buildBreak(tiltDegrees: 90)).dx.sign, .plus)
        XCTAssertEqual(ShapePlot.offset(ShapeLab.buildBreak(tiltDegrees: 270)).dx.sign, .minus)
        XCTAssertLessThan(ShapePlot.offset(ShapeLab.buildBreak(tiltDegrees: 0)).dy, 0, "ride sits above the spinless ball")
        XCTAssertGreaterThan(ShapePlot.offset(ShapeLab.buildBreak(tiltDegrees: 180)).dy, 0)
        XCTAssertEqual(ShapePlot.offset(ShapeLab.buildBreak(tiltDegrees: 90)).dx, 60, "a fixed schematic offset, not a magnitude")
    }

    func testNamesARightHandersViewFromTheMoundNeverTheCatchers() {
        XCTAssertTrue(ShapeLab.heroSub.contains("the way a right-handed pitcher sees it from the mound"))
        XCTAssertEqual(ShapeLab.plotCaption, "Pitcher\u{2019}s eye")
        let plot = ShapePlot.label(ShapeLab.buildBreak(tiltDegrees: 0), pitchName: "custom pitch")
        XCTAssertEqual(plot, "Shape of a custom pitch as a right-handed pitcher sees it from the mound. Against a spinless ball at center, it rides and stays true. A schematic of direction, not a measured magnitude.")
        let words = [ShapeLab.heroSub, ShapeLab.anchorNote, ShapeLab.sideNote, ShapeLab.tiltHint,
                     ShapeLab.referenceNote, ShapeLab.presetNote, plot]
        XCTAssertFalse(words.contains { $0.lowercased().contains("catcher") })
    }

    /// The honest line is the site's, word for word.
    func testTheTeachingModelSaysWhatItIsNot() {
        XCTAssertEqual(ShapeLab.anchorNote, "A teaching model. Spin tilt sets the direction of the Magnus force: backspin creates ride, topspin creates drop, and sidespin creates run or sweep. This page describes shape only; it does not predict how far any arm moves a pitch.")
    }
}
