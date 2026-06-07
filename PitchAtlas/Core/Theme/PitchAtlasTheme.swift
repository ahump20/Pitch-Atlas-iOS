import SwiftUI

// =============================================================================
// Pitch Atlas — SwiftUI Token Map
// =============================================================================
// Direct port of the web design system's *rendered* (void-tuned, dark) tokens.
// Source of truth: the web repo's src/index.css (the refractor void remap).
// Pattern: an enum of static tokens + Color(hex:) + Font.custom(relativeTo:) with
// system fallbacks. Palette and typefaces are Pitch Atlas's own.
//
// Dark only. The void is the frame, not decoration.
// =============================================================================

enum PitchAtlasTheme {

    // MARK: - Surfaces
    /// App background, every screen, sitewide.
    static let void = Color(hex: 0x070509)
    /// Raised content cards — the "leather-press" surface.
    static let press = Color(hex: 0x15161A)
    /// Alternating panels, secondary card fill.
    static let paper2 = Color(hex: 0x100C18)
    /// Deepest insets, edge frames.
    static let paper3 = Color(hex: 0x161120)

    // MARK: - Text
    /// Primary text on void.
    static let bone = Color(hex: 0xF6F1E6)
    /// Secondary text, captions — cool slate.
    static let bone2 = Color(hex: 0xC2C7D6)
    /// Muted / tertiary, hairlines, the "unverified" tier.
    static let ink3 = Color(hex: 0x7C8294)

    // MARK: - Accent (cyan is the ONLY interactive color)
    static let cyan = Color(hex: 0x37D6FF)
    static let cyanDeep = Color(hex: 0x1C8FD6)

    // MARK: - Seam red (graphic / seam / banned-tier only — never body text on void)
    static let seamBright = Color(hex: 0xFF2D44)

    // MARK: - Provenance ladder (the confidence tiers)
    static let okBright = Color(hex: 0x34E27E)   // official-data
    static let tealGlow = Color(hex: 0x1FB6A6)   // coach-observed
    static let amberBright = Color(hex: 0xFFC23C) // reputable-analysis
    static let sandBright = Color(hex: 0xCDBA8E)  // secondhand / community-firsthand
    // pitcher-own-words -> cyan; unverified -> ink3

    // MARK: - Pitch-family accents (index card dots)
    static let lime = Color(hex: 0x7CFF52)   // offspeed
    static let violet = Color(hex: 0x8A6BFF) // breaking

    // MARK: - Hairlines / texture
    /// The 1px card border — bone at 10%.
    static let machined = Color(hex: 0xF6F1E6, opacity: 0.10)
    /// Subtle dividers — bone2 at 14%.
    static let navyLine = Color(hex: 0xC2C7D6, opacity: 0.14)

    // MARK: - Gradients
    /// The holographic foil — refractor card borders, the diamond mark, holo wordmark.
    /// Web origin: 115deg linear sweep.
    static let foil = LinearGradient(
        stops: [
            .init(color: Color(hex: 0xFF2D6E), location: 0.00),
            .init(color: Color(hex: 0xFF8A3C), location: 0.14),
            .init(color: Color(hex: 0xFFE14D), location: 0.28),
            .init(color: Color(hex: 0x46FF9C), location: 0.43),
            .init(color: Color(hex: 0x33E0FF), location: 0.57),
            .init(color: Color(hex: 0x6B7BFF), location: 0.71),
            .init(color: Color(hex: 0xC44BFF), location: 0.85),
            .init(color: Color(hex: 0xFF2D6E), location: 1.00),
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    /// Gold 1/1 — reserved STRICTLY for the single defining specimen per pitch.
    static let gold = LinearGradient(
        stops: [
            .init(color: Color(hex: 0x5A3D12), location: 0.00),
            .init(color: Color(hex: 0xCAA14A), location: 0.22),
            .init(color: Color(hex: 0xFFF0C2), location: 0.38),
            .init(color: Color(hex: 0xB8893A), location: 0.54),
            .init(color: Color(hex: 0xF4D98A), location: 0.70),
            .init(color: Color(hex: 0x7A571F), location: 0.90),
        ],
        startPoint: .top, endPoint: .bottom
    )

    // MARK: - Typography
    // All four are bundled OFL fonts (registered in Info.plist UIAppFonts once the
    // .ttf files land in Resources/Fonts). Until then, Font.custom silently falls
    // back to the system font, so the app builds and runs either way.

    /// Athletic logotype, pitch names, banners. Render with `.antonSkew()`.
    static func anton(_ size: CGFloat, relativeTo: Font.TextStyle = .largeTitle) -> Font {
        .custom("Anton-Regular", size: size, relativeTo: relativeTo)
    }
    /// Editorial display, hero titles, section heads. The italic carries the warmth.
    static func newsreader(_ size: CGFloat, relativeTo: Font.TextStyle = .title) -> Font {
        .custom("Newsreader-Regular", size: size, relativeTo: relativeTo)
    }
    static func newsreaderItalic(_ size: CGFloat, relativeTo: Font.TextStyle = .title) -> Font {
        .custom("Newsreader-Italic", size: size, relativeTo: relativeTo)
    }
    /// Body prose, the coaching voice.
    static func hanken(_ size: CGFloat, relativeTo: Font.TextStyle = .body) -> Font {
        .custom("HankenGrotesk-Regular", size: size, relativeTo: relativeTo)
    }
    static func hankenMedium(_ size: CGFloat, relativeTo: Font.TextStyle = .body) -> Font {
        .custom("HankenGrotesk-Medium", size: size, relativeTo: relativeTo)
    }
    /// Micro-labels, source badges, nav, all-caps tracking.
    static func martian(_ size: CGFloat, relativeTo: Font.TextStyle = .caption2) -> Font {
        .custom("MartianMono-Regular", size: size, relativeTo: relativeTo)
    }

    // MARK: - Provenance tier -> color
    /// Maps a ClaimConfidence raw value (from the web model) to its tier color.
    static func color(forConfidence raw: String) -> Color {
        switch raw {
        case "official-data": return okBright
        case "pitcher-own-words": return cyan
        case "coach-observed": return tealGlow
        case "reputable-analysis": return amberBright
        case "secondhand-attributed", "community-firsthand": return sandBright
        default: return ink3 // unverified + unknown -> honest gray
        }
    }
}

// MARK: - Hex Color Initializer

extension Color {
    /// Initialize a Color from a hex integer (e.g. 0x37D6FF).
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Shape Style aliases (so call sites read `.fill(.void)`)

extension ShapeStyle where Self == Color {
    static var paVoid: Color { PitchAtlasTheme.void }
    static var paPress: Color { PitchAtlasTheme.press }
    static var paBone: Color { PitchAtlasTheme.bone }
    static var paBone2: Color { PitchAtlasTheme.bone2 }
    static var paCyan: Color { PitchAtlasTheme.cyan }
    static var paSeam: Color { PitchAtlasTheme.seamBright }
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
