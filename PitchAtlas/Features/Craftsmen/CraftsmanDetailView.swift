import SwiftUI

// =============================================================================
// Pitch Atlas — single craftsman record
// =============================================================================
// One arm's archive plate: how they threw it, the edge they pitched with, their
// sourced numbers, a pulled quote, and — for the gyroball legend — a "myth vs
// physics" card that stays flagged, never stated as fact. Every measured value
// renders through its provenance so the figure reads as evidence, not decoration.
// When the signature pitch is a filed specimen, a link drops into the Atlas.
// =============================================================================

struct CraftsmanDetailView: View {
    @Environment(PitchStore.self) private var store
    let craftsman: Craftsman

    private var isLegend: Bool { craftsman.kind == .legend }
    private var filedSpecimen: PitchAtlasEntry? {
        guard let slug = craftsman.signaturePitchSlug else { return nil }
        return store.pitch(slug: slug)
    }

    var body: some View {
        ZStack {
            PitchAtlasTheme.void.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.lg) {
                    header
                    introCard
                    howCard

                    if let edge = craftsman.mentalEdge {
                        edgeCard(edge)
                    }

                    if !craftsman.recordNumbers.isEmpty {
                        numbersSection
                    }

                    if let quote = craftsman.quote {
                        quoteCard(quote)
                    }

                    if let legendNote = craftsman.legendNote {
                        legendCard(legendNote)
                    }

                    if let specimen = filedSpecimen {
                        specimenLink(specimen)
                    }
                }
                .padding(.horizontal, PitchAtlasSpacing.lg)
                .padding(.top, PitchAtlasSpacing.md)
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
            }
        }
        .navigationTitle(craftsman.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: PitchAtlasEntry.self) { PitchDetailView(entry: $0) }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            HStack(alignment: .top) {
                SectionLabel(text: craftsman.specimenNo, color: PitchAtlasTheme.cyanDeep)
                Spacer()
                if isLegend {
                    StatusPill(text: "Legend — flagged", tone: PitchAtlasTheme.sandBright)
                }
            }

            Text(craftsman.name.uppercased())
                .font(PitchAtlasTheme.anton(40))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
                .padding(.vertical, 2)

            HStack(spacing: PitchAtlasSpacing.sm) {
                SectionLabel(text: craftsman.signaturePitch, color: PitchAtlasTheme.cyan, size: 9)
                Text(craftsman.era)
                    .font(PitchAtlasTheme.martian(9))
                    .foregroundStyle(PitchAtlasTheme.ink3)
            }
            .padding(.top, 2)

            Text(craftsman.tagline)
                .font(PitchAtlasTheme.newsreaderItalic(17))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, PitchAtlasSpacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(craftsman.specimenNo). \(craftsman.name). \(craftsman.signaturePitch), \(craftsman.era).\(isLegend ? " Legend, flagged." : "") \(craftsman.tagline)")
    }

    // MARK: - Intro

    private var introCard: some View {
        Text(craftsman.intro)
            .font(PitchAtlasTheme.hanken(16))
            .foregroundStyle(PitchAtlasTheme.bone)
            .fixedSize(horizontal: false, vertical: true)
            .leatherPress()
            .accessibilityElement(children: .combine)
            .accessibilityLabel(craftsman.intro)
    }

    // MARK: - How they threw it

    private var howCard: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "How they threw it")
            ClaimText(claim: craftsman.signature)
        }
        .leatherPress()
        .accessibilityElement(children: .combine)
    }

    // MARK: - The edge

    private func edgeCard(_ edge: Claim) -> some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "The edge")
            ClaimText(claim: edge)
        }
        .leatherPress()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Numbers

    private var numbersSection: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "The Record")
            VStack(spacing: PitchAtlasSpacing.sm) {
                ForEach(Array(craftsman.recordNumbers.enumerated()), id: \.offset) { index, number in
                    GaugeView(label: number.label, claim: number.claim, accent: index == 0)
                }
            }
        }
    }

    // MARK: - Pulled quote

    private func quoteCard(_ quote: Claim) -> some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.md) {
            Text(quote.value)
                .font(PitchAtlasTheme.newsreader(24))
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
            SourceClaimLabel(claim: quote)
        }
        .leatherPress()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quote. \(quote.value)")
    }

    // MARK: - Myth vs physics (legend, flagged)

    private func legendCard(_ legendNote: Claim) -> some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            HStack {
                SectionLabel(text: "Myth vs Physics", color: PitchAtlasTheme.sandBright)
                Spacer()
                StatusPill(text: "Flagged", tone: PitchAtlasTheme.sandBright)
            }
            ClaimText(claim: legendNote)
        }
        .leatherPress()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Filed specimen link

    private func specimenLink(_ specimen: PitchAtlasEntry) -> some View {
        NavigationLink(value: specimen) {
            HStack(spacing: PitchAtlasSpacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    SectionLabel(text: "In the Atlas", color: PitchAtlasTheme.cyanDeep, size: 9)
                    Text("See the filed specimen")
                        .font(PitchAtlasTheme.hankenMedium(16))
                        .foregroundStyle(PitchAtlasTheme.bone)
                }
                Spacer(minLength: PitchAtlasSpacing.xs)
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(PitchAtlasTheme.cyan)
            }
            .leatherPress()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("See the filed specimen for \(craftsman.signaturePitch) in the Atlas")
        .accessibilityAddTraits(.isButton)
    }
}
