import XCTest
import SwiftUI
@testable import PitchAtlas

/// Tier B plates and Tier C index rows (web .rfx-plate / .rfx-entry, CraftsmanCard.tsx,
/// LostPitchCard.tsx, EraBand.tsx, lib/era.ts, and PitchIndex.tsx's EntryRow).
final class PlateAndRowTests: XCTestCase {
    func testRestForMatchesTheWebHash() {
        XCTAssertEqual(restFor("four-seam"), 0.951036, accuracy: 1e-5)
        XCTAssertEqual(restFor("eephus"), -0.714876, accuracy: 1e-5)
        XCTAssertEqual(restFor("gyroball"), 0.773891, accuracy: 1e-5)
    }

    func testPlateLipByVariant() {
        let burnt = Color(rgb: WebTokens.Accent.burnt)
        XCTAssertEqual(Plate<EmptyView>.edgeColor(accent: burnt, variant: .standard), burnt.opacity(0.78))
        XCTAssertEqual(Plate<EmptyView>.edgeColor(accent: burnt, variant: .dashed), burnt.opacity(0.78))
        XCTAssertEqual(Plate<EmptyView>.edgeColor(accent: burnt, variant: .edge), PitchAtlasTheme.seamBright.opacity(0.82))
        XCTAssertEqual(Plate<EmptyView>.edgeColor(accent: burnt, variant: .edgeDashed), PitchAtlasTheme.seamBright.opacity(0.82))
        XCTAssertEqual(Plate<EmptyView>.edgeColor(accent: burnt, variant: .filed), ComponentInk.filedBone.opacity(0.82))
        XCTAssertTrue(PlateVariant.dashed.isDashed)
        XCTAssertTrue(PlateVariant.edgeDashed.isDashed)
        XCTAssertFalse(PlateVariant.edge.isDashed)
    }

    func testStatusInkIsSeamForBannedAndQuietForTheEdgeCases() {
        XCTAssertEqual(IndexRowStyle.statusTone(.banned), .seam)
        for s: RepertoireStatus in [.alias, .illusion, .notAPitch] { XCTAssertEqual(IndexRowStyle.statusTone(s), .quiet) }
        for s: RepertoireStatus in [.standard, .niche, .rare, .nearExtinct] { XCTAssertEqual(IndexRowStyle.statusTone(s), .bone2) }
    }

    func testFiledRowsWearTheAccentTopRuleAndSquareTopCorners() {
        XCTAssertEqual(IndexRowStyle.topRule(filed: true), 2)
        XCTAssertEqual(IndexRowStyle.topRule(filed: false), 0)
        XCTAssertEqual(IndexRowStyle.topRadius(filed: true), 0)
        XCTAssertEqual(IndexRowStyle.topRadius(filed: false), 14)
    }

    func testFiledRowsInkTheirMarkInTheSpecimensOwnAccent() throws {
        let store = PitchStore()
        let filed = try XCTUnwrap(store.repertoire.entries.first { $0.filedSlug != nil })
        let basic = try XCTUnwrap(store.repertoire.entries.first { $0.filedSlug == nil })
        XCTAssertEqual(IndexRowStyle.markTint(for: filed), Color(rgb: PitchAccents.triad(for: filed.filedSlug!).c3))
        XCTAssertEqual(IndexRowStyle.markTint(for: basic), basic.family.accent)
    }

    func testRowSpeaksEveryAlias() throws {
        let store = PitchStore()
        let e = try XCTUnwrap(store.repertoire.entries.first { ($0.aka ?? []).count >= 2 })
        let label = IndexRowStyle.accessibilityLabel(for: e)
        XCTAssertTrue(label.hasPrefix("\(e.name), \(e.family.label), "), label)
        XCTAssertTrue(label.contains(e.filedSlug == nil ? "Basic file" : "Filed specimen"), label)
        XCTAssertTrue(label.contains(e.status.displayLabel), label)
        XCTAssertTrue(label.hasSuffix("also known as \(e.aka!.joined(separator: ", "))"), label)
    }

    func testIndexMarkSeamIsTheOrientedSeamSplitFrontAndBack() throws {
        let runs = IndexSeamMark.runs
        XCTAssertTrue(runs.contains { $0.front }, "a front run")
        XCTAssertTrue(runs.contains { !$0.front }, "a back run")
        for (a, b) in zip(runs, runs.dropFirst()) {
            XCTAssertNotEqual(a.front, b.front, "runs alternate faces")
            XCTAssertEqual(a.points.last, b.points.first, "each run starts where the last one ended")
        }
        XCTAssertEqual(runs.reduce(0) { $0 + $1.points.count }, 161 + runs.count - 1, "161 points, the joins shared")
        let p0 = SeamMath.rotate(SeamMath.seamPoint(0), aboutAxis: SeamMath.viewTiltAxis, by: SeamMath.viewTiltAngle)
        let first = try XCTUnwrap(runs.first?.points.first)
        XCTAssertEqual(Double(first.x), p0.x, accuracy: 1e-9)
        XCTAssertEqual(Double(first.y), -p0.y, accuracy: 1e-9)
    }

