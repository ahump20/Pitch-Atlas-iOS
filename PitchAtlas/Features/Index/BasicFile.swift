import Foundation

// =============================================================================
// BasicFile — what a basic file reads around itself
// =============================================================================
// Web: pages/RepertoireChapter.tsx and data/repertoire/index.ts. The run of
// unfiled pitches a basic file pages through (BASIC_REPERTOIRE), the family it
// sits in (repertoireByFamily), and the words and accent its header takes
// (FAMILY_EYEBROW, FAMILY_ACCENT, SEAM_STATUSES). A filed pitch opens its full
// specimen instead, so it has no place in the run.
// =============================================================================

enum BasicFile {
    /// BASIC_REPERTOIRE: every pitch without a filed specimen, in catalog order.
    static func basics(in entries: [RepertoireEntry]) -> [RepertoireEntry] {
        entries.filter { $0.filedSlug == nil }
    }

    /// The basic files on either side of this one.
    static func neighbors(of entry: RepertoireEntry, in entries: [RepertoireEntry])
        -> (previous: RepertoireEntry?, next: RepertoireEntry?) {
        guard entry.filedSlug == nil else { return (nil, nil) }
        let run = basics(in: entries)
        guard let index = run.firstIndex(where: { $0.id == entry.id }) else { return (nil, nil) }
        return (index > 0 ? run[index - 1] : nil, index + 1 < run.count ? run[index + 1] : nil)
    }

    /// The family rail: every other pitch in the family, filed or not, in catalog order.
    static func siblings(of entry: RepertoireEntry, in entries: [RepertoireEntry]) -> [RepertoireEntry] {
        entries.filter { $0.family == entry.family && $0.id != entry.id }
    }

    /// SEAM_STATUSES: the honest edge cases (banned, alias, illusion, not a pitch).
    static func isEdge(_ status: RepertoireStatus) -> Bool {
        WebTokens.Status.edge.contains(status.rawValue)
    }

    /// FAMILY_ACCENT, with an edge status taking the banned seam.
    static func accentRGB(_ entry: RepertoireEntry) -> UInt32 {
        PitchAccents.familyRGB(isEdge(entry.status) ? .banned : entry.family)
    }

    /// FAMILY_EYEBROW: the family as the header's kicker names it.
    static func eyebrow(_ family: RepertoireFamily) -> String {
        switch family {
        case .fastball: "Fastball"
        case .breaking: "Breaking ball"
        case .offspeed: "Offspeed"
        case .specialty: "Specialty"
        case .banned: "Banned & doctored"
        }
    }

    static func railHeading(_ family: RepertoireFamily) -> String {
        "Others in the \(eyebrow(family).lowercased())"
    }

    /// The header's sub: the other names, after "aka", on a middle dot.
    static func akaLine(_ entry: RepertoireEntry) -> String? {
        guard let aka = entry.aka, !aka.isEmpty else { return nil }
        return "aka " + aka.joined(separator: " · ")
    }
}
