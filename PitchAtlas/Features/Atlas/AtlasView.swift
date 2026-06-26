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
            FieldBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xl) {
                    masthead
                    if case .failed(let msg) = store.status {
                        ErrorStateView(reason: msg)
                    } else if store.pitches.isEmpty {
                        // Four-state honesty: a legitimately empty bundle says so,
                        // rather than leaving the rail silently absent.
                        EmptyStateView(message: "No filed specimens shipped in this build yet. The index, grips, and craftsmen are still here.")
                    }
                    if !store.pitches.isEmpty { filedRail }
                    wings
                    provenanceLadder
                }
                .padding(PitchAtlasSpacing.lg)
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                .emitsBlazeScrollProgress()
            }
        }
        .navigationTitle("Atlas")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: PitchAtlasEntry.self) { PitchDetailView(entry: $0) }
    }

    // MARK: Masthead

    private var masthead: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.md) {
            HStack(alignment: .center, spacing: PitchAtlasSpacing.sm) {
                BrandSealMark(size: 62)
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs2) {
                    SectionLabel(text: "THE LIVING FIELD MANUAL", color: PitchAtlasTheme.powder)
                    Text("Sourced, not corrected.")
                        .font(PitchAtlasTheme.newsreaderItalic(18))
                        .foregroundStyle(PitchAtlasTheme.bone2)
                }
            }

            HoloWordmark(text: "PITCH\nATLAS", size: 48, lineSpacing: -8)
                .padding(.leading, PitchAtlasSpacing.sm)

            VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                Text("The pitch, struck as a specimen.")
                    .font(PitchAtlasTheme.newsreader(27))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .fixedSize(horizontal: false, vertical: true)

                Text("A grip-first archive for pitches, variants, feel cues, forgotten experiments, master examples, and field notes.")
                    .font(PitchAtlasTheme.hanken(15))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)

                archivePillRow
            }

            if let featured = store.pitches.first {
                NavigationLink(value: featured) {
                    PitchSpecimenCard(entry: featured, style: .hero)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Open the featured specimen, \(featured.canonical.name)")
                .accessibilityAddTraits(.isButton)
            }

            BlazeInlineCompanionView(style: .atlas, mood: .sniffing)

            Text("How pitches are gripped and thrown. Sources stay visible. Community opens when you sign in.")
                .font(PitchAtlasTheme.hanken(16))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var archivePillRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PitchAtlasSpacing.xs) {
                archivePill("Grip first", tone: PitchAtlasTheme.cyan)
                archivePill("Source attached", tone: PitchAtlasTheme.powder)
                archivePill("No fake certainty", tone: PitchAtlasTheme.seamBright)
            }
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
                HStack(spacing: PitchAtlasSpacing.xs) {
                    archivePill("Grip first", tone: PitchAtlasTheme.cyan)
                    archivePill("Source attached", tone: PitchAtlasTheme.powder)
                }
                archivePill("No fake certainty", tone: PitchAtlasTheme.seamBright)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func archivePill(_ text: String, tone: Color) -> some View {
        HStack(spacing: PitchAtlasSpacing.xs2) {
            Circle()
                .fill(tone)
                .frame(width: 6, height: 6)
                .accessibilityHidden(true)
            Text(text.uppercased())
                .font(PitchAtlasTheme.martian(8))
                .tracking(0.8)
                .foregroundStyle(PitchAtlasTheme.bone2)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, PitchAtlasSpacing.xs)
        .padding(.vertical, 6)
        .background(PitchAtlasTheme.void.opacity(0.82), in: Capsule())
        .overlay(Capsule().strokeBorder(PitchAtlasTheme.machined, lineWidth: 1))
    }

    // MARK: Filed specimens rail

    private var filedRail: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "FILED SPECIMENS")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PitchAtlasSpacing.md) {
                    ForEach(store.pitches) { entry in
                        NavigationLink(value: entry) {
                            PitchSpecimenCard(entry: entry, style: .rail)
                                .frame(width: 156, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Open specimen \(entry.display.specimenNo), \(entry.display.shortName)")
                        .accessibilityAddTraits(.isButton)
                    }
                }
                .padding(.vertical, PitchAtlasSpacing.xs2)
                .accessibilityLabel("Filed specimens, horizontally scrollable")
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

                // the card-back fine print: the computed freshness, never a fake
                // "live". A missing date says so plainly — a bare dash hides the gap.
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.sourcesLastChecked.isEmpty
                         ? "SOURCES LAST-CHECKED DATE NOT RECORDED IN THIS BUILD"
                         : "SOURCES LAST CHECKED \(store.sourcesLastChecked)")
                        .font(PitchAtlasTheme.martian(8))
                        .tracking(1)
                        .foregroundStyle(PitchAtlasTheme.cardbackInk3)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Checked, not auto-refreshed.")
                        .font(PitchAtlasTheme.hanken(11))
                        .foregroundStyle(PitchAtlasTheme.cardbackInk3)
                }
                .padding(.top, PitchAtlasSpacing.xs)
            }
        }
    }
}
