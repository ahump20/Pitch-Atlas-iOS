import SwiftUI

// =============================================================================
// HomeRecord — chapter 05, the record
// =============================================================================
// Web: v2/CloseCta.tsx. The close: the vow, the two ways back in, Muybridge's
// plate 273 (the pitcher every chapter mark is traced from), the wall line, and
// the citation registry's own count and date, computed from the bundled sources.
// =============================================================================

struct HomeRecord: View {
    @Environment(PitchStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                ChapterMark(.record, accent: ArchiveInk.recordTint)
                    .padding(.bottom, 20)
                AthleticTitle(text: Text("Preserve the pitches baseball almost forgot."), size: 32, lineSpacing: -2, alignment: .center)
                Text("Open a grip. Follow a story. Leave a firsthand observation for the next person who comes looking.")
                    .font(PitchAtlasTheme.hanken(15.5))
                    .lineSpacing(5)
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 20)
                VStack(spacing: 12) {
                    RouteButton(path: "repertoire") { Text("Open the Pitch Index →") }
                        .buttonStyle(.pitch(.chrome))
                    NavigationLink(value: AtlasRoute.lostPitches) { Text("The lost pitches →") }
                        .buttonStyle(.pitch(.ghost))
                }
                .padding(.top, 32)
            }
            .padding(.top, 96)

            VStack(spacing: 0) {
                DeliveryPlate()
                Text("Every grip filed before the arm forgets it. Every claim still wearing its source.")
                    .font(PitchAtlasType.heroTitle(size: 22))
                    .lineSpacing(-1)
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .shadow(color: .black.opacity(0.45), radius: 20, y: 16)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 40)
                Text(SourceRegistry.recordLine(store.sources))
                    .font(PitchAtlasTheme.hanken(13, relativeTo: .footnote))
                    .lineSpacing(4)
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 20)
                RouteButton(path: "sources") {
                    Text("How a claim is filed →")
                        .font(PitchAtlasTheme.hanken(13, relativeTo: .footnote))
                        .underline()
                        .foregroundStyle(PitchAtlasTheme.bone)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 64)
            .padding(.bottom, 80)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background { MatteStage() }
        .overlay(alignment: .top) { SeamDescent() }
    }
}
