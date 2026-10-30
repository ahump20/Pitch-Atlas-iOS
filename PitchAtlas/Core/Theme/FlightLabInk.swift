import SwiftUI

/// The Flight Lab's colors, written raw in web pages/SoftballFlightLabPage.tsx
/// (TONE_CLASS, the stage box) and components/flightlab/FlightLabSchematic.tsx
/// (the amber landmarks, the ground, the hatch, the mat, the thrown ball).
enum FlightLabInk {
    static let stage = Color(hex: 0x070509)
    static let amber = Color(hex: 0xFFC23C)
    static let warn = Color(hex: 0xFF8A3D)
    static let bad = Color(hex: 0xFF5A6B)
    static let groundTop = Color(hex: 0x2A1D12)
    static let groundBottom = Color(hex: 0x120D09)
    static let mat = Color(hex: 0x3E6B4C)
    static let ball = Color(hex: 0xE8EE6A)
    static let ballEdge = Color(hex: 0x1A1A0A)
    /// rgba(7,5,9,0.82): the tag panels and the ruler's ground.
    static let panel = Color(hex: 0x070509, opacity: 0.82)

    /// A lob's color, from the generated lob record's "#RRGGBB".
    static func lob(_ hex: String) -> Color {
        Color(hex: UInt(hex.dropFirst(), radix: 16) ?? 0xF6F1E6)
    }
}
