import SwiftUI

// =============================================================================
// Pitch Atlas — Craftsmen hall
// =============================================================================
// The archive of arms who defined a pitch — and the one legend that is a pitch,
// not a person, kept flagged in its own card so the gap stays visible. Four-state
// aware: a decode failure shows the error, an empty hall says why, otherwise the
// plates stack and each pushes a single-craftsman record.
// =============================================================================

struct CraftsmenView: View {
    @Environment(PitchStore.self) private var store

    var body: some View {
        ZStack {
            PitchAtlasTheme.void.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xl) {
                    masthead

                    content
                }
                .padding(.horizontal, PitchAtlasSpacing.lg)
                .padding(.top, PitchAtlasSpacing.md)
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                .emitsBlazeScrollProgress()
            }
        }
        .navigationTitle("Craftsmen")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Craftsman.self) { CraftsmanDetailView(craftsman: $0) }
    }

    // MARK: - Masthead

    private var masthead: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            SectionLabel(text: "The Craftsmen")

            Text("CRAFTSMEN")
                .font(PitchAtlasTheme.anton(48))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
                .padding(.vertical, 2)

            Text("Arms who defined a pitch — and one legend that is a pitch, not a person.")
                .font(PitchAtlasTheme.newsreaderItalic(17))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, PitchAtlasSpacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("The Craftsmen. Arms who defined a pitch, and one legend that is a pitch, not a person.")
    }

    // MARK: - Four states

    @ViewBuilder
    private var content: some View {
        if case .failed(let msg) = store.status {
            ErrorStateView(reason: msg)
        } else if store.craftsmen.isEmpty {
            EmptyStateView(message: "The hall couldn't load.")
        } else {
            VStack(spacing: PitchAtlasSpacing.md) {
                ForEach(store.craftsmen) { craftsman in
                    NavigationLink(value: craftsman) {
                        CraftsmanCard(craftsman: craftsman)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
