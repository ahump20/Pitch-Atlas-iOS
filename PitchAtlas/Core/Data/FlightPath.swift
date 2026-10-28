import Foundation

// =============================================================================
// FlightPath — the flight figure's geometry
// =============================================================================
// Web: lib/flightPath.ts (TunnelPlot draws it) and lib/physics.ts's
// magnusStrength. The endpoint is the sourced shape bucket; the side and the
// rise a path bends toward come from those same words; the authored spin vector
// only sets how late it leaves the shared line. Layout units, never a
// measurement.
// =============================================================================

enum FlightPath {
    static let w: Double = 360
    static let h: Double = 380
    static let cx: Double = w / 2
    static let cy: Double = 232
    /// horizontal direction offset
    static let col: Double = 96
    /// vertical direction offset
    static let row: Double = 76
    static let clamp: Double = 124
    /// half the length of the vertical axis through the spinless endpoint
    static let axis: Double = 100
    /// the shared release, at the top of the frame: one point both pitches leave from
    static let releaseY: Double = 24
    /// the tunnel window, where two well-tunneled pitches still look like one pitch:
    /// below the release and above every endpoint, so each path falls from it
    static let tunnelY: Double = 80
    /// how far each of a pair that breaks the same way is pushed aside
    static let nudge: Double = 26

    struct Spot: Equatable {
        /// endpoint, in the sourced break direction
        let x: Double
        let y: Double
        /// the cubic's control points, from the release to the endpoint
        let c1x: Double
        let c1y: Double
        let c2x: Double
        let c2y: Double
    }

    private static func side(_ dir: HorizontalDir) -> Double {
        dir == .armSide ? 1 : dir == .gloveSide ? -1 : 0
    }

    /// render +y is up; the figure's y runs down
    private static func rise(_ shape: VerticalShape?) -> Double {
        shape == .ride ? 1 : shape == .drop ? -1 : 0
    }

    /// The spin's share across the line of flight: the length of the unit spin axis
    /// crossed with the render velocity (0, 0, -1). A zero axis has none.
    static func magnusStrength(_ spinAxis: Vec3) -> Double {
        let length = (spinAxis.x * spinAxis.x + spinAxis.y * spinAxis.y + spinAxis.z * spinAxis.z).squareRoot()
        let scale = length == 0 ? 1 : length
        let x = spinAxis.x / scale, y = spinAxis.y / scale
        // (x, y, z) × (0, 0, -1) = (-y, x, 0)
        return (x * x + y * y).squareRoot()
    }

    /// Two pitches that break the same way share an endpoint, so the figure
    /// nudges them apart and both read.
    static func sameCell(_ a: PitchMotion, _ b: PitchMotion) -> Bool {
        a.verticalShape == b.verticalShape && a.horizontalDir == b.horizontalDir
    }

    /// One pitch's path, mirrored for handedness (1 right, -1 left). A spinless
    /// ball would fall straight from the release to the center. A pitch's break
    /// adds to that line late, toward the side and the rise its shape words name:
    /// the first control point sits a third of the way down the spinless line,
    /// the second between that line and the endpoint.
    static func plot(_ motion: PitchMotion, handFactor: Double, nudge: Double = 0) -> Spot {
        let x = max(cx - clamp, min(cx + clamp, cx + side(motion.horizontalDir) * handFactor * col + nudge))
        let y = cy - rise(motion.verticalShape) * row
        // 0 for full Magnus .. 0.6 for a pure gyro; past 0.6 a late ride would hook back up
        let late = 0.6 * (1 - max(0, min(1, magnusStrength(motion.spinAxis))))
        return Spot(x: x, y: y,
                    c1x: cx, c1y: releaseY + (cy - releaseY) / 3,
                    c2x: (cx + (1 + late) * cx + (1 - late) * x) / 3,
                    c2y: (releaseY + (1 + late) * cy + (1 - late) * y) / 3)
    }

    /// The direction words the figure draws, for its spoken name (TunnelPlot.tsx).
    static func shapeWords(_ motion: PitchMotion) -> String {
        if motion.indeterminateBreak == true { return "with no fixed direction" }
        let vertical = motion.verticalShape == .ride ? "riding" : motion.verticalShape == .drop ? "dropping" : "holding flat"
        let horizontal = motion.horizontalDir == .armSide ? " toward the arm side"
            : motion.horizontalDir == .gloveSide ? " toward the glove side" : ""
        return vertical + horizontal
    }
}
