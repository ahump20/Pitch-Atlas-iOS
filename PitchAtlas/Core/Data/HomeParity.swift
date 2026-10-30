import Foundation

// =============================================================================
// HomeParity — the home's picks, computed the way the site computes them
// =============================================================================
// Small pure values the home (and the footer on every screen) reads, each one a
// port of a web function so the app shows the same specimens, the same quote,
// and the same record line as pitch-atlas.com. HomeParityTests pins them.
// =============================================================================

/// featuredPitchSet() (web src/data/featured.ts): one real filed specimen per
/// core family, in the same stable order everywhere.
enum FeaturedSet {
    static let families: [PitchFamily] = [.fastball, .breaking, .offspeed]

    static func entries(in store: PitchStore) -> [PitchAtlasEntry] {
        families.compactMap { family in store.pitches.first { $0.canonical.family == family } }
    }
}

/// useRotatingQuote (web src/hooks/useRotatingQuote.ts): each screen gets its own
/// line from a stable hash of its web path, advancing on a slow tick.
enum QuotePick {
    /// The tick interval the site uses; the tick holds still under Reduce Motion.
    static let interval: TimeInterval = 13

    /// hashPath with JavaScript's `(h * 31 + c) | 0` int32 wraparound, then abs.
    static func hash(path: String) -> Int {
        var h: Int32 = 0
        for unit in path.utf16 {
            h = h &* 31 &+ Int32(unit)
        }
        return abs(Int(h))
    }

    static func index(path: String, tick: Int, count: Int) -> Int? {
        guard count > 0 else { return nil }
        return (hash(path: path) + tick) % count
    }

    static func quote(forPath path: String, tick: Int, in store: PitchStore) -> AtlasQuote? {
        index(path: path, tick: tick, count: store.quotes.count).map { store.quotes[$0] }
    }

    /// RotatingQuote's figcaption: the attribution is the link to the source, and
    /// " · {context}" follows it as plain words when the quote has a context.
    static func credit(_ quote: AtlasQuote) -> (link: String, tail: String?) {
        (quote.attribution, quote.context.flatMap { $0.isEmpty ? nil : " · \($0)" })
    }
}

/// asOfDate() (web src/lib/format.ts): "October 24, 2026", parsed by parts so no
/// timezone can shift the day. Anything that isn't a plain ISO date is returned
/// as written, never turned into a wrong date.
enum AsOf {
    private static let months = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December",
    ]

    static func format(_ iso: String) -> String {
        let parts = iso.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              parts.allSatisfy({ $0.allSatisfy { $0.isASCII && $0.isWholeNumber } }),
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]),
              (1...12).contains(month) else { return iso }
        return "\(months[month - 1]) \(day), \(year)"
    }
}

/// The citation registry's record line (web CloseCta): every source, dated from
/// the newest retrieval.
enum SourceRegistry {
    static func latestRetrievedAt(_ sources: [Source]) -> String? {
        sources.map(\.retrievedAt).max()
    }

    static func recordLine(_ sources: [Source]) -> String {
        guard let latest = latestRetrievedAt(sources) else {
            return "Follow the archive back to its records: no sources ship in this build."
        }
        return "Follow the archive back to its records: \(sources.count) sources in the citation registry, retrieved through \(AsOf.format(latest))."
    }
}

/// externalContentFor({ placement: 'home' }) and ExternalMediaCard's words (web
/// src/data/media/external.ts, components/media/ExternalMediaCard.tsx).
enum MediaShelf {
    /// Where a shelf stands (web ExternalContentQuery.placement).
    enum Placement { case home, repertoire, grips }

    /// web externalContentFor: published and not pulled down, then the shelf's
    /// rule — a placement's own, else any post tagged to the pitch, the craftsman,
    /// the family or one of the topics. Newest first, ties in filed order.
    static func query(_ items: [ExternalContentItem], placement: Placement? = nil, pitchSlug: String? = nil,
                      craftsmanSlug: String? = nil, family: RepertoireFamily? = nil, topics: [String] = [],
                      limit: Int? = nil) -> [ExternalContentItem] {
        let wanted = Set(topics)
        let matches = items.enumerated().filter { _, item in
            guard item.isShowable else { return false }
            switch placement {
            case .home: return item.featured == true
            case .repertoire: return item.featured == true || !item.tags.families.isEmpty
            case .grips: return item.tags.topics.contains("grip")
            case nil: break
            }
            if let pitchSlug, item.tags.pitchSlugs.contains(pitchSlug) { return true }
            if let craftsmanSlug, item.tags.craftsmanSlugs.contains(craftsmanSlug) { return true }
            if let family, item.tags.families.contains(family.rawValue) { return true }
            if !wanted.isEmpty, item.tags.topics.contains(where: wanted.contains) { return true }
            return false
        }
        let sorted = matches.sorted { a, b in
            a.element.publishedAt == b.element.publishedAt ? a.offset < b.offset : a.element.publishedAt > b.element.publishedAt
        }.map(\.element)
        return limit.map { Array(sorted.prefix(max(0, $0))) } ?? sorted
    }

    /// The home's shelf: featured posts only.
    static func home(_ items: [ExternalContentItem], limit: Int) -> [ExternalContentItem] {
        query(items, placement: .home, limit: limit)
    }

    static func laneLabel(_ trustLane: String) -> String {
        switch trustLane {
        case "trusted-mind": "Trusted mind"
        case "heritage": "Heritage file"
        default: "Community find"
        }
    }

    static func platformLabel(_ platform: String) -> String {
        switch platform {
        case "x": "X"
        case "youtube": "YouTube"
        case "instagram": "Instagram"
        default: "TikTok"
        }
    }

    /// "JUN 2026": the site's short month and year, in its upper-case stamp.
    static func monthYear(_ iso: String) -> String {
        let months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
        let parts = iso.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2,
              parts.allSatisfy({ $0.allSatisfy { $0.isASCII && $0.isWholeNumber } }),
              let month = Int(parts[1]), (1...12).contains(month) else { return iso }
        return "\(months[month - 1]) \(parts[0])"
    }

    /// The official TikTok player, never autoplaying. X, YouTube and Instagram
    /// posts stay credited outbound links in the app; a pulled post has no player.
    static func playerURL(_ item: ExternalContentItem) -> URL? {
        guard item.platform == "tiktok", item.embedMode == "official-embed", item.availability != "removed" else { return nil }
        return URL(string: "https://www.tiktok.com/player/v1/\(item.externalId)?rel=0&description=0&music_info=0&autoplay=0")
    }
}

/// The home's numbered chapters (web ChapterMark `n`/`name`/`delivery`). Each mark
/// holds a frame of Muybridge's plate 273 and, the first time it is seen, steps the
/// pitcher to its own phase: set, break, cock, release, finish.
enum HomeChapter: CaseIterable {
    case specimen, seam, filedSet, doors, record

    var number: String {
        switch self {
        case .specimen: "01"
        case .seam: "02"
        case .filedSet: "03"
        case .doors: "04"
        case .record: "05"
        }
    }

    var name: String {
        switch self {
        case .specimen: "The Specimen"
        case .seam: "Inside the cover"
        case .filedSet: "The Filed Set"
        case .doors: "The Other Doors"
        case .record: "The Record"
        }
    }

    var delivery: ClosedRange<Int> {
        switch self {
        case .specimen: 1...1
        case .seam: 1...3
        case .filedSet: 3...5
        case .doors: 5...7
        case .record: 7...10
        }
    }
}
