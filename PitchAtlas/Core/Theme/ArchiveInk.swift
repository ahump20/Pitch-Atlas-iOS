import SwiftUI

/// The home's own inks. The site writes these as raw hex in its home styles
/// (web src/styles/archive.css and world.css), not as design-sync tokens, so they
/// are ported here by hand; each names the selector it comes from.
enum ArchiveInk {
    // MARK: The specimen case (.archive-case)
    /// .archive-case background
    static let caseField = Color(hex: 0x0E0D0C)
    /// .archive-case-title
    static let caseTitle = Color(hex: 0xF3ECDD)
    /// .archive-case-title em
    static let caseTitleAccent = Color(hex: 0xD0AE82)
    /// .archive-case-light, the warm rake behind the card (#c1976630)
    static let caseLight = Color(hex: 0xC19766, opacity: 0x30 / 255.0)
    /// .archive-case-light's left shade (#090909ad, 112deg)
    static let caseShade = Color(hex: 0x090909, opacity: 0xAD / 255.0)
    /// .archive-case-footer text and its rule (#c8b69630)
    static let caseFooter = Color(hex: 0xB5A993)
    static let caseFooterRule = Color(hex: 0xC8B696, opacity: 0x30 / 255.0)
    /// .archive-case-card::after, the card's floor shadow
    static let caseCardShadow = Color(hex: 0x000000, opacity: 0.65)

    // MARK: Discovery (.archive-discovery, world.css)
    static let discoveryText = Color(hex: 0xEDE3CF)
    /// .archive-discovery-heading .archive-eyebrow
    static let discoveryEyebrow = Color(hex: 0xC4A777)
    /// .archive-discovery-heading h2 em
    static let discoveryAccent = Color(hex: 0xD1B58B)
    /// .archive-discovery-heading > p
    static let discoveryLede = Color(hex: 0xC4BAA7)
    /// .archive-discovery-folio and the sheet tucked under it
    static let folioFill = Color(hex: 0x1B1B1F)
    static let folioBorder = Color(hex: 0x727B84, opacity: 0x66 / 255.0)
    static let folioUnder = Color(hex: 0x292B30)
    /// the folio's inset top light (#d6dfe533)
    static let folioTopLight = Color(hex: 0xD6DFE5, opacity: 0x33 / 255.0)
    static let folioUnderBorder = Color(hex: 0x6D7780, opacity: 0x55 / 255.0)
    /// .archive-discovery-specimen radial (#353c42 → #18191c)
    static let specimenGlow = Color(hex: 0x353C42)
    static let specimenFloor = Color(hex: 0x18191C)
    static let specimenEyebrow = Color(hex: 0xBBA886)
    /// .archive-discovery-specimen text
    static let specimenText = Color(hex: 0xEEE4D0)
    static let specimenRule = Color(hex: 0x6D7780, opacity: 0x44 / 255.0)
    /// .archive-reference-credit
    static let referenceCredit = Color(hex: 0xC4B79C)
    /// .archive-discovery-story eyebrows, quote, invitation
    static let storyEyebrow = Color(hex: 0xD0A478)
    static let storyQuote = Color(hex: 0xF0E6D8)
    static let storyBody = Color(hex: 0xCBB6A3)
    /// .archive-discovery-history border (#9f87544d)
    static let historyRule = Color(hex: 0x9F8754, opacity: 0x4D / 255.0)
    /// .archive-discovery-routes border (#b69a5b45), small, arrow
    static let routeRule = Color(hex: 0xB69A5B, opacity: 0x45 / 255.0)
    static let routeNote = Color(hex: 0xB2A38C)
    static let routeArrow = Color(hex: 0xD1B58B)
    /// .archive-text-link underline (#a68a5966)
    static let textLinkUnderline = Color(hex: 0xA68A59, opacity: 0x66 / 255.0)

