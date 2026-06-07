import SwiftUI

// =============================================================================
// Pitch Atlas — Sources (the provenance colophon)
// =============================================================================
// The tab that earns the whole product its line: "Sourced, not corrected."
// It explains the tier dots used everywhere else, states an honest tally drawn
// from the bundle, and lists every source with the date it was last checked.
//
// Freshness is never invented here: the only "as of" is store.sourcesLastChecked,
// computed off the build manifest. Four states are explicit — a decode failure
// shows ErrorStateView, no sources shows EmptyStateView, a search miss shows its
// own empty reason, and the normal path lists the colophon.
// =============================================================================

struct SourcesView: View {
    @Environment(PitchStore.self) private var store
    @State private var query: String = ""

    /// The provenance ladder, top tier to honest gray — the legend for every dot
    /// the app draws. Order matches the contract and the web colophon.
    private let ladder: [ClaimConfidence] = [
        .officialData,
        .pitcherOwnWords,
        .coachObserved,
        .reputableAnalysis,
        .secondhandAttributed,
        .communityFirsthand,
        .unverified
    ]

    private var filteredSources: [Source] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return store.sources }
        let needle = trimmed.lowercased()
        return store.sources.filter {
            $0.label.lowercased().contains(needle)
                || $0.url.lowercased().contains(needle)
        }
    }

    var body: some View {
        ZStack {
            PitchAtlasTheme.void.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xl) {
                    masthead
                    freshnessCard
                    ladderCard
                    tallyLine
                    sourceList
                }
                .padding(.horizontal, PitchAtlasSpacing.lg)
                .padding(.top, PitchAtlasSpacing.lg)
                .padding(.bottom, PitchAtlasSpacing.xl3)
            }
        }
        .navigationTitle("Sources")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Masthead

    private var masthead: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "Provenance")
            Text("SOURCES")
                .font(PitchAtlasTheme.anton(52))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
            Text("Every number wears its confidence. Nothing here is marked right or wrong.")
                .font(PitchAtlasTheme.newsreaderItalic(18))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Provenance. Sources. Every number wears its confidence. Nothing here is marked right or wrong.")
    }

    // MARK: - Freshness (computed, never hardcoded)

    @ViewBuilder
    private var freshnessCard: some View {
        let checked = store.sourcesLastChecked
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            SectionLabel(text: "Sources last checked")
            if checked.isEmpty {
                Text("Not recorded in this build.")
                    .font(PitchAtlasTheme.hanken(14))
                    .foregroundStyle(PitchAtlasTheme.ink3)
            } else {
                Text(checked)
                    .font(PitchAtlasTheme.newsreader(24))
                    .foregroundStyle(PitchAtlasTheme.bone)
            }
            Text("Checked, not auto-refreshed.")
                .font(PitchAtlasTheme.hanken(13))
                .foregroundStyle(PitchAtlasTheme.ink3)
        }
        .leatherPress()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            checked.isEmpty
                ? "Sources last checked. Not recorded in this build. Checked, not auto-refreshed."
                : "Sources last checked \(checked). Checked, not auto-refreshed."
        )
    }

    // MARK: - Provenance ladder (the legend for the dots)

    private var ladderCard: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.md) {
            SectionLabel(text: "The provenance ladder")
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                ForEach(Array(ladder.enumerated()), id: \.element) { index, tier in
                    if index > 0 { HairlineDivider() }
                    ladderRow(tier)
                }
            }
        }
        .leatherPress()
    }

    private func ladderRow(_ tier: ClaimConfidence) -> some View {
        HStack(alignment: .top, spacing: PitchAtlasSpacing.sm) {
            ProvenanceDot(confidence: tier)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs2) {
                Text(tier.label.uppercased())
                    .font(PitchAtlasTheme.martian(10))
                    .tracking(1.4)
                    .foregroundStyle(tier.tierColor)
                Text(tier.meaning)
                    .font(PitchAtlasTheme.hanken(13))
                    .foregroundStyle(PitchAtlasTheme.ink3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tier.label). \(tier.meaning)")
    }

    // MARK: - Honest tally (computed from the store)

    private var tallyLine: some View {
        Text("\(store.sources.count) sources across \(store.pitches.count) filed pitches.")
            .font(PitchAtlasTheme.hankenMedium(14))
            .foregroundStyle(PitchAtlasTheme.bone2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("\(store.sources.count) sources across \(store.pitches.count) filed pitches.")
    }

    // MARK: - Source list (with search + four states)

    @ViewBuilder
    private var sourceList: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.md) {
            SectionLabel(text: "Every source")

            if case .failed(let msg) = store.status {
                ErrorStateView(reason: msg)
            } else if store.sources.isEmpty {
                EmptyStateView(message: "Sources couldn't load.")
            } else {
                searchField

                let results = filteredSources
                if results.isEmpty {
                    EmptyStateView(message: "No sources match \(query).")
                } else {
                    LazyVStack(alignment: .leading, spacing: PitchAtlasSpacing.md) {
                        ForEach(Array(results.enumerated()), id: \.element.id) { index, source in
                            if index > 0 { HairlineDivider() }
                            SourceRow(source: source)
                        }
                    }
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: PitchAtlasSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(PitchAtlasTheme.ink3)
                .accessibilityHidden(true)

            TextField(
                "",
                text: $query,
                prompt: Text("Search by source or link")
                    .foregroundColor(PitchAtlasTheme.ink3)
            )
            .font(PitchAtlasTheme.hanken(15))
            .foregroundStyle(PitchAtlasTheme.bone)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .submitLabel(.search)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(PitchAtlasTheme.ink3)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, PitchAtlasSpacing.sm)
        .padding(.vertical, PitchAtlasSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: PitchAtlasRadius.chip, style: .continuous)
                .fill(PitchAtlasTheme.paper2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: PitchAtlasRadius.chip, style: .continuous)
                .strokeBorder(PitchAtlasTheme.machined, lineWidth: 1)
        )
    }
}
