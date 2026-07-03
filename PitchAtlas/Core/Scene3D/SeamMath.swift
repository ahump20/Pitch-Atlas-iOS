import Foundation
import simd

// =============================================================================
// SeamMath — the one seam-point function, in simd
// =============================================================================
// Pure port of the web repo's src/lib/seam.ts. Every native seam — the 2D
// schematic in SeamBall, the 3D tube in SpecimenSceneBuilder, the stitch
// placement, and the contact solver — reads this one file, so the model and
// the diagram can never disagree. No rendering imports: renderer-agnostic on
// purpose so a future RealityKit adapter reuses it unchanged.
//
// Curve: the canonical closed-form figure-eight seam (same as the web):
//
//     x = 2 sin t + sin 3t
//     y = 2 cos t - cos 3t
//     z = 2 sqrt(2) cos 2t      for t in [0, 2 PI]
//
// The raw curve does not sit on a sphere, so every point is normalized to the
// unit ball. This is a seam-informed schematic, not a measured cover geometry.
// =============================================================================

enum SeamMath {

    /// Raw figure-eight curve, before it is placed on the sphere.
    static func seamRaw(_ t: Double) -> SIMD3<Double> {
        SIMD3(
            2 * sin(t) + sin(3 * t),
            2 * cos(t) - cos(3 * t),
            2 * 2.0.squareRoot() * cos(2 * t)
        )
    }

    /// A seam point on the unit sphere, at parameter t in [0, 2 PI].
    static func seamPoint(_ t: Double) -> SIMD3<Double> {
        simd_normalize(seamRaw(t))
    }

    /// Evenly spaced seam points (no duplicate closing point), for placing
    /// stitches and the leather maps' seam-distance field.
    static func seamSamples(_ count: Int) -> [SIMD3<Double>] {
        (0..<count).map { seamPoint(Double($0) / Double(count) * 2 * .pi) }
    }

    /// Seam tangent at parameter t (radians), from the analytic curve by central
    /// differences, projected to the sphere's tangent plane at the normalized
    /// seam point. Mirrors the web's gripPose.ts seamTangent exactly.
    static func seamTangent(_ t: Double) -> SIMD3<Double> {
        let e = 1e-4
        let a = simd_normalize(seamRaw(t - e))
        let b = simd_normalize(seamRaw(t + e))
        let p = simd_normalize(seamRaw(t))
        let d = b - a
        return tangentialize(d, at: p)
    }

    /// Walk from a unit-sphere point along a unit tangent direction by `arc`
    /// radians of great-circle surface arc.
    static func surfaceWalk(from p: SIMD3<Double>, along dir: SIMD3<Double>, arc: Double) -> SIMD3<Double> {
        simd_normalize(p * cos(arc) + dir * sin(arc))
    }

    /// Rodrigues rotation of p about a unit axis by angle radians.
    static func rotate(_ p: SIMD3<Double>, aboutAxis axis: SIMD3<Double>, by angle: Double) -> SIMD3<Double> {
        let k = simd_normalize(axis)
        let cosA = cos(angle)
        let sinA = sin(angle)
        let kc = simd_cross(k, p)
        let kd = simd_dot(k, p) * (1 - cosA)
        return p * cosA + kc * sinA + k * kd
    }

    /// Project a direction onto the tangent plane at a unit-sphere point.
    static func tangentialize(_ dir: SIMD3<Double>, at p: SIMD3<Double>) -> SIMD3<Double> {
        let radial = p * simd_dot(dir, p)
        return simd_normalize(dir - radial)
    }

    /// Near-horizontal backspin axis, in the same space as the seam. Shared
    /// default; each specimen carries its own authored `motion.spinAxis`.
    static let spinAxis: SIMD3<Double> = simd_normalize(SIMD3(1, 0.12, 0))

    /// Presentation tilt applied to the seam so the horseshoe faces the viewer —
    /// the same view choice the web ball and schematic share. A view choice,
    /// not geometry.
    static let viewTiltAxis: SIMD3<Double> = simd_normalize(SIMD3(0.2, 1, 0.35))
    static let viewTiltAngle: Double = 0.62
}
