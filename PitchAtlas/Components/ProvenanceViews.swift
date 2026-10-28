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

/// The bare 8pt tier dot. Every caller prints `TierWords` beside it, so the dot
/// stays mute here; `ConfidenceDot` is the dot-plus-words mark for new surfaces.
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

// MARK: - Tier words

/// A tier's glyph and label. The tier color stays on the dot; the words print in
/// bone-2 so they read at every size, and the glyph keeps the seven tiers distinct
/// across three colors (web provenance/ConfidenceLabel.tsx).
struct TierWords: View {
    let confidence: ClaimConfidence
    var size: CGFloat = 9
    var tracking: CGFloat = 1.2

    var body: some View {
        HStack(spacing: 4) {
            Text(confidence.glyph)
                .accessibilityHidden(true)
            Text(confidence.label.uppercased())
        }
        .font(PitchAtlasTheme.martian(size))
        .tracking(tracking)
        .foregroundStyle(PitchAtlasTheme.bone2)
    }
}

// MARK: - Source / claim label

/// A claim's provenance line: tier dot + tier label + the source (or, for a weak
/// claim with no source, its explanatory note). Never hides the gap.
struct SourceClaimLabel: View {
    let claim: Claim
    var showMeaning: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: PitchAtlasSpacing.xs) {
            ProvenanceDot(confidence: claim.confidence)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 2) {
                TierWords(confidence: claim.confidence, size: 9, tracking: 1.2)

                if let source = claim.source {
                    Text(source.label)
                        .font(PitchAtlasTheme.martian(9))
                        .tracking(0.4)
                        .foregroundStyle(PitchAtlasTheme.text3)
                        .lineLimit(2)
                }

                // A weak claim's note is its required provenance; a confident,
                // sourced claim's note is an editorial caveat. Either way it carries
                // meaning — show it whenever it exists rather than silently dropping
                // the caveat on well-sourced figures.
                if let note = claim.note, !note.isEmpty {
                    Text(note)
                        .font(PitchAtlasTheme.newsreaderItalic(12))
                        .foregroundStyle(PitchAtlasTheme.text3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if showMeaning {
                    Text(claim.confidence.meaning)
                        .font(PitchAtlasTheme.hanken(11))
                        .foregroundStyle(PitchAtlasTheme.text3)
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
        if let n = claim.note, !n.isEmpty { parts.append(n) }
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
                        .foregroundStyle(PitchAtlasTheme.text3)
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
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(claim.value)
                    .font(PitchAtlasTheme.newsreader(accent ? 28 : 22))
                    .foregroundStyle(accent ? PitchAtlasTheme.cyan : PitchAtlasTheme.bone)
                    .fixedSize(horizontal: false, vertical: true)
                // An approximate gauge says so — same honesty ClaimText carries, so
                // a rounded figure never reads as a measured one.
                if claim.approximate == true {
                    Text("approx.")
                        .font(PitchAtlasTheme.martian(8))
                        .tracking(0.5)
                        .foregroundStyle(PitchAtlasTheme.text3)
                }
            }
            SourceClaimLabel(claim: claim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .leatherPress(padding: PitchAtlasSpacing.sm, radius: PitchAtlasRadius.panel)
    }
}

// MARK: - Source row (the Sources screen)

/// One entry on the Sources colophon: label, link, and the date it was checked.
/// The whole point of the tab is "sourced, not corrected" — so the citation is a
/// real, tappable link out to the source of record, not dead text you have to
/// retype. A url that won't parse falls back to plain text rather than a broken tap.
struct SourceRow: View {
    let source: Source

    private var linkURL: URL? { URL(string: source.url) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(source.label)
                .font(PitchAtlasTheme.hankenMedium(14))
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)

            if let linkURL {
                Link(destination: linkURL) {
                    HStack(spacing: PitchAtlasSpacing.xs2) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 11, weight: .semibold))
                        Text(source.url)
                            .font(PitchAtlasTheme.martian(9))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .foregroundStyle(PitchAtlasTheme.cyanDeep)
                    .frame(minHeight: 44, alignment: .leading)
                }
                .accessibilityLabel("Opens in browser. \(source.label)")
            } else {
                Text(source.url)
                    .font(PitchAtlasTheme.martian(9))
                    .foregroundStyle(PitchAtlasTheme.text3)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            HStack(spacing: PitchAtlasSpacing.xs) {
                Text("CHECKED \(source.retrievedAt)")
                    .font(PitchAtlasTheme.martian(8))
                    .tracking(1)
                    .foregroundStyle(PitchAtlasTheme.text3)
                if let season = source.season {
                    Text("· \(season)")
                        .font(PitchAtlasTheme.martian(8))
                        .foregroundStyle(PitchAtlasTheme.text3)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Confidence dot (the web's provenance/ConfidenceDot)

/// The web ConfidenceDot: an 8pt tier dot with a 9pt glow, then the tier's words
/// in mono 10 at .1em, bone-2. The dot never stands alone.
struct ConfidenceDot: View {
    let confidence: ClaimConfidence
    var approximate = false
    /// withLabel={false}: the dot alone, where the tier's words print beside it.
    var withLabel = true
    /// The words' ink when not the field's text-2: the grip bench's reading panel
    /// retints its bone-2 to #d2bca6.
    var labelInk: Color? = nil
    static func accessibilityText(for c: ClaimConfidence, approximate: Bool) -> String {
        "Source: \(c.label)" + (approximate ? ", approximate" : "")
    }
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PitchAtlasTheme.color(forConfidence: confidence.rawValue)).frame(width: 8, height: 8)
                .shadow(color: PitchAtlasTheme.color(forConfidence: confidence.rawValue), radius: 4.5)
            if withLabel {
                Text(confidence.label.uppercased()).font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                    .tracking(em: 0.1, size: 10)
                    .foregroundStyle(labelInk.map(AnyShapeStyle.init) ?? AnyShapeStyle(PitchAtlasTheme.text2))
            }
            if approximate { ApproxPill() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.accessibilityText(for: confidence, approximate: approximate))
    }
}

// MARK: - Approx pill

struct ApproxPill: View {
    var body: some View {
        Text("≈ approx").font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2))
            .foregroundStyle(PitchAtlasTheme.text2)
            .padding(.horizontal, 6).padding(.vertical, 1)
            .overlay(Capsule().strokeBorder(PitchAtlasTheme.text3, lineWidth: 1))
    }
}

// MARK: - Scout rows (the card's scout-file block)

/// One scout-file row: a 56pt mono key and the value; a tier, when given, prints as a ConfidenceDot.
struct ScoutRow: View {
    static let keyWidth: CGFloat = 56
    let label: String
    let value: String
    var tier: ClaimConfidence? = nil
    var approximate = false
    var accent: Color = PitchAtlasTheme.bone2
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Text(label.uppercased()).font(PitchAtlasType.font(.martian400, size: 8, relativeTo: .caption2)).tracking(em: 0.12, size: 8)
                .foregroundStyle(accent).frame(width: Self.keyWidth, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                Text(value).font(PitchAtlasType.body(size: 12)).foregroundStyle(PitchAtlasTheme.bone).lineLimit(3)
                if let tier {
                    HStack(spacing: 6) {
                        Circle().fill(PitchAtlasTheme.color(forConfidence: tier.rawValue)).frame(width: 6, height: 6)
                        Text(tier.label.uppercased() + (approximate ? " · approx" : ""))
                            .font(PitchAtlasType.font(.martian400, size: 8, relativeTo: .caption2)).tracking(em: 0.1, size: 8)
                            .foregroundStyle(PitchAtlasTheme.bone2)
                    }
                }
            }
        }
        .padding(.horizontal, 9).padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct ScoutRows<Content: View>: View {
    static var tintOpacity: Double { 0.14 }
    static func isTinted(index: Int) -> Bool { index % 2 == 1 }
    let accent: Color
    let rows: [AnyView]
    init(accent: Color, rows: [AnyView]) where Content == EmptyView { self.accent = accent; self.rows = rows }
    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { i in
                rows[i]
                    .background(Self.isTinted(index: i) ? accent.opacity(Self.tintOpacity) : .clear)
                    .overlay(alignment: .top) { if i > 0 { Rectangle().fill(PitchAtlasTheme.bone.opacity(0.06)).frame(height: 1) } }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(PitchAtlasTheme.bone.opacity(0.08), lineWidth: 1))
    }
}
