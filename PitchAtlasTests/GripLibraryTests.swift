import XCTest
@testable import PitchAtlas

/// The Grip Library, read the way GripLibrary.tsx reads AUSTIN_GRIPS. The expected
/// results are the site's own filter run over the same bundle (web 47e21e6).
final class GripLibraryTests: XCTestCase {
    private let file = PitchStore().grips

    private func entry(_ id: String) throws -> GripEntry {
        try XCTUnwrap(file.entries.first { $0.id == id }, "\(id) is not in the bundle")
    }

    /// "Find a grip" looks for the words in the grip's name and in Austin's own
    /// note, any case, the ends of the query trimmed; nothing typed shows all.
    func testFindAGripSearchesTheNameAndAustinsWords() {
        let ids = { (query: String) in GripLibraryReads.matches(self.file.entries, query: query).map(\.id) }
        XCTAssertEqual(ids(""), file.entries.map(\.id))
        XCTAssertEqual(ids("   "), file.entries.map(\.id))
        XCTAssertEqual(ids("curve"), ["twelve-six"])
        XCTAssertEqual(ids("  curve  "), ["twelve-six"])
        XCTAssertEqual(ids("CHANGEUP"), ["football-change", "three-finger-change"])
        XCTAssertEqual(ids("thumb"), ["twelve-six"], "the note is searched, not only the name")
        XCTAssertEqual(ids("seam"), ["four-seam", "two-seam", "twelve-six", "split-finger"])
        XCTAssertEqual(ids("knuckle"), [])
    }

    /// The status line under the field, in the site's words.
    func testTheCountReadsLikeTheSite() {
        XCTAssertEqual(GripLibraryReads.countLine(shown: 7, of: 7), "7 of 7 grips")
        XCTAssertEqual(GripLibraryReads.countLine(shown: 0, of: 7), "0 of 7 grips")
    }

    /// A grip with a filed specimen goes to it; one with only a basic file opens
    /// that; the words are the site's.
    func testEachGripLinksWhereTheSiteDoes() throws {
        XCTAssertEqual(GripLibraryReads.link(try entry("four-seam")), .specimen(slug: "four-seam"))
        XCTAssertEqual(GripLibraryReads.link(try entry("split-finger")), .file(id: "split-finger-fastball"))
        XCTAssertEqual(GripLibraryReads.link(try entry("circle-change")), .specimen(slug: "circle-change"))
        XCTAssertEqual(GripLibraryReads.Link.specimen(slug: "x").label, "See the specimen")
        XCTAssertEqual(GripLibraryReads.Link.file(id: "x").label, "Open the file")
    }

    /// The circle change has no photograph of Austin's hand, so the library shows
    /// the labeled gap where the photos would be — and only there.
    func testTheCircleChangeShowsItsLabeledGap() throws {
        let gap = try XCTUnwrap(GripLibraryReads.gap(for: try entry("circle-change"), in: file))
        XCTAssertEqual(gap.marker, "Circle Changeup · Filed from external sources · No Austin grip photo")
        XCTAssertNil(GripLibraryReads.gap(for: try entry("four-seam"), in: file))
        XCTAssertNil(GripLibraryReads.gap(for: try entry("split-finger"), in: file))
    }

    /// The library offers Pause while a grip on show moves, and not under Reduce
    /// Motion, when nothing could.
    func testPauseIsOfferedOnlyWhileAShownGripMoves() throws {
        XCTAssertTrue(GripLibraryReads.loops(file.entries, reduceMotion: false))
        XCTAssertFalse(GripLibraryReads.loops(file.entries, reduceMotion: true))
        XCTAssertFalse(GripLibraryReads.loops([try entry("split-finger")], reduceMotion: false))
        XCTAssertFalse(GripLibraryReads.loops([], reduceMotion: false))
    }

    /// A film moves only while some of it is on screen, the way AutoplayVideo.tsx's
    /// observer reads the page: it starts a tenth of a screen early from below and
    /// stops once it has scrolled fully away.
    func testAFilmPlaysOnlyWhileOnScreen() {
        let screen = CGRect(x: 0, y: 0, width: 440, height: 956)
        let film = { (y: CGFloat) in CGRect(x: 20, y: y, width: 400, height: 700) }
        XCTAssertTrue(GripLoopFace.isOnScreen(film(100), in: screen))
        XCTAssertTrue(GripLoopFace.isOnScreen(film(-690), in: screen), "a sliver left at the top still plays")
        XCTAssertFalse(GripLoopFace.isOnScreen(film(-710), in: screen), "scrolled away above, it stops")
        XCTAssertTrue(GripLoopFace.isOnScreen(film(1000), in: screen), "it starts a tenth of a screen before it shows")
        XCTAssertFalse(GripLoopFace.isOnScreen(film(1060), in: screen))
        XCTAssertFalse(GripLoopFace.isOnScreen(.zero, in: screen), "a film with no size never plays")
    }

    /// The coal room is painted row by row on the lazy page: each row draws its
    /// slice of one room, so the crown (50% 40% at 50% −6%) and the bone wash
    /// (40% 36% at 12% 16%) sit at the same room point whatever row draws them.
    func testCoalRoomSlicesShareOneRoom() {
        let first = CoalRoomSlice.centers(width: 440, roomHeight: 30_000, rowOffset: 0)
        let later = CoalRoomSlice.centers(width: 440, roomHeight: 30_000, rowOffset: 1_200)
        XCTAssertEqual(first.crown.x, 220, accuracy: 1e-9)
        XCTAssertEqual(first.crown.y, -1_800, accuracy: 1e-9)
        XCTAssertEqual(first.wash.x, 52.8, accuracy: 1e-9)
        XCTAssertEqual(first.wash.y, 4_800, accuracy: 1e-9)
        XCTAssertEqual(first.crown.y - later.crown.y, 1_200, accuracy: 1e-9)
        XCTAssertEqual(first.wash.y - later.wash.y, 1_200, accuracy: 1e-9)
    }
}
