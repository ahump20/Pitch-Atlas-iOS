import Foundation
import CoreGraphics

// =============================================================================
// ShapeLab — the spin-axis sandbox's model
// =============================================================================
// Web: src/lib/sandbox.ts (buildBreak, tiltClock, ANCHOR_NOTE) and the address
// rules and copy of src/pages/SandboxPage.tsx. A teaching model, not a measured
// predictor: the one input is spin tilt on a clock face, the output is a shape
// read (ride, drop, arm-side run, glove-side sweep, or a blend). No rpm, no
// velocity, no efficiency, no inches. The spin axis still turns the schematic
// ball so the picture moves with the lesson.
// =============================================================================

struct ShapeBreak: Equatable {
    let tiltDegrees: Int
    let clock: String
    let verticalShape: VerticalShape
    let horizontalDir: HorizontalDir
    let shapeNote: String
    let spinAxis: Vec3

    /// The schematic's motion: Magnus, never gyro, read as movement.
    var motion: PitchMotion {
        PitchMotion(spinAxis: spinAxis, forceLabel: "Magnus", gyro: false, verticalShape: verticalShape,
                    horizontalDir: horizontalDir, breakView: .movement, indeterminateBreak: nil)
    }
}

enum ShapeLab {
    struct Preset: Hashable {
        let label: String
        let tilt: Int
    }

    /// SandboxPage's PRESETS.
    static let presets = [
        Preset(label: "12:00 ride", tilt: 0),
        Preset(label: "3:00 run", tilt: 90),
        Preset(label: "6:00 drop", tilt: 180),
        Preset(label: "9:00 sweep", tilt: 270),
        Preset(label: "Ride + run", tilt: 45),
        Preset(label: "Drop + sweep", tilt: 225),
    ]

    /// The slider's travel: 0 to 345 in steps of 15.
    static let tiltRange = 0...345
    static let tiltStep = 15

    // MARK: The site's words (SandboxPage.tsx, sandbox.ts)

    static let anchorNote = "A teaching model. Spin tilt sets the direction of the Magnus force: backspin creates ride, topspin creates drop, and sidespin creates run or sweep. This page describes shape only; it does not predict how far any arm moves a pitch."
    static let heroSub = "Spin is what gives the pitch its direction. Turn the clock and watch the seam ball and the plot redraw as ride, drop, arm-side run, or glove-side sweep, the way a right-handed pitcher sees it from the mound."
    static let presetNote = "Illustrative clock positions, not claims about a specific pitcher."
    static let tiltHint = "Where the spin points on a clock. 12:00 is pure backspin (ride); 6:00 is topspin (drop); 3:00 and 9:00 are pure sidespin."
    static let referenceNote = "Keep a sourced grip beside the experiment. Choosing a file leaves the spin tilt unchanged; the plot remains an illustrative model, not measured movement for that pitch."
    static let sideNote = "The plot\u{2019}s arm and glove sides are named from the ball\u{2019}s point of view; which physical side that is flips with the pitcher\u{2019}s hand."
    static let plotCaption = "Pitcher\u{2019}s eye"
    static let ballCaption = "From the side"

    static func ballLabel(_ tilt: Int) -> String {
        "The ball, oriented to a \(tiltClock(tilt)) spin tilt. The dashed line is the spin axis."
    }

    // MARK: The model

    private static func normalize(_ degrees: Int) -> Int { ((degrees % 360) + 360) % 360 }

    static func buildBreak(tiltDegrees: Int) -> ShapeBreak {
        let norm = normalize(tiltDegrees)
        let rad = Double(norm) * .pi / 180
        let vertical = cos(rad)
        let horizontal = sin(rad)
        let verticalShape: VerticalShape = vertical > 0.38 ? .ride : vertical < -0.38 ? .drop : .flat
        let horizontalDir: HorizontalDir = horizontal > 0.38 ? .armSide : horizontal < -0.38 ? .gloveSide : .none
        // (cos, −sin, 0) is already unit length
        let axis = Vec3(x: cos(rad), y: -sin(rad), z: 0)
        return ShapeBreak(tiltDegrees: norm, clock: tiltClock(norm), verticalShape: verticalShape,
                          horizontalDir: horizontalDir,
                          shapeNote: note(verticalShape, horizontalDir), spinAxis: axis)
    }

