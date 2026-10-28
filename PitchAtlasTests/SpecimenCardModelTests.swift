import XCTest
import SwiftUI
@testable import PitchAtlas

final class SpecimenCardModelTests: XCTestCase {
    func testMetricsAt360MatchTheWebUnitTable() {
        let m = SpecimenCardMetrics(width: 360, frame: .standard)
        XCTAssertEqual(m.u, 3.6, accuracy: 1e-9)
        XCTAssertEqual(m.height, 504, accuracy: 1e-9)
        XCTAssertEqual(m.nameSize, 25.92, accuracy: 0.01)
        XCTAssertEqual(m.numberSize, 18.72, accuracy: 0.01)
        XCTAssertEqual(m.overlineSize, 7.2, accuracy: 0.01)
        XCTAssertEqual(m.cueSize, 14.04, accuracy: 0.01)
        XCTAssertEqual(m.stageTopRX, 78.01, accuracy: 0.01)
        XCTAssertEqual(m.stageTopRY, 82.8, accuracy: 0.01)
        XCTAssertEqual(m.stageBottomR, 14.0, accuracy: 0.01)
        XCTAssertEqual(m.readMetaSize, 7.38, accuracy: 0.01)
        XCTAssertEqual(m.stockPadding, 13)
        XCTAssertEqual(SpecimenCardMetrics(width: 360, frame: .ember).stockPadding, 16)
    }
    func testMicroTypeFloorsHoldOnSmallCards() {
        let m = SpecimenCardMetrics(width: 200, frame: .standard)   // u = 2
        XCTAssertEqual(m.overlineSize, 7); XCTAssertEqual(m.chipSize, 7)
        XCTAssertEqual(m.factSize, 8); XCTAssertEqual(m.stripSize, 8); XCTAssertEqual(m.readMetaSize, 7)
    }
    func testEmberSupersedesAThrowbackFinish() {
        XCTAssertEqual(CardFrame.of(slug: "four-seam", grade: .gold), .ember)
        XCTAssertEqual(CardFrame.of(slug: "twelve-six", grade: .inMotion), .powder)
        XCTAssertEqual(CardFrame.of(slug: "circle-change", grade: .firstParty), .teal)
        XCTAssertEqual(CardFrame.of(slug: "slider", grade: .reference), .standard)
    }
    func testRestLeanMatchesTheWebFormula() {
        XCTAssertEqual(CardLean.rest(index: 0), 0.38844, accuracy: 1e-4)
        XCTAssertEqual(CardLean.rest(index: 1), -0.39221, accuracy: 1e-4)
        XCTAssertEqual(CardLean.hero, -0.28)
    }
    func testContentForPitchWithAustinMediaUsesTheGripsShortCue() throws {
        let store = PitchStore()
        let entry = try XCTUnwrap(store.pitches.first { store.gripEntry(forSpecimen: $0.slug).map { $0.film != nil || !$0.photos.isEmpty } == true })
        let grip = try XCTUnwrap(store.gripEntry(forSpecimen: entry.slug))
        let c = SpecimenCardContent.make(entry: entry, grip: grip)
        XCTAssertEqual(c.cue, grip.shortCue)
        XCTAssertEqual(c.cueTier, grip.claimTier)
        XCTAssertTrue(c.chipIsAustin)
        XCTAssertEqual(c.chipLabel, grip.film != nil ? "Austin video" : "Austin photo")
        XCTAssertFalse(c.approximate)
    }
    func testContentForPitchWithoutAustinMediaUsesReferenceClaim() throws {
        let store = PitchStore()
        let entry = try XCTUnwrap(store.pitches.first { e in
            let g = store.gripEntry(forSpecimen: e.slug); return g == nil || (g!.film == nil && g!.photos.isEmpty) })
        let c = SpecimenCardContent.make(entry: entry, grip: store.gripEntry(forSpecimen: entry.slug))
        let reference = entry.canonical.gripDetails.first ?? entry.canonical.grip
        XCTAssertEqual(c.cue, reference.value)
        XCTAssertEqual(c.cueTier, reference.confidence)
        XCTAssertEqual(c.approximate, reference.approximate ?? false)
        XCTAssertEqual(c.chipLabel, "Reference schematic")
        XCTAssertEqual(c.face, .schematic)
    }
    func testAccessibilityLabelCarriesNameNumberCueAndTierWords() throws {
        let store = PitchStore()
        let e = try XCTUnwrap(store.pitch(slug: "four-seam"))
        let c = SpecimenCardContent.make(entry: e, grip: store.gripEntry(forSpecimen: e.slug))
        for part in [e.display.shortName, "No. 00", c.cue, c.cueTier.label] { XCTAssertTrue(c.accessibilityLabel.contains(part), part) }
    }
    func testArchedWindowFillsItsRect() {
        let rect = CGRect(x: 0, y: 0, width: 300, height: 270)
        let box = ArchedWindow(topRX: 65, topRY: 69, bottomR: 12).path(in: rect).boundingRect
        XCTAssertEqual(box.width, 300, accuracy: 0.5); XCTAssertEqual(box.height, 270, accuracy: 0.5)
        XCTAssertTrue(ArchedWindow(topRX: 65, topRY: 69, bottomR: 12).path(in: rect).contains(CGPoint(x: 150, y: 135)))
        XCTAssertFalse(ArchedWindow(topRX: 65, topRY: 69, bottomR: 12).path(in: rect).contains(CGPoint(x: 2, y: 2)), "the arch clears the corner")
    }

