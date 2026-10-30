import XCTest
@testable import PitchAtlas

/// The site's phone menu (layout/Masthead.tsx NAV, MORE_CONTENT, TOOLS; web 47e21e6) as
/// the Atlas tab's ☰ sheet. Pitch Index and Grips are tabs here, one tap already;
/// Softball joins with the softball wing (D5).
final class AtlasMenuTests: XCTestCase {
    private let store = PitchStore()

    func testTheMenuIsTheSitesInTheSitesOrder() {
        XCTAssertEqual(AtlasMenu.groups.map(\.title), [nil, "The rest of the atlas", "Tools"])
        XCTAssertEqual(AtlasMenu.groups.map { $0.items.map(\.label) }, [
            ["Softball", "Learn"],
            ["Craftsmen", "Lost Pitches", "Sources", "About"],
            ["Shape Lab", "Shape map", "Compare two pitches", "Compare two grips"],
        ])
    }

    /// Every item leads somewhere: a page the router opens, or the compare table.
    func testEveryItemLandsOnAPlace() throws {
        for item in AtlasMenu.groups.flatMap(\.items) {
            let url = try XCTUnwrap(URL(string: "pitchatlas://\(item.route)"))
            if url.host == "compare" {
                XCTAssertTrue(CompareSelection().handle(url, store: store), item.label)
            } else {
                XCTAssertNotNil(DeepLinkRouter.destination(for: url, store: store), item.label)
            }
        }
        XCTAssertEqual(AtlasMenu.groups.last?.items.first?.route, "sandbox")
    }
}
