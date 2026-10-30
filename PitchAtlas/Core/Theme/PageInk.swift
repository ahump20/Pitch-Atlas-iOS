import SwiftUI

/// The plain pages' inks: About, Support and Sources (web pages/AboutPage.tsx,
/// SupportPage.tsx, SourcesPage.tsx), written as Tailwind opacity utilities on
/// the theme's own colors. Each names the class it comes from.
enum PageInk {
    /// `border-ink/15`: the page's bone rules between sections and rows
    static let rule = PitchAtlasTheme.bone.opacity(0.15)
    /// `border-seam/50`: the numbered stamp's rim
    static let stampRim = PitchAtlasTheme.seamBright.opacity(0.5)
    /// `border-ink/30`: the outlined mono button
    static let outline = PitchAtlasTheme.bone.opacity(0.3)
    /// `decoration-seam/40`: a seam link's underline
    static let seamUnderline = PitchAtlasTheme.seamBright.opacity(0.4)
    /// `text-ink-2/85`: the claim legend's words
    static let legend = PitchAtlasTheme.ink2.opacity(0.85)
    /// "Unknown"'s rim: color-mix(in srgb, #C8102E 40%, transparent)
    static let unknownRim = Color(hex: 0xC8102E, opacity: 0.4)
}
