import SwiftUI

@main
struct PitchAtlasApp: App {
    /// The bundled content, loaded once at launch and shared via @Environment.
    @State private var store = PitchStore()
    /// The gyroscope feed for the foil rake, shared across surfaces.
    @State private var motion = MotionProvider()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(motion)
                .preferredColorScheme(.dark)
                .task { motion.start() }
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
    @Environment(PitchStore.self) private var store
    @State private var router = DeepLinkRouter()

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
        @Bindable var router = router
        TabView(selection: $router.selection) {
            NavigationStack(path: $router.atlasPath) { AtlasView() }
                .tabItem { Label(AppTab.atlas.title, systemImage: AppTab.atlas.systemImage) }
                .tag(AppTab.atlas)
            NavigationStack(path: $router.indexPath) { IndexView() }
                .tabItem { Label(AppTab.index.title, systemImage: AppTab.index.systemImage) }
                .tag(AppTab.index)
            NavigationStack(path: $router.gripsPath) { GripsView() }
                .tabItem { Label(AppTab.grips.title, systemImage: AppTab.grips.systemImage) }
                .tag(AppTab.grips)
            NavigationStack(path: $router.craftsmenPath) { CraftsmenView() }
                .tabItem { Label(AppTab.craftsmen.title, systemImage: AppTab.craftsmen.systemImage) }
                .tag(AppTab.craftsmen)
            NavigationStack(path: $router.sourcesPath) { SourcesView() }
                .tabItem { Label(AppTab.sources.title, systemImage: AppTab.sources.systemImage) }
                .tag(AppTab.sources)
        }
        .tint(PitchAtlasTheme.cyan)
        .onOpenURL { url in router.handle(url, store: store) }
        .task { applyDebugLaunch() }
    }

    /// DEBUG-only: push a detail straight from a launch env so QA can screenshot it
    /// without the system "open in app?" prompt. No effect in production.
    private func applyDebugLaunch() {
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        if let slug = env["PA_PITCH"], let entry = store.pitch(slug: slug) {
            router.selection = .atlas
            router.atlasPath.append(entry)
        }
        if let slug = env["PA_CRAFTSMAN"], let craftsman = store.craftsman(slug: slug) {
            router.selection = .craftsmen
            router.craftsmenPath.append(craftsman)
        }
        #endif
    }
}

#Preview {
    RootView()
        .environment(PitchStore())
        .preferredColorScheme(.dark)
}
