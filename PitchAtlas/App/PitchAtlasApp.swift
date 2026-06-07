import SwiftUI

@main
struct PitchAtlasApp: App {
    /// The bundled content, loaded once at launch and shared via @Environment.
    @State private var store = PitchStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.dark)
        }
    }
}

/// The canonical tab enum — also the target for `pitchatlas://` deep links (wired later).
enum AppTab: String, CaseIterable, Identifiable {
    case atlas, index, grips, craftsmen, sources

    var id: String { rawValue }

    var title: String {
        switch self {
        case .atlas: return "Atlas"
        case .index: return "Index"
        case .grips: return "Grips"
        case .craftsmen: return "Craftsmen"
        case .sources: return "Sources"
        }
    }

    /// Utility chrome may use SF Symbols; brand marks (the diamond/seam/seal) are bespoke and land later.
    var systemImage: String {
        switch self {
        case .atlas: return "circle.grid.cross"
        case .index: return "list.bullet.rectangle"
        case .grips: return "hand.raised.fingers.spread"
        case .craftsmen: return "person.crop.square.on.square.angled"
        case .sources: return "text.book.closed"
        }
    }
}

struct RootView: View {
    @State private var selectedTab: AppTab = RootView.initialTab

    /// DEBUG-only launch override so QA can open straight to a tab; production always starts on Atlas.
    static var initialTab: AppTab {
        #if DEBUG
        if let raw = ProcessInfo.processInfo.environment["PA_TAB"], let tab = AppTab(rawValue: raw) {
            return tab
        }
        #endif
        return .atlas
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    screen(for: tab)
                }
                .tabItem { Label(tab.title, systemImage: tab.systemImage) }
                .tag(tab)
            }
        }
        .tint(PitchAtlasTheme.cyan)
    }

    @ViewBuilder
    private func screen(for tab: AppTab) -> some View {
        switch tab {
        case .atlas: AtlasView()
        case .index: IndexView()
        case .grips: GripsView()
        case .craftsmen: CraftsmenView()
        case .sources: SourcesView()
        }
    }
}

#Preview {
    RootView()
        .environment(PitchStore())
        .preferredColorScheme(.dark)
}
