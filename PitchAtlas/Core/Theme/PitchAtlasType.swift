import SwiftUI

/// The web's type system: the fourteen faces pitch-atlas.com loads
/// (@fontsource, Latin, imported by tools/fonts/import-web-fonts.py) and the
/// roles its CSS sets with them. Every role scales with Dynamic Type through
/// `relativeTo:`.
enum PitchAtlasType {
    enum Face: CaseIterable {
        case newsreader400, newsreader400i, newsreader500, newsreader600, newsreader600i
        case hanken400, hanken400i, hanken500, hanken600, hanken700
        case martian400, martian500, martian600
        case anton400

        var family: String {
            switch self {
            case .newsreader400, .newsreader400i, .newsreader500, .newsreader600, .newsreader600i: "Newsreader"
            case .hanken400, .hanken400i, .hanken500, .hanken600, .hanken700: "Hanken Grotesk"
            case .martian400, .martian500, .martian600: "Martian Mono"
            case .anton400: "Anton"
            }
        }

        var weight: Int {
            switch self {
            case .newsreader400, .newsreader400i, .hanken400, .hanken400i, .martian400, .anton400: 400
            case .newsreader500, .hanken500, .martian500: 500
            case .newsreader600, .newsreader600i, .hanken600, .martian600: 600
            case .hanken700: 700
            }
        }

        var italic: Bool { self == .newsreader400i || self == .newsreader600i || self == .hanken400i }

        /// The name inside the bundled file. The @fontsource static Martian Mono
        /// is the semi-expanded instance, which is what the site renders.
        var postScriptName: String {
            switch self {
            case .newsreader400: "Newsreader16pt16pt-Regular"
            case .newsreader400i: "Newsreader16pt16pt-Italic"
            case .newsreader500: "Newsreader16pt16pt-Medium"
            case .newsreader600: "Newsreader16pt16pt-SemiBold"
            case .newsreader600i: "Newsreader16pt16pt-SemiBoldItalic"
            case .hanken400: "HankenGrotesk-Regular"
            case .hanken400i: "HankenGrotesk-Italic"
            case .hanken500: "HankenGrotesk-Medium"
            case .hanken600: "HankenGrotesk-SemiBold"
            case .hanken700: "HankenGrotesk-Bold"
            case .martian400: "MartianMonoSemiExpanded-Regular"
            case .martian500: "MartianMonoSemiExpanded-Medium"
            case .martian600: "MartianMonoSemiExpanded-SemiBold"
            case .anton400: "Anton-Regular"
            }
        }
    }

    static func font(_ face: Face, size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(face.postScriptName, size: size, relativeTo: style)
    }

    // MARK: - Roles (web CSS, main 3f518f6)

    /// Hero headline — Newsreader 400, tracking −.052em.
    static func heroTitle(size: CGFloat) -> Font { font(.newsreader400, size: size, relativeTo: .largeTitle) }
    /// The hero's italic second line — Newsreader 400 italic.
    static func heroItalic(size: CGFloat) -> Font { font(.newsreader400i, size: size, relativeTo: .largeTitle) }
    /// Section titles — Anton, uppercase, line-height .98, never skewed.
    static func sectionTitle(size: CGFloat) -> Font { font(.anton400, size: size, relativeTo: .title) }
    /// Kicker — Martian 500, 11, tracking .2em, led by a 22×2 rule.
    static let kicker = font(.martian500, size: 11, relativeTo: .caption2)
    /// Label — Martian 400, 11, tracking .18em.
    static let label = font(.martian400, size: 11, relativeTo: .caption2)
    /// Chrome call to action — Martian 600, 11, tracking .14em.
    static let chromeCTA = font(.martian600, size: 11, relativeTo: .caption)
    /// Chip — Martian 400, 9.5.
    static let chip = font(.martian400, size: 9.5, relativeTo: .caption2)
    /// Segment and pill toggles — Martian 400, 12, tracking .06em.
    static let segment = font(.martian400, size: 12, relativeTo: .caption)
    /// Status pill — Martian 500, 8.
    static let statusPill = font(.martian500, size: 8, relativeTo: .caption2)
    /// The card's grip cue — Newsreader italic.
    static func cardCue(size: CGFloat) -> Font { font(.newsreader400i, size: size, relativeTo: .callout) }
    /// Body prose — Hanken 400.
    static func body(size: CGFloat = 16) -> Font { font(.hanken400, size: size, relativeTo: .body) }

    /// Letter-spacing in ems, as the web writes it.
    enum Tracking {
        static let heroTitle: CGFloat = -0.052
        static let kicker: CGFloat = 0.2
        static let label: CGFloat = 0.18
        static let chromeCTA: CGFloat = 0.14
        static let segment: CGFloat = 0.06
    }
}

extension View {
    /// CSS `letter-spacing: <em>em` at a given font size.
    func tracking(em: CGFloat, size: CGFloat) -> some View {
        tracking(em * size)
    }
}
