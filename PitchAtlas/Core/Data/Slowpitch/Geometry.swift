import Foundation

// =============================================================================
// Slow-pitch Flight Lab — units, field geometry and the ball
// =============================================================================
// Line-for-line port of the web repo's src/lib/slowpitch/geometry.ts
// (github.com/ahump20/Pitch-Atlas @ 47e21e6). Constants and identifiers keep
// their web names so the two can be audited side by side.
//
// Pure numbers, no SwiftUI and no SceneKit. Everything downstream (the flight,
// the zone, the batter, the verdict) reads from here, so a 3D scene, a 2D
// schematic and the page text can never disagree about where the plate is.
//
// Frame (metres, documented so the math is auditable):
//   x: across the plate. Negative x is the batter's side (the lefty box), so a
//      negative `side` on a lob is an inside pitch.
//   y: up from the ground.
//   z: along the pitch line, toward the catcher. The plate's front edge sits at
//      z = -8.5 in, the line where its straight sides end at z = 0, and its back
//      point at z = +8.5 in. The pitcher is at large negative z.
//
// The figures here are the model the original Flight Lab build ran on. The
// rulebook figures a visitor reads (arc limits, bat length) are sourced Claims
// in the web repo's src/data/softball/flightLab.ts, shipped to the app as
// generated JSON (see FlightLabContent); these are their model inputs.
// =============================================================================

/// A 3-vector: the integrator's working type (the web's `[number, number, number]`).
/// Named apart from the app's pitch `Vec3` so the two never collide.
struct SlowpitchVec3: Hashable {
    var x: Double
    var y: Double
    var z: Double

    init(_ x: Double, _ y: Double, _ z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    /// Index access, 0...2, for the ports of the web's tuple-indexed loops.
    subscript(i: Int) -> Double {
        get {
            switch i {
            case 0: return x
            case 1: return y
            default: return z
            }
        }
        set {
            switch i {
            case 0: x = newValue
            case 1: y = newValue
            default: z = newValue
            }
        }
    }
}

/// The slow-pitch model's namespace: constants and functions keep their web names.
enum Slowpitch {
    /// One foot, in metres.
    static let FT = 0.3048
    /// One inch, in metres.
    static let IN = 0.0254
    /// One mile per hour, in metres per second.
    static let MPH = 0.44704
    /// One revolution per minute, in radians per second.
    static let RPM = Double.pi / 30

    struct Plate: Hashable {
        let halfWidth: Double
        /// z of the front edge (the pitcher's side).
        let front: Double
        /// z of the back point.
        let back: Double
    }

    /// Home plate: 17 in wide, front edge to back point 17 in.
    static let PLATE = Plate(halfWidth: 8.5 * IN, front: -8.5 * IN, back: 8.5 * IN)

    /// The plate's outline in (x, z), front edge first, back point last.
    static let PLATE_POLYGON: [(Double, Double)] = [
        (-PLATE.halfWidth, PLATE.front),
        (PLATE.halfWidth, PLATE.front),
        (PLATE.halfWidth, 0),
        (0, PLATE.back),
        (-PLATE.halfWidth, 0),
    ]

    /// z of the pitcher's plate: 50 ft in front of the plate's back point.
    static let PITCHERS_PLATE_Z = PLATE.back - 50 * FT

    struct Mat: Hashable {
        let length: Double
        let halfWidth: Double
    }

    /// The strike mat used under Senior rules, as the original build modelled it: a
    /// 17 in wide rectangle running 32.5 in back from the line where the plate's
    /// straight sides end (z = 0). The plate itself covers the front.
    static let MAT = Mat(length: 32.5 * IN, halfWidth: 8.5 * IN)

    /// Where every modelled lob leaves the hand, in metres.
    static let RELEASE = SlowpitchVec3(-0.2, 0.86, -14)

    /// A 12 in circumference softball's radius, in metres.
    static let BALL_RADIUS = (12 * IN) / (2 * Double.pi)
    /// Cross-sectional area of the ball, m^2.
    static let BALL_AREA = Double.pi * BALL_RADIUS * BALL_RADIUS
    /// Ball mass, kg.
    static let BALL_MASS = 0.187
    /// Gravity, m/s^2.
    static let GRAVITY = 9.81
    /// Air density, kg/m^3.
    static let AIR_DENSITY = 1.2
    /// Drag coefficient. A constant, borrowed from baseball-style fits (approximate).
    static let DRAG_COEFFICIENT = 0.45

