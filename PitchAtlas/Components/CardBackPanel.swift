import SwiftUI

// =============================================================================
// CardBackPanel — neutral archive reading stock, native
// =============================================================================
// Dark stock, inset pressed edges and layered contact shadows.
// Warm reading ink keeps source labels clear. Orange remains reserved for
// the signature collectible rather than every reading surface.
// =============================================================================

struct CardBackPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(PitchAtlasSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(PitchAtlasTheme.cardbackInk)
            .background { ArchiveCoverSurface(radius: 14) }
            .inkContext(.object)
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
