import SwiftUI
import UIKit

@main
struct PitchAtlasApp: App {
    @Environment(\.scenePhase) private var scenePhase
    /// The bundled content, loaded once at launch and shared via @Environment.
    @State private var store: PitchStore
    /// The gyroscope feed for the foil rake, shared across surfaces.
    @State private var motion = MotionProvider()
    /// Supabase auth/session state for community actions.
    @State private var auth = AuthSessionStore()
    /// The hidden archive notes found on this device (the site's localStorage set).
    @State private var notes: HiddenNotes

    init() {
        #if DEBUG
        OfflineLaunch.installIfAsked()
        #endif
        AppChromeAppearance.install()
        let store = PitchStore()
        _store = State(initialValue: store)
        _notes = State(initialValue: HiddenNotes(known: store.tidbits.map(\.id)))
    }

    var body: some Scene {
        WindowGroup {
            LaunchLoadingGate {
                RootView()
                    .environment(store)
                    .environment(motion)
                    .environment(auth)
                    .environment(\.hiddenNotes, notes)
                    .preferredColorScheme(.dark)
                    .task {
                        motion.start()
                        await auth.start()
                    }
                    .onChange(of: scenePhase) { _, phase in
                        // The gyro is a hardware resource: run it only while the app
                        // is active, release it on background/inactive. start() guards
                        // on isDeviceMotionActive, so re-activation re-arms identically.
                        phase == .active ? motion.start() : motion.stop()
                    }
            }
        }
    }
}

#if DEBUG
/// DEBUG-only: PA_OFFLINE=1 refuses every request on the shared session (the
/// one the Supabase client and the community images ride) as "not connected",
/// so a simulator can show a first launch with no network without touching the
/// Mac's own network. No effect in production.
private enum OfflineLaunch {
    static func installIfAsked() {
        guard ProcessInfo.processInfo.environment["PA_OFFLINE"] == "1" else { return }
        URLProtocol.registerClass(RefuseEveryRequest.self)
    }

    final class RefuseEveryRequest: URLProtocol {
        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
        override func startLoading() {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
        }
        override func stopLoading() {}
    }
}
#endif

private enum AppChromeAppearance {
    static func install() {
        let field = UIColor(web: WebTokens.Palette.void).withAlphaComponent(0.98)
        let bone = UIColor(web: WebTokens.Palette.bone)
        let bone2 = UIColor(web: WebTokens.Palette.bone2).withAlphaComponent(0.78)
        let cyan = UIColor(web: WebTokens.Palette.cyan)

        let tab = UITabBarAppearance()
        tab.configureWithTransparentBackground()
        tab.backgroundColor = .clear
        tab.shadowColor = .clear
        [tab.stackedLayoutAppearance, tab.inlineLayoutAppearance, tab.compactInlineLayoutAppearance].forEach { item in
            item.normal.iconColor = bone2
            item.normal.titleTextAttributes = [.foregroundColor: bone2]
            item.selected.iconColor = cyan
            item.selected.titleTextAttributes = [.foregroundColor: cyan]
        }
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().isTranslucent = true

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = field
        nav.shadowColor = .clear
        nav.titleTextAttributes = [.foregroundColor: bone]
        nav.largeTitleTextAttributes = [.foregroundColor: bone]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
    }
}

