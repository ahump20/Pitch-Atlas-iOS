import SwiftUI

// =============================================================================
// Pitch Atlas — SwiftUI Token Map
// =============================================================================
// The web design system's tokens, read from the generated WebTokens (which
// the content generator writes from the web repo's main branch). Near-black
// void field, cyan interaction, seam red, bone inks, and the foil/ember
// materials in PitchAtlasMaterials. Dark only.
// =============================================================================

enum PitchAtlasTheme {

    // MARK: - Surfaces (web --color-void / -press / -paper-2 / -paper-3)
    /// App background, every screen, sitewide — the web's near-black field.
    static let void = Color(web: WebTokens.Palette.void)
    /// Raised content cards — the "leather-press" surface.
    static let press = Color(web: WebTokens.Palette.press)
    /// --color-press-2: the interior of a foil-edged panel.
    static let press2 = Color(web: WebTokens.Palette.press2)
    /// Alternating panels, secondary card fill.
    static let paper2 = Color(web: WebTokens.Palette.paper2)
    /// Deepest insets, edge frames.
    static let paper3 = Color(web: WebTokens.Palette.paper3)

    static var voidRGB: UInt32 { WebTokens.Palette.void.rgb }
    static var pressRGB: UInt32 { WebTokens.Palette.press.rgb }

    // MARK: - Text
    /// Primary text on the field.
    static let bone = Color(web: WebTokens.Palette.bone)
    /// Secondary text, captions, labels — web --color-bone-2.
    static let bone2 = Color(web: WebTokens.Palette.bone2)
    /// Tertiary text inside objects — web --color-bone-3.
    static let bone3 = Color(web: WebTokens.Palette.bone3)
    /// Secondary ink on the void — web --color-ink-2.
    static let ink2 = Color(web: WebTokens.Palette.ink2)
    /// Tertiary ink on the void — web --color-ink-3. Inside a raised surface it
    /// measures 4.32:1, so tertiary text there uses `text3`, which resolves to
    /// bone-3. Use this concrete value only where a plain Color is required.
    static let ink3 = Color(web: WebTokens.Palette.ink3)
    /// Secondary text ink that follows the surface (ink-2 on the void, bone-2 in objects).
    static let text2 = ContextInk(level: .secondary)
    /// Tertiary text ink that follows the surface (ink-3 on the void, bone-3 in objects).
    static let text3 = ContextInk(level: .tertiary)

    static var bone2RGB: UInt32 { WebTokens.Palette.bone2.rgb }

    // MARK: - Accent
    /// The interaction accent — web --color-cyan.
    static let cyan = Color(web: WebTokens.Palette.cyan)
    static let cyanDeep = Color(web: WebTokens.Palette.cyanDeep)

    static var cyanRGB: UInt32 { WebTokens.Palette.cyan.rgb }
    /// Input placeholder text — web --color-ctl-placeholder.
    static let placeholder = Color(web: WebTokens.Palette.ctlPlaceholder)

    // MARK: - Seam red (graphic / seam / banned-tier only — never body text on void)
    static let seamBright = Color(web: WebTokens.Palette.seam)

    // MARK: - Roles (generated web tokens)
    /// Section kickers and the app-wide tint — the web's `--color-kicker` (cyan).
    static let kicker = Color(web: WebTokens.Palette.kicker)
    /// A confirmed, done, verified state — web `--color-ok`.
    static let success = Color(web: WebTokens.Palette.ok)
    /// A warning, a pending state, "educational use" — web `--color-amber`.
    static let caution = Color(web: WebTokens.Palette.amber)
    /// The lost-pitch and legend edge, the "Reference" register — web `--color-sand-bright`.
    static let lostEdge = Color(web: WebTokens.Palette.sandBright)

    // MARK: - Lost-pitch sand (web --color-sand-bright)
    static let sandBright = Color(web: WebTokens.Palette.sandBright)

    // MARK: - Card-back inks (light inks on the matte .v2-back stock — never the cream cb-* inks)
    static let cardbackPaper = Color(hex: 0x24221F)
    static let cardbackInk = bone
    static let cardbackInk2 = bone2
    static let cardbackInk3 = bone3
    static let cardbackLine = bone.opacity(0.10)
    static let cardbackNavy = kicker
    static let cardbackBurgundy = seamBright

    // MARK: - Hairlines / texture
    /// The 1px machined hairline — web --color-machined. Increase Contrast
    /// lifts it so frame edges and dividers stay visible.
    static let machinedUIColor = contrastAware(WebTokens.Palette.machined)
    static let machined = Color(uiColor: machinedUIColor)
    /// Subtle dividers — web --color-navy-line; lifted the same way.
    static let navyLineUIColor = contrastAware(WebTokens.Palette.navyLine)
    static let navyLine = Color(uiColor: navyLineUIColor)

