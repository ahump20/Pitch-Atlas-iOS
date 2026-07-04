import SwiftUI

// =============================================================================
// Pitch Atlas — spacing & radius ladder
// =============================================================================
// 4pt spacing rhythm. Radii are deliberately small/machined: crisp hairline
// chrome, comfortable-but-not-pill content.
// =============================================================================

enum PitchAtlasSpacing {
    static let xs2: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xl2: CGFloat = 32
    static let xl3: CGFloat = 40
    static let xl4: CGFloat = 48
    static let xl5: CGFloat = 64
    static let xl6: CGFloat = 80
    static let tabBarClearance: CGFloat = 96
}

enum PitchAtlasRadius {
    /// Chips / buttons.
    static let chip: CGFloat = 9
    /// Inset panels.
    static let panel: CGFloat = 12
    /// Grip-photo tiles.
    static let tile: CGFloat = 14
    /// Specimen / foil cards.
    static let card: CGFloat = 18
}
