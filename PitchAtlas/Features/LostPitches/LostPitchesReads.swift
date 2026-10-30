import Foundation

// =============================================================================
// LostPitchesReads — the archive and a file, read off the record
// =============================================================================
// Web: pages/LostPitchesHall.tsx, components/lost-pitches/EraTimeline.tsx,
// components/lost-pitches/ArchiveImageRail.tsx and pages/LostPitchChapter.tsx.
// Whatever those pages work out from the data (where a plate sits in time, how
// the lanes stack, the image record's counts, a file's rooms and its neighbors)
// is worked out here, never typed into a view.
// =============================================================================

/// EraTimeline: every plate laid on a fixed 1898–1960 axis by the year its era
/// began, a lane per documentation tier.
enum LostTimeline {
    static let axis = (start: 1898.0, end: 1960.0)
    static let decades = [1900, 1910, 1920, 1930, 1940, 1950]
    /// The least room, as a share of the lane, between two markers on one row.
    static let gap = 0.18

    struct Placed: Identifiable {
        let pitch: LostPitch
        let year: Int
        /// 0…1 along the axis.
        let left: Double
        let row: Int
        var id: String { pitch.slug }
    }

    /// Fractional position 0…1 of a year along the axis, clamped at both ends.
    static func position(_ year: Double) -> Double {
        min(1, max(0, (year - axis.start) / (axis.end - axis.start)))
    }

    /// Greedy row packing: sorted by year (file order breaking a tie), each marker
    /// drops into the first row whose last marker sits at least `gap` to its left.
    /// An era with no year is left off, as the site leaves it.
    static func pack(_ pitches: [LostPitch]) -> (placed: [Placed], rows: Int) {
        var dated: [(offset: Int, pitch: LostPitch, year: Int)] = []
        for (offset, pitch) in pitches.enumerated() {
            if let year = EraSpan.parse(pitch.era)?.start { dated.append((offset, pitch, year)) }
        }
        dated.sort { (a, b) -> Bool in a.year == b.year ? a.offset < b.offset : a.year < b.year }
        var rowRight: [Double] = []
        var placed: [Placed] = []
        for entry in dated {
            let left = position(Double(entry.year))
            let row: Int
            if let open = rowRight.firstIndex(where: { left >= $0 + gap }) {
                row = open
                rowRight[open] = left
            } else {
                row = rowRight.count
                rowRight.append(left)
            }
            placed.append(Placed(pitch: entry.pitch, year: entry.year, left: left, row: row))
        }
        return (placed, max(1, rowRight.count))
    }
}

enum LostArchiveReads {
    /// The rail prints a plate's rights as its raw value ("public-domain").
    static func rightsLine(_ image: ArchiveImage) -> String { image.rights.rawValue }

    /// The way from a plate to the file it belongs to.
    static func openLine(_ image: ArchiveImage) -> String { "Open \(image.relatedLabel)" }

    /// The plate's kind as the rail prints it: its first dash a space
    /// (`plateKind.replace('-', ' ')`), so "original-study" reads "original study".
    static func kindLine(_ image: ArchiveImage) -> String {
        let raw = image.plateKind.rawValue
        guard let dash = raw.firstIndex(of: "-") else { return raw }
        return raw.replacingCharacters(in: dash...dash, with: " ")
    }

    /// The stats box: plates filed, how many are public domain, how many original.
    static func stats(_ images: [ArchiveImage]) -> (filed: Int, publicDomain: Int, original: Int) {
        (images.count, images.filter { $0.rights == .publicDomain }.count, images.filter { $0.rights == .original }.count)
    }

    struct TierGroup: Identifiable {
        let info: LostPitchTierInfo
        let entries: [LostPitch]
        var id: DocumentationTier { info.tier }
    }

    /// LOST_PITCH_TIERS in order, each with its entries in file order; a tier
    /// with nothing filed under it is left out, as the site returns null for it.
    static func tierGroups(_ root: LostPitchesRoot) -> [TierGroup] {
        root.tiers.compactMap { info in
            let entries = root.entries.filter { $0.tier == info.tier }
            return entries.isEmpty ? nil : TierGroup(info: info, entries: entries)
        }
    }
}

enum LostPitchFileReads {
    /// "In this archive file": the pitch, what it was, why it is lost, and the
    /// surviving record only when one is filed.
    static func chapters(_ p: LostPitch) -> [ArchiveChapter] {
        var result = [ArchiveChapter(id: "story", title: "The pitch"),
                      ArchiveChapter(id: "account", title: "What it was"),
                      ArchiveChapter(id: "absence", title: "Why it is lost")]
        if !p.recordEntries.isEmpty { result.append(ArchiveChapter(id: "record", title: "Surviving record")) }
        return result
    }

    /// Chapter to chapter in the archive's file order.
    static func neighbors(of p: LostPitch, in order: [LostPitch]) -> (prev: LostPitch?, next: LostPitch?) {
        guard let i = order.firstIndex(where: { $0.slug == p.slug }) else { return (nil, nil) }
        return (i > 0 ? order[i - 1] : nil, i + 1 < order.count ? order[i + 1] : nil)
    }

    struct FollowOn {
        let eyebrow: String
        let title: String
        let body: String
        let link: String
        let path: String

        /// The basic file the path names, when it names one ("repertoire/<id>").
        var repertoireId: String? {
            let parts = path.split(separator: "/")
            guard parts.count == 2, parts[0] == "repertoire" else { return nil }
            return String(parts[1])
        }
    }

    /// Only the fadeaway follows its name into a pitch. Verbatim, LostPitchChapter.tsx.
    static func followOn(_ p: LostPitch) -> FollowOn? {
        guard p.slug == "rube-foster-fadeaway" else { return nil }
        return FollowOn(eyebrow: "Follow the name into the pitch",
                        title: "From the fadeaway to the screwball file.",
                        body: "The surviving account above identifies Foster\u{2019}s fadeaway as a screwball. The screwball file follows that pitch\u{2019}s grip and direction, with its own sources. It does not reconstruct Foster\u{2019}s undocumented hold.",
                        link: "Open the screwball file",
                        path: "repertoire/screwball")
    }

    /// The file's discussion thread, in the web's own key.
    static func topic(_ p: LostPitch) -> CommunityTopic { .lost(slug: p.slug) }
}
