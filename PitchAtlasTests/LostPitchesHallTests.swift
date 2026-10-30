import SwiftUI
import XCTest
@testable import PitchAtlas

/// The Lost Pitches hall and a lost pitch's file, read the way LostPitchesHall.tsx,
/// WhyPitchesDie.tsx, EraTimeline.tsx, ArchiveImageRail.tsx and
/// LostPitchChapter.tsx read the record. The expected words and placements are
/// the ones pitch-atlas.com printed on /lost-pitches (web 47e21e6).
final class LostPitchesHallTests: XCTestCase {
    private let store = PitchStore()

    private func lost(_ slug: String) throws -> LostPitch {
        try XCTUnwrap(store.lostPitch(slug: slug), "\(slug) is not in the bundle")
    }

    // MARK: - Why pitches die

    /// The through-line: four forces in the order they take a pitch out of the
    /// game, each told in full and each carrying at least one sourced claim.
    func testTheThroughLineFilesFourForcesInTheSitesOrderEachSourced() {
        let forces = store.lostPitches.forces
        XCTAssertEqual(forces.map(\.era), ["1920 →", "1948", "Always", "2020 · 2024"])
        XCTAssertEqual(forces.map(\.heading), ["A rule outlaws it.",
                                               "A ruling kills it mid-career.",
                                               "The technique dies with the arm.",
                                               "The record comes back, but only the numbers."])
        for force in forces {
            XCTAssertFalse(force.body.isEmpty, force.heading)
            XCTAssertFalse(force.claims.isEmpty, "\(force.heading) carries no claim")
            for claim in force.claims {
                XCTAssertNotNil(claim.source, "\(force.heading): \(claim.value)")
            }
        }
        XCTAssertEqual(forces.count, store.manifest.counts["lost-pitches.forces"], "the generator counted them from source")
    }

    // MARK: - The record, in time

    /// EraTimeline's packing: by start year, each marker drops into the first row
    /// whose last marker sits 18% or more to its left.
    func testTheTimelinePacksEachLaneTheSitesWay() {
        let documented = LostTimeline.pack(store.lostPitches.entries.filter { $0.tier == .documented })
        XCTAssertEqual(documented.placed.map(\.pitch.specimenNo), ["N-03", "N-05", "N-07", "N-04", "N-06", "N-08", "N-02", "N-01"])
        XCTAssertEqual(documented.placed.map(\.row), [0, 1, 0, 2, 3, 4, 0, 0])
        XCTAssertEqual(documented.rows, 5)
        let partial = LostTimeline.pack(store.lostPitches.entries.filter { $0.tier == .partial })
        XCTAssertEqual(partial.placed.map(\.pitch.specimenNo), ["N-09", "N-11", "N-13", "N-14", "N-12", "N-10"])
        XCTAssertEqual(partial.placed.map(\.row), [0, 1, 2, 3, 0, 1])
        XCTAssertEqual(LostTimeline.pack([]).rows, 1, "a lane keeps one row, as the site's max(1, rows) does")
    }

    /// The axis runs 1898 to 1960, clamped at both ends; the decades sit on it.
    func testTheAxisRunsEighteenNinetyEightToNineteenSixty() {
        XCTAssertEqual(LostTimeline.position(1898), 0, accuracy: 1e-12)
        XCTAssertEqual(LostTimeline.position(1929), 0.5, accuracy: 1e-12)
        XCTAssertEqual(LostTimeline.position(1960), 1, accuracy: 1e-12)
        XCTAssertEqual(LostTimeline.position(1890), 0)
        XCTAssertEqual(LostTimeline.position(1970), 1)
        XCTAssertEqual(LostTimeline.decades, [1900, 1910, 1920, 1930, 1940, 1950])
    }

    // MARK: - The image record

    /// The rail prints a plate's rights as the site does, its raw value.
    func testThePlateRightsLineIsTheRawRightsValue() throws {
        let paige = try XCTUnwrap(store.archiveImage(forLostPitch: "satchel-paige-hesitation-pitch"))
        XCTAssertEqual(LostArchiveReads.rightsLine(paige), "public-domain")
        let smith = try XCTUnwrap(store.archiveImage(forLostPitch: "hilton-smith-curveball"))
        XCTAssertEqual(LostArchiveReads.rightsLine(smith), "original")
        XCTAssertEqual(LostArchiveReads.openLine(smith), "Open Hilton Smith's Curveball")
    }

    /// The plate's kind prints as the site prints it, its first dash a space.
    func testThePlateKindPrintsWithItsDashAsASpace() throws {
        let smith = try XCTUnwrap(store.archiveImage(forLostPitch: "hilton-smith-curveball"))
        XCTAssertEqual(smith.plateKind, .originalStudy)
        XCTAssertEqual(LostArchiveReads.kindLine(smith), "original study")
        let paige = try XCTUnwrap(store.archiveImage(forLostPitch: "satchel-paige-hesitation-pitch"))
        XCTAssertEqual(LostArchiveReads.kindLine(paige), paige.plateKind.rawValue, "a kind with no dash prints as filed")
    }

