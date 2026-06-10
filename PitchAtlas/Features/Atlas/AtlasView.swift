import SwiftUI

// =============================================================================
// AtlasView: the home surface
// =============================================================================
// The brand showcase and the hub: the holographic wordmark, a featured native
// specimen, the filed-specimen rail, entry points to the wings that are not tabs
// (Learn, Lost Pitches, About), the provenance ladder, and the computed freshness
// line. The one place the foil gradient is allowed to sing.
// =============================================================================

struct AtlasView: View {
    @Environment(PitchStore.self) private var store

    private let ladder: [ClaimConfidence] = [
        .officialData, .pitcherOwnWords, .coachObserved,
        .reputableAnalysis, .secondhandAttributed, .unverified,
    ]

    var body: some View {
        ZStack {
            PitchAtlasTheme.void.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xl) {
                    masthead
                    if case .failed(let msg) = store.status {
                        ErrorStateView(reason: msg)
                    }
                    if !store.pitches.isEmpty { filedRail }
                    wings
                    provenanceLadder
                }
                .padding(PitchAtlasSpacing.lg)
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
            }
        }
        .navigationTitle("Atlas")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: PitchAtlasEntry.self) { PitchDetailView(entry: $0) }
    }

    // MARK: Masthead

    private var masthead: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "THE FIELD MANUAL", color: PitchAtlasTheme.cyanDeep)

            HoloWordmark(text: "PITCH\nATLAS", size: 56)

            Text("Sourced, not corrected.")
                .font(PitchAtlasTheme.newsreaderItalic(19))
                .foregroundStyle(PitchAtlasTheme.bone2)

            if let featured = store.pitches.first {
                NavigationLink(value: featured) {
                    // Real footage leads the masthead when the featured specimen
                    // carries a film; the drawn ball is the fallback face.
                    if let film = featured.canonical.gripFilm {
                        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
                            GripFilmCard(film: film, height: 380,
                                         offersMotionControl: false, showsCaption: false)
                            HStack {
                                Text(featured.canonical.name.uppercased())
                                    .font(PitchAtlasTheme.martian(10))
                                    .tracking(2)
                                    .foregroundStyle(PitchAtlasTheme.cyan)
                                Spacer()
                                SectionLabel(text: "Open the specimen", size: 10)
                            }
                        }
                    } else {
                        VStack(spacing: PitchAtlasSpacing.xs) {
                            SeamBall(motion: featured.motion, size: 220)
                                .frame(maxWidth: .infinity)
                            Text(featured.canonical.name.uppercased())
                                .font(PitchAtlasTheme.martian(10))
                                .tracking(2)
                                .foregroundStyle(PitchAtlasTheme.cyan)
                            SectionLabel(text: "Tap the specimen", size: 10)
                        }
                        .padding(.vertical, PitchAtlasSpacing.md)
                        .frame(maxWidth: .infinity)
                        .leatherPress(padding: PitchAtlasSpacing.lg)
                        .foilRake()
                    }
                }
                .buttonStyle(.plain)
            }

            BlazeInlineCompanionView(style: .atlas, mood: .sniffing)

            Text("How every pitch is gripped and thrown. The index, filed specimens, grip library, craftsmen, and lost pitches are bundled with sources; community opens when you sign in.")
                .font(PitchAtlasTheme.hanken(16))
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Filed specimens rail

    private var filedRail: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "FILED SPECIMENS")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PitchAtlasSpacing.md) {
                    ForEach(store.pitches) { entry in
                        NavigationLink(value: entry) {
                            VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
                                // The owner's real hand fronts the tile where a
                                // still is on file; the drawn ball is the fallback.
                                if let still = entry.canonical.realStill {
                                    BundledImage(src: still.src, alt: still.alt)
                                        .frame(height: 110)
                                        .frame(maxWidth: .infinity)
                                        .clipShape(RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous)
                                                .strokeBorder(PitchAtlasTheme.machined, lineWidth: 1)
                                        )
                                } else {
                                    SeamBall(motion: entry.motion, size: 110)
                                }
                                HStack(spacing: PitchAtlasSpacing.xs) {
                                    FamilyDot(color: entry.canonical.family.accent)
                                    Text(entry.display.shortName)
                                        .font(PitchAtlasTheme.hankenMedium(14))
                                        .foregroundStyle(PitchAtlasTheme.bone)
                                }
                                SectionLabel(text: entry.display.specimenNo, color: PitchAtlasTheme.cyanDeep, size: 8)
                            }
                            .frame(width: 130, alignment: .leading)
                            .leatherPress(padding: PitchAtlasSpacing.sm, radius: PitchAtlasRadius.tile)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, PitchAtlasSpacing.xs2)
            }
        }
    }

    // MARK: Wings (non-tab entry points)

    private var wings: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "WINGS")
            NavigationLink { LearnView() } label: {
                wingRow(title: "The Field Manual", sub: "Sourced teaching across \(store.knowledge.count) wings", tone: PitchAtlasTheme.cyan)
            }.buttonStyle(.plain)
            NavigationLink { LostPitchesView() } label: {
                wingRow(title: "Lost Pitches", sub: "The Negro Leagues wing. The tier is the feature", tone: PitchAtlasTheme.sandBright)
            }.buttonStyle(.plain)
            NavigationLink { AboutView() } label: {
                wingRow(title: "About the Atlas", sub: "How it stays honest", tone: PitchAtlasTheme.ink3)
            }.buttonStyle(.plain)
            NavigationLink { AccountView() } label: {
                wingRow(title: "Account and Safety", sub: "Sign in, report, block, support, and delete account", tone: PitchAtlasTheme.amberBright)
            }.buttonStyle(.plain)
        }
    }

    private func wingRow(title: String, sub: String, tone: Color) -> some View {
        HStack(spacing: PitchAtlasSpacing.sm) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(PitchAtlasTheme.newsreader(18))
                    .foregroundStyle(PitchAtlasTheme.bone)
                Text(sub)
                    .font(PitchAtlasTheme.hanken(13))
                    .foregroundStyle(PitchAtlasTheme.ink3)
            }
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tone)
        }
        .leatherPress()
    }

    // MARK: The grading scale (provenance ladder + freshness, on a card back)

    /// The confidence model, printed where a real set prints its data: on the
    /// cream card back. The five real tiers ARE the grades — no invented
    /// grading vocabulary — and the freshness line closes the panel the way
    /// fine print closes a physical card back.
    private var provenanceLadder: some View {
        CardBackPanel {
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                CardBackRules(title: "The grading scale ★ sourced, not corrected")

                ForEach(ladder, id: \.self) { tier in
                    let ink = PitchAtlasTheme.cardbackColor(forConfidence: tier.rawValue)
                    HStack(alignment: .top, spacing: PitchAtlasSpacing.sm) {
                        Circle()
                            .fill(ink)
                            .frame(width: 9, height: 9)
                            .padding(.top, 3)
                        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs2) {
                            Text(tier.label)
                                .font(PitchAtlasTheme.martian(9))
                                .tracking(1)
                                .foregroundStyle(ink)
                            Text(tier.meaning)
                                .font(PitchAtlasTheme.hanken(12))
                                .foregroundStyle(PitchAtlasTheme.cardbackInk2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.bottom, PitchAtlasSpacing.xs)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(PitchAtlasTheme.cardbackLine).frame(height: 1)
                    }
                }

                // the card-back fine print: the computed freshness, never a fake "live"
                VStack(alignment: .leading, spacing: 2) {
                    Text("SOURCES LAST CHECKED \(store.sourcesLastChecked.isEmpty ? "—" : store.sourcesLastChecked)")
                        .font(PitchAtlasTheme.martian(8))
                        .tracking(1)
                        .foregroundStyle(PitchAtlasTheme.cardbackInk3)
                    Text("Checked, not auto-refreshed.")
                        .font(PitchAtlasTheme.hanken(11))
                        .foregroundStyle(PitchAtlasTheme.cardbackInk3)
                }
                .padding(.top, PitchAtlasSpacing.xs)
            }
        }
    }
}
