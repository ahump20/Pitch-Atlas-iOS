import XCTest
@testable import PitchAtlas

/// Findings from the 1.2 whole-branch review of navigation, each pinned before
/// its fix. Web truth: compare/CompareProvider.tsx at 47e21e6.
final class NavigationReviewFixTests: XCTestCase {
    private let store = PitchStore()

    /// CompareProvider parses the address only when it carries a query: the menu's
    /// bare "Compare two pitches" opens the table on the pair already chosen.
    func testABareCompareLinkKeepsTheChosenPair() throws {
        let state = CompareSelection()
        state.toggle("four-seam"); state.toggle("slider")
        state.hand = .left
        XCTAssertTrue(state.handle(try XCTUnwrap(URL(string: "pitchatlas://compare")), store: store))
        XCTAssertEqual(state.slugs, ["four-seam", "slider"])
        XCTAssertEqual(state.hand, .left)
        XCTAssertTrue(state.presented)
        XCTAssertTrue(state.handle(try XCTUnwrap(URL(string: "pitchatlas://compare?a=cutter")), store: store))
        XCTAssertEqual(state.slugs, ["cutter"], "a link that names a pair still sets it")
    }

    /// Every link the router lands is counted, so the covers (the table, the
    /// bench) close and the Index lets go of a row-tapped page; a miss is not.
    func testEveryLandingIsCountedAndAMissIsNot() throws {
        let router = DeepLinkRouter()
        XCTAssertEqual(router.landings, 0)
        router.handle(try XCTUnwrap(URL(string: "pitchatlas://repertoire")), store: store)
        XCTAssertEqual(router.landings, 1)
        XCTAssertEqual(router.selection, .index)
        router.handle(try XCTUnwrap(URL(string: "pitchatlas://no-such-place")), store: store)
        XCTAssertEqual(router.landings, 1)
    }

    /// The "make room" choice shows over whatever is in front: the bench when it
    /// is open, the table when it is open, else the page.
    func testMakeRoomShowsOverWhateverIsInFront() {
        XCTAssertEqual(MakeRoomHost.host(pending: true, tableOpen: false, benchOpen: false), .root)
        XCTAssertEqual(MakeRoomHost.host(pending: true, tableOpen: false, benchOpen: true), .bench)
        XCTAssertEqual(MakeRoomHost.host(pending: true, tableOpen: true, benchOpen: false), .table)
        XCTAssertNil(MakeRoomHost.host(pending: false, tableOpen: false, benchOpen: true))
    }
}
