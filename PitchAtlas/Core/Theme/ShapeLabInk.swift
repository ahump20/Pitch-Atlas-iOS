import SwiftUI

/// Shape Lab's figures. The site writes these raw in its SVGs (web
/// src/components/fallback/MovementPlot.tsx, the leather gradient and the spinless
/// ball) and its stage spot (index.css .stage-spot), so they are ported here by hand.
enum ShapeLabInk {
    /// MovementPlot's radialGradient: #16171C at 0, #101116 at 62%, #070709 at 100%.
    static let leatherHigh = Color(hex: 0x16171C)
    static let leatherMid = Color(hex: 0x101116)
    static let leatherLow = Color(hex: 0x070709)
    /// The spinless reference ball's fill.
    static let spinless = Color(hex: 0x101116)
    /// .stage-spot: rgba(238,240,246,.12) at 50% 40%, gone by 60%.
    static let stageSpot = Color(hex: 0xEEF0F6, opacity: 0.12)
}
