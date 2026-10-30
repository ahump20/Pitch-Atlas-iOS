import XCTest
import SwiftUI
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

    // MARK: Task 12 — the wall mount and the binder

    func testBinderColumnsByWidth() {
        XCTAssertEqual(BinderLayout.columns(width: 390), 2)
        XCTAssertEqual(BinderLayout.columns(width: 639), 2)
        XCTAssertEqual(BinderLayout.columns(width: 640), 3)
        XCTAssertEqual(BinderLayout.columns(verticalSizeClass: .regular), 2)
        XCTAssertEqual(BinderLayout.columns(verticalSizeClass: .compact), 3)
    }

    func testPocketsCatchTheLightAtDifferentAngles() {
        // nth-child is 1-based on the web: index 0 is child 1.
        XCTAssertEqual(BinderLayout.foilPosition(index: 0), UnitPoint(x: 0.30, y: 0.25))
        XCTAssertEqual(BinderLayout.foilPosition(index: 1), UnitPoint(x: 0.12, y: 0.80))   // 3n+2
        XCTAssertEqual(BinderLayout.foilPosition(index: 2), UnitPoint(x: 0.78, y: 0.60))   // 3n
        XCTAssertEqual(BinderLayout.rotation(index: 0), -0.5)                              // 4n+1
        XCTAssertEqual(BinderLayout.rotation(index: 2), 0.45)                              // 5n+3
        XCTAssertEqual(BinderLayout.rotation(index: 1), 0)
        XCTAssertEqual(BinderLayout.rotation(index: 12), 0.45, "the 13th pocket matches both rules; 5n+3 is declared later")
    }

    func testPocketFacesAreHonestByConstruction() {
        let store = PitchStore()
        let entries = store.repertoire.entries
        let faces = entries.map { PocketFace.resolve($0, store: store) }
        for (e, face) in zip(entries, faces) {
            let grip = store.gripEntry(forRepertoire: e)
            let still = grip?.photos.first?.src ?? grip?.film?.poster
            switch face {
            case .photo(let src): XCTAssertEqual(src, still, e.id)
            case .schematic(let filed): XCTAssertNil(still, e.id); XCTAssertEqual(filed.slug, e.filedSlug)
            case .slip: XCTAssertNil(still, e.id); XCTAssertNil(e.filedSlug, e.id)
            }
        }
        XCTAssertTrue(faces.contains(.slip), "the index carries entries with no image filed")
        XCTAssertTrue(faces.contains { if case .photo = $0 { true } else { false } })
    }

    func testPocketOpensTheSpecimenOrTheBasicFile() throws {
        let store = PitchStore()
        let filed = try XCTUnwrap(store.repertoire.entries.first { $0.filedSlug != nil })
        let basic = try XCTUnwrap(store.repertoire.entries.first { $0.filedSlug == nil })
        XCTAssertEqual(PocketFace.accessibilityLabel(for: filed), "\(filed.name): Open specimen")
        XCTAssertEqual(PocketFace.accessibilityLabel(for: basic), "\(basic.name): Basic file")
    }

    func testEdgeStatusesTakeTheSeam() {
        XCTAssertEqual(RepertoireStatus.allCases.filter(\.isEdge), [.banned, .alias, .illusion, .notAPitch])
    }

    func testWallCardWidthHoldsTheWebMaxima() {
        XCTAssertEqual(WallSpecimen.cardWidth(cell: 400, isChase: false), 360)
        XCTAssertEqual(WallSpecimen.cardWidth(cell: 400, isChase: true), 378)
        XCTAssertEqual(WallSpecimen.cardWidth(cell: 600, isChase: true), 520)
    }

    func testChaseSweepCrossesTheCellAsItArrives() {
        let w: CGFloat = 300
        func at(_ minY: CGFloat) -> CGFloat {
            ChaseSweep.sweepOffset(frame: CGRect(x: 0, y: minY, width: w, height: 500), viewport: 800, width: w)
        }
        XCTAssertEqual(at(800), -360, accuracy: 1e-9)          // its top edge at the bottom of the screen: parked left
        XCTAssertEqual(at(345), 360, accuracy: 1e-9)           // 35% through its pass: swept clear
        XCTAssertLessThan(at(600), at(500))                    // left to right as it rises
        XCTAssertEqual(ChaseSweep.sweepOffset(frame: .zero, viewport: nil, width: w), 360)
    }
}

