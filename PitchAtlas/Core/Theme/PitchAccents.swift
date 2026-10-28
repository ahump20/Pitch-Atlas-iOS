import SwiftUI

/// Per-pitch and per-family accents, ported from web refractor/accents.ts and
/// sections/family-accent.ts. Values come from the generated WebTokens.
enum PitchAccents {
    static func triad(for slug: String) -> WebAccent { WebTokens.Accent.byPitch[slug] ?? WebTokens.Accent.fallback }

    static func familyRGB(_ family: RepertoireFamily) -> UInt32 {
        WebTokens.Family.accent[family.rawValue] ?? WebTokens.Accent.fallback.c3
    }
    static func familyRGB(_ family: PitchFamily) -> UInt32 {
        WebTokens.Family.accent[family.rawValue] ?? WebTokens.Accent.fallback.c3
    }
    static func familyColor(_ family: RepertoireFamily) -> Color { Color(rgb: familyRGB(family)) }
    static func familyColor(_ family: PitchFamily) -> Color { Color(rgb: familyRGB(family)) }

    /// Small type that would take an accent: burnt orange measures ~4.4:1 on the
    /// void, so small print beside it goes bone. Every other accent passes through.
    static func accentInk(_ rgb: UInt32) -> Color {
        rgb == WebTokens.Accent.burnt ? Color(web: WebTokens.Palette.bone) : Color(rgb: rgb)
    }

    private static let ctaDark: UInt32 = WebTokens.Palette.ctlOnAccent.rgb
    private static let ctaLight: UInt32 = WebTokens.Palette.white.rgb

    /// The accent-filled action button: dark ink while it reads at 4.5:1, white
    /// where white does, else lift the fill toward white in 5% steps.
    static func accentButton(fill: UInt32) -> (background: UInt32, foreground: UInt32) {
        for step in 0...20 {
            let background = step == 0 ? fill : towardWhite(fill, Double(step) * 0.05)
            if contrast(ctaDark, background) >= 4.5 { return (background, ctaDark) }
            if step == 0 && contrast(ctaLight, background) >= 4.5 { return (background, ctaLight) }
        }
        return (ctaLight, ctaDark)
    }

    /// CSS `color-mix(in srgb, a, b amount)` on packed RGB: `a` weighted 1 − amount,
    /// `b` weighted amount, each channel rounded.
    static func mixRGB(_ a: UInt32, _ b: UInt32, _ amount: Double) -> UInt32 {
        let t = min(1, max(0, amount))
        func channel(_ shift: UInt32) -> UInt32 {
            let x = Double((a >> shift) & 0xFF), y = Double((b >> shift) & 0xFF)
            return UInt32((x + (y - x) * t).rounded()) << shift
        }
        return channel(16) | channel(8) | channel(0)
    }

    /// WCAG 2 contrast ratio between two sRGB colors.
    static func contrast(_ a: UInt32, _ b: UInt32) -> Double {
        let (la, lb) = (luminance(a), luminance(b))
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    private static func luminance(_ rgb: UInt32) -> Double {
        func channel(_ v: UInt32) -> Double {
            let c = Double(v) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel((rgb >> 16) & 0xFF) + 0.7152 * channel((rgb >> 8) & 0xFF) + 0.0722 * channel(rgb & 0xFF)
    }

    private static func towardWhite(_ rgb: UInt32, _ amount: Double) -> UInt32 {
        func lift(_ v: UInt32) -> UInt32 { UInt32((Double(v) + (255 - Double(v)) * amount).rounded()) }
        return (lift((rgb >> 16) & 0xFF) << 16) | (lift((rgb >> 8) & 0xFF) << 8) | lift(rgb & 0xFF)
    }
}

extension Color {
    /// sRGB interpolation, as CSS `color-mix(in srgb, self, other amount)`:
    /// `self` weighted 1 − amount, `other` weighted amount.
    func mix(_ other: Color, _ amount: Double) -> Color {
        let t = CGFloat(min(1, max(0, amount)))
        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        UIColor(self).getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        UIColor(other).getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(.sRGB,
                     red: Double(r1 + (r2 - r1) * t),
                     green: Double(g1 + (g2 - g1) * t),
                     blue: Double(b1 + (b2 - b1) * t),
                     opacity: Double(a1 + (a2 - a1) * t))
    }
}