    func testEraReadsTheRealYearsAndNothingElse() {
        XCTAssertEqual(EraSpan.parse("1928-1943"), EraSpan(start: 1928, end: 1943))
        XCTAssertEqual(EraSpan.parse("2024-present"), EraSpan(start: 2024, end: nil))
        XCTAssertEqual(EraSpan.parse("Active since 2019"), EraSpan(start: 2019, end: nil))
        XCTAssertEqual(EraSpan.parse("Designed 2001"), EraSpan(start: 2001, end: 2001))
        XCTAssertNil(EraSpan.parse("Deadball era"))
        XCTAssertEqual(EraSpan.axisPosition(1925), 0)
        XCTAssertEqual(EraSpan.axisPosition(2030), 1)
        XCTAssertEqual(EraSpan.axisPosition(1977.5), 0.5, accuracy: 1e-12)
        XCTAssertEqual(EraSpan.axisPosition(1900), 0)
        XCTAssertEqual(EraSpan.axisPosition(2050), 1)
    }

    func testEraBandLengthIsTheCareer() {
        let ryan = EraBand.geometry(EraSpan(start: 1966, end: 1993))
        XCTAssertEqual(ryan.left, EraSpan.axisPosition(1966), accuracy: 1e-12)
        XCTAssertEqual(ryan.width, EraSpan.axisPosition(1993) - EraSpan.axisPosition(1966), accuracy: 1e-12)
        XCTAssertFalse(ryan.open)
        let rookie = EraBand.geometry(EraSpan(start: 2024, end: nil))
        XCTAssertEqual(rookie.left + rookie.width, 1, accuracy: 1e-12, "an open career runs to the edge")
        XCTAssertTrue(rookie.open)
        let point = EraBand.geometry(EraSpan(start: 2001, end: 2001))
        XCTAssertEqual(point.width, 0.025, accuracy: 1e-12, "a single year still shows: the web's 2.5% floor")
    }

    func testCraftsmanPlateWearsTheSignaturePitchAccent() throws {
        let store = PitchStore()
        let legend = try XCTUnwrap(store.craftsmen.first { $0.kind == .legend })
        let master = try XCTUnwrap(store.craftsmen.first { $0.kind != .legend && $0.signaturePitchSlug != nil })
        XCTAssertEqual(CraftsmanPlate.accentRGB(legend), WebTokens.Palette.tealGlow.rgb)
        XCTAssertEqual(CraftsmanPlate.accentRGB(master), PitchAccents.triad(for: master.signaturePitchSlug!).c3)
        XCTAssertEqual(CraftsmanPlate.label(legend), "Legend · \(legend.specimenNo)")
        XCTAssertEqual(CraftsmanPlate.label(master), "Master · \(master.specimenNo)")
        XCTAssertEqual(CraftsmanPlate.variant(legend), .dashed)
        XCTAssertEqual(CraftsmanPlate.variant(master), .standard)
        XCTAssertNil(CraftsmanPlate.span(legend), "a legend is a design, not a career: no band")
        XCTAssertNotNil(CraftsmanPlate.span(master))
        if let unsigned = store.craftsmen.first(where: { $0.kind != .legend && $0.signaturePitchSlug == nil }) {
            XCTAssertEqual(CraftsmanPlate.accentRGB(unsigned), WebTokens.Palette.cyan.rgb)
        }
    }

    func testCraftsmanFooterNamesFilmAndHand() throws {
        let store = PitchStore()
        let c = try XCTUnwrap(store.craftsmen.first { $0.hand != nil })
        let notes = CraftsmanPlate.footerNotes(c, hasFilm: true)
        XCTAssertEqual(notes, ["Film filed", "\(c.hand!.rawValue.capitalized)-handed"])
        XCTAssertEqual(CraftsmanPlate.footerNotes(c, hasFilm: false), ["\(c.hand!.rawValue.capitalized)-handed"])
        if let handless = store.craftsmen.first(where: { $0.hand == nil }) {
            XCTAssertEqual(CraftsmanPlate.footerNotes(handless, hasFilm: false), [])
        }
    }

    func testLostPitchPlateNamesTheKindAndFlagsTheLegend() throws {
        XCTAssertEqual(LostPitchPlate.kindLabel(.pitch), "Lost pitch")
        XCTAssertEqual(LostPitchPlate.kindLabel(.pitcher), "The arm")
        XCTAssertEqual(LostPitchPlate.kindLabel(.doctored), "The doctored family")
        let store = PitchStore()
        let pitches = store.lostPitches.entries
        if let legend = pitches.first(where: { $0.tier == .legend }) { XCTAssertEqual(LostPitchPlate.variant(legend), .edgeDashed) }
        let documented = try XCTUnwrap(pitches.first { $0.tier != .legend })
        XCTAssertEqual(LostPitchPlate.variant(documented), .standard)
    }

    @MainActor func testRowsAndPlatesRender() throws {
        let store = PitchStore()
        let entries = store.repertoire.entries
        let sample = [entries.first { $0.filedSlug != nil }, entries.first { $0.filedSlug == nil },
                      entries.first { $0.status == .banned }, entries.first { store.gripEntry(forRepertoire: $0)?.photos.first != nil }]
        for e in sample.compactMap({ $0 }) {
            XCTAssertNotNil(ImageRenderer(content: IndexRow(entry: e).frame(width: 340).environment(store)).uiImage, e.id)
        }
        for c in store.craftsmen.prefix(3) {
            XCTAssertNotNil(ImageRenderer(content: CraftsmanCard(craftsman: c).frame(width: 340).environment(store)).uiImage, c.slug)
        }
        for p in store.lostPitches.entries.prefix(3) {
            XCTAssertNotNil(ImageRenderer(content: LostPitchCard(pitch: p).frame(width: 340)).uiImage, p.slug)
        }
    }
}
