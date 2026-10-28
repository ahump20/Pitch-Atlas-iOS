import SwiftUI

/// BrandMark.tsx's own colors: the saddle-leather diamond, its warm-black bezel,
/// the cream ball, the atlas meridians and the red horseshoe seam.
enum BrandInk {
    /// `pa-foil`, 0→1 along the square's diagonal, which the 45° turn stands upright.
    static let leather: [Gradient.Stop] = [
        .init(color: Color(hex: 0x5E3A22), location: 0),
        .init(color: Color(hex: 0x9C7350), location: 0.36),
        .init(color: Color(hex: 0x6B4528), location: 0.60),
        .init(color: Color(hex: 0x3A2414), location: 1),
    ]
    static let bezel = Color(hex: 0x16120D)
    /// `pa-ball`: lit from 40%/32% of the ball, 75% radius.
    static let ball: [Gradient.Stop] = [
        .init(color: Color(hex: 0xFFFCF4), location: 0),
        .init(color: Color(hex: 0xEFE7D4), location: 0.70),
        .init(color: Color(hex: 0xC9B997), location: 1),
    ]
    static let meridian = Color(hex: 0x5FE0EA)
    static let seam = Color(hex: 0xFF2433)
    /// `drop-shadow(0 2px 6px rgba(0,0,0,.5))`
    static let shadow = Color.black.opacity(0.5)
}
