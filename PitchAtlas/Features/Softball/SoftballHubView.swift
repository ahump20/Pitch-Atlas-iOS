import SwiftUI

// =============================================================================
// SoftballHubView — the front door to the softball wing
// =============================================================================
// Web: pages/SoftballHub.tsx. A soft launch, and it says so: 00 "Start here" (the
// windmill, slowpitch, the flight lab), 01 the fastpitch arsenal, 02 the craftsmen
// of the circle. Every pitch and craftsman file is one tap from here. The Flight
// Lab opens on the site until the app files it.
// =============================================================================

struct SoftballHubView: View {
    @Environment(PitchStore.self) private var store

    var body: some View {
        ZStack {
            FieldBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHero(eyebrow: "The circle · soft launch",
                                title: Text("Softball enters the atlas."),
                                sub: Text(SoftballReads.hubSub),
                                trail: [Crumb(label: "The Atlas", path: "home"), Crumb(label: "Softball")])
                    section("00", "Start here", lede: nil) {
                        NavigationLink(value: AtlasRoute.fastpitch) {
                            SoftballStartPlate(eyebrow: "Fastpitch · fundamentals", title: "The windmill, from the ground up",
                                               blurb: store.softball.hubFastpitchBlurb, accent: PitchAtlasTheme.cyan)
                        }
                        .buttonStyle(.plain)
                        NavigationLink(value: AtlasRoute.slowpitch) {
                            SoftballStartPlate(eyebrow: "Slowpitch · arc and touch", title: "Arc, spin, and placement",
                                               blurb: SoftballReads.slowpitchBlurb, accent: PitchAtlasTheme.seamBright)
                        }
                        .buttonStyle(.plain)
                        NavigationLink(value: AtlasRoute.flightLab(rule: .usssa)) {
                            SoftballStartPlate(eyebrow: "Slowpitch · flight lab", title: "Your zone, at your height",
                                               blurb: SoftballReads.flightLabBlurb, accent: Color(web: WebTokens.Palette.amberBright))
                        }
                        .buttonStyle(.plain)
                    }
                    section("01", "The fastpitch arsenal", lede: SoftballReads.arsenalLede) {
                        ForEach(store.softball.pitches) { pitch in
                            NavigationLink(value: AtlasRoute.softballPitch(slug: pitch.slug)) { SoftballPitchPlate(pitch: pitch) }
                                .buttonStyle(.plain)
                        }
                    }
                    section("02", "The craftsmen of the circle", lede: SoftballReads.craftsmenLede) {
                        ForEach(store.softball.craftsmen) { craftsman in
                            NavigationLink(value: AtlasRoute.softballCraftsman(slug: craftsman.slug)) {
                                SoftballCraftsmanPlate(craftsman: craftsman)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    SiteFooter(path: "/softball")
                }
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                .emitsScrollProgress()
            }
        }
        .navigationTitle("Softball")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { BrandLockup(size: .sm) }
        }
    }

    private func section<Content: View>(_ index: String, _ label: String, lede: String?,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            StageTierMarker(index: index, label: label)
            if let lede {
                SoftballProse(text: lede, size: 16, ink: PitchAtlasTheme.ink2).padding(.bottom, 32)
            }
            VStack(spacing: 16) { content() }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 64)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - The plates

/// The plate's title: `.rfx-platetitle` under text-2xl, 24 on a 32 line.
private struct PlateTitle: View {
    let text: String
    var body: some View {
        TightLines(text.uppercased(), face: .anton400, size: 24, lineHeight: 32.0 / 24.0, relativeTo: .title2, trackingEm: 0.01)
            .foregroundStyle(PitchAtlasTheme.bone)
    }
}

/// The plate's foot: a hairline, then "Open →" (or the file line) in cyan.
private struct PlateOpen<Leading: View>: View {
    var text = "Open →"
    @ViewBuilder var leading: Leading
    var body: some View {
        HStack(spacing: 12) {
            leading
            Spacer(minLength: 0)
            PlateMono(text, ink: PitchAtlasTheme.cyan)
        }
        .padding(.top, 13)
        .overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.10)).frame(height: 1) }
    }
}