    /// The stats box reads its three counts off the plates.
    func testTheImageRecordCountsItsPlates() {
        let images = store.archiveImages
        let stats = LostArchiveReads.stats(images)
        XCTAssertEqual(stats.filed, images.count)
        XCTAssertEqual(stats.publicDomain, images.filter { $0.rights == .publicDomain }.count)
        XCTAssertEqual(stats.original, images.filter { $0.rights == .original }.count)
        XCTAssertGreaterThan(stats.publicDomain, 0)
        XCTAssertGreaterThan(stats.original, 0)
    }

    // MARK: - The tiers

    /// LOST_PITCH_TIERS in order, each holding its entries in file order; every
    /// entry is filed exactly once.
    func testTheTiersFileTheirEntriesInFileOrder() {
        let groups = LostArchiveReads.tierGroups(store.lostPitches)
        XCTAssertEqual(groups.map(\.info.tier), [.documented, .partial, .legend])
        XCTAssertEqual(groups.map(\.info.index), ["N", "P", "L"])
        XCTAssertEqual(groups.flatMap(\.entries).count, store.lostPitches.entries.count)
        XCTAssertEqual(groups.first?.entries.first?.specimenNo, "N-01")
        for group in groups {
            let order = store.lostPitches.entries.filter { $0.tier == group.info.tier }.map(\.slug)
            XCTAssertEqual(group.entries.map(\.slug), order)
        }
    }

    /// The card no longer wears a tier pill; it names the kind and the era.
    func testTheCardLabelNamesNumberKindAndEra() throws {
        let paige = try lost("satchel-paige-hesitation-pitch")
        XCTAssertEqual(LostPitchPlate.accessibilityLabel(paige),
                       "N-01, Satchel Paige's Hesitation Pitch, Lost pitch, Documented, Negro Leagues / 1948 American League. The pause the rulebook outlawed")
    }

    /// The cards and the media wells print the site's own seal.
    func testTheSitesSealIsBundled() {
        XCTAssertNotNil(BundledImage.load(ArchiveSealMark.src))
    }

    // MARK: - A lost pitch's file

    /// "In this archive file": the pitch, what it was, why it is lost, and the
    /// surviving record only when one is filed.
    func testTheFileChaptersFollowWhatTheRecordHolds() throws {
        let rube = try lost("rube-foster-fadeaway")
        XCTAssertEqual(LostPitchFileReads.chapters(rube).map(\.title), ["The pitch", "What it was", "Why it is lost", "Surviving record"])
        XCTAssertEqual(LostPitchFileReads.chapters(rube).map(\.id), ["story", "account", "absence", "record"])
        let bare = try stripped(rube, ["record"])
        XCTAssertEqual(LostPitchFileReads.chapters(bare).map(\.id), ["story", "account", "absence"])
    }

    /// Chapter to chapter in the archive's file order.
    func testTheFileWalksTheArchiveInFileOrder() throws {
        let entries = store.lostPitches.entries
        let first = LostPitchFileReads.neighbors(of: entries[0], in: entries)
        XCTAssertNil(first.prev)
        XCTAssertEqual(first.next?.slug, entries[1].slug)
        let last = LostPitchFileReads.neighbors(of: entries[entries.count - 1], in: entries)
        XCTAssertEqual(last.prev?.slug, entries[entries.count - 2].slug)
        XCTAssertNil(last.next)
        let missing = LostPitchFileReads.neighbors(of: entries[0], in: [])
        XCTAssertNil(missing.prev)
        XCTAssertNil(missing.next)
    }

    /// Only the fadeaway follows its name into a pitch: the screwball file.
    func testOnlyTheFadeawayFollowsItsNameIntoAPitch() throws {
        let followOn = try XCTUnwrap(LostPitchFileReads.followOn(try lost("rube-foster-fadeaway")))
        XCTAssertEqual(followOn.path, "repertoire/screwball")
        XCTAssertEqual(followOn.repertoireId, "screwball")
        XCTAssertNotNil(store.repertoireEntry(id: "screwball"), "the follow-on opens a file the bundle carries")
        XCTAssertNil(LostPitchFileReads.followOn(try lost("satchel-paige-hesitation-pitch")))
    }

    /// The community thread a file opens: `lost:<slug>`, the web's own key.
    func testTheFilesThreadIsTheWebsKey() throws {
        XCTAssertEqual(LostPitchFileReads.topic(try lost("rube-foster-fadeaway")).key, "lost:rube-foster-fadeaway")
    }

    // MARK: - Helpers

    /// The entry with some fields removed, through the bundle's own coding.
    private func stripped(_ p: LostPitch, _ keys: [String]) throws -> LostPitch {
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(p)) as? [String: Any])
        keys.forEach { object.removeValue(forKey: $0) }
        return try JSONDecoder().decode(LostPitch.self, from: JSONSerialization.data(withJSONObject: object))
    }
}
