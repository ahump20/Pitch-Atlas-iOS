import SwiftUI

// =============================================================================
// Pitch Atlas — Lost Pitches wing
// =============================================================================
// The Negro Leagues pitches whose box scores are being recovered and whose grips
// mostly never will be. Here the documentation tier IS the feature: a legend up
// front teaches the three tiers, then every card wears how solid its own record
// is. Four-state aware — a decode failure shows the error, an empty wing says why,
// otherwise the tier legend and the entries stack and each pushes a single record.
// =============================================================================

struct LostPitchesView: View {
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
            }
        }
        .navigationTitle("Lost Pitches")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: LostPitch.self) { LostPitchDetailView(pitch: $0) }
    }

    // MARK: - Masthead

    private var masthead: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            SectionLabel(text: "Lost Pitches")

            Text("LOST")
                .font(PitchAtlasTheme.anton(56))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
                .padding(.vertical, 2)

            Text("The box score survives. The grip does not. Every entry wears how solid the record is.")
                .font(PitchAtlasTheme.newsreaderItalic(17))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, PitchAtlasSpacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Lost Pitches. The box score survives. The grip does not. Every entry wears how solid the record is.")
    }

    // MARK: - Tier legend (teaches the documentation tiers up front)

    private var tierLegend: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "How solid is the record", size: 9)

            ForEach(store.lostPitches.tiers) { info in
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
                    StatusPill(text: info.label, tone: info.tier.tone)
                    Text(info.note)
                        .font(PitchAtlasTheme.hanken(14))
                        .foregroundStyle(PitchAtlasTheme.bone2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(info.label). \(info.note)")
            }
        }
        .leatherPress()
    }

    // MARK: - Four states

    @ViewBuilder
    private var content: some View {
        if case .failed(let msg) = store.status {
            ErrorStateView(reason: msg)
        } else if store.lostPitches.entries.isEmpty {
            EmptyStateView(message: "This wing couldn't load.")
        } else {
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.md) {
                if !store.lostPitches.tiers.isEmpty {
                    tierLegend
                }

                ForEach(store.lostPitches.entries) { pitch in
                    NavigationLink(value: pitch) {
                        LostPitchCard(pitch: pitch)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
