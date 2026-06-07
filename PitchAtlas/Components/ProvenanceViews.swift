import SwiftUI

// =============================================================================
// Pitch Atlas — provenance views
// =============================================================================
// The visual layer of "Sourced, not corrected." Every number wears a tier dot
// that keeps its glow, its tier label, and its source — or, for a weak claim,
// its required note. This is what makes a figure read as evidence, not decoration.
// =============================================================================

extension ClaimConfidence {
    /// The tier color, routed through the single source of truth in the theme.
    var tierColor: Color { PitchAtlasTheme.color(forConfidence: rawValue) }
}

// MARK: - Provenance dot

/// The 8pt tier dot. The glow is load-bearing — it is what makes provenance read
/// as evidence rather than a bullet point. Do not flatten it.
struct ProvenanceDot: View {
    let confidence: ClaimConfidence
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(confidence.tierColor)
            .frame(width: size, height: size)
            .shadow(color: confidence.tierColor.opacity(0.75), radius: size * 0.65)
            .accessibilityHidden(true)
    }
}

// MARK: - Source / claim label

/// A claim's provenance line: tier dot + tier label + the source (or, for a weak
/// claim with no source, its explanatory note). Never hides the gap.
struct SourceClaimLabel: View {
    let claim: Claim
    var showMeaning: Bool = false

    private var isWeak: Bool {
        claim.confidence == .unverified || claim.confidence == .secondhandAttributed
    }

    var body: some View {
        HStack(alignment: .top, spacing: PitchAtlasSpacing.xs) {
            ProvenanceDot(confidence: claim.confidence)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(claim.confidence.label.uppercased())
                    .font(PitchAtlasTheme.martian(9))
                    .tracking(1.2)
                    .foregroundStyle(claim.confidence.tierColor)

                if let source = claim.source {
                    Text(source.label)
                        .font(PitchAtlasTheme.martian(9))
                        .tracking(0.4)
                        .foregroundStyle(PitchAtlasTheme.ink3)
                        .lineLimit(2)
                }

                if let note = claim.note, isWeak || claim.source == nil {
                    Text(note)
                        .font(PitchAtlasTheme.newsreaderItalic(12))
                        .foregroundStyle(PitchAtlasTheme.ink3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if showMeaning {
                    Text(claim.confidence.meaning)
                        .font(PitchAtlasTheme.hanken(11))
                        .foregroundStyle(PitchAtlasTheme.ink3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [claim.confidence.label]
        if let s = claim.source { parts.append("source, \(s.label)") }
        if let n = claim.note, isWeak || claim.source == nil { parts.append(n) }
        return parts.joined(separator: ". ")
    }
}

// MARK: - Claim text (value + provenance)

/// A sourced value: the figure or phrase, then its provenance line underneath.
struct ClaimText: View {
    let claim: Claim
    var valueFont: Font = PitchAtlasTheme.hanken(16)
    var valueColor: Color = PitchAtlasTheme.bone

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(claim.value)
                    .font(valueFont)
                    .foregroundStyle(valueColor)
                    .fixedSize(horizontal: false, vertical: true)
                if claim.approximate == true {
                    Text("approx.")
                        .font(PitchAtlasTheme.martian(8))
                        .tracking(0.5)
                        .foregroundStyle(PitchAtlasTheme.ink3)
                }
            }
            SourceClaimLabel(claim: claim)
        }
    }
}

// MARK: - Labeled gauge (a named, sourced number)

/// A break/spin gauge: label on top, the claim value large, provenance beneath.
/// `accent` paints the one hero number per pitch in cyan.
struct GaugeView: View {
    let label: String
    let claim: Claim
    var accent: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            SectionLabel(text: label, size: 9)
            Text(claim.value)
                .font(PitchAtlasTheme.newsreader(accent ? 28 : 22))
                .foregroundStyle(accent ? PitchAtlasTheme.cyan : PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
            SourceClaimLabel(claim: claim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .leatherPress(padding: PitchAtlasSpacing.sm, radius: PitchAtlasRadius.panel)
    }
}

// MARK: - Source row (the Sources screen)

/// One entry on the Sources colophon: label, link, and the date it was checked.
struct SourceRow: View {
    let source: Source

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(source.label)
                .font(PitchAtlasTheme.hankenMedium(14))
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
            Text(source.url)
                .font(PitchAtlasTheme.martian(9))
                .foregroundStyle(PitchAtlasTheme.cyanDeep)
                .lineLimit(1)
                .truncationMode(.middle)
            HStack(spacing: PitchAtlasSpacing.xs) {
                Text("CHECKED \(source.retrievedAt)")
                    .font(PitchAtlasTheme.martian(8))
                    .tracking(1)
                    .foregroundStyle(PitchAtlasTheme.ink3)
                if let season = source.season {
                    Text("· \(season)")
                        .font(PitchAtlasTheme.martian(8))
                        .foregroundStyle(PitchAtlasTheme.ink3)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(source.label), checked \(source.retrievedAt)")
    }
}
