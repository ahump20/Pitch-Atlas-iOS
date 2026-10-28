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
}
