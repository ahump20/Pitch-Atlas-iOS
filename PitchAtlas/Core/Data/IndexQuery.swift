import Foundation

// =============================================================================
// IndexQuery — what the Pitch Index shows for a search, a filter and a sort
// =============================================================================
// Web: components/sections/PitchIndex.tsx and lib/index-scope.ts. The index stays
// grouped by family; search reads the name, every alias and the family; the
// family facet adds the site's "Filed specimens"; the count line and the empty
// state say which lever to pull. Every number is counted from the bundle.
// =============================================================================

/// The family facet: all, one family, or only the pitches with a filed specimen.
enum IndexFamilyFilter: Hashable {
    case all
    case family(RepertoireFamily)
    case filed

    /// The site's FILTERS, in its order.
    static let ordered: [IndexFamilyFilter] = [
        .all, .family(.fastball), .family(.offspeed), .family(.breaking), .family(.specialty), .family(.banned), .filed,
    ]

    var label: String {
        switch self {
        case .all: "All"
        case .filed: "Filed specimens"
        case .family(let family):
            switch family {
            case .fastball: "Fastball"
            case .offspeed: "Offspeed"
            case .breaking: "Breaking"
            case .specialty: "Specialty"
            case .banned: "Banned"
            }
        }
    }
}

/// Rows or the binder spread.
enum IndexLayout: String, CaseIterable {
    case rows, binder
}

/// One family's rows under its header.
struct IndexGroup {
    let info: RepertoireFamilyInfo
    let entries: [RepertoireEntry]
}

struct IndexQuery: Equatable {
    var text = ""
    var family: IndexFamilyFilter = .all
    var status: RepertoireStatus? = nil
    var sort: IndexSort = .family
    var layout: IndexLayout = .rows

    var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// The family, sort and status facets that differ from the default — the pill's count.
    var advancedCount: Int {
        (family == .all ? 0 : 1) + (sort == .family ? 0 : 1) + (status == nil ? 0 : 1)
    }

    /// Anything the reader has changed, the view included: when Reset shows.
    var hasActiveState: Bool {
        !trimmed.isEmpty || family != .all || layout != .rows || sort != .family || status != nil
    }

    /// Name, every alias and the family key, case-insensitive.
    func matches(_ entry: RepertoireEntry) -> Bool {
        let q = trimmed.lowercased()
        guard !q.isEmpty else { return true }
        return ([entry.name] + (entry.aka ?? []) + [entry.family.rawValue])
            .joined(separator: " ").lowercased().contains(q)
    }

    /// The families in the bundle's order, each with the rows that pass every
    /// facet, sorted within the family. A family with no rows drops out.
    func groups(in store: PitchStore) -> [IndexGroup] {
        store.repertoire.families.compactMap { info in
            var entries = store.repertoire.entries.filter { $0.family == info.family }
            switch family {
            case .all: break
            case .filed: entries = entries.filter { $0.filedSlug != nil }
            case .family(let only): if only != info.family { entries = [] }
            }
            if let status { entries = entries.filter { $0.status == status } }
            entries = entries.filter(matches)
            let rows = sort.ordered(entries, store: store)
            return rows.isEmpty ? nil : IndexGroup(info: info, entries: rows)
        }
    }

    /// "42 pitches", "13 pitches · filed specimens", "3 pitches · breaking · matching "slider"".
    func countLabel(total: Int) -> String {
        var label = "\(total) \(total == 1 ? "pitch" : "pitches")"
        switch family {
        case .all: break
        case .filed: label += " · filed specimens"
        case .family(let only): label += " · \(only.rawValue)"
        }
        if !trimmed.isEmpty { label += " · matching \"\(trimmed)\"" }
        return label
    }

    var emptyTitle: String {
        trimmed.isEmpty ? "Nothing under this filter" : "No pitch by that name"
    }

    /// The empty state's line: which lever to pull, out of `indexed` entries.
    func emptyDescription(indexed: Int) -> String {
        if trimmed.isEmpty {
            return "No entry matches the active filters. Reset to see all \(indexed) entries."
        }
        let clear = family == .all && status == nil ? "" : ", or clear the active filters"
        return "\"\(trimmed)\" is not in the \(indexed) indexed entries. Try a family or an alias\(clear). The index only shows what the atlas has actually filed."
    }
}

/// lib/index-scope.ts: the shelf the reader sees, counted from the bundle.
enum IndexScope {
    /// "42 pitches across 5 families"
    static func shelfLabel(_ store: PitchStore) -> String {
        "\(store.repertoire.entries.count) pitches across \(store.repertoire.families.count) families"
    }
}

enum IndexSort: String, CaseIterable, Identifiable {
    case family, az, documentation, filed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .family: return "Family"
        case .az: return "A-Z"
        case .documentation: return "Documentation"
        case .filed: return "Filed first"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .family: return "Sort by family order"
        case .az: return "Sort A to Z by name"
        case .documentation: return "Sort by documentation depth"
        case .filed: return "Sort filed specimens first"
        }
    }

    func ordered(_ entries: [RepertoireEntry], store: PitchStore) -> [RepertoireEntry] {
        switch self {
        case .family:
            return entries
        case .az:
            return entries.enumerated().sorted { lhs, rhs in
                let names = lhs.element.name.localizedStandardCompare(rhs.element.name)
                return names == .orderedSame ? lhs.offset < rhs.offset : names == .orderedAscending
            }.map(\.element)
        case .documentation:
            return entries.enumerated().sorted { lhs, rhs in
                let left = documentationRank(lhs.element, store: store)
                let right = documentationRank(rhs.element, store: store)
                return left == right ? lhs.offset < rhs.offset : left < right
            }.map(\.element)
        case .filed:
            return entries.enumerated().sorted { lhs, rhs in
                let left = lhs.element.filedSlug == nil ? 1 : 0
                let right = rhs.element.filedSlug == nil ? 1 : 0
                return left == right ? lhs.offset < rhs.offset : left < right
            }.map(\.element)
        }
    }

    // Documentation depth read straight off the baked specimen grade — the same
    // authoritative value the detail badge shows — so the sort can never drift
    // from the grade. A row with no filed specimen ranks last.
    func documentationRank(_ entry: RepertoireEntry, store: PitchStore) -> Int {
        guard let slug = entry.filedSlug, let pitch = store.pitch(slug: slug) else { return 4 }
        switch pitch.specimenGrade.key {
        case .gold: return 0
        case .inMotion: return 1
        case .firstParty: return 2
        case .reference: return 3
        }
    }
}
