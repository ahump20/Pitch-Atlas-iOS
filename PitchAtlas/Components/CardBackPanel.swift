import SwiftUI

// =============================================================================
// CardBackPanel — the burnt-orange archive cover, native
// =============================================================================
// Worn orange stock, inset pressed edges and layered contact shadows.
// Ivory reading ink preserves source-label contrast on the darkest and lightest
// cover tones. The surrounding app canvas remains charcoal.
// =============================================================================

struct CardBackPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(PitchAtlasSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(PitchAtlasTheme.cardbackInk)
            .background { ArchiveCoverSurface(radius: 14) }
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
