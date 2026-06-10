import SwiftUI

// =============================================================================
// CardBackPanel — the cream card back, native
// =============================================================================
// Real vintage card backs print the data on cream stock inside a gold frame;
// this panel is that register, ported from the web's .rfx-cardback: Scorecard
// Cream paper, the double border (gold frame outside, charcoal hairline
// inside), and charcoal ink content. Data panels (the grading scale, the
// freshness ledger, source lists) print on paper — the charcoal table stays
// the field around them.
// =============================================================================

struct CardBackPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(PitchAtlasSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(PitchAtlasTheme.cardbackPaper)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(PitchAtlasTheme.cardbackLine, lineWidth: 1)
                    .padding(3)
            )
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xC9A85C), Color(hex: 0x8A6B24), Color(hex: 0xC9A85C)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 14, x: 0, y: 10)
    }
}

/// The card-back header strip: a small slab title set between two hard ink
/// rules — vintage card-back anatomy (the "STATS" bar on the physical backs).
struct CardBackRules: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(PitchAtlasTheme.anton(15))
            .foregroundStyle(PitchAtlasTheme.cardbackNavy)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
            .overlay(alignment: .top) {
                Rectangle().fill(PitchAtlasTheme.cardbackInk).frame(height: 2)
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(PitchAtlasTheme.cardbackInk).frame(height: 2)
            }
    }
}

/// A blocky uppercase ink stamp, set a degree off-square like a hand stamp.
/// Color rides in (burgundy NEVER, forest ALWAYS, navy eras).
struct InkStamp: View {
    let text: String
    var color: Color = PitchAtlasTheme.cardbackBurgundy
    var rotation: Double = -1

    var body: some View {
        Text(text.uppercased())
            .font(PitchAtlasTheme.martian(8))
            .tracking(1.4)
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(color, lineWidth: 1)
            )
            .rotationEffect(.degrees(rotation))
    }
}
