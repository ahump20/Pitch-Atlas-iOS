import SwiftUI

@main
struct PitchAtlasApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
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
    @State private var selectedTab: AppTab = .atlas

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    ComingOnlineScreen(tab: tab)
                }
                .tabItem { Label(tab.title, systemImage: tab.systemImage) }
                .tag(tab)
            }
        }
        .tint(PitchAtlasTheme.cyan)
    }
}

/// Honest placeholder shell for the foundation build — the void field + brand type,
/// labeled as not-yet-wired. No fake data. Each tab's real surface replaces this.
struct ComingOnlineScreen: View {
    let tab: AppTab

    var body: some View {
        ZStack {
            PitchAtlasTheme.void.ignoresSafeArea()

            VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                Text("PITCH ATLAS")
                    .font(PitchAtlasTheme.martian(11))
                    .tracking(3)
                    .foregroundStyle(PitchAtlasTheme.ink3)

                Text(tab.title.uppercased())
                    .font(PitchAtlasTheme.anton(44))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .antonSkew()

                Text("Sourced, not corrected.")
                    .font(PitchAtlasTheme.newsreaderItalic(18))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .padding(.top, PitchAtlasSpacing.xs)

                HStack(spacing: PitchAtlasSpacing.xs) {
                    Circle()
                        .fill(PitchAtlasTheme.cyan)
                        .frame(width: 8, height: 8)
                        .shadow(color: PitchAtlasTheme.cyan.opacity(0.6), radius: 4)
                    Text("Surface coming online")
                        .font(PitchAtlasTheme.martian(10))
                        .tracking(1.5)
                        .foregroundStyle(PitchAtlasTheme.ink3)
                }
                .padding(.top, PitchAtlasSpacing.lg)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(PitchAtlasSpacing.xl)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    RootView()
}
