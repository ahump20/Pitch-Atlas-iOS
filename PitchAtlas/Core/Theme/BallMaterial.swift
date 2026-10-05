import SwiftUI
import UIKit

/// The ball's physical materials — hide, seam, lacing and the 3D studio rig.
/// These are material colors, not UI tokens, so they live here beside the
/// generated palette rather than in it. Each names the web file it ports
/// (web main 3f518f6); "native" marks a value the app authored with no web
/// counterpart.
enum BallMaterial {
    // MARK: - 2D hide and seam (SeamBall)
    /// Matte hide, light to shadow — web fallback/BaseballCover.tsx radial.
    static let hide: [UInt32] = [0xFCFBF5, 0xF0EFE8, 0xD9D8D1, 0x9B9C96, 0x575B59]
    /// Pore speckle in the hide — native.
    static let pore: UInt32 = 0x746F63
    /// The seam groove under the lacing — native.
    static let seamGroove: UInt32 = 0x655B51
    /// The groove's lit lip — native.
    static let seamLip: UInt32 = 0xF8F3E8
    /// Lacing shadow under each stitch — native.
    static let lacingShadow: UInt32 = 0x573831
    /// Stitch red — web fallback/SeamSchematic.tsx and refractor/RefractorBall.tsx.
    static let stitch: UInt32 = 0x9E2B35
    /// Stitch crown highlight — native.
    static let stitchCrown: UInt32 = 0xD88269

    // MARK: - 3D specimen (SpecimenSceneBuilder)
    /// Seam tube thread — native.
    static let thread: UInt32 = 0x594A40
    /// Waxed stitch-crown emission — native (from the earlier web model's emissive).
    static let stitchEmission: UInt32 = 0x3A0810
    /// Warm key light — web brand/BrandMark.tsx highlight.
    static let keyLight: UInt32 = 0xFFFCF4
    /// Cool fill light — native.
    static let fillLight: UInt32 = 0xC8DAF2
    /// Finger-pad contact markers — native.
    static let fingerPad: UInt32 = 0xCFC4AC
    /// Spin-axis arrow — web ball/three/Vectors.tsx.
    static let axis: UInt32 = 0xC7BEA8

    static func color(_ rgb: UInt32) -> Color { Color(rgb: rgb) }
    static func uiColor(_ rgb: UInt32) -> UIColor { UIColor(web: WebColor(rgb: rgb, alpha: 1)) }
}
