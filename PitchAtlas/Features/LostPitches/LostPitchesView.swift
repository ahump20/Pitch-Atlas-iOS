import SwiftUI

// =============================================================================
// Pitch Atlas — the Lost Pitches hall
// =============================================================================
// Web: pages/LostPitchesHall.tsx, in its order. The section header on the
// seam's wash, the through-line (why pitches die), the record laid against the
// decades, the image record, then the plates filed by how solid the record is
// (documented anchors first, the legend flagged), the note on why the tiers,
// and the site's footer. Four-state aware: a decode failure shows the error,
// an empty archive says it is being filed.
// =============================================================================

struct LostPitchesView: View {
    @Environment(PitchStore.self) private var store

    var body: some View {
        ZStack {
            FieldBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHero(eyebrow: "The recovered archive",
                                title: Text("Lost Pitches of the Negro Leagues."),
                                sub: Text("The statistics are being recovered; the technique mostly never will be. Filed by how solid the record is: documented anchors first, legend flagged."),
                                trail: [Crumb(label: "The Atlas", path: "home"), Crumb(label: "Lost Pitches")],
                                accent: .seam)
                    content
                    SiteFooter(path: "/lost-pitches")
                }
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                .emitsScrollProgress()
            }
        }
        // The site's header carries the brand on every page; the title still names
        // the back button on the pages this one opens.
        .navigationTitle("Lost Pitches")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { BrandLockup(size: .sm) }
        }
        // Its files open through the Atlas stack's root destination (AtlasView).
    }

    // MARK: - Four states

    @ViewBuilder
    private var content: some View {
        if case .failed(let msg) = store.status {
            ErrorStateView(reason: msg).padding(20)
        } else {
            WhyPitchesDie(forces: store.lostPitches.forces)
            if !store.lostPitches.entries.isEmpty {
                EraTimeline(root: store.lostPitches)
            }
            LostArchiveImageRail(images: store.archiveImages)
            if store.lostPitches.entries.isEmpty {
                // Verbatim, LostPitchesHall.tsx.
                Text("The archive is being filed.")
                    .font(PitchAtlasType.font(.hanken400, size: 18, relativeTo: .title3))
                    .foregroundStyle(PitchAtlasTheme.ink2)
                    .cssLineHeight(28.0 / 18.0, face: .hanken400, size: 18, relativeTo: .title3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 80)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                tiers
            }
        }
    }

    // MARK: - The plates, by tier

    /// Each tier on its marker with what it means, its plates in file order; a
    /// tier with nothing filed under it is left out. Then why the tiers exist.
    private var tiers: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 64) {
                ForEach(LostArchiveReads.tierGroups(store.lostPitches)) { group in
                    VStack(alignment: .leading, spacing: 0) {
                        StageTierMarker(index: group.info.index, label: group.info.label)
                        Text(group.info.note)
                            .font(PitchAtlasType.font(.hanken400, size: 16, relativeTo: .body))
                            .foregroundStyle(PitchAtlasTheme.ink2)
                            .cssLineHeight(1.625, face: .hanken400, size: 16, relativeTo: .body)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 64 * 0.56 * 16, alignment: .leading)
                            .padding(.bottom, 32)
                        // Lazy so each plate builds only as it scrolls into view.
                        LazyVStack(spacing: 20) {
                            ForEach(group.entries) { pitch in
                                NavigationLink(value: pitch) { LostPitchCard(pitch: pitch) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            whyTheTiers.padding(.top, 64)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 80)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The dashed seam note under the plates. Its heading is a hidden note.
    private var whyTheTiers: some View {
        VStack(alignment: .leading, spacing: 8) {
            // The heading sits on its block's 16/24 line, 6 down.
            EggButton(note: .firstNightGame) {
                Text("Why the tiers".uppercased())
                    .font(MonoLabel.font)
                    .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                    .foregroundStyle(PitchAtlasTheme.seamBright)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 6)
            .frame(minHeight: 24, alignment: .top)
            // Verbatim, LostPitchesHall.tsx.
            Text("Segregated record-keeping, almost no surviving film, barnstorming with no institutional archive, doctored pitches that were permitted in Black baseball and banned in the white one, and a culture of self-promotion that turned pitch names into ticket sales: five forces erased the technical record. The tier on each plate is how we stay honest about which of those forces we beat and which we did not.")
                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.ink2)
                .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 68 * 0.56 * 14, alignment: .leading)
        }
        .padding(25)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(PitchAtlasTheme.seamBright.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }
}