    // MARK: The seam bridge (.archive-bridge)
    static let bridgeField = Color(hex: 0x111114)
    static let bridgeGlow = Color(hex: 0x344049, opacity: 0x26 / 255.0)
    static let bridgeText = Color(hex: 0xEEE9DF)
    static let bridgeBorder = Color(hex: 0x919CA3, opacity: 0x2E / 255.0)
    /// .archive-bridge-read h2 em
    static let bridgeAccent = Color(hex: 0xBF5700)
    static let bridgeBody = Color(hex: 0xCAC1B7)
    static let bridgeNote = Color(hex: 0xA79C8F)
    /// .archive-bridge .archive-chapter-mark and its rule (#aa785655)
    static let bridgeMark = Color(hex: 0xC09B79)
    static let bridgeMarkRule = Color(hex: 0xAA7856, opacity: 0x55 / 255.0)
    /// .archive-bridge-read > .archive-text-link
    static let bridgeLink = Color(hex: 0xDDA775)
    /// .archive-seam-stage
    static let stageFill = Color(hex: 0x191716)
    static let stageBezel = Color(hex: 0x303236)
    static let stageOutline = Color(hex: 0xA7B1B7, opacity: 0x66 / 255.0)
    static let stageRegistration = Color(hex: 0xB1A38C, opacity: 0x18 / 255.0)
    /// .archive-seam-figure figcaption
    static let stageCaption = Color(hex: 0xD6B18A)
    /// the stage's hard lip (`0 3px 0 4px #111215`)
    static let stageDrop = Color(hex: 0x111215)
    /// .archive-seam-controls button, off and pressed
    static let toggleInk = Color(hex: 0xCFC4B8)
    static let toggleFill = Color(hex: 0x211A15)
    static let toggleBorder = Color(hex: 0x9B775B, opacity: 0x77 / 255.0)
    static let toggleOnInk = Color(hex: 0xFFE8D4)
    static let toggleOnFill = Color(hex: 0x723E20)
    static let toggleOnBorder = Color(hex: 0xC7854F)

    // MARK: The matte stage (.v2-stage), the filed set, doors, and record
    static let stageTop = Color(hex: 0x0D0A14)
    static let stageMid = Color(hex: 0x080610)
    static let stageBottom = Color(hex: 0x070509)
    /// WingsNav doors (#0d0c0b, rail #0b0a09) and their bone/12 border
    static let doorFill = Color(hex: 0x0D0C0B)
    static let railFill = Color(hex: 0x0B0A09)
    /// ChapterMark tints (the section's scene tint)
    static let filedSetTint = Color(hex: 0x8A93AB)
    static let doorsTint = Color(hex: 0x6CACE4)
    static let recordTint = Color(hex: 0xFFD24D)

    // MARK: The media rail (ExternalMediaRail, ExternalMediaCard)
    /// the rail's field (bg-[#090807])
    static let mediaField = Color(hex: 0x090807)
    /// the card's sheen falling into its near-black stock
    static let mediaCardSheen = Color(hex: 0xFFFFFF, opacity: 0.055)
    static let mediaCardStock = Color(hex: 0x080706, opacity: 0.96)
    /// the player well (#050505)
    static let mediaWell = Color(hex: 0x050505)
    /// the home's well sits under the story, a gold hairline above it (#ac966338)
    static let mediaWellRule = Color(hex: 0xAC9663, opacity: 0x38 / 255.0)

    // MARK: Plate 273 (.delivery-plate)
    static let plateStrip = Color(hex: 0x2B2824)
    static let plateFrameFill = Color(hex: 0x151412)
    static let plateFigure = Color(hex: 0xE6DCCB)
    static let plateGrid = Color(hex: 0xEFE6D5, opacity: 0x14 / 255.0)
    static let plateCaption = Color(hex: 0xA99E8F)
    static let plateTitle = Color(hex: 0xCDB48F)
    static let plateLink = Color(hex: 0xE0B285)

    // MARK: The page header (SectionHero.tsx, archive.css .archive-section-hero)
    /// .archive-section-hero background
    static let sectionHeroField = Color(hex: 0x141411)
    /// SectionHero ACCENT_WASH: powder rgba(75,146,219,.12), seam rgba(200,16,46,.10)
    static let heroWashPowder = Color(hex: 0x4B92DB, opacity: 0.12)
    static let heroWashSeam = Color(hex: 0xC8102E, opacity: 0.10)

    // MARK: The Pitch Index (RepertoirePage.tsx, PitchIndex.tsx)
    /// the title's "Index" (text-[#d1b58b])
    static let indexTitleAccent = Color(hex: 0xD1B58B)
    /// the filter panel (border-white/10, bg-card/50 on #0e0b15)
    static let indexPanelFill = Color(hex: 0x0E0B15, opacity: 0.5)
    /// the Lost Pitches callout: a teal glow (rgba(31,182,166,.28)) at 75% 10%
    /// falling to #16120D, over --color-press, rimmed in teal-glow at 34%
    static let lostCalloutGlow = Color(hex: 0x1FB6A6, opacity: 0.28)
    static let lostCalloutFloor = Color(hex: 0x16120D)
    static let tealGlow = Color(web: WebTokens.Palette.tealGlow)
    static let lostCalloutRim = tealGlow.opacity(0.34)
}
