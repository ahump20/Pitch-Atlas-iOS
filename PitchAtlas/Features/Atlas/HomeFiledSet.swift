import SwiftUI

// =============================================================================
// HomeFiledSet — chapter 03, the filed set
// =============================================================================
// Web: v2/ChromeWall.tsx. One specimen per core family on the matte stage, each
// in its mount with the flip to its sourced back and the study controls, then
// the way into the rest of the set.
// =============================================================================

struct HomeFiledSet: View {
    @Environment(PitchStore.self) private var store
    @State private var cellWidth: CGFloat = 0

    var body: some View {
        let featured = FeaturedSet.entries(in: store)
        if !featured.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ChapterMark(.filedSet, accent: ArchiveInk.filedSetTint)
                    .padding(.bottom, 16)
                AthleticTitle(text: Text("The ") + Text("filed set.").foregroundStyle(PitchAtlasMaterials.foilType()), size: 30)
                Text("\(featured.count) shown · \(store.pitches.count) filed. Flip a card for its sources.")
                    .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                    .textCase(.uppercase)
                    .tracking(10 * 0.14)
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 16)
                Text("One specimen per family: grip first, source attached. The rest of the set lives in the Pitch Index.")
                    .font(PitchAtlasTheme.hanken(15))
                    .lineSpacing(5)
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 16)
                wall(featured)
                    .padding(.top, 40)
                RouteButton(path: "repertoire") { Text("Open the full Pitch Index →") }
                    .buttonStyle(.pitch(.chrome))
                    .padding(.top, 40)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 80)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { MatteStage() }
            .overlay(alignment: .top) { SeamDescent() }
        }
    }

    /// `.v2-wall`: on a phone, one mount to a row, 14pt apart.
    private func wall(_ featured: [PitchAtlasEntry]) -> some View {
        VStack(spacing: 14) {
            if cellWidth > 0 {
                ForEach(Array(featured.enumerated()), id: \.element.id) { index, entry in
                    WallSpecimen(entry: entry, width: cellWidth, index: index)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background {
            GeometryReader { geo in
                Color.clear.preference(key: WallWidthKey.self, value: geo.size.width)
            }
        }
        .onPreferenceChange(WallWidthKey.self) { cellWidth = $0 }
    }
}

private struct WallWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}
