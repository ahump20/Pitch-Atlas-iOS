import SwiftUI

// =============================================================================
// Pitch Atlas — Sources, the colophon
// =============================================================================
// Web: pages/SourcesPage.tsx, in its order and words. Where you are, the room's
// marker, the headline and what the labels are for, then the "as of": the
// newest retrievedAt across the whole colophon, never a hardcoded freshness.
// How to read a claim, with the seven tiers strongest to weakest; the citation
// registry, the specimen sources in their filed order and then what the
// teaching wings cite that the registry lacks; the rights line. A search over
// the registry is the app's one addition. Four states: a decode failure, no
// sources, a search that misses, the registry.
// =============================================================================

struct SourcesView: View {
    @Environment(PitchStore.self) private var store
    @State private var query = ""

    var body: some View {
        let colophon = SourceRegistry.colophon(registry: store.sources, wings: store.knowledge)
        ZStack {
            FieldBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    page(colophon)
                    SiteFooter(path: "/sources")
                }
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                .emitsScrollProgress()
            }
            .scrollDismissesKeyboard(.interactively)
        }
        // The site's header carries the brand on every page; the title still names
        // the back button on the pages this one opens.
        .navigationTitle("Sources")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { BrandLockup(size: .sm) }
        }
    }

    /// `mx-auto max-w-6xl px-5 py-16`
    private func page(_ colophon: [Source]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Breadcrumb(trail: [Crumb(label: "The Atlas", path: "home"), Crumb(label: "Sources")])
                .padding(.bottom, 24)
            StageTierMarker(index: "04", label: "Sources")
            SectionTitle(text: "Every voice keeps its trail.", measure: 18, size: 36, lineHeight: 1.04)
            PageProse(text: SourcesCopy.lede, size: 18, measure: 58).padding(.top, 20)
            asOf(colophon).padding(.top, 24)
            legend.padding(.top, 56)
            registry(colophon).padding(.top, 48)
            // `mt-14 border-t border-ink/15 pt-8`
            PageProse(text: SourcesCopy.rights, size: 14, measure: 72)
                .padding(.top, 1 + 32)
                .overlay(alignment: .top) { PageInk.rule.frame(height: 1).accessibilityHidden(true) }
                .padding(.top, 56)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 64)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - As of (computed, never hardcoded)

    /// `.mono-label`: the date in bone and in its own case, as the site's
    /// button keeps it (preflight's text-transform: none).
    private func asOf(_ colophon: [Source]) -> some View {
        let date = SourceRegistry.latestRetrievedAt(colophon).map(AsOf.format)
        let tail = "Sources last checked, not auto-refreshed."
        let line = date.map { Text("AS OF ") + Text($0).foregroundStyle(PitchAtlasTheme.bone) + Text(". " + tail.uppercased()) }
            ?? Text(("Not recorded in this build. " + tail).uppercased())
        return line
            .font(MonoLabel.font)
            .tracking(MonoLabel.trackingEm * MonoLabel.size)
            .foregroundStyle(PitchAtlasTheme.ink2)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(date.map { "As of \($0). \(tail)" } ?? "Not recorded in this build. \(tail)")
    }

    // MARK: - How to read a claim

    private var legend: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionKick(text: "How to read a claim")
            PageProse(text: SourcesCopy.howToRead, size: 14, ink: PageInk.legend, measure: 46)
                .padding(.top, 24)
            VStack(alignment: .leading, spacing: 16) {
                ForEach(SourcesCopy.legendOrder, id: \.self) { tier in
                    VStack(alignment: .leading, spacing: 4) {
                        ConfidenceLabel(confidence: tier)
                        PageProse(text: tier.meaning, size: 14, ink: PageInk.legend, measure: 44, leading: 1.375)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.top, 24)
            approximateNote.padding(.top, 24)
        }
    }

    /// The approximate sign, and how faithful the seam render is (the seam
    /// reference any filed pitch carries).
    @ViewBuilder
    private var approximateNote: some View {
        let lead = Text("A value marked with a leading approximate sign is rounded, era-dependent, or methodology-bound.")
        let note: Text = store.pitches.first.map { pitch in
            lead + Text(" The seam render is a \(pitch.seam.accuracyLevel.rawValue), documented in ")
                + Text(pitch.seam.calibrationDoc)
                    .font(PitchAtlasType.font(.martian400, size: 14, relativeTo: .subheadline))
                    .foregroundStyle(PitchAtlasTheme.ink2)
                + Text(".")
        } ?? lead
        note
            .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
            .foregroundStyle(PageInk.legend)
            .cssLineHeight(1.375, face: .hanken400, size: 14, relativeTo: .subheadline)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 46 * 0.56 * 14, alignment: .leading)
    }

    // MARK: - The citation registry (with search and four states)

    private func registry(_ colophon: [Source]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionKick(text: "The citation registry")
            Group {
                if case .failed(let message) = store.status {
                    ErrorStateView(reason: message)
                } else if colophon.isEmpty {
                    EmptyStateView(message: "No sources ship in this build.")
                } else {
                    VStack(alignment: .leading, spacing: 24) {
                        PitchSearchField(text: $query, prompt: "Search by source or link")
                        let shown = SourcesCopy.matches(colophon, query: query)
                        if shown.isEmpty {
                            EmptyStateView(message: "No sources match \(query).")
                        } else {
                            // `gap-y-[34px]` on a coarse pointer
                            LazyVStack(alignment: .leading, spacing: 34) {
                                ForEach(Array(shown.enumerated()), id: \.offset) { _, source in
                                    RegistryEntry(source: source)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.top, 24)
        }
    }
}

/// SourceBadge with `wrapLabel`: the whole credential wraps instead of cutting
/// at 26 characters — mono 12 at leading-relaxed, tracked .18em, its season at
/// 70%, the outbound arrow, underlined in ink-3 at 40%. A 44pt target.
private struct RegistryEntry: View {
    let source: Source

    var body: some View {
        let season = source.season.map { Text(" / \($0)".uppercased()).foregroundStyle(PitchAtlasTheme.ink2.opacity(0.7)) }
        let credential = (Text(source.label.uppercased()) + (season ?? Text("")) + Text(" ↗\u{FE0E}"))
            .font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .caption))
            .tracking(MonoLabel.trackingEm * 12)
            .foregroundStyle(PitchAtlasTheme.ink2)
            .underline(true, color: PitchAtlasTheme.ink3.opacity(0.4))
        let label = credential
            .cssLineHeight(1.625, face: .martian400, size: 12, relativeTo: .caption)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 17)
            .contentShape(Rectangle())
            .padding(.vertical, -17)
        if let url = URL(string: source.url) {
            Link(destination: url) { label }
                .accessibilityLabel(source.label + (source.season.map { ", \($0)" } ?? ""))
                .accessibilityHint("Opens the source outside the app")
        } else {
            label
        }
    }
}

