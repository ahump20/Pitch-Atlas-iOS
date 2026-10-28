import XCTest
@testable import PitchAtlas

/// The basic file reads its neighbors the way RepertoireChapter.tsx does:
/// BASIC_REPERTOIRE is the catalog with every filed pitch taken out, in the
/// catalog's order, and the family rail is repertoireByFamily minus the pitch
/// itself. Expected ids come from web data/repertoire/index.ts at 47e21e6 and
/// the live /repertoire/split-finger-fastball page (no previous, next One-Seam
/// Sinker; eight fastball siblings, the alias and the illusion in seam red).
final class BasicFileTests: XCTestCase {
    private let store = PitchStore()

    private func entry(_ id: String) throws -> RepertoireEntry {
        try XCTUnwrap(store.repertoireEntry(id: id), "\(id) is not in the bundle")
    }

    func testPreviousAndNextFollowTheCatalogWithFiledPitchesTakenOut() throws {
        let entries = store.repertoire.entries

        let first = BasicFile.neighbors(of: try entry("split-finger-fastball"), in: entries)
        XCTAssertNil(first.previous)
        XCTAssertEqual(first.next?.id, "one-seam-sinker")

        // Crosses from the fastballs into the offspeed files, past the filed changeup.
        let middle = BasicFile.neighbors(of: try entry("straight-three-finger-changeup"), in: entries)
        XCTAssertEqual(middle.previous?.id, "rising-fastball")
        XCTAssertEqual(middle.next?.id, "football-changeup")

        let last = BasicFile.neighbors(of: try entry("dead-fish-changeup"), in: entries)
        XCTAssertEqual(last.previous?.id, "deathball")
        XCTAssertNil(last.next)

        // A filed pitch opens its specimen, so it has no place in the basic run.
        let filed = BasicFile.neighbors(of: try entry("four-seam-fastball"), in: entries)
        XCTAssertNil(filed.previous)
        XCTAssertNil(filed.next)
    }

    func testTheBasicRunHoldsOnlyUnfiledPitchesInCatalogOrder() {
        let entries = store.repertoire.entries
        let basics = BasicFile.basics(in: entries)
        XCTAssertFalse(basics.isEmpty)
        XCTAssertTrue(basics.allSatisfy { $0.filedSlug == nil })
        XCTAssertEqual(basics.map(\.id), entries.filter { $0.filedSlug == nil }.map(\.id))
    }

    func testTheFamilyRailIsEveryOtherPitchInTheFamilyFiledOrNot() throws {
        let siblings = BasicFile.siblings(of: try entry("split-finger-fastball"), in: store.repertoire.entries)
        XCTAssertEqual(siblings.map(\.id), [
            "four-seam-fastball", "two-seam-fastball", "sinker", "one-seam-sinker",
            "cutter", "running-fastball", "rising-fastball", "razor-shuuto",
        ])
    }

    func testTheEdgeStatusesTakeTheSeamAccentAndTheBadge() throws {
        XCTAssertEqual(BasicFile.accentRGB(try entry("split-finger-fastball")), 0xBF5700)
        XCTAssertEqual(BasicFile.accentRGB(try entry("running-fastball")), 0xFF4D46)
        XCTAssertEqual(BasicFile.accentRGB(try entry("rising-fastball")), 0xFF4D46)
        XCTAssertFalse(BasicFile.isEdge(.niche))
        XCTAssertTrue(BasicFile.isEdge(.alias))
        XCTAssertTrue(BasicFile.isEdge(.illusion))
        XCTAssertTrue(BasicFile.isEdge(.notAPitch))
        XCTAssertTrue(BasicFile.isEdge(.banned))
    }

    func testTheEyebrowAndTheRailHeadingSpeakTheSitesFamilyNames() throws {
        XCTAssertEqual(BasicFile.eyebrow(.fastball), "Fastball")
        XCTAssertEqual(BasicFile.eyebrow(.breaking), "Breaking ball")
        XCTAssertEqual(BasicFile.eyebrow(.banned), "Banned & doctored")
        XCTAssertEqual(BasicFile.railHeading(.breaking), "Others in the breaking ball")
        XCTAssertEqual(BasicFile.railHeading(.banned), "Others in the banned & doctored")
        XCTAssertEqual(BasicFile.akaLine(try entry("split-finger-fastball")), "aka split-finger · splitfinger fastball")
    }

    func testTheGripPhotosFindTheirPitchByAnyKey() {
        XCTAssertEqual(store.gripEntry(forKey: "split-finger-fastball")?.id, "split-finger")
        XCTAssertEqual(store.gripEntry(forKey: "straight-three-finger-changeup")?.id, "three-finger-change")
        XCTAssertEqual(store.gripEntry(forKey: "four-seam")?.id, "four-seam")
        XCTAssertNil(store.gripEntry(forKey: "one-seam-sinker"))
    }
}