    static func cross(_ a: SlowpitchVec3, _ b: SlowpitchVec3) -> SlowpitchVec3 {
        SlowpitchVec3(a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
    }

    static func length(_ a: SlowpitchVec3) -> Double {
        SlowpitchJS.hypot(a[0], a[1], a[2])
    }

    static func scale(_ a: SlowpitchVec3, _ k: Double) -> SlowpitchVec3 {
        SlowpitchVec3(a[0] * k, a[1] * k, a[2] * k)
    }

    /// Unit vector along `a`; a zero vector comes back unchanged rather than NaN.
    static func normalize(_ a: SlowpitchVec3) -> SlowpitchVec3 {
        scale(a, 1 / SlowpitchJS.orOne(length(a)))
    }
}

// MARK: - JavaScript number semantics

/// The handful of JavaScript `Math` and `Number` behaviours the web model leans
/// on, reproduced exactly so the port lands on the same floats as the pinned
/// tables (which were generated in Node).
enum SlowpitchJS {
    /// `Math.hypot`, as V8 computes it: scale by the largest magnitude and sum
    /// the squares with Kahan compensation. A plain sqrt(x²+y²+z²) can differ in
    /// the last bit, and the pinned windows sit on 1 cm samples.
    /// Fixed arity (no arrays): the integrator calls this hundreds of thousands of
    /// times per solve.
    static func hypot(_ a: Double, _ b: Double, _ c: Double) -> Double {
        if a.isNaN || b.isNaN || c.isNaN {
            // V8 checks for an infinite argument before a NaN one.
            return a.isInfinite || b.isInfinite || c.isInfinite ? .infinity : .nan
        }
        let (x, y, z) = (abs(a), abs(b), abs(c))
        var max = 0.0
        if x > max { max = x }
        if y > max { max = y }
        if z > max { max = z }
        if max == .infinity { return .infinity }
        if max == 0 { return 0 }
        var sum = 0.0
        var compensation = 0.0
        kahanAdd(x / max, &sum, &compensation)
        kahanAdd(y / max, &sum, &compensation)
        kahanAdd(z / max, &sum, &compensation)
        return sum.squareRoot() * max
    }

    /// Two-argument `Math.hypot`. V8 sums only the arguments given, so this is
    /// the three-argument form with nothing after `b`.
    static func hypot(_ a: Double, _ b: Double) -> Double {
        if a.isNaN || b.isNaN {
            return a.isInfinite || b.isInfinite ? .infinity : .nan
        }
        let (x, y) = (abs(a), abs(b))
        var max = 0.0
        if x > max { max = x }
        if y > max { max = y }
        if max == .infinity { return .infinity }
        if max == 0 { return 0 }
        var sum = 0.0
        var compensation = 0.0
        kahanAdd(x / max, &sum, &compensation)
        kahanAdd(y / max, &sum, &compensation)
        return sum.squareRoot() * max
    }

    @inline(__always)
    private static func kahanAdd(_ n: Double, _ sum: inout Double, _ compensation: inout Double) {
        let summand = n * n - compensation
        let preliminary = sum + summand
        compensation = (preliminary - sum) - summand
        sum = preliminary
    }

    /// `Math.max(a, b)`: NaN wins, and +0 beats -0. (Swift's `max` drops a NaN.)
    static func max(_ a: Double, _ b: Double) -> Double {
        if a.isNaN || b.isNaN { return .nan }
        if a == 0 && b == 0 { return a.sign == .plus ? a : b }
        return a > b ? a : b
    }

    /// `Math.min(a, b)`: NaN wins, and -0 beats +0.
    static func min(_ a: Double, _ b: Double) -> Double {
        if a.isNaN || b.isNaN { return .nan }
        if a == 0 && b == 0 { return a.sign == .minus ? a : b }
        return a < b ? a : b
    }

    /// `Math.round`: half rounds toward +∞ (so -3.5 → -3), unlike Swift's
    /// `.rounded()`, which rounds half away from zero.
    static func round(_ x: Double) -> Double {
        if !x.isFinite { return x }
        let floor = x.rounded(.down)
        return x - floor >= 0.5 ? floor + 1 : floor
    }

    /// `x || 1` for a number: 0 and NaN are falsy.
    static func orOne(_ x: Double) -> Double {
        x == 0 || x.isNaN ? 1 : x
    }

    /// `String(n)` for the values the lab prints: integers without a ".0",
    /// -0 as "0", anything else as the shortest round-trip decimal.
    static func string(_ n: Double) -> String {
        if n.isNaN { return "NaN" }
        if n.isInfinite { return n < 0 ? "-Infinity" : "Infinity" }
        if n == n.rounded(.towardZero), abs(n) < 1e15 {
            return String(Int64(n))
        }
        return "\(n)"
    }

    /// `Number.prototype.toFixed(digits)`: the exact decimal value of the double,
    /// with a tie going to the larger magnitude. `String(format: "%.1f")` rounds
    /// an exact tie to even instead (0.25 → "0.2" where JS says "0.3").
    static func toFixed(_ x: Double, _ digits: Int) -> String {
        if x.isNaN { return "NaN" }
        if abs(x) >= 1e21 { return string(x) }
        if x < 0 {
            let body = toFixed(-x, digits)
            return "-" + body
        }
        // The exact expansion of a double this size terminates well before 80
        // fractional digits for any value the lab formats.
        let exact = String(format: "%.80f", x)
        let parts = exact.split(separator: ".", maxSplits: 1)
        var integer = Array(parts[0]).map { Int(String($0))! }
        let fraction = parts.count > 1 ? Array(parts[1]).map { Int(String($0))! } : []
        var kept = Array(fraction.prefix(digits))
        while kept.count < digits { kept.append(0) }
        let next = digits < fraction.count ? fraction[digits] : 0
        if next >= 5 {
            var i = kept.count - 1
            var carry = 1
            while carry == 1 && i >= 0 {
                kept[i] += 1
                if kept[i] == 10 { kept[i] = 0 } else { carry = 0 }
                i -= 1
            }
            var j = integer.count - 1
            while carry == 1 && j >= 0 {
                integer[j] += 1
                if integer[j] == 10 { integer[j] = 0 } else { carry = 0 }
                j -= 1
            }
            if carry == 1 { integer.insert(1, at: 0) }
        }
        let intText = integer.map(String.init).joined()
        return digits > 0 ? intText + "." + kept.map(String.init).joined() : intText
    }
}