    /// A hairline at the web's alpha, raised under Increase Contrast: the same
    /// ink, at least .45 and up to 2.5× as opaque.
    static func contrastLifted(_ color: WebColor) -> WebColor {
        WebColor(rgb: color.rgb, alpha: min(1, max(color.alpha * 2.5, 0.45)))
    }

    private static func contrastAware(_ color: WebColor) -> UIColor {
        let lifted = contrastLifted(color)
        return UIColor { traits in
            UIColor(web: traits.accessibilityContrast == .high ? lifted : color)
        }
    }

    // MARK: - Gradients
    // The web's foil, foil-type and ember are PitchAtlasMaterials (generated stops).

    // MARK: - Typography
    // The faces are the web's own (PitchAtlasType). These helpers keep their
    // call sites and resolve to the matching face.

    /// Athletic logotype, pitch names, banners. Render with `.antonSkew()` only where the web skews.
    static func anton(_ size: CGFloat, relativeTo: Font.TextStyle = .largeTitle) -> Font {
        PitchAtlasType.font(.anton400, size: size, relativeTo: relativeTo)
    }
    /// Editorial display, hero titles, section heads.
    static func newsreader(_ size: CGFloat, relativeTo: Font.TextStyle = .title) -> Font {
        PitchAtlasType.font(.newsreader400, size: size, relativeTo: relativeTo)
    }
    static func newsreaderItalic(_ size: CGFloat, relativeTo: Font.TextStyle = .title) -> Font {
        PitchAtlasType.font(.newsreader400i, size: size, relativeTo: relativeTo)
    }
    /// Body prose, the coaching voice.
    static func hanken(_ size: CGFloat, relativeTo: Font.TextStyle = .body) -> Font {
        PitchAtlasType.font(.hanken400, size: size, relativeTo: relativeTo)
    }
    static func hankenMedium(_ size: CGFloat, relativeTo: Font.TextStyle = .body) -> Font {
        PitchAtlasType.font(.hanken500, size: size, relativeTo: relativeTo)
    }
    /// Micro-labels, source badges, nav, all-caps tracking.
    static func martian(_ size: CGFloat, relativeTo: Font.TextStyle = .caption2) -> Font {
        PitchAtlasType.font(.martian400, size: size, relativeTo: relativeTo)
    }

    // MARK: - Provenance tier -> color
    /// The web's three trust colors across the seven tiers (provenance/
    /// refractorClaimMeta.ts CONFIDENCE_COLOR): firsthand burnt, relayed blue,
    /// unverified seam. An unknown tier reads as unverified — never upgraded.
    /// The color belongs to the dot; a tier's words print in bone-2 beside it.
    static func color(forConfidence raw: String) -> Color {
        Color(web: WebTokens.Tier.dot[raw] ?? WebTokens.Tier.dot["unverified"] ?? WebTokens.Palette.seam)
    }

    /// The tier ink on cream card stock (refractor/specimenFace.tsx CARD_INK).
    static func cardInk(forConfidence raw: String) -> Color {
        Color(web: WebTokens.Tier.ink[raw] ?? WebTokens.Tier.ink["unverified"] ?? WebTokens.CreamInk.ink)
    }
}

// MARK: - Hex Color Initializer

extension Color {
    /// Initialize a Color from a hex integer (e.g. 0x5FE0EA). Theme-only: the
    /// CI color-literal check rejects it anywhere else.
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Anton signature skew

extension View {
    /// The brand signature: Anton sheared -7deg with a dark layered stroke/shadow.
    /// A flat, un-skewed Anton headline reads as a generic sports template — this
    /// modifier is what keeps the wordmark on-brand. (SwiftUI has no text-stroke;
    /// the hard offset shadow stands in for the dark stroke.)
    ///
    /// This is a true 2D horizontal *shear* (matching the web's `transform:
    /// skewX(-7deg)`), not a Z-axis rotation. A rotation crooks the baseline so the
    /// whole word tilts; a shear leans the vertical strokes like athletic italic
    /// while the baseline stays level. tan(-7deg) puts the lean forward, web-true.
    func antonSkew() -> some View {
        let shear = CGAffineTransform(a: 1, b: 0,
                                      c: CGFloat(tan(-7.0 * Double.pi / 180.0)),
                                      d: 1, tx: 0, ty: 0)
        return self
            .transformEffect(shear)
            .shadow(color: .black.opacity(0.45), radius: 0, x: 2, y: 3)
    }
}
