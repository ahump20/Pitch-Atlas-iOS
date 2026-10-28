import SwiftUI

// =============================================================================
// PageKit — the plain pages' parts
// =============================================================================
// Web: pages/AboutPage.tsx, SupportPage.tsx and SourcesPage.tsx at the site's
// phone width, on index.css's .rfx-skick, .rfx-stitle, .rfx-athletic and
// .rfx-skew: a section between bone rules, the kicker as it sits in its line,
// the athletic section title, the numbered stamp and its skewed heading, the
// mono caps, the prose, and the links that leave the page.
// =============================================================================

/// `border-t border-ink/15 … px-5 py-16`: a bone rule across the top, 64 above
/// and below the content, 20 at the sides.
struct PageSection<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 1 + 64)
            .padding(.bottom, 64)
            .overlay(alignment: .top) { PageInk.rule.frame(height: 1).accessibilityHidden(true) }
    }
}

/// `.rfx-skick` as these pages set it: an inline-flex kicker in a 16/24 line,
/// so its 16.5pt box rides 8 below the top of the line.
struct SectionKick: View {
    let text: String

    var body: some View {
        KickerLabel(text: text)
            .cssLineHeight(1.5, face: .martian500, size: 11, relativeTo: .caption2)
            .padding(.top, 8)
    }
}

/// `.rfx-stitle` at its phone floor: Anton capitals at 0.98, balanced, held to
/// its measure in Anton's own `ch`.
struct SectionTitle: View {
    let text: String
    /// max-w-[Nch]
    let measure: CGFloat
    var size: CGFloat = 28
    var lineHeight: CGFloat = 0.98

    /// Anton's "0" is 0.4946em (on the site, 15ch of 28px Anton is 208).
    static let antonCh: CGFloat = 0.4946

    var body: some View {
        TightLines(text.uppercased(), face: .anton400, size: size, lineHeight: lineHeight,
                   relativeTo: .title2, balanced: true)
            .foregroundStyle(PitchAtlasTheme.bone)
            .frame(maxWidth: measure * Self.antonCh * size, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
            .accessibilityAddTraits(.isHeader)
    }
}

/// The numbered stamp: mono 9 in the seam, tracked .12em, 4×8 inside a 1pt
/// rim at half strength, 4pt corners, tilted 2° one way, then the other.
struct NumberStamp: View {
    let text: String
    /// The row's place: even rows lean right, odd rows left.
    let index: Int

    var body: some View {
        Text(text.uppercased())
            // font-bold; the bundle's heaviest Martian is 600
            .font(PitchAtlasType.font(.martian600, size: 9, relativeTo: .caption2))
            .tracking(em: 0.12, size: 9)
            .foregroundStyle(PitchAtlasTheme.seamBright)
            .cssLineHeight(1.5, face: .martian600, size: 9, relativeTo: .caption2)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(PageInk.stampRim, lineWidth: 1))
            .rotationEffect(.degrees(index.isMultiple(of: 2) ? 2 : -2))
            .accessibilityHidden(true)
    }
}

/// `.rfx-athletic .rfx-skew`: Anton capitals at 0.9, tracked .01em, leaning −7°.
struct AthleticHeading: View {
    let text: String
    var size: CGFloat = 20

    var body: some View {
        TightLines(text.uppercased(), face: .anton400, size: size, lineHeight: 0.9,
                   relativeTo: .title3, trackingEm: 0.01)
            .foregroundStyle(PitchAtlasTheme.bone)
            .modifier(CSSSkewX())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
            .accessibilityAddTraits(.isHeader)
    }
}

/// `.rfx-skew`: skewX(−7°) about the box's center, as CSS transforms it.
struct CSSSkewX: GeometryEffect {
    var degrees: Double = -7

    func effectValue(size: CGSize) -> ProjectionTransform {
        let t = CGFloat(tan(degrees * .pi / 180))
        return ProjectionTransform(CGAffineTransform(a: 1, b: 0, c: t, d: 1, tx: -t * size.height / 2, ty: 0))
    }
}

/// Mono capitals at line-height 1.5: the field labels, the archive ladder.
struct MonoCaps: View {
    let text: String
    var size: CGFloat = 10
    var trackingEm: CGFloat = 0.1
    var ink: Color = PitchAtlasTheme.ink3

