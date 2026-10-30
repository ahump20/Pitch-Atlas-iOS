import SwiftUI

// =============================================================================
// The softball wing's two pages: fastpitch fundamentals and slowpitch
// =============================================================================
// Web: pages/SoftballFastpitchPage.tsx (the windmill's four phases, the
// fundamentals blocks, the way back to the wing) and SoftballSlowpitchPage.tsx
// (01–04: the rule, the craft, men's and coed, the flight lab). Every claim wears
// its source; the copy the site hard-codes is verbatim in SoftballReads.
// =============================================================================

struct SoftballFastpitchView: View {
    @Environment(PitchStore.self) private var store

    var body: some View {
        let copy = store.softball.fastpitchCopy
        SoftballPage(title: "Fastpitch") {
            SectionHero(eyebrow: "Fastpitch · fundamentals",
                        title: Text("The windmill, from the ground up."),
                        sub: Text(copy.heroSub),
                        trail: SoftballReads.trail("Fastpitch"))
            SoftballRoom(index: "01", label: "The windmill, in four phases") {
                SoftballProse(text: copy.phaseLede, size: 16, ink: PitchAtlasTheme.ink2).padding(.bottom, 40)
                VStack(alignment: .leading, spacing: 40) {
                    ForEach(store.softball.windmillPhases) { phase in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(phase.num)
                                    .font(PitchAtlasType.font(.martian500, size: 14, relativeTo: .footnote))
                                    .monospacedDigit()
                                    .foregroundStyle(PitchAtlasTheme.bone)
                                Text(phase.name.uppercased())
                                    .font(PitchAtlasType.font(.anton400, size: 20, relativeTo: .title3))
                                    .tracking(em: 0.025, size: 20)
                                    .foregroundStyle(PitchAtlasTheme.bone)
                                    .accessibilityAddTraits(.isHeader)
                            }
                            ClaimProse(claim: phase.what)
                        }
                        .padding(.top, 16)
                        .overlay(alignment: .top) { PitchAtlasTheme.bone.opacity(0.15).frame(height: 1) }
                    }
                }
            }
            ForEach(store.softball.fundamentalBlocks) { block in
                SoftballRoom(index: block.index, label: block.label) {
                    SoftballProse(text: block.lede,
                                  ink: block.educational == true ? PitchAtlasTheme.seamBright.opacity(0.9) : PitchAtlasTheme.ink2,
                                  measure: 68)
                        .padding(.bottom, 40)
                    VStack(alignment: .leading, spacing: 32) {
                        ForEach(Array(block.claims.enumerated()), id: \.offset) { _, claim in ClaimProse(claim: claim) }
                    }
                }
            }
            SoftballPanel(text: SoftballReads.fastpitchNext) {
                NavigationLink(value: AtlasRoute.softball) { SoftballSeamButton(title: "The softball wing") }
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 80)
            SiteFooter(path: "/softball/fastpitch")
        }
    }
}

struct SoftballSlowpitchView: View {
    @Environment(PitchStore.self) private var store

    var body: some View {
        SoftballPage(title: "Slowpitch") {
            SectionHero(eyebrow: "Slowpitch · arc and touch",
                        title: Text("Arc, spin, and placement."),
                        sub: Text(SoftballReads.slowpitchSub),
                        trail: SoftballReads.trail("Slowpitch"),
                        accent: .seam)
            SoftballRoom(index: "01", label: "The rule that shapes it") {
                VStack(alignment: .leading, spacing: 36) {
                    ForEach(store.softball.slowpitchNotes, id: \.label) { note in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(note.label.uppercased())
                                .font(MonoLabel.font)
                                .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                                .foregroundStyle(PitchAtlasTheme.ink2)
                                .accessibilityAddTraits(.isHeader)
                            ClaimProse(claim: note.claim, size: 18, ink: PitchAtlasTheme.bone)
                        }
                    }
                }
            }
            SoftballRoom(index: "02", label: "The craft that is left") {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(store.softball.slowpitchCraft, id: \.self) { SoftballProse(text: $0, measure: 68) }
                }
            }
            SoftballRoom(index: "03", label: "Men’s and coed") {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(store.softball.slowpitchFormats, id: \.self) { SoftballProse(text: $0) }
                }
                SoftballProse(text: SoftballReads.slowpitchHonest, size: 14, ink: PitchAtlasTheme.ink2, measure: 78)
                    .padding(.top, 24)
                    .overlay(alignment: .top) { PitchAtlasTheme.bone.opacity(0.15).frame(height: 1) }
                    .padding(.top, 40)
            }
            SoftballRoom(index: "04", label: "See your zone at your height") {
                SoftballProse(text: SoftballReads.slowpitchZone).padding(.bottom, 32)
                if let url = SoftballReads.flightLabURL {
                    Link(destination: url) {
                        SoftballStartPlate(eyebrow: "Slowpitch · flight lab", title: "Your zone, at your height",
                                           blurb: SoftballReads.slowpitchLabBlurb, accent: PitchAtlasTheme.cyan,
                                           open: "Open the lab ↗\u{FE0E}")
                    }
                    .accessibilityHint("Opens in Safari")
                }
            }
            SiteFooter(path: "/softball/slowpitch")
        }
    }
}

// MARK: - The wing's page kit

/// A softball page: the field, the scroll, the brand in the bar.
struct SoftballPage<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            FieldBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) { content }
                    .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                    .emitsScrollProgress()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { BrandLockup(size: .sm) }
        }
    }
}

/// A numbered room: the stage tier marker over its content, at the site's 64 rhythm.
struct SoftballRoom<Content: View>: View {
    let index: String
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StageTierMarker(index: index, label: label)
            content
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 64)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// `.rfx-panel` with a line and one way on.
struct SoftballPanel<Action: View>: View {
    let text: String
    @ViewBuilder var action: Action

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SoftballProse(text: text, size: 16, ink: PitchAtlasTheme.bone2, measure: 52)
            action
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { PanelSurface(radius: 2) }
        .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(PitchAtlasTheme.bone.opacity(0.15), lineWidth: 1))
    }
}

/// The seam-ruled mono button ("The softball wing →", "Study the riseball →").
struct SoftballSeamButton: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
            Text("→").accessibilityHidden(true)
        }
        .font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .caption))
        .tracking(em: 0.12, size: 12)
        .foregroundStyle(PitchAtlasTheme.seamBright)
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
        .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(PitchAtlasTheme.seamBright.opacity(0.6), lineWidth: 1))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}
