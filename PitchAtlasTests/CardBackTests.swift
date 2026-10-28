import XCTest
@testable import PitchAtlas

/// The flip and the sourced back (web SpecimenBack.tsx + ChromeWall's WallCard).
final class CardBackTests: XCTestCase {
    func testFlipFaceSwapsAtNinetyDegrees() {
        XCTAssertEqual(FlipFace.visible(angle: 0), .front)
        XCTAssertEqual(FlipFace.visible(angle: 89.9), .front)
        XCTAssertEqual(FlipFace.visible(angle: 90), .back)
        XCTAssertEqual(FlipFace.visible(angle: 180), .back)
        // a full turn shows the front again, either direction
        XCTAssertEqual(FlipFace.visible(angle: 270), .front)
        XCTAssertEqual(FlipFace.visible(angle: 360), .front)
        XCTAssertEqual(FlipFace.visible(angle: -180), .back)
    }

    func testFlipLabelsNameCardAndState() {
        XCTAssertEqual(FlipButton.label(name: "Slider", flipped: false), "Flip Slider to its sourced back")
        XCTAssertEqual(FlipButton.label(name: "Slider", flipped: true), "Flip Slider back to its card")
        XCTAssertEqual(FlipButton.title(flipped: false), "↺ Source")
        XCTAssertEqual(FlipButton.title(flipped: true), "↺ Card")
    }

    func testScoutRowsAreGripCueThenShapeFromTheRecord() throws {
        let store = PitchStore()
        let e = try XCTUnwrap(store.pitches.first { $0.canonical.physics.shape != nil })
        let file = ScoutFile.make(entry: e)
        let grip = e.canonical.gripDetails.first ?? e.canonical.grip
        XCTAssertEqual(file.rows.map(\.key), ["Grip cue", "Shape"])
        XCTAssertEqual(file.rows[0].value, grip.value)
        XCTAssertEqual(file.rows[0].tier, grip.confidence)
        XCTAssertEqual(file.rows[0].approximate, grip.approximate ?? false)
        XCTAssertEqual(file.rows[1].value, e.canonical.physics.shape?.value)
        XCTAssertEqual(file.rows[1].tier, e.canonical.physics.shape?.confidence)
    }

    func testScoutRowsOmitMissingShape() throws {
        let store = PitchStore()
        // every filed record may carry a shape; the guard keeps the rule honest if one stops
        guard let e = store.pitches.first(where: { $0.canonical.physics.shape == nil }) else { return }
        XCTAssertEqual(ScoutFile.make(entry: e).rows.map(\.key), ["Grip cue"])
    }

    func testSourceLinksNameTheClaimTheyBack() throws {
        let store = PitchStore()
        let e = try XCTUnwrap(store.pitch(slug: "slider"))
        let grip = e.canonical.gripDetails.first ?? e.canonical.grip
        let gripSource = try XCTUnwrap(grip.source)
        let shapeSource = try XCTUnwrap(e.canonical.physics.shape?.source)
        let file = ScoutFile.make(entry: e)
        XCTAssertEqual(file.sourceLinks.map(\.label), ["Grip: \(gripSource.label)", "Shape: \(shapeSource.label)"])
        XCTAssertEqual(file.sourceLinks.map(\.url.absoluteString), [gripSource.url, shapeSource.url])
    }

    func testBackHeadReadsNumberAndFamily() throws {
        let store = PitchStore()
        let fourSeam = try XCTUnwrap(store.pitch(slug: "four-seam"))
        XCTAssertEqual(ScoutFile.headline(for: fourSeam), "No. 00 · Fastball")
        let slider = try XCTUnwrap(store.pitch(slug: "slider"))
        XCTAssertEqual(ScoutFile.headline(for: slider), "No. \(slider.display.specimenNo) · Breaking")
    }
}