    var body: some View {
        Text(text.uppercased())
            .font(PitchAtlasType.font(.martian400, size: size, relativeTo: .caption2))
            .tracking(em: trackingEm, size: size)
            .foregroundStyle(ink)
            .cssLineHeight(1.5, face: .martian400, size: size, relativeTo: .caption2)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(text)
    }
}

/// Body prose: Hanken at leading-relaxed (1.625), held to its measure in `ch`.
struct PageProse: View {
    let text: String
    var size: CGFloat = 16
    var ink: Color = PitchAtlasTheme.ink2
    /// max-w-[Nch]
    var measure: CGFloat = 64
    var leading: CGFloat = 1.625

    var body: some View {
        Text(text)
            .font(PitchAtlasType.font(.hanken400, size: size, relativeTo: size >= 15 ? .body : .subheadline))
            .foregroundStyle(ink)
            .cssLineHeight(leading, face: .hanken400, size: size, relativeTo: size >= 15 ? .body : .subheadline)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: measure * 0.56 * size, alignment: .leading)
    }
}

/// A numbered row (SupportPage HELP_ROWS, AboutPage VALUE_ROWS): the stamp,
/// 16 below it the skewed heading, 8 below that the words, a rule under all.
struct NumberedRow: View {
    let index: Int
    let label: String
    let text: String
    /// py-6 on Support, py-5 on About
    var inset: CGFloat = 24
    var textSize: CGFloat = 15

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NumberStamp(text: "\(index + 1)", index: index)
            AthleticHeading(text: label).padding(.top, 16)
            PageProse(text: text, size: textSize).padding(.top, 8)
        }
        .padding(.vertical, inset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) { PageInk.rule.frame(height: 1).accessibilityHidden(true) }
        .accessibilityElement(children: .combine)
    }
}

/// A mono link in the seam, "… →", that opens another page of the atlas: 14pt
/// capitals in a 24pt line, a 44pt target that keeps the line's height.
struct SeamRouteLink: View {
    let label: String
    let path: String

    var body: some View {
        RouteButton(path: path) {
            (Text(label.uppercased()) + Text(" →"))
                .font(PitchAtlasType.font(.martian400, size: 14, relativeTo: .callout))
                .tracking(em: 0.025, size: 14)
                .foregroundStyle(PitchAtlasTheme.seamBright)
                .cssLineHeight(20.0 / 14.0, face: .martian400, size: 14, relativeTo: .callout)
                .frame(minHeight: 24)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
                .padding(.vertical, -10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// A mono link out of the app (the nearby field's examples): 10pt capitals in
/// the seam, tracked .1em, a 44pt target.
struct ExternalMonoLink: View {
    let label: String
    let url: String

    var body: some View {
        if let destination = URL(string: url) {
            Link(destination: destination) {
                Text(label.uppercased())
                    .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                    .tracking(em: 0.1, size: 10)
                    .foregroundStyle(PitchAtlasTheme.seamBright)
                    .cssLineHeight(1.5, face: .martian400, size: 10, relativeTo: .caption2)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(label)
            .accessibilityHint("Opens outside the app")
        }
    }
}

/// `rounded-* border border-ink/15 bg-paper-2 p-5`: a card on the dark paper.
struct PageCard<Content: View>: View {
    var radius: CGFloat = 14
    var rim: Color = PageInk.rule
    var inset: CGFloat = 20
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            // the padding sits inside the 1pt rim
            .padding(inset + 1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: radius).fill(PitchAtlasTheme.paper2))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(rim, lineWidth: 1))
    }
}

/// The outlined mono button (About's "Read the source model"): `rounded-md
/// border border-ink/30 px-5 py-3 font-mono text-sm uppercase tracking-wide`,
/// 14pt capitals in bone on a 20pt line, a 46pt button.
struct OutlineMonoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PitchAtlasType.font(.martian400, size: 14, relativeTo: .callout))
            .tracking(em: 0.025, size: 14)
            .textCase(.uppercase)
            .foregroundStyle(PitchAtlasTheme.bone)
            .cssLineHeight(20.0 / 14.0, face: .martian400, size: 14, relativeTo: .callout)
            // py-3 px-5 inside the 1pt rim
            .padding(.horizontal, 21)
            .padding(.vertical, 13)
            .frame(minHeight: 44)
            .overlay(RoundedRectangle(cornerRadius: 8)
                .strokeBorder(configuration.isPressed ? PitchAtlasTheme.bone : PageInk.outline, lineWidth: 1))
            .contentShape(Rectangle())
    }
}
