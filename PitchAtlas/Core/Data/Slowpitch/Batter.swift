import Foundation

// =============================================================================
// Slow-pitch Flight Lab — the batter
// =============================================================================
// Line-for-line port of src/lib/slowpitch/batter.ts (web @ 47e21e6): one
// measured swing, scaled to any height.
//
// The default is one batter's real swing, measured from their own video and
// calibrated off home plate (confidence `community-firsthand`; the source and
// note ship in flight-lab.json as `measuredBatter`). It is never named. Every
// ratio below is a fraction of standing height so the same swing scales to a
// taller or shorter batter. The barrel angle at contact comes from one swing and
// is unverified.
//
// The lab's idea: your eyes judge a lob over the plate, but the barrel meets it
// out front, where a falling lob is still higher. So contact sits a stride and
// an arm's reach in front of where the batter stands, and the sweet spot reaches
// a fixed distance from the hands.
// =============================================================================

enum SlowpitchBoxPosition: String, Codable, Hashable, CaseIterable {
    case front
    case middle
    case back
}

/// Where and how a batter stands. Lengths in inches.
struct SlowpitchStance: Codable, Hashable {
    /// Standing height.
    var heightIn: Double
    /// Toes to the plate's inside edge.
    var toesIn: Double
    /// Where in the box.
    var box: SlowpitchBoxPosition
    /// Bat length.
    var batIn: Double
}

/// Landmark heights (metres from `landmarks`, or fractions of height in `BATTER_MODEL`).
struct SlowpitchLandmarks: Codable, Hashable {
    let knee: Double
    let belt: Double
    let chest: Double
    let shoulder: Double
}

/// How the barrel meets a ball at a given distance across the plate.
struct SlowpitchReach: Hashable {
    enum Side: String, Hashable {
        case barrel
        case jam
        case end
    }

    /// How far in front of the pivot contact happens, metres.
    let forward: Double
    /// Angle of the bat from straight out across the plate, degrees.
    let angleDeg: Double
    /// 1 on the sweet spot, fading to 0 toward the hands or off the end.
    let lateral: Double
    /// Where on the bat it lands.
    let side: Side
}

/// What the 34 in bat changes against a shorter one, for a ball down the middle.
struct SlowpitchBatComparison {
    /// How much farther the sweet spot reaches, inches.
    let reachGapIn: Double
    /// Out front of the pivot at contact, inches: (this bat, the other bat).
    let outFrontIn: (Double, Double)
    /// How much farther off the plate to stand to meet the ball where the other
    /// bat did, inches.
    let matchShiftIn: Double
}

extension Slowpitch {
    /// The measured batter's stance: 5 ft 2 in, toes 22 in off the plate, middle of
    /// the box, a 34 in bat.
    static let DEFAULT_STANCE = SlowpitchStance(heightIn: 62, toesIn: 22, box: .middle, batIn: 34)

    /// Bat diameter, for labels (34 x 2 1/4 in). Not a model input.
    static let BAT_DIAMETER_IN = 2.25

    /// Bat lengths the lab compares against (a batter's old baseball or softball bat).
    static let COMPARE_BATS: [Double] = [31, 32, 33]

    struct BatterModel {
        /// Landmark heights as fractions of standing height.
        let landmarks: SlowpitchLandmarks
        /// Stance centre's distance off the toes line, per inch of height.
        let stanceDepthPerHeight: Double
        /// Stride toward the pitcher at contact, per inch of height.
        let stridePerHeight: Double
        /// Hands' reach from the body at contact, per inch of height.
        let armReachPerHeight: Double
        /// Sweet spot, inches in from the barrel end.
        let sweetSpotFromEndIn: Double
        /// Hands' grip point, inches up the handle from the knob (read from the
        /// model's own arithmetic, not a separate measurement).
        let handsFromKnobIn: Double
        /// Barrel angle at contact, degrees below level (one swing; unverified).
        let barrelAngleDeg: Double
        /// Beyond this angle from straight out, contact moves toward the hands.
        let maxContactAngleDeg: Double
        /// Degrees past that angle over which the barrel fades to the hands.
        let contactAngleFalloffDeg: Double
        /// Inches past full reach over which the barrel fades off the end.
        let endFalloffIn: Double
        /// Heights within this many inches beyond the knee or shoulder still rate.
        let bodyBandIn: Double
        /// Score at or above which a pitch is "your pitch".
        let hotThreshold: Double
        /// Score at or above which a pitch is still reachable on the barrel.
        let warmThreshold: Double
        /// Box position along the pitch line, inches (front is toward the pitcher).
        let boxOffsetIn: [SlowpitchBoxPosition: Double]
    }

    /// The measured swing's proportions.
    static let BATTER_MODEL = BatterModel(
        landmarks: SlowpitchLandmarks(knee: 0.242, belt: 0.503, chest: 0.661, shoulder: 0.79),
        stanceDepthPerHeight: 0.089,
        stridePerHeight: 0.16,
        armReachPerHeight: 0.3432,
        sweetSpotFromEndIn: 6,
        handsFromKnobIn: 3,
        barrelAngleDeg: 10,
        maxContactAngleDeg: 52,
        contactAngleFalloffDeg: 16,
        endFalloffIn: 3,
        bodyBandIn: 6,
        hotThreshold: 0.8,
        warmThreshold: 0.5,
        boxOffsetIn: [.front: -16, .middle: 0, .back: 16]
    )

