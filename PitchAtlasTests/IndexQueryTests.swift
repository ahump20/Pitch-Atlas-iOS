import XCTest
@testable import PitchAtlas

/// The Pitch Index reads a search, a facet and a sort the way PitchIndex.tsx does.
/// Every expected count is read from the bundle, never typed in.
final class IndexQueryTests: XCTestCase {
    private let store = PitchStore()

    private func total(_ query: IndexQuery) -> Int {
        query.groups(in: store).reduce(0) { $0 + $1.entries.count }
    }

    func testTheDefaultShowsEveryEntryByFamilyInTheBundlesOrder() {
        let groups = IndexQuery().groups(in: store)
        XCTAssertEqual(groups.map(\.info.family), store.repertoire.families.map(\.family))
        XCTAssertEqual(total(IndexQuery()), store.repertoire.entries.count)
        XCTAssertEqual(IndexQuery().countLabel(total: store.repertoire.entries.count),
                       "\(store.repertoire.entries.count) pitches")
    }

    func testSearchReadsTheNameEveryAliasAndTheFamily() throws {
        // the family key: every breaking ball answers "breaking"
        let breaking = store.repertoire.entries.filter { $0.family == .breaking }
        XCTAssertEqual(total(IndexQuery(text: "breaking")), breaking.count)
        // an alias only
        let aliased = try XCTUnwrap(store.repertoire.entries.first { !($0.aka ?? []).isEmpty })
        let alias = try XCTUnwrap(aliased.aka?.first)
        let found = IndexQuery(text: "  \(alias.uppercased())  ").groups(in: store).flatMap(\.entries)
        XCTAssertTrue(found.contains(aliased), "\(alias) should find \(aliased.name)")
        XCTAssertEqual(total(IndexQuery(text: "no such pitch anywhere")), 0)
    }

    func testFiledSpecimensKeepsOnlyTheFiledRowsAcrossFamilies() {
        let filed = store.repertoire.entries.filter { $0.filedSlug != nil }
        let query = IndexQuery(family: .filed)
        XCTAssertEqual(total(query), filed.count)
        XCTAssertTrue(query.groups(in: store).allSatisfy { $0.entries.allSatisfy { $0.filedSlug != nil } })
        XCTAssertEqual(query.countLabel(total: filed.count), "\(filed.count) pitches · filed specimens")
    }

    func testAFamilyFacetAndASearchNameEachOtherInTheCount() {
        let query = IndexQuery(text: "slider", family: .family(.breaking))
        let n = total(query)
        XCTAssertGreaterThan(n, 0)
        XCTAssertTrue(query.groups(in: store).allSatisfy { $0.info.family == .breaking })
        XCTAssertEqual(query.countLabel(total: n), "\(n) \(n == 1 ? "pitch" : "pitches") · breaking · matching \"slider\"")
        XCTAssertEqual(IndexQuery().countLabel(total: 1), "1 pitch")
    }

    func testTheFacetOrderAndLabelsAreTheSites() {
        XCTAssertEqual(IndexFamilyFilter.ordered.map(\.label),
                       ["All", "Fastball", "Offspeed", "Breaking", "Specialty", "Banned", "Filed specimens"])
        XCTAssertEqual(IndexSort.allCases.map(\.label), ["Family", "A-Z", "Documentation", "Filed first"])
    }

    func testThePillCountsTheFacetsAndResetAppearsForAnyChange() {
        XCTAssertEqual(IndexQuery().advancedCount, 0)
        XCTAssertFalse(IndexQuery().hasActiveState)
        XCTAssertEqual(IndexQuery(family: .filed, status: .niche, sort: .az).advancedCount, 3)
        XCTAssertTrue(IndexQuery(layout: .binder).hasActiveState, "the binder view alone shows Reset")
        XCTAssertEqual(IndexQuery(layout: .binder).advancedCount, 0, "the view is not a filter")
        XCTAssertTrue(IndexQuery(text: "fosh").hasActiveState)
        XCTAssertFalse(IndexQuery(text: "   ").hasActiveState)
    }

    func testTheEmptyStateNamesTheLeverToPull() {
        let n = store.repertoire.entries.count
        let search = IndexQuery(text: "zzz")
        XCTAssertEqual(search.emptyTitle, "No pitch by that name")
        XCTAssertEqual(search.emptyDescription(indexed: n),
                       "\"zzz\" is not in the \(n) indexed entries. Try a family or an alias. The index only shows what the atlas has actually filed.")
        let filtered = IndexQuery(text: "zzz", family: .family(.banned))
        XCTAssertEqual(filtered.emptyDescription(indexed: n),
                       "\"zzz\" is not in the \(n) indexed entries. Try a family or an alias, or clear the active filters. The index only shows what the atlas has actually filed.")
        let facet = IndexQuery(status: .notAPitch)
        XCTAssertEqual(facet.emptyTitle, "Nothing under this filter")
        XCTAssertEqual(facet.emptyDescription(indexed: n), "No entry matches the active filters. Reset to see all \(n) entries.")
    }

    func testTheShelfLabelIsCountedFromTheBundle() {
        XCTAssertEqual(IndexScope.shelfLabel(store),
                       "\(store.repertoire.entries.count) pitches across \(store.repertoire.families.count) families")
    }

    func testTheRepertoireShelfTakesFeaturedOrFamilyTaggedPostsNewestFirst() {
        let items = store.externalMedia.items
        let shelf = MediaShelf.query(items, placement: .repertoire, limit: 2)
        XCTAssertLessThanOrEqual(shelf.count, 2)
        XCTAssertTrue(shelf.allSatisfy { $0.isShowable && ($0.featured == true || !$0.tags.families.isEmpty) })
        XCTAssertEqual(shelf.map(\.publishedAt), shelf.map(\.publishedAt).sorted(by: >))
        // a pitch's own shelf holds only posts tagged to it
        let slider = MediaShelf.query(items, pitchSlug: "slider")
        XCTAssertTrue(slider.allSatisfy { $0.tags.pitchSlugs.contains("slider") })
        XCTAssertEqual(MediaShelf.home(items, limit: 3), MediaShelf.query(items, placement: .home, limit: 3))
    }
}
