import SwiftUI
import Observation

// =============================================================================
// DeepLinkRouter — pitchatlas:// routing
// =============================================================================
// Owns the selected tab and a NavigationPath per tab so a link can select a tab
// and stack the screens under it. A link names a place the way the site's path
// does: pitchatlas://learn/<slug> opens what pitch-atlas.com/learn/<slug> shows.
//   pitchatlas://home                     -> Atlas, the home (the site's "/")
//   pitchatlas://tab/<atlas|index|grips|craftsmen|sources>
//   pitchatlas://pitch/<slug>             -> Atlas, the filed specimen
//   pitchatlas://repertoire[/<id>]        -> Index, the basic file; an entry with a
//                                            filed specimen opens it, as the site
//                                            sends /repertoire/<id> to /pitch/<slug>
//   pitchatlas://craftsmen[/<slug>]       -> Craftsmen, the craftsman (craftsman/<slug> too)
//   pitchatlas://learn[/<slug>]           -> Atlas, Learn, the wing
//   pitchatlas://lost-pitches[/<slug>]    -> Atlas, Lost Pitches, the pitch
//   pitchatlas://about, ://account,
//     ://support                          -> Atlas, that page
//   pitchatlas://grips, ://sources        -> that tab
//   pitchatlas://movement-map             -> Atlas, the Shape map
//   pitchatlas://sandbox[?tilt=&pitch=]   -> Atlas, Shape Lab (a bad tilt is 12:00,
//                                            an unknown pitch no reference)
// pitchatlas://compare belongs to CompareSelection. A link replaces the stack on
// its tab, so it always lands in the same place. A slug that misses opens the
// list it would have lived in — never a crash, never a dead push.
// =============================================================================

/// The Atlas tab's own pages: the wings that are not tabs.
enum AtlasRoute: Hashable {
    case craftsmen, learn, lostPitches, about, account, support
    /// Shape Lab, carrying the link's tilt and reference (the site's ?tilt=&pitch=).
    case shapeLab(tilt: Int, pitch: String?)
    case shapeMap
}

/// One screen a link stacks onto a tab, carrying the value its destination reads.
enum DeepLinkStep: Hashable {
    case atlas(AtlasRoute)
    case pitch(PitchAtlasEntry)
    case basicFile(RepertoireEntry)
    case craftsman(Craftsman)
    case wing(KnowledgeWing)
    case lostPitch(LostPitch)

    fileprivate func append(to path: inout NavigationPath) {
        switch self {
        case .atlas(let route): path.append(route)
        case .pitch(let entry): path.append(entry)
        case .basicFile(let entry): path.append(entry)
        case .craftsman(let craftsman): path.append(craftsman)
        case .wing(let wing): path.append(wing)
        case .lostPitch(let pitch): path.append(pitch)
        }
    }
}

/// Where a link lands: the tab, then the screens stacked on it, root first.
struct DeepLinkDestination: Equatable {
    let tab: AppTab
    let stack: [DeepLinkStep]
}

@Observable
final class DeepLinkRouter {
    var selection: AppTab = RootView.initialTab
    var atlasPath = NavigationPath()
    var indexPath = NavigationPath()
    var gripsPath = NavigationPath()
    var craftsmenPath = NavigationPath()
    var sourcesPath = NavigationPath()

    func handle(_ url: URL, store: PitchStore) {
        guard let destination = Self.destination(for: url, store: store) else { return }
        var path = NavigationPath()
        destination.stack.forEach { $0.append(to: &path) }
        switch destination.tab {
        case .atlas: atlasPath = path
        case .index: indexPath = path
        case .grips: gripsPath = path
        case .craftsmen: craftsmenPath = path
        case .sources: sourcesPath = path
        }
        selection = destination.tab
    }

    static func destination(for url: URL, store: PitchStore) -> DeepLinkDestination? {
        guard url.scheme == "pitchatlas", let host = url.host?.lowercased() else { return nil }
        let slug = url.pathComponents.dropFirst().first
        func land(_ tab: AppTab, _ stack: [DeepLinkStep] = []) -> DeepLinkDestination {
            DeepLinkDestination(tab: tab, stack: stack)
        }

        switch host {
        case "home":
            return land(.atlas)
        case "tab":
            return slug.flatMap(AppTab.init(rawValue:)).map { land($0) }
        case "pitch":
            guard let entry = slug.flatMap(store.pitch(slug:)) else { return land(.index) }
            return land(.atlas, [.pitch(entry)])
        case "repertoire":
            guard let entry = slug.flatMap(store.repertoireEntry(id:)) else { return land(.index) }
            if let filed = entry.filedSlug.flatMap(store.pitch(slug:)) {
                return land(.atlas, [.pitch(filed)])
            }
            return land(.index, [.basicFile(entry)])
        case "craftsmen", "craftsman":
            guard let craftsman = slug.flatMap(store.craftsman(slug:)) else { return land(.craftsmen) }
            return land(.craftsmen, [.craftsman(craftsman)])
        case "learn":
            guard let wing = slug.flatMap(store.wing(slug:)) else { return land(.atlas, [.atlas(.learn)]) }
            return land(.atlas, [.atlas(.learn), .wing(wing)])
        case "lost-pitches":
            guard let pitch = slug.flatMap(store.lostPitch(slug:)) else { return land(.atlas, [.atlas(.lostPitches)]) }
            return land(.atlas, [.atlas(.lostPitches), .lostPitch(pitch)])
        case "about":
            return land(.atlas, [.atlas(.about)])
        case "account":
            return land(.atlas, [.atlas(.account)])
        case "support":
            return land(.atlas, [.atlas(.support)])
        case "sandbox":
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            func value(_ key: String) -> String? { items.first { $0.name == key }?.value }
            let reference = ShapeLab.reference(value("pitch"), store: store)?.slug
            return land(.atlas, [.atlas(.shapeLab(tilt: ShapeLab.parseTilt(value("tilt")), pitch: reference))])
        case "movement-map":
            return land(.atlas, [.atlas(.shapeMap)])
        case "grips":
            return land(.grips)
        case "sources":
            return land(.sources)
        default:
            return nil
        }
    }
}
