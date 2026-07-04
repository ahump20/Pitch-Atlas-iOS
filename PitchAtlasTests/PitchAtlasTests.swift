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

    /// Blaze must stay tied to the existing pet sheet, not split into invented
    /// mood art or a different dog.
    func testBlazeFrameManifestUsesCanonicalSheet() {
        XCTAssertEqual(BlazeFrameManifest.frameWidth, 192)
        XCTAssertEqual(BlazeFrameManifest.frameHeight, 208)
        XCTAssertEqual(BlazeFrameManifest.sheetColumns, 8)
        XCTAssertEqual(BlazeFrameManifest.sheetRows, 9)
        XCTAssertEqual(BlazeFrameManifest.sourceSpriteSHA256,
                       "992ed0f946edd8ea694c04977f22de162f191fd5aa5e8abc910d816320fa0a7b")
        XCTAssertEqual(BlazeFrameManifest.sourcePetSHA256,
                       "d5f6fc46f71fd672375e40263cf5fb08dda5d81bd66b505e3a32d63358af24d2")

        XCTAssertEqual(BlazeFrameManifest.sequence(for: .idle).frames.count, 6)
        XCTAssertEqual(BlazeFrameManifest.sequence(for: .chasing).frames.count, 8)
        XCTAssertEqual(BlazeFrameManifest.sequence(for: .caught).frames.count, 4)
        XCTAssertEqual(BlazeFrameManifest.sequence(for: .sniffing).frames.count, 4)
        XCTAssertEqual(BlazeFrameManifest.sequence(for: .napping).frames.count, 6)
        XCTAssertEqual(BlazeFrameManifest.sequence(for: .concerned).frames.count, 4)
        XCTAssertEqual(BlazeFrameManifest.sequence(for: .still).frames.count, 1)
    }

    func testBlazeMoodPolicy() {
        XCTAssertEqual(BlazeRouteMood.mood(for: .atlas, pathDepth: 0), .sniffing)
        XCTAssertEqual(BlazeRouteMood.mood(for: .index, pathDepth: 1), .chasing)
        XCTAssertEqual(BlazeRouteMood.mood(for: .craftsmen, pathDepth: 0), .idle)
        XCTAssertEqual(BlazeRouteMood.mood(for: .sources, pathDepth: 0), .hidden)
        XCTAssertEqual(BlazeRouteMood.mood(for: .atlas, pathDepth: 0, isSeriousFlow: true), .hidden)
    }

    func testBlazeReducedMotionPolicy() {
        XCTAssertEqual(BlazeRouteMood.reducedMotionMood(.chasing, reduceMotion: true), .still)
        XCTAssertEqual(BlazeRouteMood.reducedMotionMood(.sniffing, reduceMotion: true), .still)
        XCTAssertEqual(BlazeRouteMood.reducedMotionMood(.concerned, reduceMotion: true), .concerned)
        XCTAssertEqual(BlazeRouteMood.reducedMotionMood(.hidden, reduceMotion: true), .hidden)
        XCTAssertEqual(BlazeRouteMood.reducedMotionMood(.caught, reduceMotion: false), .caught)
    }

    func testBlazePreferenceAndResources() {
        XCTAssertEqual(BlazeCompanionPreference.key, "pitchAtlas.showBlazeCompanion")
        XCTAssertFalse(BlazeCompanionPreference.defaultValue)
        XCTAssertNotNil(blazeResource("pet", "json", subdirectory: "blaze"))
        XCTAssertNotNil(blazeResource("spritesheet", "webp", subdirectory: "blaze"))
        XCTAssertNotNil(blazeResource("frame-manifest", "json", subdirectory: "blaze"))
        XCTAssertNotNil(blazeResource("blaze_chasing_00", "png", subdirectory: "blaze/frames"))
        XCTAssertNotNil(blazeResource("blaze_still_00", "png", subdirectory: "blaze/frames"))
    }

    /// Gather the headline claims on a pitch for the provenance check.
    private func claims(in entry: PitchAtlasEntry) -> [Claim] {
        var out: [Claim] = [entry.canonical.grip, entry.canonical.mechanics,
                            entry.physics.teaching, entry.physics.spinAxis]
        out.append(contentsOf: entry.canonical.gripDetails)
        if let shape = entry.physics.shape { out.append(shape) }
        if let spinRate = entry.physics.spinRateRpm { out.append(spinRate) }
        if let primaryBreak = entry.physics.primaryBreak { out.append(primaryBreak.claim) }
        if let secondaryBreak = entry.physics.secondaryBreak { out.append(secondaryBreak.claim) }
        if let activeSpin = entry.physics.activeSpinPct { out.append(activeSpin) }
        if let voice = entry.canonical.voice { out.append(voice) }
        for variant in entry.masterVariants {
            if let distinction = variant.distinction { out.append(distinction) }
            out.append(contentsOf: variant.recordNumbers.map(\.claim))
            if let quote = variant.quote { out.append(quote) }
        }
        return out
    }

    private func blazeResource(_ name: String, _ ext: String, subdirectory: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdirectory)
            ?? Bundle.main.url(forResource: name, withExtension: ext)
    }
}

private extension PitchAtlasEntry {
    var physics: PhysicsReference { canonical.physics }
}