private struct PlateBlurb: View {
    let text: String
    var lines: Int?
    var body: some View {
        Text(text)
            .font(PitchAtlasType.body(size: 15))
            .lineSpacing(6)
            .foregroundStyle(PitchAtlasTheme.bone2)
            .lineLimit(lines)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct SoftballStartPlate: View {
    let eyebrow: String
    let title: String
    let blurb: String
    let accent: Color
    var open = "Open →"

    var body: some View {
        Plate(accent: accent, variant: .edge) {
            PlateMono(eyebrow, ink: accent)
            PlateTitle(text: title)
            PlateBlurb(text: blurb)
            PlateOpen(text: open) { EmptyView() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(eyebrow). \(title). \(blurb)")
        .accessibilityAddTraits(.isButton)
    }
}

struct SoftballPitchPlate: View {
    let pitch: SoftballPitch

    var body: some View {
        let accent = SoftballReads.accent(pitch.slug)
        let family = SoftballReads.familyLabel(pitch.family)
        let row = SoftballReads.provenance("Movement", claim: pitch.movement, openQuestion: pitch.openQuestion)
        Plate(accent: accent, variant: pitch.flagship == true ? .edge : .standard) {
            HStack(spacing: 12) {
                PlateMono("\(family) · \(pitch.specimenNo)", ink: accent)
                Spacer(minLength: 0)
                if pitch.flagship == true { PlateMono("Flagship", ink: Color(web: WebTokens.Palette.powder)) }
            }
            PlateTitle(text: pitch.name)
            PlateBlurb(text: pitch.tagline, lines: 3)
            VStack(alignment: .leading, spacing: 8) {
                SoftballProvenanceRow(line: row)
                HStack { Spacer(minLength: 0); PlateMono("Open →", ink: PitchAtlasTheme.cyan) }
            }
            .padding(.top, 13)
            .overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.10)).frame(height: 1) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(family), \(pitch.specimenNo)\(pitch.flagship == true ? ", flagship" : ""). \(pitch.name). \(pitch.tagline) \(row)")
        .accessibilityAddTraits(.isButton)
    }
}

struct SoftballCraftsmanPlate: View {
    let craftsman: Craftsman

    var body: some View {
        Plate(accent: SoftballReads.accent(craftsman.signaturePitchSlug)) {
            HStack(spacing: 12) {
                PlateMono("Master · \(craftsman.specimenNo)", ink: Color(web: WebTokens.Palette.powder))
                Spacer(minLength: 0)
                PlateMono(craftsman.era, ink: PitchAtlasTheme.text3)
            }
            VStack(alignment: .leading, spacing: 4) {
                PlateTitle(text: craftsman.name)
                PlateMono(craftsman.signaturePitch, ink: PitchAtlasTheme.bone2)
            }
            PlateBlurb(text: craftsman.tagline, lines: 3)
            HStack(spacing: 12) {
                PlateMono("Open the file →", ink: PitchAtlasTheme.cyan)
                if let hand = craftsman.hand {
                    Text("·").foregroundStyle(PitchAtlasTheme.text3).accessibilityHidden(true)
                    PlateMono("\(hand.rawValue.capitalized)-handed", ink: PitchAtlasTheme.text3)
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 13)
            .overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.10)).frame(height: 1) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Master, \(craftsman.specimenNo), \(craftsman.era). \(craftsman.name), \(craftsman.signaturePitch). \(craftsman.tagline)")
        .accessibilityAddTraits(.isButton)
    }
}

/// SoftballProvenanceRow: mono 10, capitals, tracked .08em, ink-3; the claim type
/// and the tier in bone-2.
struct SoftballProvenanceRow: View {
    let line: String

    var body: some View {
        let parts = line.components(separatedBy: " · ")
        parts.enumerated().reduce(Text("")) { text, item in
            let piece = Text(item.element.uppercased())
                .foregroundColor(item.offset < 2 ? PitchAtlasTheme.bone2 : PitchAtlasTheme.ink3)
            return item.offset == 0 ? piece : text + Text(" · ").foregroundColor(PitchAtlasTheme.ink3) + piece
        }
        .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
        .tracking(em: 0.08, size: 10)
        .lineSpacing(5)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel(line)
    }
}

/// Body prose at the site's measure.
struct SoftballProse: View {
    let text: String
    var size: CGFloat = 18
    var ink: Color = PitchAtlasTheme.bone
    var measure: CGFloat = 64

    var body: some View {
        Text(text)
            .font(PitchAtlasType.font(.hanken400, size: size, relativeTo: size >= 18 ? .title3 : .body))
            .foregroundStyle(ink)
            .cssLineHeight(1.625, face: .hanken400, size: size, relativeTo: size >= 18 ? .title3 : .body)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: measure * 0.56 * size, alignment: .leading)
    }
}
