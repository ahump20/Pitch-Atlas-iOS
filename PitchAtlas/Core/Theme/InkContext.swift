import SwiftUI

/// The web scopes its secondary inks by surface: on the void field secondary
/// text reads ink-2/ink-3; inside an object (plate, row, panel, binder sheet)
/// it re-scopes to bone-2/bone-3, because ink-3 on press measures 4.32:1; on
/// cream card stock it takes the base @theme inks. `leatherPress()` and the
/// other raised surfaces set `.object` for everything inside them.
enum InkContext: Sendable {
    case void, object, cream

    var text2RGB: UInt32 {
        switch self {
        case .void: WebTokens.Palette.ink2.rgb
        case .object: WebTokens.Palette.bone2.rgb
        case .cream: WebTokens.CreamInk.ink2.rgb
        }
    }

    var text3RGB: UInt32 {
        switch self {
        case .void: WebTokens.Palette.ink3.rgb
        case .object: WebTokens.Palette.bone3.rgb
        case .cream: WebTokens.CreamInk.ink3.rgb
        }
    }
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