    /// The batter's landmark heights for a standing height, metres.
    static func landmarks(_ heightIn: Double) -> SlowpitchLandmarks {
        let h = heightIn * IN
        let r = BATTER_MODEL.landmarks
        return SlowpitchLandmarks(knee: r.knee * h, belt: r.belt * h, chest: r.chest * h, shoulder: r.shoulder * h)
    }

    /// Distance from the hands to the sweet spot at contact, metres: the arm's reach
    /// plus the bat from grip to sweet spot, laid back by the barrel angle.
    static func sweetSpotReach(_ heightIn: Double, _ batIn: Double) -> Double {
        let m = BATTER_MODEL
        let barrel = (batIn - m.sweetSpotFromEndIn - m.handsFromKnobIn) * cos((m.barrelAngleDeg * Double.pi) / 180)
        return (m.armReachPerHeight * heightIn + barrel) * IN
    }

    /// Where the batter stands, (x, z) metres. x is on the batter's side (negative).
    static func stanceSpot(_ stance: SlowpitchStance) -> (x: Double, z: Double) {
        (
            x: -(PLATE.halfWidth + (stance.toesIn + BATTER_MODEL.stanceDepthPerHeight * stance.heightIn) * IN),
            z: BATTER_MODEL.boxOffsetIn[stance.box]! * IN
        )
    }

    /// The pivot the swing turns on at contact: the stance spot after the stride.
    static func contactPivot(_ stance: SlowpitchStance) -> (x: Double, z: Double) {
        let s = stanceSpot(stance)
        return (x: s.x, z: s.z - BATTER_MODEL.stridePerHeight * stance.heightIn * IN)
    }

    /// Meet a ball `x` metres across the plate. Out of reach, the ball fades off the
    /// end of the bat. In reach, contact sits in front of the pivot on the reach
    /// circle; a ball too close in forces the bat round and jams the hands.
    static func reachAt(_ stance: SlowpitchStance, _ x: Double) -> SlowpitchReach {
        let m = BATTER_MODEL
        let r = sweetSpotReach(stance.heightIn, stance.batIn)
        let across = x - contactPivot(stance).x
        if across >= r {
            let lateral = SlowpitchJS.max(0, 1 - (across - r) / IN / m.endFalloffIn)
            return SlowpitchReach(forward: 0, angleDeg: 0, lateral: lateral, side: lateral < m.warmThreshold ? .end : .barrel)
        }
        let forward = (r * r - across * across).squareRoot()
        let angleDeg = (atan2(forward, across) * 180) / Double.pi
        let lateral = angleDeg <= m.maxContactAngleDeg
            ? 1
            : SlowpitchJS.max(0, 1 - (angleDeg - m.maxContactAngleDeg) / m.contactAngleFalloffDeg)
        return SlowpitchReach(forward: forward, angleDeg: angleDeg, lateral: lateral, side: lateral < m.warmThreshold ? .jam : .barrel)
    }

    /// How good a contact height is for this batter, 0..1: full marks from the belt
    /// to the chest, easing off toward the knee and the shoulder, and gone a few
    /// inches past either.
    static func heightComfort(_ heightIn: Double, _ y: Double) -> Double {
        let l = landmarks(heightIn)
        let (knee, belt, chest, shoulder) = (l.knee, l.belt, l.chest, l.shoulder)
        let band = BATTER_MODEL.bodyBandIn * IN
        if y >= belt && y <= chest { return 1 }
        if y < belt {
            return y >= knee
                ? 0.4 + (0.6 * (y - knee)) / (belt - knee)
                : SlowpitchJS.max(0, 0.4 * (1 - (knee - y) / band))
        }
        return y <= shoulder
            ? 1 - (0.55 * (y - chest)) / (shoulder - chest)
            : SlowpitchJS.max(0, 0.45 * (1 - (y - shoulder) / band))
    }

    /// Compare the stance's bat with a bat of `otherIn` inches.
    static func compareBats(_ stance: SlowpitchStance, _ otherIn: Double) -> SlowpitchBatComparison {
        let across = -contactPivot(stance).x
        let r = sweetSpotReach(stance.heightIn, stance.batIn)
        let rOther = sweetSpotReach(stance.heightIn, otherIn)
        let forward = SlowpitchJS.max(0, r * r - across * across).squareRoot()
        let forwardOther = SlowpitchJS.max(0, rOther * rOther - across * across).squareRoot()
        let acrossToMatch = SlowpitchJS.max(0, r * r - forwardOther * forwardOther).squareRoot()
        return SlowpitchBatComparison(
            reachGapIn: (r - rOther) / IN,
            outFrontIn: (forward / IN, forwardOther / IN),
            matchShiftIn: (acrossToMatch - across) / IN
        )
    }
}
