import Foundation

// =============================================================================
// CraftsmenReads — the hall and a file, read off the record
// =============================================================================
// Web: pages/CraftsmenHall.tsx, components/craftsmen/CraftsmanMedia.tsx and
// pages/CraftsmanChapter.tsx. Whatever those pages print from the data (the
// chronology's bookends, the film shelf's picks, a file's kicker, its rooms and
// its neighbors) is worked out here, never typed into a view.
// =============================================================================

enum CraftsmenHallReads {
    /// featuredCraftsmanMedia's order.
    static let featuredSlugs = ["nolan-ryan", "mariano-rivera", "paul-skenes"]

    /// The note under "C The masters", its bookends read off the data. Nil when
    /// they can't be read, as the site then prints nothing.
    static func mastersNote(_ masters: [Craftsman]) -> String? {
        guard let first = masters.first, let firstYear = EraSpan.parse(first.era)?.start,
              let last = masters.last else { return nil }
        return "\(masters.count) arms, filed in the order their eras began: \(firstYear) to \(last.name). Each card's band is the career laid against the same century; the longer the bar, the longer the arm lasted."
    }

    /// The film shelf: the first clip filed for each featured arm.
    static func featuredFilm(_ items: [CraftsmanMediaItem]) -> [CraftsmanMediaItem] {
        featuredSlugs.compactMap { slug in items.first { $0.craftsmanSlug == slug } }
    }

    /// MediaFrame's provider line.
    static func frameLabel(_ item: CraftsmanMediaItem) -> String {
        item.kind == "tiktok" ? "TikTok embed" : "X embed"
    }
}

enum CraftsmanFileReads {
    /// The stage kicker, set upper case by the view: "Master · 1986-2008 · right-handed".
    static func kicker(_ c: Craftsman) -> String {
        var line = "\(c.kind == .legend ? "Legend" : "Master") · \(c.era)"
        if let hand = c.hand { line += " · \(hand.rawValue)-handed" }
        return line
    }

    /// "In this craftsman file": the arm, the signature pitch, the record when filed.
    static func chapters(_ c: Craftsman) -> [ArchiveChapter] {
        var result = [ArchiveChapter(id: "story", title: "The arm"), ArchiveChapter(id: "signature", title: "Signature pitch")]
        if !c.recordProse.isEmpty { result.append(ArchiveChapter(id: "record", title: "The record")) }
        return result
    }

    /// The room after the signature: the mental edge, else the pitcher's own words.
    static func secondRoom(_ c: Craftsman) -> String? {
        if c.mentalEdge != nil { return "The mental edge" }
        return c.quote != nil ? "In their words" : nil
    }

    /// The record's index: the legend's myth-and-physics room takes 03.
    static func recordIndex(_ c: Craftsman) -> String { c.kind == .legend ? "04" : "03" }

    /// Chapter to chapter in the hall's chronology, so "next" is the next era.
    static func neighbors(of c: Craftsman, in order: [Craftsman]) -> (prev: Craftsman?, next: Craftsman?) {
        guard let i = order.firstIndex(where: { $0.slug == c.slug }) else { return (nil, nil) }
        return (i > 0 ? order[i - 1] : nil, i + 1 < order.count ? order[i + 1] : nil)
    }

    static func studyLink(_ pitch: PitchAtlasEntry) -> String { "Study the \(pitch.canonical.name.lowercased())" }
    static func inspectLink(_ pitch: PitchAtlasEntry) -> String { "Inspect the \(pitch.display.shortName.lowercased()) grip" }
    static func mediaTitle(_ c: Craftsman) -> String { "\(c.name), still teaching." }
}
