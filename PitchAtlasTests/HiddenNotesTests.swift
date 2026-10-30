import XCTest
@testable import PitchAtlas

/// The ten hidden archive notes, pinned to the site's eggs layer (web 47e21e6):
/// data/tidbits/index.ts, components/eggs/tidbitStore.ts, TidbitReveal.tsx,
/// FoundIndex.tsx, and the ten EggButton placements.
final class HiddenNotesTests: XCTestCase {
    private let store = PitchStore()
    private var suite: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suite = "HiddenNotesTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    private func notes() -> HiddenNotes {
        HiddenNotes(known: store.tidbits.map(\.id), defaults: defaults)
    }

    /// TIDBITS: ten notes, each wearing a source and naming where it is filed.
    func testTheBundleFilesTheSitesTenNotesEachSourcedAndPlaced() {
        XCTAssertEqual(store.tidbits.count, 10)
        for note in store.tidbits {
            XCTAssertNotNil(note.claim.source?.url, note.id)
            XCTAssertFalse(note.eggLocation.isEmpty, note.id)
        }
    }

    /// Every note is placed by exactly one spot the app ships, and every spot places a
    /// real note: "n of 10" is always completable.
    func testEveryNoteHasExactlyOnePlacement() {
        let placed = HiddenNotePlacement.allCases.map(\.rawValue)
        XCTAssertEqual(Set(placed).count, placed.count)
        XCTAssertEqual(Set(placed), Set(store.tidbits.map(\.id)))
    }

    func testFindingANoteTwiceCountsOnce() {
        let n = notes()
        n.discover("stitches")
        n.discover("stitches")
        XCTAssertEqual(n.count, 1)
        XCTAssertTrue(n.has("stitches"))
        XCTAssertFalse(n.has("eephus"))
    }

    /// An id the bundle does not file is never counted (the site's tidbitById guard).
    func testAnUnknownIdIsIgnored() {
        let n = notes()
        n.discover("no-such-note")
        XCTAssertEqual(n.count, 0)
    }

    /// The found set is the site's key and shape: a JSON array of ids under
    /// pa-tidbits-found-v1, read back by the next launch.
    func testTheFoundSetSurvivesARelaunchUnderTheSitesKey() throws {
        notes().discover("doubleday")
        notes().discover("the-k")
        let raw = try XCTUnwrap(defaults.string(forKey: "pa-tidbits-found-v1"))
        let ids = try JSONDecoder().decode([String].self, from: Data(raw.utf8))
        XCTAssertEqual(ids, ["doubleday", "the-k"])
        XCTAssertEqual(notes().count, 2)
    }

    /// A stored value that is not a JSON array of strings loads as nothing found.
    func testACorruptStoreLoadsEmpty() {
        defaults.set("{not json", forKey: "pa-tidbits-found-v1")
        XCTAssertEqual(notes().count, 0)
    }

    /// PitchIndex: the eephus note shows only when the trimmed, lowercased search is
    /// exactly "eephus".
    func testTheEephusNoteNeedsTheExactSearch() {
        XCTAssertTrue(HiddenNotePlacement.showsEephus(query: "  EEPHUS "))
        XCTAssertFalse(HiddenNotePlacement.showsEephus(query: "eephu"))
        XCTAssertFalse(HiddenNotePlacement.showsEephus(query: "eephus pitch"))
    }

    /// The site's words: the trigger labels, the reveal, the index and the footer.
    func testTheSitesWords() {
        XCTAssertEqual(HiddenNotePlacement.stitches.label, "Reveal a hidden note about how a baseball is stitched")
        XCTAssertEqual(HiddenNotePlacement.doubleday.label,
                       "The archive stays open: reveal a hidden note about the game's origin")
        XCTAssertEqual(HiddenNotes.footerLine(count: 3, total: 10), "Hidden notes · 3 of 10 found")
        XCTAssertEqual(HiddenNotes.filedLine(count: 3, total: 10), "Filed: 3 of 10 found")
        XCTAssertEqual(HiddenNotes.lockedLine("The Shape Lab"), "Not yet found · filed from The Shape Lab")
        XCTAssertEqual(HiddenNotes.indexLede,
                       "Ten real, sourced tidbits are hidden across the historical files. Find one and it gets filed here. Locked slots name only where they are filed.")
    }
}
