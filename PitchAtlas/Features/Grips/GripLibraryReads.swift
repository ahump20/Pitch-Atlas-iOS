import Foundation

// =============================================================================
// Pitch Atlas — what the Grip Library reads off Austin's grips
// =============================================================================
// Web: components/sections/GripLibrary.tsx — the search under "Find a grip", the
// count beneath it, where each grip's link goes, the circle change's labeled gap,
// and when the library offers Pause. Pure reads, so the site's filter and its
// words are pinned by tests.
// =============================================================================

enum GripLibraryReads {
    /// Where a grip's link goes: its filed specimen, else its basic file.
    enum Link: Equatable {
        case specimen(slug: String), file(id: String)

        /// The site's words for the link.
        var label: String {
            switch self {
            case .specimen: "See the specimen"
            case .file: "Open the file"
            }
        }
    }

    /// "Find a grip": the query, lower-cased with its ends trimmed, inside the
    /// grip's name and Austin's note. Nothing typed shows every grip.
    static func matches(_ entries: [GripEntry], query: String) -> [GripEntry] {
        let needle = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return entries }
        return entries.filter { "\($0.label) \($0.note)".lowercased().contains(needle) }
    }

    /// The status line under the field.
    static func countLine(shown: Int, of total: Int) -> String { "\(shown) of \(total) grips" }

    static func link(_ entry: GripEntry) -> Link? {
        if let slug = entry.specimenSlug { return .specimen(slug: slug) }
        if let id = entry.repertoireId { return .file(id: id) }
        return nil
    }

    /// The labeled gap where the circle change's photographs would be: it has no
    /// film and no photo of Austin's hand, and the site never borrows one.
    static func gap(for entry: GripEntry, in file: GripsFile) -> GripDistinction? {
        guard entry.id == "circle-change", entry.film == nil, entry.photos.isEmpty else { return nil }
        return file.circleChangeDistinction
    }

    /// The library carries Pause while a grip on show moves; under Reduce Motion
    /// nothing does.
    static func loops(_ shown: [GripEntry], reduceMotion: Bool) -> Bool {
        !reduceMotion && shown.contains { $0.film != nil }
    }
}