    private static func note(_ v: VerticalShape, _ h: HorizontalDir) -> String {
        switch (v, h) {
        case (.ride, .none): return "Pure ride. The pitch holds above the spinless path."
        case (.drop, .none): return "Pure drop. The pitch falls under the spinless path."
        case (.flat, .armSide): return "Pure arm-side run. The pitch slides toward the throwing arm side."
        case (.flat, .gloveSide): return "Pure glove-side sweep. The pitch slides toward the glove side."
        default:
            let vertical = v == .ride ? "ride" : v == .drop ? "drop" : "flat carry"
            let side = h == .armSide ? "arm-side run" : h == .gloveSide ? "glove-side sweep" : "no side action"
            return "Blended shape: \(vertical) with \(side)."
        }
    }

    /// A tilt in degrees (0 = 12:00, clockwise) as a clock, "1:30".
    static func tiltClock(_ degrees: Int) -> String {
        let total = Int((Double(normalize(degrees)) / 360 * 12 * 60).rounded())
        let hour = (total / 60) % 12
        return "\(hour == 0 ? 12 : hour):\(String(format: "%02d", total % 60))"
    }

    /// The slider's spoken value, the clock and the shape it makes: "3:00 run".
    static func spokenTilt(_ degrees: Int) -> String {
        let r = buildBreak(tiltDegrees: degrees)
        return "\(r.clock), \(r.shapeNote)"
    }

    // MARK: The address (SandboxPage's ?tilt= and ?pitch=)

    /// Only whole digits from 0 to 345 on a 15° stop; anything else is the stock 12:00.
    static func parseTilt(_ raw: String?) -> Int {
        guard let raw, !raw.isEmpty, raw.allSatisfy({ $0.isASCII && $0.isNumber }),
              let tilt = Int(raw), tiltRange.contains(tilt), tilt % tiltStep == 0 else { return presets[0].tilt }
        return tilt
    }

    /// A filed pitch, or no reference.
    static func reference(_ raw: String?, store: PitchStore) -> PitchAtlasEntry? {
        raw.flatMap { store.pitch(slug: $0) }
    }
}

/// MovementPlot.tsx's geometry: a right-handed pitcher's view from the mound, ARM on
/// the right. The pitch sits a fixed schematic offset from the spinless ball toward
/// the way it breaks — direction, never magnitude.
enum ShapePlot {
    static let width: CGFloat = 360
    static let height: CGFloat = 240
    static let center = CGPoint(x: 178, y: 116)
    static let ballRadius: CGFloat = 17
    /// A fixed offset by direction, not a measured magnitude.
    static let step: CGFloat = 60
    static let clamp: CGFloat = 92

    static func offset(_ r: ShapeBreak) -> CGVector {
        let dy: CGFloat = r.verticalShape == .ride ? -step : r.verticalShape == .drop ? step : 0
        let dx: CGFloat = r.horizontalDir == .armSide ? step : r.horizontalDir == .gloveSide ? -step : 0
        return CGVector(dx: dx, dy: dy)
    }

    static func label(_ r: ShapeBreak, pitchName: String) -> String {
        let vertical = r.verticalShape == .ride ? "rides" : r.verticalShape == .drop ? "drops" : "holds flat"
        let side = r.horizontalDir == .armSide ? "runs arm-side" : r.horizontalDir == .gloveSide ? "sweeps glove-side" : "stays true"
        return "Shape of a \(pitchName) as a right-handed pitcher sees it from the mound. Against a spinless ball at center, it \(vertical) and \(side). A schematic of direction, not a measured magnitude."
    }
}
