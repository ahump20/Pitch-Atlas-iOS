import SwiftUI

// =============================================================================
// HiddenNotes — the ten hidden archive notes and the found set
// =============================================================================
// Web: components/eggs/tidbitStore.ts (the found ids, a JSON array under
// pa-tidbits-found-v1, anonymous and on this device only), EggProvider.tsx (reveal
// files a note; an id the bundle lacks is ignored), and the ten EggButton
// placements with their labels. The notes themselves are generated content
// (tidbits.json from data/tidbits/index.ts).
// =============================================================================

@Observable
final class HiddenNotes {
    static let storageKey = "pa-tidbits-found-v1"

    /// The note ids the bundle files, in the site's order.
    let known: [String]
    private(set) var found: [String]
    @ObservationIgnored private let defaults: UserDefaults

    init(known: [String], defaults: UserDefaults = .standard) {
        self.known = known
        self.defaults = defaults
        found = Self.load(defaults)
    }

    var total: Int { known.count }
    /// Counted against the bundle, so "n of 10" never runs past the notes it files.
    var count: Int { found.filter(known.contains).count }
    func has(_ id: String) -> Bool { found.contains(id) }

    func discover(_ id: String) {
        guard known.contains(id), !found.contains(id) else { return }
        found.append(id)
        if let data = try? JSONEncoder().encode(found), let raw = String(data: data, encoding: .utf8) {
            defaults.set(raw, forKey: Self.storageKey)
        }
    }

    private static func load(_ defaults: UserDefaults) -> [String] {
        guard let raw = defaults.string(forKey: storageKey),
              let ids = try? JSONDecoder().decode([String].self, from: Data(raw.utf8)) else { return [] }
        return ids
    }

    // MARK: The site's words (TidbitReveal.tsx, FoundIndex.tsx, SiteFooter.tsx)

    static let foundKick = "Archive note found"
    static let indexKick = "Hidden archive notes"
    static let indexLede = "Ten real, sourced tidbits are hidden across the historical files. Find one and it gets filed here. Locked slots name only where they are filed."
    static func footerLine(count: Int, total: Int) -> String { "Hidden notes · \(count) of \(total) found" }
    static func filedLine(count: Int, total: Int) -> String { "Filed: \(count) of \(total) found" }
    static func indexTitle(count: Int, total: Int) -> String { "\(count) of \(total) found" }
    static func lockedLine(_ location: String) -> String { "Not yet found · filed from \(location)" }
}

/// The ten spots, by the note each one files, with the site's aria-label.
enum HiddenNotePlacement: String, CaseIterable {
    case stitches, doubleday, sixtySix = "sixty-six", theK = "the-k", spitballBan = "spitball-ban"
    case eephus, rubbingMud = "rubbing-mud", knuckleball, firstNightGame = "first-night-game"
    case curveballClaim = "curveball-claim"

    var label: String {
        switch self {
        case .stitches: "Reveal a hidden note about how a baseball is stitched"
        case .doubleday: "The archive stays open: reveal a hidden note about the game's origin"
        case .sixtySix: "Reveal a hidden note about why the pitching rubber sits 60 feet 6 inches away"
        case .theK: "Reveal a hidden note about how baseball record-keeping began"
        case .spitballBan: "Reveal a hidden note about the banned spitball and its grandfathered pitchers"
        case .eephus: "Reveal a hidden note about the eephus pitch"
        case .rubbingMud: "Reveal a hidden note about the secret mud rubbed on every baseball"
        case .knuckleball: "Reveal a hidden note about how little a knuckleball spins"
        case .firstNightGame: "Reveal a hidden note about the first night game in baseball history"
        case .curveballClaim: "Reveal a hidden note about who really invented the curveball"
        }
    }

    /// PitchIndex.tsx: `q === 'eephus'` on the trimmed, lowercased search.
    static func showsEephus(query: String) -> Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "eephus"
    }
}

private struct HiddenNotesKey: EnvironmentKey {
    static let defaultValue: HiddenNotes? = nil
}

extension EnvironmentValues {
    /// The found set; nil where no root has set it (previews), and the spots stay plain.
    var hiddenNotes: HiddenNotes? {
        get { self[HiddenNotesKey.self] }
        set { self[HiddenNotesKey.self] = newValue }
    }
}
