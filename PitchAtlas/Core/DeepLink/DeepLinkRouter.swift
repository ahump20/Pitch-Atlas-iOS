import SwiftUI
import Observation

enum AtlasUtilityRoute: Hashable {
    case account
}

// =============================================================================
// DeepLinkRouter — pitchatlas:// routing
// =============================================================================
// Owns the selected tab and a NavigationPath per tab so a deep link can select a
// tab and push a detail. Routes:
//   pitchatlas://tab/<atlas|index|grips|craftsmen|sources>
//   pitchatlas://pitch/<slug>        -> Atlas, push the filed specimen
//   pitchatlas://craftsman/<slug>    -> Craftsmen, push the craftsman
// Unknown links resolve to the closest tab and are ignored if the slug misses —
// never a crash, never a dead push.
// =============================================================================

@Observable
final class DeepLinkRouter {
    var selection: AppTab = RootView.initialTab
    var atlasPath = NavigationPath()
    var indexPath = NavigationPath()
    var gripsPath = NavigationPath()
    var craftsmenPath = NavigationPath()
    var sourcesPath = NavigationPath()

    func handle(_ url: URL, store: PitchStore) {
        guard url.scheme == "pitchatlas" else { return }
        let host = url.host ?? ""
        let slug = url.pathComponents.dropFirst().first ?? ""

        switch host {
        case "tab":
            if let tab = AppTab(rawValue: slug) { selection = tab }
        case "pitch":
            if let entry = store.pitch(slug: slug) {
                selection = .atlas
                atlasPath.append(entry)
            }
        case "craftsman":
            if let craftsman = store.craftsman(slug: slug) {
                selection = .craftsmen
                craftsmenPath.append(craftsman)
            }
        default:
            break
        }
    }
}
