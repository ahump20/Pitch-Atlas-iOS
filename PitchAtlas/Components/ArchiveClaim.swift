import SwiftUI

// =============================================================================
// The archive claim kit — a chapter room's marker and its sourced prose
// =============================================================================
// Web: layout/StageTierMarker.tsx, provenance/ClaimProse.tsx,
// provenance/ConfidenceLabel.tsx, provenance/SourceBadge.tsx, SourcedValue.tsx's
// ClaimNote, and index.css's .scene-coal. A room opens on a mono index, its name
// and a machined hairline; a prose claim prints its words, then its tier as a
// glyph and a label, then its source as a link out, then its caveat. The tier is
// told by the glyph and the words, never by color alone.
// =============================================================================

/// `.mono-label`: Martian 11, upper case, tracked .18em, line-height 1.
enum MonoLabel {
    static let size: CGFloat = 11
    static let trackingEm: CGFloat = 0.18
    static var font: Font { PitchAtlasType.font(.martian400, size: size, relativeTo: .caption2) }
}

/// StageTierMarker: the mono index, the room's name as its heading, and the
/// hairline running out to the edge.
struct StageTierMarker: View {
    let index: String
    let label: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(index)
                .font(PitchAtlasType.font(.martian500, size: 14, relativeTo: .footnote))
                .monospacedDigit()
                .foregroundStyle(PitchAtlasTheme.bone)
                .padding(.top, 1)
                .accessibilityHidden(true)
            Text(label.uppercased())
                .font(MonoLabel.font)
                .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                .foregroundStyle(PitchAtlasTheme.ink2)
                .cssLineHeight(1.375, face: .martian400, size: MonoLabel.size, relativeTo: .caption2)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
                .accessibilityAddTraits(.isHeader)
            Hairline().padding(.top, 6.4)
        }
        .padding(.bottom, 40)
    }
}

/// ConfidenceLabel: the tier's glyph and name in the mono label. Unverified is the
/// one tier that alarms in the seam; official data reads in full bone.
struct ConfidenceLabel: View {
    let confidence: ClaimConfidence

    var body: some View {
        HStack(spacing: 6) {
            Text(confidence.glyph).accessibilityHidden(true)
            Text(confidence.label.uppercased())
        }
        .font(MonoLabel.font)
        .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
        .foregroundStyle(ink)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(confidence.label)
        .accessibilityHint(confidence.meaning)
    }

    private var ink: Color {
        switch confidence {
        case .unverified: PitchAtlasTheme.seamBright
        case .officialData: PitchAtlasTheme.bone
        default: PitchAtlasTheme.ink2
        }
    }
}

/// SourceBadge: the source as a credential — its name cut at 26 characters, its
/// season, the outbound arrow — underlined and opening outside the app. A 44pt
/// target that keeps the line's own height.
struct SourceBadge: View {
    let source: Source

    /// max-w-[26ch] at the mono label's 11pt (Martian's zero is 0.7em wide).
    @ScaledMetric(relativeTo: .caption2) private var labelWidth: CGFloat = 26 * 0.7 * MonoLabel.size

    var body: some View {
        let label = HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(source.label.uppercased())
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: labelWidth, alignment: .leading)
                .fixedSize(horizontal: true, vertical: false)
            if let season = source.season {
                Text("/ \(season)".uppercased()).opacity(0.7)
            }
            Text("↗").accessibilityHidden(true)
        }
        .font(MonoLabel.font)
        .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
        .foregroundStyle(PitchAtlasTheme.ink2)
        .underline(true, color: PitchAtlasTheme.ink3.opacity(0.4))
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

/// ClaimNote: a claim's caveat in small print beneath it.
struct ClaimNote: View {
    let text: String

    var body: some View {
        Text(text)
            .font(PitchAtlasType.font(.hanken400, size: 13, relativeTo: .footnote))
            .foregroundStyle(PitchAtlasTheme.ink2.opacity(0.85))
            .cssLineHeight(1.375, face: .hanken400, size: 13, relativeTo: .footnote)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 62 * 0.56 * 13, alignment: .leading)
    }
}

/// ClaimProse: the sentence in Hanken, its tier and source beneath, and the caveat
/// when one exists.
struct ClaimProse: View {
    let claim: Claim
    var size: CGFloat = 17
    var leading: CGFloat = 1.625
    var ink: Color = PitchAtlasTheme.bone.opacity(0.9)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(claim.value)
                .font(PitchAtlasType.font(.hanken400, size: size, relativeTo: size >= 18 ? .title3 : .body))
                .foregroundStyle(ink)
                .cssLineHeight(leading, face: .hanken400, size: size, relativeTo: size >= 18 ? .title3 : .body)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 64 * 0.56 * size, alignment: .leading)
            FlowRow(spacing: 8, lineSpacing: 4, rowAlignment: .center) {
                ConfidenceLabel(confidence: claim.confidence)
                if let source = claim.source {
                    Text("/")
                        .font(PitchAtlasType.body())
                        .foregroundStyle(PitchAtlasTheme.ink3)
                        .accessibilityHidden(true)
                    SourceBadge(source: source)
                }
            }
            if let note = claim.note, !note.isEmpty {
                ClaimNote(text: note)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// `.scene-coal`: the void under a warm crown at the top and a faint bone wash
/// at the upper left — the dark room a grip is looked at in.
struct CoalScene: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                PitchAtlasTheme.void
                if !reduceTransparency {
                    // radial-gradient(50% 40% at 50% -6%, #17130D 0%, transparent 60%)
                    CSSEllipseWash(color: ArchiveInk.coalCrown, center: CGPoint(x: w * 0.5, y: -h * 0.06),
                                   radii: CGSize(width: w * 0.5, height: h * 0.4), fade: 0.6)
                    // radial-gradient(40% 36% at 12% 16%, rgba(216,207,184,.055), transparent 60%)
                    CSSEllipseWash(color: ArchiveInk.coalWash, center: CGPoint(x: w * 0.12, y: h * 0.16),
                                   radii: CGSize(width: w * 0.4, height: h * 0.36), fade: 0.6)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// A CSS elliptical radial gradient: a color at the center fading to clear at
/// `fade` of the way out to an ellipse of the given radii.
struct CSSEllipseWash: View {
    let color: Color
    let center: CGPoint
    let radii: CGSize
    var fade: CGFloat = 1

    var body: some View {
        let rx = max(radii.width, 1), ry = max(radii.height, 1)
        RadialGradient(stops: [.init(color: color, location: 0), .init(color: color.opacity(0), location: fade)],
                       center: .center, startRadius: 0, endRadius: rx)
            .frame(width: rx * 2, height: rx * 2)
            .scaleEffect(x: 1, y: ry / rx)
            .position(center)
            .allowsHitTesting(false)
    }
}
