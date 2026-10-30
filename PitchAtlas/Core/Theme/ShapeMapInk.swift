import SwiftUI

/// The Shape map's family colors, written raw in web sections/MovementMap.tsx
/// FAMILY_META, and its tooltip ground.
enum ShapeMapInk {
    static let fastball = Color(hex: 0xBF5700)
    static let breaking = Color(hex: 0x5FE0EA)
    static let offspeed = Color(hex: 0xD8CFBB)

    static func family(_ family: PitchFamily) -> Color {
        switch family {
        case .fastball: fastball
        case .breaking: breaking
        case .offspeed: offspeed
        }
    }
}
