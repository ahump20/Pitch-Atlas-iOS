import SwiftUI

/// The web scopes its secondary inks by surface: on the void field secondary
/// text reads ink-2/ink-3; inside an object (plate, row, panel, binder sheet)
/// it re-scopes to bone-2/bone-3, because ink-3 on press measures 4.32:1; on
/// cream card stock it takes the base @theme inks; on the bound paper of a
/// craftsman's file (archive.css `.archive-paper`) the ivory inks. `leatherPress()`
/// and the other raised surfaces set `.object` for everything inside them.
enum InkContext: Sendable {
    case void, object, cream, paper

    var text2RGB: UInt32 {
        switch self {
        case .void: WebTokens.Palette.ink2.rgb
        case .object: WebTokens.Palette.bone2.rgb
        case .cream: WebTokens.CreamInk.ink2.rgb
        // `.archive-paper :is(.text-ink-2, .text-ink-3) { color: #c8bbae }`
        case .paper: 0xC8BBAE
        }
    }

    var text3RGB: UInt32 {
        switch self {
        case .void: WebTokens.Palette.ink3.rgb
        case .object: WebTokens.Palette.bone3.rgb
        case .cream: WebTokens.CreamInk.ink3.rgb
        case .paper: 0xC8BBAE
        }
    }
}

// The claim kit's own inks (StageTierMarker, ConfidenceLabel, SourceBadge,
// ClaimNote). Only the paper re-inks them: its `--color-ink*` variables and its
// `a` rule. Every other surface keeps the void's values, as before.
extension InkContext {
    /// `.text-ink`, a chapter index: the paper's ivory, bone elsewhere.
    var inkRGB: UInt32 { self == .paper ? 0xEEE9DF : WebTokens.Palette.bone.rgb }
    /// `.mono-label`'s own color, `var(--color-ink-2)`: the paper sets #cec4b8.
    var labelRGB: UInt32 { self == .paper ? 0xCEC4B8 : WebTokens.Palette.ink2.rgb }
    /// A source link: `.archive-paper a { color: #e4b182 }`.
    var linkRGB: UInt32 { self == .paper ? 0xE4B182 : WebTokens.Palette.ink2.rgb }
    /// A link's underline, `decoration-ink-3/40`: the paper's ink-3 is #bfb09f.
    var underlineRGB: UInt32 { self == .paper ? 0xBFB09F : WebTokens.Palette.ink3.rgb }
}

private struct InkContextKey: EnvironmentKey {
    static let defaultValue: InkContext = .void
}

extension EnvironmentValues {
    var inkContext: InkContext {
        get { self[InkContextKey.self] }
        set { self[InkContextKey.self] = newValue }
    }
}

extension View {
    /// Declare the surface the content sits on, so secondary inks resolve for it.
    func inkContext(_ context: InkContext) -> some View {
        environment(\.inkContext, context)
    }
}

/// A secondary or tertiary text ink that resolves against the surface it is
/// drawn on (see `InkContext`).
struct ContextInk: ShapeStyle {
    enum Level: Sendable { case secondary, tertiary }
    let level: Level

    func resolve(in environment: EnvironmentValues) -> Color {
        let context = environment.inkContext
        return Color(rgb: level == .secondary ? context.text2RGB : context.text3RGB)
    }
}