    // MARK: Task 9 — the 5:7 front

    @MainActor
    func testCardRendersAt5by7ForEveryFrame() throws {
        let store = PitchStore()
        for slug in ["four-seam", "twelve-six", "circle-change", "slider", "eephus"] {
            let e = try XCTUnwrap(store.pitch(slug: slug), slug)
            let content = SpecimenCardContent.make(entry: e, grip: store.gripEntry(forSpecimen: slug))
            let metrics = SpecimenCardMetrics(width: 300, frame: content.frame)
            let r = ImageRenderer(content: SpecimenCardFront(content: content, metrics: metrics, playsFilm: false).environment(store))
            let img = try XCTUnwrap(r.uiImage, slug)
            XCTAssertEqual(img.size.height / img.size.width, 1.4, accuracy: 0.02, slug)
        }
    }

    @MainActor
    func testCardWordsRepeatCueAndTierInScalableText() throws {
        let store = PitchStore()
        let e = try XCTUnwrap(store.pitch(slug: "slider"))
        let c = SpecimenCardContent.make(entry: e, grip: store.gripEntry(forSpecimen: "slider"))
        XCTAssertEqual(CardWords.lines(for: c), [c.cue, c.cueTier.label + (c.approximate ? " · approximate" : "")])
    }

    func testEmberPlateInksPassContrast() {
        XCTAssertGreaterThanOrEqual(PitchAccents.contrast(0x6E655A, 0xEFE6D0), 4.5, "read meta")
        XCTAssertGreaterThanOrEqual(PitchAccents.contrast(0x6B4318, 0xF1E4C8), 4.5, "ember meta")
        XCTAssertGreaterThanOrEqual(PitchAccents.contrast(0x9D927D, 0x0B0805), 4.5, "file label")
    }

    /// CSS object-fit: cover + object-position: the media covers the box and its
    /// focus point lines up with the box's same point (GripClip.focus on the web).
    func testFocusFillMatchesCSSObjectPosition() {
        // a tall 9:16 loop in a 10:9 window, focus 50% 44%
        let r = FocusCrop.layout(box: CGSize(width: 300, height: 270), aspect: 9.0 / 16.0,
                                            focus: UnitPoint(x: 0.5, y: 0.44))
        XCTAssertEqual(r.width, 300, accuracy: 1e-9)
        XCTAssertEqual(r.height, 300 * 16 / 9, accuracy: 1e-9)
        XCTAssertEqual(r.minX, 0, accuracy: 1e-9)
        XCTAssertEqual(r.minY, (270 - 300 * 16 / 9) * 0.44, accuracy: 1e-9)
        // a wide frame in a tall box fills by height and crops the sides
        let w = FocusCrop.layout(box: CGSize(width: 100, height: 200), aspect: 2, focus: .center)
        XCTAssertEqual(w.height, 200, accuracy: 1e-9)
        XCTAssertEqual(w.minX, (100 - 400) * 0.5, accuracy: 1e-9)
        XCTAssertEqual(FocusCrop.unitPoint(FilmFocus(x: 50, y: 44)), UnitPoint(x: 0.5, y: 0.44))
        XCTAssertEqual(FocusCrop.unitPoint(nil), .center)
    }

    func testCardsForEveryFiledPitchResolveAFaceAndACue() {
        let store = PitchStore()
        for e in store.pitches {
            let c = SpecimenCardContent.make(entry: e, grip: store.gripEntry(forSpecimen: e.slug))
            XCTAssertFalse(c.cue.isEmpty, e.slug)
            if case .film(let film) = c.face { XCTAssertNotNil(film.focus, "\(e.slug): a filmed face crops to its own point") }
        }
        XCTAssertEqual(store.pitches.filter { CardFrame.of(slug: $0.slug, grade: $0.specimenGrade.key) == .ember }.map(\.slug), ["four-seam"],
                       "the four-seam is the only 1 of 1")
    }
}
