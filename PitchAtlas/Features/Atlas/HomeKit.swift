import SwiftUI

// =============================================================================
// HomeKit — the pieces the home's chapters share
// =============================================================================
// Web: src/styles/world.css (.archive-eyebrow, .archive-text-link), the v2 stage
// (index.css .v2-stage, .v2-display) and motion/Descent.tsx. A route button opens
// a pitch-atlas.com path through the deep-link router, so a door on the home and
// the same address arriving from outside the app land in the same place.
// =============================================================================

/// `.archive-eyebrow`: mono micro-caps, tracked .13em.
struct ArchiveEyebrow: View {
    let text: String
    let ink: Color
    var size: CGFloat = 10

    var body: some View {
        Text(text.uppercased())
            .font(PitchAtlasType.font(.martian400, size: size, relativeTo: .caption2))
            .tracking(size * 0.13)
            .foregroundStyle(ink)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// `.archive-text-link`: the prose link, underlined in muted gold, with its arrow.
struct ArchiveLinkLabel: View {
    let title: String
    var arrow = "→"
    let ink: Color
    var size: CGFloat = 15

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(title)
                .underline(true, color: ArchiveInk.textLinkUnderline)
                .fixedSize(horizontal: false, vertical: true)
            Text(arrow).accessibilityHidden(true)
        }
        .font(PitchAtlasType.font(.hanken600, size: size, relativeTo: .callout))
        .foregroundStyle(ink)
        .multilineTextAlignment(.leading)
        .frame(minHeight: 44, alignment: .leading)
        .contentShape(Rectangle())
    }
}

/// Opens a pitch-atlas.com path ("repertoire", "craftsmen/adam-wainwright") the
/// way an outside link would: the tab it belongs to, that tab's stack replaced.
struct RouteButton<Label: View>: View {
    let path: String
    @ViewBuilder var label: Label

    @Environment(DeepLinkRouter.self) private var router
    @Environment(PitchStore.self) private var store

    var body: some View {
        Button {
            guard let url = URL(string: "pitchatlas://\(path)") else { return }
            router.handle(url, store: store)
        } label: {
            label
        }
    }
}

/// `.v2-stage`: the matte ground the filed set, the doors and the record stand on,
/// a violet-black falling to near-black, with the top hairline fading out at the
/// gutters. Matte is the half of the set that isn't chrome.
struct MatteStage: View {
    var body: some View {
        ZStack(alignment: .top) {
            EllipticalGradient(stops: [.init(color: ArchiveInk.stageTop, location: 0),
                                       .init(color: ArchiveInk.stageMid, location: 0.52),
                                       .init(color: ArchiveInk.stageBottom, location: 1)],
                               center: UnitPoint(x: 0.5, y: -0.08), startRadiusFraction: 0, endRadiusFraction: 1.05)
            LinearGradient(colors: [.white.opacity(0.012), .clear], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.22))
            LinearGradient(stops: [.init(color: .clear, location: 0),
                                   .init(color: PitchAtlasTheme.bone.opacity(0.1), location: 0.15),
                                   .init(color: PitchAtlasTheme.bone.opacity(0.1), location: 0.85),
                                   .init(color: .clear, location: 1)],
                           startPoint: .leading, endPoint: .trailing)
                .frame(height: 1)
        }
        .accessibilityHidden(true)
    }
}

/// Descent.tsx: the seam's thread dropping into a chapter, a fading hairline, three
/// alternating stitches and the puncture point. Decorative.
struct SeamDescent: View {
    var body: some View {
        VStack(spacing: 2) {
            LinearGradient(colors: [.clear, PitchAtlasTheme.bone.opacity(0.15), PitchAtlasTheme.bone.opacity(0.3)],
                           startPoint: .top, endPoint: .bottom)
                .frame(width: 1, height: 36)
            Canvas { context, _ in
                for (i, y) in [5.0, 16.0, 27.0].enumerated() {
                    var tick = Path()
                    let (from, to) = i % 2 == 0 ? (4.0, 12.0) : (12.0, 4.0)
                    tick.move(to: CGPoint(x: from, y: y - 3.5))
                    tick.addLine(to: CGPoint(x: to, y: y + 3.5))
                    context.stroke(tick, with: .color(PitchAtlasTheme.seamBright.opacity(0.62)),
                                   style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                }
            }
            .frame(width: 16, height: 34)
            RoundedRectangle(cornerRadius: 1)
                .strokeBorder(PitchAtlasTheme.bone.opacity(0.3), lineWidth: 1)
                .frame(width: 6, height: 6)
                .rotationEffect(.degrees(45))
        }
        .accessibilityHidden(true)
    }
}

/// The quiet bordered control under the hero card (`Pause motion`).
struct CardActionLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(PitchAtlasType.font(.hanken600, size: 12, relativeTo: .caption))
            .foregroundStyle(ComponentInk.compareInk)
            .padding(.horizontal, 12.8)
            .frame(minHeight: 36)
            .background(RoundedRectangle(cornerRadius: 6).fill(ComponentInk.compareFill))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(ComponentInk.compareBorder, lineWidth: 1))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
    }
}

extension View {
    /// `.v2-display`: bone type pressed into the stage, a lit top edge and a soft drop.
    func stageDisplay() -> some View {
        shadow(color: .white.opacity(0.16), radius: 0, x: 0, y: -1)
            .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
            .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
    }
}

/// The athletic display title (`.rfx-athletic .v2-display`): Anton, upper case, set
/// close and upright. Only the wordmark takes the skew.
struct AthleticTitle: View {
    let text: Text
    var size: CGFloat
    var lineSpacing: CGFloat = -4
    var alignment: TextAlignment = .leading

    var body: some View {
        text
            .font(PitchAtlasTheme.anton(size, relativeTo: .title))
            .textCase(.uppercase)
            .tracking(size * 0.01)
            .lineSpacing(lineSpacing)
            .foregroundStyle(PitchAtlasTheme.bone)
            .multilineTextAlignment(alignment)
            .fixedSize(horizontal: false, vertical: true)
            .stageDisplay()
            .accessibilityAddTraits(.isHeader)
    }
}
