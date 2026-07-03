import Foundation
import simd

// =============================================================================
// ContactPose — where an authored finger contact sits on the leather
// =============================================================================
// Pure port of the contact head of the web's src/lib/gripPose.ts: one authored
// contact (seamT + seamOffset + azimuth + engagement + pressureTier) maps to a
// contact point on the unit sphere, its outward normal, and the finger-spine
// direction laid through it. The 3D contact pads, their shadow decals, and the
// numbered pips all read this one solver, so the pad can never sit off the
// authored seam anchor. No rendering imports — renderer-agnostic on purpose.
//
// Conventions (shared with SeamMath and the web):
//  - the ball is the unit sphere; distances are in ball radii, which on the
//    unit sphere are also radians of surface arc.
//  - seamOffset is signed surface arc perpendicular to the seam path: 0 = the
//    contact sits on the seam, positive = toward the open leather.
//  - azimuth is the finger-spine direction relative to the seam tangent, in
//    degrees: 0 rides along the seam like a rail, +/-90 crosses it square.
//  - handedness .left mirrors x, matching the web ball renderer's mirror.
// =============================================================================

/// The solved pose for one authored contact.
struct ContactPose {
    /// The contact point on the unit sphere.
    let contact: SIMD3<Double>
    /// Outward surface normal at the contact (the normalized contact point).
    let normal: SIMD3<Double>
    /// Direction the finger points, tangent to the surface at the contact.
    let spineDir: SIMD3<Double>
    /// Rendered pad radius, in ball radii: the finger's width scaled by its
    /// pressure tier. A specimen hand, not anatomy.
    let padRadius: Double
    /// How proud of the leather the contact sits: the engagement's lift plus
    /// the authored per-contact lift.
    let lift: Double
}

enum ContactPoseSolver {

    /// How proud of the leather each engagement holds the contact (the web
    /// ENGAGEMENT table's contactLift column, ported exactly): a nail or a
    /// knuckle holds the flesh off the ball; a wedged-deep inside grip barely
    /// lifts at all.
    static let engagementLift: [FingerEngagement: Double] = [
        .tip: 0.006,
        .pad: 0.004,
        .inside: 0.003,
        .nail: 0.04,
        .knuckle: 0.055,
    ]

    /// Pressure widens the rendered pad (the web PRESSURE_RADIUS table,
    /// ported exactly).
    static let pressureRadiusFactor: [PressureTier: Double] = [
        .primary: 1.1,
        .support: 1.0,
        .light: 0.92,
    ]

    /// Rendered finger widths, in ball radii (the web FINGER table's radius
    /// column, ported exactly). A specimen hand, not anatomy.
    static let fingerRadius: [Finger: Double] = [
        .thumb: 0.155,
        .index: 0.125,
        .middle: 0.13,
        .ring: 0.12,
        .pinky: 0.1,
    ]

    /// Map one authored contact to its pose on the leather.
    ///
    /// The contact point starts on the seam at seamT, is displaced perpendicular
    /// to the seam path by seamOffset (surface arc), and the spine direction is
    /// the seam tangent swung by `azimuth` degrees about the surface normal.
    /// Everything is deterministic from the authored fields.
    static func solve(_ contact: GripContactModel, handedness: Handedness = .right) -> ContactPose {
        let t = contact.seamT * 2 * .pi
        let onSeam = simd_normalize(SeamMath.seamRaw(t))
        let tangent = SeamMath.seamTangent(t)
        let across = simd_normalize(simd_cross(onSeam, tangent))

        // displace perpendicular to the seam path along the surface
        let contactPoint = SeamMath.surfaceWalk(from: onSeam, along: across, arc: contact.seamOffset)
        let normal = contactPoint
        let tangentAtContact = SeamMath.tangentialize(tangent, at: contactPoint)

        // the finger-spine direction: seam tangent swung by azimuth about the normal
        let spineDir = simd_normalize(
            SeamMath.rotate(tangentAtContact, aboutAxis: normal, by: contact.azimuth * .pi / 180)
        )

        let padRadius = (fingerRadius[contact.finger] ?? 0.125)
            * (pressureRadiusFactor[contact.pressureTier] ?? 1.0)
        let lift = (engagementLift[contact.engagement] ?? 0.004) + contact.lift

        if handedness == .left {
            let mirror = SIMD3<Double>(-1, 1, 1)
            return ContactPose(
                contact: contactPoint * mirror,
                normal: normal * mirror,
                spineDir: spineDir * mirror,
                padRadius: padRadius,
                lift: lift
            )
        }
        return ContactPose(
            contact: contactPoint,
            normal: normal,
            spineDir: spineDir,
            padRadius: padRadius,
            lift: lift
        )
    }
}
