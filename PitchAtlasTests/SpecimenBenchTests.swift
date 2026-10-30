import XCTest
@testable import PitchAtlas

/// The one-pitch bench, read the way inspector/useInspector.ts, SpecimenInspector.tsx,
/// InspectorRail.tsx and InspectButton.tsx read it (web 47e21e6).
final class SpecimenBenchTests: XCTestCase {
    private let store = PitchStore()

    /// useInspector's `filed`: only a pitch in the bundle opens; a new bench starts on
    /// the grip with no partner and the pitch's own view; the hand carries over.
    func testOnlyAFiledPitchOpensTheBench() {
        let bench = SpecimenBench()
        bench.open("no-such-pitch", store: store)
        XCTAssertNil(bench.opened, "an unknown slug opens nothing")
        bench.hand = .left
        bench.open("four-seam", store: store)
        XCTAssertEqual(bench.opened?.slug, "four-seam")
        XCTAssertNil(bench.partner)
        XCTAssertEqual(bench.mode, .grips, "the card aspect is a fast-follow, so the bench opens on the grip")
        XCTAssertNil(bench.orientation, "a new bench shows each pitch's own view")
        XCTAssertEqual(bench.hand, .left, "the hand carries over, as the site's does")
        bench.close()
        XCTAssertNil(bench.opened)
    }

    /// The bench's view: the reader's choice, or the first pitch's own default view.
    func testViewIsTheReadersOrThePitchsOwn() throws {
        let bench = SpecimenBench()
        let entry = try XCTUnwrap(store.pitches.first { $0.canonical.gripModel.defaultView != .top })
        bench.open(entry.slug, store: store)
        XCTAssertEqual(bench.view(for: [entry]), entry.canonical.gripModel.defaultView)
        bench.orientation = .top
        XCTAssertEqual(bench.view(for: [entry]), .top)
    }

    /// "Compare with": never the open pitch; "No second pitch" clears it; a pitch the
    /// bundle lacks is refused; a chosen pair is also the tray's pair, so it waits after Close.
    func testCompareWithSetsTheTraysPair() throws {
        let bench = SpecimenBench()
        let compare = CompareSelection()
        bench.open("four-seam", store: store)
        XCTAssertFalse(SpecimenBench.partnerOptions(for: "four-seam", store: store).contains { $0.slug == "four-seam" })
        XCTAssertEqual(SpecimenBench.partnerOptions(for: "four-seam", store: store).count, store.pitches.count - 1)
        bench.choosePartner("four-seam", store: store, compare: compare)
        XCTAssertNil(bench.partner, "a pitch is never its own partner")
        bench.choosePartner("no-such-pitch", store: store, compare: compare)
        XCTAssertNil(bench.partner)
        XCTAssertEqual(compare.slugs, [], "nothing chosen, nothing in the tray")
        let other = try XCTUnwrap(store.pitches.first { $0.slug != "four-seam" }).slug
        bench.choosePartner(other, store: store, compare: compare)
        XCTAssertEqual(bench.partner, other)
        XCTAssertEqual(compare.slugs, ["four-seam", other])
        XCTAssertFalse(compare.presented, "the table stays shut; the bench shows the pair")
        bench.choosePartner(nil, store: store, compare: compare)
        XCTAssertNil(bench.partner)
        XCTAssertEqual(compare.slugs, ["four-seam", other], "clearing the partner leaves the tray's pair")
    }

    /// InspectorHeader and InspectButton, in the site's words.
    func testBenchSaysWhatItShows() throws {
        let a = try XCTUnwrap(store.pitch(slug: "four-seam"))
        let b = try XCTUnwrap(store.pitches.first { $0.slug != "four-seam" })
        XCTAssertEqual(SpecimenBench.title(a, partner: nil), a.canonical.name)
        XCTAssertEqual(SpecimenBench.title(a, partner: b), "\(a.canonical.name) and \(b.canonical.name)")
        XCTAssertEqual(SpecimenBench.inspectLabel, "Inspect card")
        XCTAssertEqual(SpecimenBench.inspectAccessibility("circle-change"), "Inspect card circle change")
        XCTAssertEqual(SpecimenBench.withLabel, "Compare with")
        XCTAssertEqual(SpecimenBench.noPartner, "No second pitch")
        XCTAssertNil(SpecimenBench.overline(a), "\"Four-seam fastball\" needs no \"Fastball\" over it")
        let breaking = try XCTUnwrap(store.pitches.first { $0.canonical.family == .breaking && !$0.canonical.name.lowercased().contains("breaking") })
        XCTAssertEqual(SpecimenBench.overline(breaking), "Breaking")
        XCTAssertEqual(SpecimenBench.note(.grips), "Where each finger meets the seam, finger by finger.")
        XCTAssertEqual(SpecimenBench.note(.cues), "How the hold becomes the release.")
        XCTAssertEqual(SpecimenBench.note(.movement), "An illustrative flight drawn from the mound, beside the sourced shape words.")
    }
}
