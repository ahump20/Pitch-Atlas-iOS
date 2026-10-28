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

    /// `.rfx-field`: color-mix(in srgb, c2 34%, #0B0805), then #0B0805 at 52% and
    /// #070503, on a 170° run. Every stop is opaque, as the site's are.
    func testTheFieldRunsOpaqueWarmBlackTintedByTheAccent() {
        let stops = ComponentInk.fieldStops(c2: 0x125B63)   // the two-seam's c2
        XCTAssertEqual(stops.map(\.rgb), [0x0D2425, 0x0B0805, 0x070503], "rgb(13,36,37) is what the site computes")
        XCTAssertEqual(stops.map(\.location), [0, 0.52, 1])
        XCTAssertEqual(ComponentInk.fieldAngle, 170)
        XCTAssertEqual(PitchAccents.mixRGB(0x000000, 0xFFFFFF, 0.5), 0x808080)
        XCTAssertEqual(PitchAccents.mixRGB(0x0B0805, 0x125B63, 0), 0x0B0805)
    }

    /// The face is the warm-black field, never the foil stock showing through it
    /// and never gray copies of the card's own strokes: a standard card's head band
    /// reads dark and keeps its pitch's tint, as the site's does. (The edge stack
    /// cast from every layer once laid a 42464B band across exactly this line.)
    @MainActor
    func testTheFaceOfAStandardCardReadsDark() throws {
        let store = PitchStore()
        let e = try XCTUnwrap(store.pitch(slug: "slider"))
        let content = SpecimenCardContent.make(entry: e, grip: store.gripEntry(forSpecimen: "slider"))
        XCTAssertEqual(content.frame, .standard)
        let metrics = SpecimenCardMetrics(width: 300, frame: content.frame)
        let r = ImageRenderer(content: SpecimenCardFront(content: content, metrics: metrics, playsFilm: false).environment(store))
        r.scale = 1
        let image = try XCTUnwrap(r.cgImage)
        let probe = try XCTUnwrap(Self.pixel(image, x: 165, y: Int(metrics.stockPadding) + 8))
        let luminance = 0.2126 * probe.r + 0.7152 * probe.g + 0.0722 * probe.b
        // What the render holds down the probe's column and across its row, so a
        // failure says what the face actually shows.
        let column = stride(from: 0, to: 64, by: 4).map { y in "y\(y)=\(Self.pixel(image, x: 165, y: y).map(Self.hex) ?? "-")" }
        let row = stride(from: 0, to: image.width, by: 25).map { x in "x\(x)=\(Self.pixel(image, x: x, y: Int(metrics.stockPadding) + 8).map(Self.hex) ?? "-")" }
        XCTAssertLessThan(luminance, 0.25, "the head band shows the field, not the foil: \(probe); "
                          + "image \(image.width)x\(image.height); column \(column.joined(separator: " ")); row \(row.joined(separator: " "))")
        XCTAssertGreaterThan(probe.r, probe.g + 0.05, "the slider's field keeps its red under the head: \(probe)")
    }

    private static func hex(_ p: (r: Double, g: Double, b: Double)) -> String {
        String(format: "%02X%02X%02X", Int(p.r * 255), Int(p.g * 255), Int(p.b * 255))
    }

    private static func pixel(_ image: CGImage, x: Int, y: Int) -> (r: Double, g: Double, b: Double)? {
        var bytes = [UInt8](repeating: 0, count: 4)
        guard let ctx = CGContext(data: &bytes, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.draw(image, in: CGRect(x: -x, y: y - image.height + 1, width: image.width, height: image.height))
        return (Double(bytes[0]) / 255, Double(bytes[1]) / 255, Double(bytes[2]) / 255)
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

    // MARK: Task 10 — tilt, light, rim rake

    func testDragTiltFollowsTheWebFormulaAndClamps() throws {
        let t = try XCTUnwrap(CardTiltState.drag(translation: CGSize(width: 50, height: 0), width: 300))
        XCTAssertEqual(t.rx, 50.0 / 300 * 14 * 2.4, accuracy: 1e-9)       // 5.6°
        XCTAssertEqual(t.ry, t.rx * -0.22, accuracy: 1e-9)
        XCTAssertEqual(t.mx, 50 + t.rx / 14 * 42, accuracy: 1e-9)
        XCTAssertEqual(t.my, 32 + t.ry / 14 * 30, accuracy: 1e-9)
        XCTAssertEqual(CardTiltState.drag(translation: CGSize(width: 900, height: 0), width: 300)!.rx, 14)
    }

    func testVerticalDragDoesNotTilt() {
        XCTAssertNil(CardTiltState.drag(translation: CGSize(width: 6, height: 40), width: 300), "a scroll that starts on the card scrolls the page")
        XCTAssertNil(CardTiltState.drag(translation: CGSize(width: 5, height: 0), width: 300), "under the 8pt threshold nothing moves")
    }

    func testGyroTiltClampsAtTen() {
        let t = CardTiltState.gyro(roll: 1, pitch: -1)
        XCTAssertEqual(t.rx, 10); XCTAssertEqual(t.ry, 10)
        XCTAssertEqual(CardTiltState.gyro(roll: 0, pitch: 0), .rest)
    }

    func testRestLightSitsWhereTheWebRests() {
        XCTAssertEqual(CardTiltState.rest.light, UnitPoint(x: 0.5, y: 0.32))
    }

    /// The bench grabs the card on both axes to ±28° (web inspector mode); up is
    /// a positive tilt toward the viewer, as -dy on the web.
    func testBenchGrabTiltsBothAxesToTwentyEight() throws {
        let size = CGSize(width: 300, height: 420)
        let t = try XCTUnwrap(CardTiltState.grab(translation: CGSize(width: 0, height: -60), size: size))
        XCTAssertEqual(t.rx, 0, accuracy: 1e-9)
        XCTAssertEqual(t.ry, 60.0 / 420 * 28 * 2.4, accuracy: 1e-9)
        let far = try XCTUnwrap(CardTiltState.grab(translation: CGSize(width: 2000, height: 2000), size: size))
        XCTAssertEqual(far.rx, 28); XCTAssertEqual(far.ry, -28)
        XCTAssertNil(CardTiltState.grab(translation: CGSize(width: 3, height: 4), size: size))
        XCTAssertEqual(CardTiltMode.inspector.dragMax, 28)
        XCTAssertEqual(CardTiltMode.hero.dragMax, 14)
    }
}
