import SwiftUI

// =============================================================================
// SourcedClaim — the provenance line on the dark field
// =============================================================================
// Web: components/provenance/RefractorClaim.tsx (ConfidenceDot, RefractorSource,
// RefractorClaim, RefractorNote) and components/grip/GripSourceBadge.tsx. Every
// claim on the specimen page prints its words, its tier as a glowing dot with the
// tier's name, and its source as a link that leaves the app; a caveat rides under
// it on a cyan rule. The tier is never read from color alone.
// =============================================================================

/// The ground a claim sits on. Muted ink is ink-3 on the void, bone-3 on a press
/// panel (ink-3 falls to 4.3:1 there), and the grip bench's reading panel
/// retints all of it to its own #d2bca6.
enum ClaimGround {
    case void, panel, reading

    var mutedInk: Color {
        switch self {
        case .void: PitchAtlasTheme.ink3
        case .panel: PitchAtlasTheme.bone3
        case .reading: ChapterInk.readingMuted
        }
    }

    /// The tier's words: the field's own text-2, except on the reading panel.
    var tierInk: Color? { self == .reading ? ChapterInk.readingMuted : nil }
}

/// RefractorSource: the source's name in mono 10, upper case, underlined, cut at
/// 28 characters, its season, and the outbound arrow. A 44pt target that keeps
/// the line's own height.
struct RefractorSourceLink: View {
    let source: Source
    var ground: ClaimGround = .void

    /// max-w-[28ch] at Martian Mono 10 (its zero is 0.62em wide).
    @ScaledMetric(relativeTo: .caption2) private var labelWidth: CGFloat = 28 * 6.2

    var body: some View {
        let ink = ground.mutedInk
        let label = HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(source.label)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: labelWidth, alignment: .leading)
                .fixedSize(horizontal: true, vertical: false)
                .underline(true, color: ink.opacity(0.4))
            if let season = source.season {
                Text("/ \(season)").underline(true, color: ink.opacity(0.4))
            }
            Text("↗").accessibilityHidden(true)
        }
        .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
        .tracking(em: 0.06, size: 10)
        .textCase(.uppercase)
        .foregroundStyle(ink)
        .padding(.vertical, 15)
        .contentShape(Rectangle())
        .padding(.vertical, -15)

        if let url = URL(string: source.url) {
            Link(destination: url) { label }
                .accessibilityLabel(source.label + (source.season.map { ", \($0)" } ?? ""))
                .accessibilityHint("Opens the source outside the app")
        } else {
            label
        }
    }
}

/// The tier dot and the source, side by side, wrapping where they must.
struct ClaimTierLine: View {
    let claim: Claim
    var ground: ClaimGround = .void

    var body: some View {
        FlowRow(spacing: 10, lineSpacing: 4, rowAlignment: .center) {
            ConfidenceDot(confidence: claim.confidence, approximate: claim.approximate == true,
                          labelInk: ground.tierInk)
            if let source = claim.source {
                Text("/").font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                    .foregroundStyle(ground.mutedInk)
                    .accessibilityHidden(true)
                RefractorSourceLink(source: source, ground: ground)
            }
        }
    }
}

/// RefractorNote: a claim's caveat, what the line can and cannot claim, on a
/// cyan rule.
struct RefractorNoteView: View {
    let text: String
    var ground: ClaimGround = .void

    var body: some View {
        Text(text)
            .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
            .foregroundStyle(ground.mutedInk)
            .cssLineHeight(1.625, face: .martian400, size: 10, relativeTo: .caption2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.leading, 12)
            .overlay(alignment: .leading) {
                Rectangle().fill(PitchAtlasTheme.cyan.opacity(0.38)).frame(width: 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// RefractorClaim: the prose, then its tier and source, then any caveat.
struct RefractorClaimView: View {
    let claim: Claim
    var size: CGFloat = 15
    var ink: Color = PitchAtlasTheme.bone2
    var ground: ClaimGround = .void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(claim.value)
                .font(PitchAtlasType.font(.hanken400, size: size, relativeTo: size >= 15 ? .body : .subheadline))
                .foregroundStyle(ground == .reading ? ChapterInk.readingMuted : ink)
                .cssLineHeight(1.625, face: .hanken400, size: size, relativeTo: size >= 15 ? .body : .subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            ClaimTierLine(claim: claim, ground: ground)
            if let note = claim.note { RefractorNoteView(text: note, ground: ground) }
        }
    }
}

/// GripSourceBadge: the hand on the ball is a claim, so it wears its tier and
/// source inside the panel. An unfiled grip wears its tier here too.
struct GripSourceBadge: View {
    let provenance: Claim

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            ConfidenceDot(confidence: provenance.confidence, withLabel: false)
            VStack(alignment: .leading, spacing: 2) {
                Text(provenance.confidence.label.uppercased())
                    .font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2))
                    .tracking(em: 0.1, size: 9)
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .lineLimit(1)
                if let source = provenance.source, let url = URL(string: source.url) {
                    Link(destination: url) {
                        Text(source.label)
                            .underline(true, color: PitchAtlasTheme.bone.opacity(0.3))
                            .lineLimit(2)
                            .padding(.vertical, 16)
                            .contentShape(Rectangle())
                            .padding(.vertical, -16)
                    }
                    .accessibilityHint("Opens the source outside the app")
                } else {
                    Text("No source corroborates this grip").lineLimit(2)
                }
            }
            .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
            .tracking(em: 0.04, size: 10)
            .foregroundStyle(PitchAtlasTheme.bone2)
            .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(web: WebTokens.Palette.stage).opacity(0.85), in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(PitchAtlasTheme.bone.opacity(0.15), lineWidth: 1))
        .accessibilityElement(children: .contain)
    }
}