/// SourcesPage.tsx's words, and the registry's search.
enum SourcesCopy {
    /// LEGEND_ORDER: strongest to weakest.
    static let legendOrder: [ClaimConfidence] = [
        .officialData, .reputableAnalysis, .secondhandAttributed, .pitcherOwnWords,
        .coachObserved, .communityFirsthand, .unverified,
    ]

    static let lede = "Pitching knowledge travels through official records, pitchers, coaches, analysts, historians, and the community. Every claim is labeled by where it came from and how confident that source is, so those voices can share one museum without losing their context."

    /// The site says "on the site"; in here it is the atlas.
    static let howToRead = "Every claim in the atlas wears one of seven badges, strongest to weakest. The badge is the point: official tracking context and a coaching cue from a blog can both belong here, but they do not look the same. Each claim was checked against the source it cites before it shipped; what a source could not support is shown as unverified, not hidden."

    static let rights = "Original geometry, diagrams, and words. Real grip photos ship only from clean sources: our own photography, community own-grip uploads, and verified Creative Commons or public-domain images with attribution; never an unlicensed agency photo, a team or league mark, or broadcast footage. Instructional text is paraphrased and cited, never copied. No runtime API calls: every figure here is static and sourced in the repository."

    /// A source matches when its name or its link holds the query, any case.
    static func matches(_ sources: [Source], query: String) -> [Source] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return sources }
        return sources.filter { $0.label.lowercased().contains(needle) || $0.url.lowercased().contains(needle) }
    }
}
