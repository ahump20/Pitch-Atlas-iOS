import SwiftUI

// =============================================================================
// AtlasMenu — the rest of the atlas, from the Atlas tab
// =============================================================================
// Web: layout/Masthead.tsx, the phone menu (#mobile-nav): NAV, then "The rest of
// the atlas" (MORE_CONTENT), then "Tools" (TOOLS), each a mono capital line over
// a hairline. Pitch Index and Grips are tabs here, already one tap away; Softball
// joins with the softball wing and the Shape map with its own task. A sheet from
// the leading ☰ in the Atlas toolbar; a choice closes it and follows the link.
// =============================================================================

enum AtlasMenu {
    struct Item: Hashable {
        let label: String
        /// The pitchatlas:// path the item opens.
        let route: String
    }

    struct Group: Hashable {
        let title: String?
        let items: [Item]
    }

    static let groups = [
        Group(title: nil, items: [Item(label: "Learn", route: "learn")]),
        Group(title: "The rest of the atlas", items: [
            Item(label: "Craftsmen", route: "craftsmen"),
            Item(label: "Lost Pitches", route: "lost-pitches"),
            Item(label: "Sources", route: "sources"),
            Item(label: "About", route: "about"),
        ]),
        Group(title: "Tools", items: [
            Item(label: "Shape Lab", route: "sandbox"),
            Item(label: "Compare two pitches", route: "compare"),
            Item(label: "Compare two grips", route: "grips"),
        ]),
    ]

    static let openLabel = "Open the menu"
}

/// The ☰ in the Atlas toolbar and the sheet it opens.
struct AtlasMenuButton: View {
    @State private var open = false

    var body: some View {
        Button { open = true } label: {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(AtlasMenu.openLabel)
        .sheet(isPresented: $open) {
            AtlasMenuSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct AtlasMenuSheet: View {
    @Environment(PitchStore.self) private var store
    @Environment(DeepLinkRouter.self) private var router
    @Environment(\.compareSelection) private var compare
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(AtlasMenu.groups, id: \.self) { group in
                    VStack(alignment: .leading, spacing: 4) {
                        if let title = group.title {
                            Text(title.uppercased())
                                .font(PitchAtlasType.font(.martian400, size: 11, relativeTo: .caption2))
                                .tracking(em: 0.18, size: 11)
                                .foregroundStyle(PitchAtlasTheme.ink3)
                                .accessibilityAddTraits(.isHeader)
                                .padding(.top, 16)
                        }
                        VStack(spacing: 0) {
                            ForEach(group.items, id: \.self) { item in
                                Button { follow(item) } label: {
                                    Text(item.label.uppercased())
                                        .font(PitchAtlasType.font(.martian400, size: 14, relativeTo: .subheadline))
                                        .tracking(em: 0.1, size: 14)
                                        .foregroundStyle(PitchAtlasTheme.ink2)
                                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                                        .overlay(alignment: .bottom) { PitchAtlasTheme.bone.opacity(0.10).frame(height: 1) }
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(item.label)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .background(PitchAtlasTheme.void)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Menu")
    }

    /// Close the sheet, then follow the link the way the site's would.
    private func follow(_ item: AtlasMenu.Item) {
        dismiss()
        guard let url = URL(string: "pitchatlas://\(item.route)") else { return }
        if !compare.handle(url, store: store) { router.handle(url, store: store) }
    }
}
