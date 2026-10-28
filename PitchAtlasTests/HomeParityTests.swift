import XCTest
@testable import PitchAtlas

/// The home picks the same specimens, quote, and record line the site does.
final class HomeParityTests: XCTestCase {
    private let store = PitchStore()

    /// featuredPitchSet(): the first filed pitch of each core family, in that order.
    func testFeaturedSetIsOneSpecimenPerCoreFamilyInWebOrder() {
        XCTAssertEqual(FeaturedSet.entries(in: store).map(\.slug), ["four-seam", "twelve-six", "circle-change"])
    }

    /// useRotatingQuote: hashPath with JS int32 math, plus the 13-second tick.
    func testQuotePickMatchesTheWebHash() {
        XCTAssertEqual(QuotePick.index(path: "/", tick: 0, count: 19), 9)
        XCTAssertEqual(QuotePick.index(path: "/repertoire", tick: 0, count: 19), 11)
        XCTAssertEqual(QuotePick.index(path: "/pitch/four-seam", tick: 0, count: 19), 17)
        XCTAssertEqual(QuotePick.index(path: "/sources", tick: 2, count: 19), 6)
        XCTAssertEqual(QuotePick.index(path: "/", tick: 0, count: 0), nil)
        XCTAssertEqual(QuotePick.quote(forPath: "/", tick: 0, in: store)?.id, "q-craftsman-greg-maddux")
    }

    /// asOfDate(): "October 24, 2026"; anything that isn't a plain ISO date stays as written.
    func testAsOfFormatsLikeTheWeb() {
        XCTAssertEqual(AsOf.format("2026-10-24"), "October 24, 2026")
        XCTAssertEqual(AsOf.format("2026-01-05"), "January 5, 2026")
        XCTAssertEqual(AsOf.format("2026-13-01"), "2026-13-01")
        XCTAssertEqual(AsOf.format("not a date"), "not a date")
    }

    /// CloseCta: the registry line counts every source and dates from the newest retrieval.
    func testRegistryLineComputesFromTheSources() {
        XCTAssertEqual(SourceRegistry.latestRetrievedAt(store.sources), store.sources.map(\.retrievedAt).max())
        XCTAssertEqual(SourceRegistry.latestRetrievedAt([]), nil)
        let line = SourceRegistry.recordLine(store.sources)
        XCTAssertTrue(line.hasPrefix("Follow the archive back to its records: \(store.sources.count) sources in the citation registry, retrieved through "))
        XCTAssertFalse(line.contains("0000"))
    }

    /// ChapterMark delivery pairs from the home sections: set, break, cock, release, finish.
    func testChapterMarksStepThroughTheDelivery() {
        XCTAssertEqual(HomeChapter.allCases.map(\.delivery), [1...1, 1...3, 3...5, 5...7, 7...10])
        XCTAssertEqual(HomeChapter.allCases.map(\.number), ["01", "02", "03", "04", "05"])
        XCTAssertEqual(HomeChapter.allCases.map(\.name), ["The Specimen", "Inside the cover", "The Filed Set", "The Other Doors", "The Record"])
        XCTAssertEqual(store.plate273?.frames.count, 10, "every delivery frame the marks step through ships")
    }

    /// externalContentFor({ placement: 'home', limit: 3 }): featured, published,
    /// not pulled down, newest first, ties kept in filed order.
    func testHomeShelfKeepsFeaturedPublishedPostsNewestFirst() {
        let items = [
            post("old", published: "2018-11-02"),
            post("a", published: "2026-06-10"),
            post("b", published: "2026-06-10"),
            post("unfeatured", published: "2026-07-01", featured: false),
            post("unflagged", published: "2026-07-01", featured: nil),
            post("held", published: "2026-07-02", state: "pending"),
            post("gone", published: "2026-07-03", availability: "removed"),
            post("newest", published: "2026-06-20"),
        ]
        XCTAssertEqual(MediaShelf.home(items, limit: 3).map(\.id), ["newest", "a", "b"])
        XCTAssertEqual(MediaShelf.home(items, limit: 10).map(\.id), ["newest", "a", "b", "old"])
        XCTAssertEqual(MediaShelf.home([], limit: 3).count, 0)
    }

    /// ExternalMediaCard: the lane and provider words, the month stamp, and the
    /// official TikTok player (X stays an outbound link in the app).
    func testMediaCardWordsMatchTheSite() {
        XCTAssertEqual(MediaShelf.laneLabel("trusted-mind"), "Trusted mind")
        XCTAssertEqual(MediaShelf.laneLabel("heritage"), "Heritage file")
        XCTAssertEqual(MediaShelf.laneLabel("community"), "Community find")
        XCTAssertEqual(MediaShelf.platformLabel("x"), "X")
        XCTAssertEqual(MediaShelf.platformLabel("youtube"), "YouTube")
        XCTAssertEqual(MediaShelf.platformLabel("instagram"), "Instagram")
        XCTAssertEqual(MediaShelf.platformLabel("tiktok"), "TikTok")
        XCTAssertEqual(MediaShelf.monthYear("2026-06-10"), "JUN 2026")
        XCTAssertEqual(MediaShelf.monthYear("2018-11-02"), "NOV 2018")
        XCTAssertEqual(MediaShelf.monthYear("soon"), "soon")
        XCTAssertEqual(MediaShelf.playerURL(post("a", published: "2026-06-10"))?.absoluteString,
                       "https://www.tiktok.com/player/v1/7a?rel=0&description=0&music_info=0&autoplay=0")
        XCTAssertNil(MediaShelf.playerURL(post("x1", published: "2026-06-10", platform: "x")))
        XCTAssertNil(MediaShelf.playerURL(post("gone", published: "2026-06-10", availability: "removed")))
    }

    private func post(_ id: String, published: String, featured: Bool? = true, state: String = "published",
                      availability: String = "available", platform: String = "tiktok") -> ExternalContentItem {
        ExternalContentItem(id: id, platform: platform, externalId: "7\(id)", canonicalUrl: "https://www.tiktok.com/@a/video/7\(id)",
                            sourceId: "s", sourceName: "Source", sourceHandle: "@source", sourceUrl: "https://www.tiktok.com/@a",
                            title: id, lede: "", sourceCaption: nil, publishedAt: published, retrievedAt: "2026-10-01",
                            tags: ExternalContentTags(pitchSlugs: [], craftsmanSlugs: [], families: [], topics: []),
                            trustLane: "heritage", moderationState: state, availability: availability,
                            embedMode: "official-embed", featured: featured)
    }
}