/// The canonical tab enum and target for `pitchatlas://` deep links.
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
    @Environment(AuthSessionStore.self) private var auth
    @State private var router = DeepLinkRouter()
    @State private var comparison = CompareSelection()
    @State private var bench = SpecimenBench()
    @State private var toasts = ToastCenter()
    @Environment(\.hiddenNotes) private var notes
    /// DEBUG-only: a hidden note's reveal (or the found index) opened at launch.
    @State private var debugNote: HiddenNoteSheet.Mode?

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
        @Bindable var bench = bench
        TabView(selection: $router.selection) {
            NavigationStack(path: $router.atlasPath) {
                TabScaffold(tab: .atlas) { AtlasView() }
            }
                .compareTray()
                .tabItem { Label(AppTab.atlas.title, systemImage: AppTab.atlas.systemImage) }
                .tag(AppTab.atlas)
            NavigationStack(path: $router.indexPath) {
                TabScaffold(tab: .index) { IndexView() }
            }
                .compareTray()
                .tabItem { Label(AppTab.index.title, systemImage: AppTab.index.systemImage) }
                .tag(AppTab.index)
            NavigationStack(path: $router.gripsPath) {
                TabScaffold(tab: .grips) { GripsView() }
            }
                .compareTray()
                .tabItem { Label(AppTab.grips.title, systemImage: AppTab.grips.systemImage) }
                .tag(AppTab.grips)
            NavigationStack(path: $router.craftsmenPath) {
                TabScaffold(tab: .craftsmen) { CraftsmenView() }
            }
                .compareTray()
                .tabItem { Label(AppTab.craftsmen.title, systemImage: AppTab.craftsmen.systemImage) }
                .tag(AppTab.craftsmen)
            NavigationStack(path: $router.sourcesPath) {
                TabScaffold(tab: .sources) { SourcesView() }
            }
                .compareTray()
                .tabItem { Label(AppTab.sources.title, systemImage: AppTab.sources.systemImage) }
                .tag(AppTab.sources)
        }
        .environment(\.compareSelection, comparison)
        .environment(\.specimenBench, bench)
        .environment(router)
        // a third pitch asks for room over any page while the table is shut
        .overlay {
            if let pending = comparison.pending,
               MakeRoomHost.host(pending: true, tableOpen: comparison.presented, benchOpen: bench.opened != nil) == .root {
                MakeRoom(pending: pending).environment(\.compareSelection, comparison)
            }
        }
        // the tray's status line (role="status"), spoken once for every tab's tray
        // a link followed from inside the table or the bench goes where it says
        .onChange(of: router.landings) {
            comparison.presented = false
            bench.opened = nil
        }
        .onChange(of: comparison.slugs.count) { _, chosen in
            AccessibilityNotification.Announcement(CompareTrayReads.status(chosen: chosen)).post()
        }
        .toastHost()
        .environment(toasts)
        // The cover sits outside the environment written above, so it carries its own:
        // the specimen pages it opens post toasts, and its links leave through the router.
        // the one-pitch bench (InspectButton), over the page like the table
        .fullScreenCover(item: $bench.opened) { opened in
            if let entry = store.pitch(slug: opened.slug) {
                InspectorView(entry: entry, bench: bench)
                    .toastHost()
                    .environment(toasts)
                    .environment(router)
                    .environment(\.compareSelection, comparison)
            }
        }
        .fullScreenCover(isPresented: $comparison.presented) {
            CompareView()
                .toastHost()
                .environment(toasts)
                .environment(router)
                .environment(\.compareSelection, comparison)
        }
        .tint(PitchAtlasTheme.kicker)
        .toolbarBackground(PitchAtlasTheme.void, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .tabBar)
        .toolbarColorScheme(.dark, for: .navigationBar, .tabBar)
        .onOpenURL { url in
            auth.handle(url: url)
            if !comparison.handle(url, store: store) { router.handle(url, store: store) }
        }
        .task { applyDebugLaunch() }
        .sheet(item: $debugNote) { mode in
            if let notes { HiddenNoteSheet(mode: mode, notes: notes) }
        }
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
        // PA_ROUTE takes a link path ("learn/spin", "compare?a=slider&b=sweeper")
        // and opens it exactly as the link would.
        if let route = env["PA_ROUTE"], let url = URL(string: "pitchatlas://\(route)") {
            if !comparison.handle(url, store: store) { router.handle(url, store: store) }
        }
        // PA_INSPECT opens the one-pitch bench on a pitch; PA_INSPECT_WITH names its partner
        if let slug = env["PA_INSPECT"] {
            bench.open(slug, store: store)
            if let partner = env["PA_INSPECT_WITH"] {
                bench.choosePartner(partner, store: store, compare: comparison)
            }
        }
        // PA_NOTE files a hidden note and opens its reveal; "index" opens the found index
        if let id = env["PA_NOTE"], let notes {
            if id == "index" {
                debugNote = .index
            } else {
                notes.discover(id)
                debugNote = .reveal(id)
            }
        }
        #endif
    }
}

#Preview {
    RootView()
        .environment(PitchStore())
        .environment(AuthSessionStore())
        .preferredColorScheme(.dark)
}
