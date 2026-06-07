import XCTest
@testable import PitchAtlas

final class PitchAtlasTests: XCTestCase {

    /// The shell must expose exactly the five v1 tabs.
    func testFiveTabs() {
        XCTAssertEqual(AppTab.allCases.count, 5)
        XCTAssertEqual(AppTab.allCases.map(\.rawValue),
                       ["atlas", "index", "grips", "craftsmen", "sources"])
    }

    /// Provenance mapping must always resolve — an unknown tier falls back to the
    /// honest gray (unverified), never crashes and never silently upgrades.
    func testConfidenceColorFallback() {
        let known = PitchAtlasTheme.color(forConfidence: "official-data")
        let unknown = PitchAtlasTheme.color(forConfidence: "nonsense-tier")
        XCTAssertEqual(unknown, PitchAtlasTheme.ink3)
        XCTAssertNotEqual(known, PitchAtlasTheme.ink3)
    }

    /// Every bundled JSON decodes with zero failures across every record.
    /// If any file or any record fails, the store records it and this fails.
    func testBundleDecodesCleanly() {
        let store = PitchStore()
        if case .failed(let message) = store.status {
            XCTFail("Content failed to decode — \(message)")
        }
        XCTAssertFalse(store.pitches.isEmpty, "no pitches decoded")
        XCTAssertFalse(store.repertoire.entries.isEmpty, "no repertoire entries decoded")
        XCTAssertFalse(store.craftsmen.isEmpty, "no craftsmen decoded")
        XCTAssertFalse(store.lostPitches.entries.isEmpty, "no lost pitches decoded")
        XCTAssertFalse(store.knowledge.isEmpty, "no knowledge wings decoded")
        XCTAssertFalse(store.grips.entries.isEmpty, "no grips decoded")
        XCTAssertFalse(store.sources.isEmpty, "no sources decoded")
    }

    /// Drift guard: decoded record counts must match the build manifest. If the
    /// generator emits more records than the models can decode (a new field/shape),
    /// the array decode throws and counts diverge — caught here and in CI.
    func testDecodedCountsMatchManifest() {
        let store = PitchStore()
        XCTAssertEqual(store.pitches.count, store.manifest.counts["pitches.json"])
        XCTAssertEqual(store.repertoire.entries.count, store.manifest.counts["repertoire.json"])
        XCTAssertEqual(store.craftsmen.count, store.manifest.counts["craftsmen.json"])
        XCTAssertEqual(store.lostPitches.entries.count, store.manifest.counts["lost-pitches.json"])
        XCTAssertEqual(store.knowledge.count, store.manifest.counts["knowledge.json"])
        XCTAssertEqual(store.grips.entries.count, store.manifest.counts["grips.json"])
        XCTAssertEqual(store.sources.count, store.manifest.counts["sources.json"])
    }

    /// Provenance integrity: a confident claim carries a source; a weak claim
    /// (unverified / secondhand) carries an explanatory note. This is the data
    /// contract the whole "Sourced, not corrected" promise rests on.
    func testProvenanceContractHolds() {
        let store = PitchStore()
        var checked = 0
        for entry in store.pitches {
            for claim in claims(in: entry) {
                checked += 1
                switch claim.confidence {
                case .unverified, .secondhandAttributed:
                    XCTAssertNotNil(claim.note,
                                    "weak claim must carry a note: \(claim.value.prefix(40))")
                default:
                    XCTAssertNotNil(claim.source,
                                    "confident claim must carry a source: \(claim.value.prefix(40))")
                }
            }
        }
        XCTAssertGreaterThan(checked, 0, "expected claims to verify")
    }

    /// Gather the headline claims on a pitch for the provenance check.
    private func claims(in entry: PitchAtlasEntry) -> [Claim] {
        var out: [Claim] = [entry.canonical.grip, entry.canonical.mechanics,
                            entry.physics.teaching, entry.physics.spinAxis,
                            entry.physics.spinRateRpm, entry.physics.primaryBreak.claim]
        out.append(contentsOf: entry.canonical.gripDetails)
        if let voice = entry.canonical.voice { out.append(voice) }
        return out
    }
}

private extension PitchAtlasEntry {
    var physics: PhysicsReference { canonical.physics }
}
