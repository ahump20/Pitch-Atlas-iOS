import XCTest
@testable import PitchAtlas

/// The plain pages carry the site's words (SupportPage.tsx, SourcesPage.tsx,
/// AboutPage.tsx). Where the app has to say something the site cannot, it names
/// its own controls, and these pin that wording to the controls themselves.
final class SupportCopyTests: XCTestCase {
    func testHelpRowsKeepTheSitesOrder() {
        XCTAssertEqual(SupportCopy.rows.map(\.label), [
            "Report a problem with a note or post",
            "Delete your account",
            "Question a claim in the archive",
        ])
    }

    /// The site's delete row speaks about the app from outside it. Inside the app
    /// it walks the real path: the Atlas toolbar's person icon, then the button.
    func testDeleteRouteNamesTheInAppPath() {
        let delete = SupportCopy.rows[1].text
        XCTAssertEqual(AtlasView.accountLabel, "Account and Safety")
        XCTAssertEqual(AccountView.deleteLabel, "Delete account")
        XCTAssertTrue(delete.contains("open Atlas, then \(AtlasView.accountLabel), and choose \(AccountView.deleteLabel)."), delete)
        XCTAssertTrue(delete.contains("That removes your community posts, your uploaded media, and the account itself."), delete)
    }

    func testContactLinksOpenThePolicyAndTheRegistry() {
        let contact = SupportCopy.contact
        XCTAssertEqual(String(contact.characters),
                       "Report issues through the in-product Report flow on any note or post. Every report is reviewed. For how the archive handles your data, read the privacy policy; for how archive claims are sourced, read the source registry.")
        let links = contact.runs.compactMap(\.link).map(\.absoluteString)
        XCTAssertEqual(links, ["https://pitch-atlas.com/privacy", "pitchatlas://sources"])
    }

    /// The support route opens inside the Atlas stack, beside About and Account.
    func testSupportHasItsOwnRoute() {
        let store = PitchStore()
        let url = URL(string: "pitchatlas://support")!
        XCTAssertEqual(DeepLinkRouter.destination(for: url, store: store),
                       DeepLinkDestination(tab: .atlas, stack: [.atlas(.support)]))
    }

    /// The legend runs strongest to weakest in the site's own order, and the
    /// line above it speaks of the atlas, not "the site".
    func testSourcesLegendReadsInTheSitesOrder() {
        XCTAssertEqual(SourcesCopy.legendOrder, [
            .officialData, .reputableAnalysis, .secondhandAttributed, .pitcherOwnWords,
            .coachObserved, .communityFirsthand, .unverified,
        ])
        XCTAssertTrue(SourcesCopy.howToRead.hasPrefix("Every claim in the atlas wears one of seven badges, strongest to weakest."))
        XCTAssertFalse(SourcesCopy.howToRead.contains("on the site"))
    }

    func testAboutKeepsTheSitesSections() {
        XCTAssertEqual(AboutCopy.layers, ["Baseball", "Pitching", "Pitch craft", "Grip", "Individual specimen"])
        XCTAssertEqual(AboutCopy.values.count, 6)
        XCTAssertEqual(AboutCopy.field.map(\.label), [
            "Measurement dashboards", "Smart balls and lab tools", "Coaching and pitch design", "Grip pages and clips",
        ])
        XCTAssertEqual(AboutCopy.truths.map(\.label), ["Known", "Unknown", "Open"])
        XCTAssertTrue(AboutCopy.field.allSatisfy { row in row.examples.allSatisfy { $0.url.hasPrefix("https://") } })
    }

    /// The retired one-liner stays out of every page the app shows.
    func testNoPageCarriesTheRetiredLine() {
        let pages = [SupportCopy.sub, SourcesCopy.lede, SourcesCopy.howToRead, SourcesCopy.rights, AboutCopy.sub, AccountView.heroSub]
            + SupportCopy.rows.map(\.text) + AboutCopy.origin + AboutCopy.why + AboutCopy.imperfection
        for text in pages {
            XCTAssertFalse(text.lowercased().contains("sourced, not corrected"), text)
        }
    }
}

/// The colophon is the registry, then what the teaching wings cite that the
/// registry lacks — one entry per URL — and its "as of" is the newest of all.
final class ColophonTests: XCTestCase {
    private let store = PitchStore()

    func testTheColophonOpensWithTheRegistryInItsFiledOrder() {
        let colophon = SourceRegistry.colophon(registry: store.sources, wings: store.knowledge)
        XCTAssertFalse(store.sources.isEmpty)
        XCTAssertEqual(Array(colophon.prefix(store.sources.count)).map(\.id), store.sources.map(\.id))
    }

    func testTheWingsAddOnlyWhatTheRegistryLacksByLabel() {
        let colophon = SourceRegistry.colophon(registry: store.sources, wings: store.knowledge)
        let tail = Array(colophon.dropFirst(store.sources.count))
        let filed = Set(store.sources.map(\.url))
        XCTAssertTrue(tail.allSatisfy { !filed.contains($0.url) })
        let english = Locale(identifier: "en_US")
        XCTAssertEqual(tail.map(\.label), tail.map(\.label).sorted { $0.compare($1, locale: english) == .orderedAscending })
        let cited = Set(SourceRegistry.knowledgeSources(store.knowledge).map(\.url))
        XCTAssertTrue(cited.isSubset(of: Set(colophon.map(\.url))))
    }

    func testTheWingsNeverRepeatAURL() {
        let wings = SourceRegistry.knowledgeSources(store.knowledge)
        XCTAssertEqual(Set(wings.map(\.url)).count, wings.count)
    }

    func testAsOfIsTheNewestRetrievedAcrossTheColophon() throws {
        let colophon = SourceRegistry.colophon(registry: store.sources, wings: store.knowledge)
        let latest = try XCTUnwrap(SourceRegistry.latestRetrievedAt(colophon))
        XCTAssertEqual(latest, colophon.map(\.retrievedAt).max())
        XCTAssertGreaterThanOrEqual(latest, try XCTUnwrap(SourceRegistry.latestRetrievedAt(store.sources)))
    }
}
