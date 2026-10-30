import Foundation

// =============================================================================
// Slow-pitch Flight Lab — the rulebook side
// =============================================================================
// Line-for-line port of src/lib/slowpitch/zone.ts (web @ 47e21e6): the legal
// arc, the strike zone for a batter, and the plate and mat hit tests.
//
// The arc numbers here are the model's inputs. The rule text a visitor reads,
// and the source and confidence behind each figure, ship as Claims in the
// generated flight-lab.json, which the web builds from these same ARC_RULES so
// the two can never drift.
// =============================================================================

enum SlowpitchRuleKey: String, Codable, Hashable, CaseIterable {
    case usssa
    case usa
    case senior
}

struct SlowpitchArcRule: Codable, Hashable {
    /// How a strike is called: through the zone in the air, or by where it lands
    /// (Senior: on the plate or the mat behind it).
    enum Strike: String, Codable, Hashable {
        case zone
        case mat
    }

    /// Lowest legal arc, ft. Measured from the ground, or from the release point
    /// when `arcMinFromRelease` is set.
    let arcMin: Double
    /// Highest legal arc, ft above the ground.
    let arcMax: Double
    /// USSSA measures its floor as a rise of `arcMin` ft after the ball leaves the
    /// hand; the others measure the peak from the ground.
    let arcMinFromRelease: Bool
    let strike: Strike
}

extension SlowpitchRuleKey {
    /// This rulebook's arc rule (`ARC_RULES[rule]`).
    var arcRule: SlowpitchArcRule {
        switch self {
        case .usssa: return Slowpitch.ARC_RULES_USSSA
        case .usa: return Slowpitch.ARC_RULES_USA
        case .senior: return Slowpitch.ARC_RULES_SENIOR
        }
    }
}

extension Slowpitch {
    fileprivate static let ARC_RULES_USSSA = SlowpitchArcRule(arcMin: 3, arcMax: 10, arcMinFromRelease: true, strike: .zone)
    fileprivate static let ARC_RULES_USA = SlowpitchArcRule(arcMin: 6, arcMax: 10, arcMinFromRelease: false, strike: .zone)
    fileprivate static let ARC_RULES_SENIOR = SlowpitchArcRule(arcMin: 6, arcMax: 12, arcMinFromRelease: false, strike: .mat)

    /// The arc limits per rulebook, from each body's 2026 rule book:
    ///  - USSSA: at least 3 ft above the hand, no more than 10 ft above the ground.
    ///  - USA Softball adult slow pitch: 6 ft to 10 ft above the ground.
    ///  - USA Softball Senior slow pitch: 6 ft to 12 ft above the ground.
    static let ARC_RULES: [SlowpitchRuleKey: SlowpitchArcRule] = [
        .usssa: ARC_RULES_USSSA,
        .usa: ARC_RULES_USA,
        .senior: ARC_RULES_SENIOR,
    ]

    /// The legal peak window [min, max] in ft above the ground.
    static func legalArcWindow(_ rule: SlowpitchRuleKey, releaseHeight: Double = RELEASE.y) -> (Double, Double) {
        let r = rule.arcRule
        return (r.arcMinFromRelease ? releaseHeight / FT + r.arcMin : r.arcMin, r.arcMax)
    }

    /// The strike zone's bottom and top for a batter, in metres above the ground:
    /// the front knee to the shoulder. USSSA writes "highest shoulder to the bottom
    /// of the front knee", USA Softball "back shoulder to the front knee"; the model
    /// draws both at the same landmarks. Senior play has no zone in the air (strikes
    /// are called on the mat), so the band only frames the batter there.
    static func zoneBounds(_ heightIn: Double) -> (bottom: Double, top: Double) {
        let l = landmarks(heightIn)
        return (bottom: l.knee, top: l.shoulder)
    }

    /// Shortest distance from (px, pz) to the segment (ax, az)-(bx, bz).
    private static func distanceToSegment(
        _ px: Double, _ pz: Double, _ ax: Double, _ az: Double, _ bx: Double, _ bz: Double
    ) -> Double {
        let dx = bx - ax
        let dz = bz - az
        let t = SlowpitchJS.max(0, SlowpitchJS.min(1, ((px - ax) * dx + (pz - az) * dz) / (dx * dx + dz * dz)))
        return SlowpitchJS.hypot(px - (ax + t * dx), pz - (az + t * dz))
    }

    /// True when the point (x, z) on the ground is inside the plate's outline.
    static func insidePlate(_ x: Double, _ z: Double) -> Bool {
        var inside = false
        var j = PLATE_POLYGON.count - 1
        for i in 0..<PLATE_POLYGON.count {
            let (xi, zi) = PLATE_POLYGON[i]
            let (xj, zj) = PLATE_POLYGON[j]
            if (zi > z) != (zj > z) && x < ((xj - xi) * (z - zi)) / (zj - zi) + xi { inside = !inside }
            j = i
        }
        return inside
    }

    /// Distance from (x, z) to the plate, metres; 0 when over it.
    static func distanceToPlate(_ x: Double, _ z: Double) -> Double {
        if insidePlate(x, z) { return 0 }
        var best = Double.infinity
        var j = PLATE_POLYGON.count - 1
        for i in 0..<PLATE_POLYGON.count {
            best = SlowpitchJS.min(
                best,
                distanceToSegment(x, z, PLATE_POLYGON[j].0, PLATE_POLYGON[j].1, PLATE_POLYGON[i].0, PLATE_POLYGON[i].1)
            )
            j = i
        }
        return best
    }

    /// Senior strike test: the ball's centre comes down on the plate or the mat.
    static func onPlateOrMat(_ x: Double, _ z: Double) -> Bool {
        insidePlate(x, z) || (abs(x) <= MAT.halfWidth && z >= 0 && z <= MAT.length)
    }

    /// Inches past the plate's front edge for a depth z, metres.
    static func inchesPastFront(_ z: Double) -> Double {
        (z - PLATE.front) / IN
    }
}
