import Foundation

// =============================================================================
// Slow-pitch Flight Lab — the verdicts
// =============================================================================
// Line-for-line port of src/lib/slowpitch/verdict.ts (web @ 47e21e6): what the
// umpire calls, what the batter's barrel makes of it, and the landing window to
// look for. One set of functions feeds a 3D scene, a 2D schematic and the words
// on the page.
// =============================================================================

/// The umpire's side of a pitch.
struct SlowpitchPitchCall {
    /// Why the arc is or is not legal.
    enum ArcWhy: String, Hashable {
        case ok
        case flat
        case high
    }

    enum Call: String, Hashable {
        case strike
        case ball
        case illegal
    }

    /// Which way a ball missed.
    enum Miss: String, Hashable {
        case none
        case short
        case long
        case inside
        case outside
    }

    /// A span of landing depths, metres.
    struct Lane: Hashable {
        let min: Double
        let max: Double
    }

    let arcLegal: Bool
    let arcWhy: ArcWhy
    /// Did it pass the strike test (the zone in the air, or the mat for Senior)?
    let strike: Bool
    let call: Call
    let miss: Miss
    /// The landing depths (z, metres) that would make this arc a strike.
    let lane: Lane
    /// Inches from the landing spot to the nearer end of the lane (negative outside it).
    let depthMarginIn: Double
    /// Inches inside the plate's edge (negative outside it).
    let sideMarginIn: Double
}

/// The batter's side of a pitch.
struct SlowpitchBatterContact {
    struct Contact: Hashable {
        let x: Double
        let y: Double
        let z: Double
        let forward: Double
        let angleDeg: Double
    }

    enum Kind: String, Hashable {
        case pitch
        case jam
        case end
        case low
        case high
    }

    /// Where the barrel meets the ball, or nil when the ball is down before it gets there.
    let contact: Contact?
    /// 0..1, sweet spot across the bat.
    let lateral: Double
    /// 0..1, how good the contact height is.
    let vertical: Double
    /// lateral x vertical.
    let score: Double
    let kind: Kind
}

/// The landing window to look for at this arc.
struct SlowpitchLookFor {
    /// Inches past the plate's front edge where this arc is "your pitch".
    let hot: (Double, Double)?
    /// Inches past the front edge where it still reaches the barrel.
    let warm: (Double, Double)?
    /// Heights over the plate (inches) of the hot window's ends: (deepest, shortest).
    let crossing: (Double, Double)?
}

/// A grid of barrel scores over the plate face, for the heat overlay.
struct SlowpitchReachHeatMap {
    /// Row-major scores, ny rows of nx. Row 0 is the ground. (Float32, as on the web.)
    let values: [Float]
    let nx: Int
    let ny: Int
    /// x range, metres.
    let x: (Double, Double)
    /// y range, metres.
    let y: (Double, Double)
}

/// The headline a batter reads.
struct SlowpitchVerdict: Hashable {
    enum Tone: String, Hashable {
        case good
        case warn
        case dim
        case bad
    }

    /// The full headline, e.g. "Strike · jams you".
    let word: String
    /// The short form for a list row: Your pitch, Jams you, Too low, Too high, Off the end, Ball, Illegal.
    let short: String
    let tone: Tone
}

/// Everything the page says about one pitch, for one batter, under one rulebook.
struct SlowpitchPitchReading {
    let call: SlowpitchPitchCall
    let contact: SlowpitchBatterContact
    let verdict: SlowpitchVerdict
    /// Landing window to look for, scored for a ball down the middle.
    let lookFor: SlowpitchLookFor
    /// The strike lane, inches past the front edge.
    let strikeWindowIn: (Double, Double)
    /// Peak height, ft.
    let apexFt: Double
    /// Height over the plate's middle line, inches.
    let overPlateIn: Double
    /// Angle it is falling at over the plate, degrees.
    let fallingAngleDeg: Double
    /// The barrel at contact: height and how far out front of the plate.
    let barrel: (heightIn: Double, outFrontIn: Double)?
}

extension Slowpitch {
    /// Call a pitch under a rulebook for a batter of `heightIn`. Zone rules: a strike
    /// is any part of the ball passing over the plate between the knee and the
    /// shoulder. Senior rules: a strike lands on the plate or the mat.
    static func callPitch(_ flight: SlowpitchFlight, _ rule: SlowpitchRuleKey, _ heightIn: Double) -> SlowpitchPitchCall {
        let (arcMin, arcMax) = legalArcWindow(rule)
        let peakFt = flight.apex[1] / FT
        let arcWhy: SlowpitchPitchCall.ArcWhy = peakFt < arcMin - 1e-6 ? .flat : peakFt > arcMax + 1e-6 ? .high : .ok
        let (bottom, top) = zoneBounds(heightIn)
        let R = BALL_RADIUS
        let p = flight.positions
        let senior = rule.arcRule.strike == .mat

        var lane: SlowpitchPitchCall.Lane
        var strike = false
        if senior {
            lane = .init(min: PLATE.front, max: MAT.length)
            strike = onPlateOrMat(flight.land.x, flight.land.z)
        } else {
            // Any part of the ball over the plate, inside the zone: check three points
            // per sample interval.
            var i = 1
            while i < flight.count && !strike {
                for k in 0..<3 {
                    let f = Double(k) / 3
                    let x = Double(p[i * 3 - 3]) + (Double(p[i * 3]) - Double(p[i * 3 - 3])) * f
                    let y = Double(p[i * 3 - 2]) + (Double(p[i * 3 + 1]) - Double(p[i * 3 - 2])) * f
                    let z = Double(p[i * 3 - 1]) + (Double(p[i * 3 + 2]) - Double(p[i * 3 - 1])) * f
                    if y >= bottom - R && y <= top + R && distanceToPlate(x, z) <= R {
                        strike = true
                        break
                    }
                }
                i += 1
            }
            // The lane: slide this same arc along the pitch line and keep the landing
            // spots whose zone-height stretch still overlaps the plate.
            var minZ = Double.infinity
            var maxZ = -Double.infinity
            for i in flight.apexIndex..<Swift.max(flight.count, flight.apexIndex) {
                let y = Double(p[i * 3 + 1])
                if y >= bottom - R && y <= top + R {
                    minZ = SlowpitchJS.min(minZ, Double(p[i * 3 + 2]))
                    maxZ = SlowpitchJS.max(maxZ, Double(p[i * 3 + 2]))
                }
            }
            lane = minZ.isFinite
                ? .init(min: flight.land.z + (PLATE.front - R - maxZ), max: flight.land.z + (PLATE.back + R - minZ))
                : .init(min: PLATE.front, max: PLATE.back)
        }

        let landZ = flight.land.z
        let sideOver = abs(flight.land.x) - (PLATE.halfWidth + (senior ? 0 : R))
        var miss: SlowpitchPitchCall.Miss = .none
        if !strike {
            miss = landZ < lane.min ? .short : landZ > lane.max ? .long : flight.land.x < 0 ? .inside : .outside
        }
        return SlowpitchPitchCall(
            arcLegal: arcWhy == .ok,
            arcWhy: arcWhy,
            strike: strike,
            call: arcWhy == .ok ? (strike ? .strike : .ball) : .illegal,
            miss: miss,
            lane: lane,
            depthMarginIn: SlowpitchJS.min(landZ - lane.min, lane.max - landZ) / IN,
            sideMarginIn: -sideOver / IN
        )
    }

    /// The strike lane as inches past the plate's front edge, (from, to).
    static func strikeWindowIn(_ call: SlowpitchPitchCall) -> (Double, Double) {
        (inchesPastFront(call.lane.min), inchesPastFront(call.lane.max))
    }

    /// Inches out in front of the plate's front edge for a depth z, metres.
    static func outFrontIn(_ z: Double) -> Double {
        (PLATE.front - z) / IN
    }

    /// Where the barrel meets this pitch. The contact depth depends on how far
    /// across the ball is, and how far across it is depends on the depth, so settle
    /// the pair in two passes.
    static func meetBall(_ flight: SlowpitchFlight, _ stance: SlowpitchStance) -> SlowpitchBatterContact {
        let m = BATTER_MODEL
        let pivot = contactPivot(stance)
        var x = flight.land.x
        var reach = reachAt(stance, x)
        for _ in 0..<2 {
            guard let at = descentAtDepth(flight, pivot.z - reach.forward) else { break }
            x = at.0
            reach = reachAt(stance, x)
        }
        let z = pivot.z - reach.forward
        let ball = descentAtDepth(flight, z)
        let l = landmarks(stance.heightIn)
        let vertical = ball.map { heightComfort(stance.heightIn, $0.1) } ?? 0

        var kind: SlowpitchBatterContact.Kind = .pitch
        if reach.lateral < m.warmThreshold {
            kind = reach.side == .end ? .end : .jam
        } else if ball == nil || (ball!.1 < l.belt && vertical < m.hotThreshold) {
            kind = .low
        } else if ball!.1 > l.chest && vertical < m.hotThreshold {
            kind = .high
        }

        return SlowpitchBatterContact(
            contact: ball.map { .init(x: x, y: $0.1, z: z, forward: reach.forward, angleDeg: reach.angleDeg) },
            lateral: reach.lateral,
            vertical: vertical,
            score: vertical * reach.lateral,
            kind: kind
        )
    }

    /// Slide this arc along the pitch line, landing from 2.5 m shorter to 3.5 m
    /// deeper in 1 cm steps, and score each landing at the batter's contact point
    /// for a ball across at `x` (the middle of the plate by default in the UI;
    /// nil means the lob's own landing x, the web's default argument).
    static func lookFor(_ flight: SlowpitchFlight, _ stance: SlowpitchStance, x: Double? = nil) -> SlowpitchLookFor {
        let x = x ?? flight.land.x
        let m = BATTER_MODEL
        let reach = reachAt(stance, x)
        let contactZ = contactPivot(stance).z - reach.forward
        var shifts: [Double] = []
        var scores: [Double] = []
        // Accumulated (not indexed) on purpose: the original stepped this way, and
        // the window ends land on the same samples only if the floats match.
        var s = -2.5
        while s <= 3.5 + 1e-9 {
            let at = descentAtDepth(flight, contactZ - s)
            shifts.append(s)
            scores.append(at.map { heightComfort(stance.heightIn, $0.1) * reach.lateral } ?? 0)
            s += 0.01
        }
        var best = 0
        for i in 1..<scores.count where scores[i] > scores[best] { best = i }

        let span = { (threshold: Double) -> (Int, Int)? in
            if scores[best] < threshold { return nil }
            var lo = best
            var hi = best
            while lo > 0 && scores[lo - 1] >= threshold { lo -= 1 }
            while hi < scores.count - 1 && scores[hi + 1] >= threshold { hi += 1 }
            return (lo, hi)
        }
        let landingIn = { (i: Int) -> Double in inchesPastFront(flight.land.z + shifts[i]) }

        let hot = span(m.hotThreshold)
        let warm = span(m.warmThreshold)
        var crossing: (Double, Double)?
        if let hot {
            let deep = descentAtDepth(flight, -shifts[hot.1])
            let short = descentAtDepth(flight, -shifts[hot.0])
            if let deep, let short { crossing = (deep.1 / IN, short.1 / IN) }
        }
        return SlowpitchLookFor(
            hot: hot.map { (landingIn($0.0), landingIn($0.1)) },
            warm: warm.map { (landingIn($0.0), landingIn($0.1)) },
            crossing: crossing
        )
    }

    /// Score this arc's shape at every point of the plate face: for each cell, slide
    /// the arc so it passes that height over that spot, and ask how the barrel meets
    /// it there.
    static func reachHeatMap(_ flight: SlowpitchFlight, _ stance: SlowpitchStance, nx: Int = 48, ny: Int = 72) -> SlowpitchReachHeatMap {
        let l = landmarks(stance.heightIn)
        let half = PLATE.halfWidth + 6 * IN
        let xr = (-half, half)
        let yr = (0.0, l.shoulder + 14 * IN)
        let pivot = contactPivot(stance)
        var values = [Float](repeating: 0, count: nx * ny)
        for i in 0..<nx {
            let reach = reachAt(stance, xr.0 + ((Double(i) + 0.5) / Double(nx)) * (xr.1 - xr.0))
            let contactZ = pivot.z - reach.forward
            for j in 0..<ny {
                guard let depth = descentDepthAtHeight(flight, yr.0 + ((Double(j) + 0.5) / Double(ny)) * (yr.1 - yr.0)) else {
                    continue
                }
                let at = descentAtDepth(flight, contactZ + depth)
                values[j * nx + i] = Float(at.map { heightComfort(stance.heightIn, $0.1) * reach.lateral } ?? 0)
            }
        }
        return SlowpitchReachHeatMap(values: values, nx: nx, ny: ny, x: xr, y: yr)
    }

    /// Put the umpire's call and the barrel's read into the batter's words.
    static func verdictFor(
        _ call: SlowpitchPitchCall, _ contact: SlowpitchBatterContact, _ shoulderY: Double, _ rule: SlowpitchRuleKey
    ) -> SlowpitchVerdict {
        if call.call == .illegal {
            return SlowpitchVerdict(
                word: call.arcWhy == .flat ? "Illegal arc · too flat" : "Illegal arc · too high",
                short: "Illegal",
                tone: .bad
            )
        }
        if call.call == .ball {
            let where_: String
            if rule.arcRule.strike == .mat {
                where_ = call.miss == .short ? "short of the plate" : call.miss == .long ? "past the mat" : "off the mat"
            } else {
                where_ = call.miss == .short ? "under your knees" : call.miss == .long ? "over your shoulder" : "off the plate"
            }
            return SlowpitchVerdict(word: "Ball · \(where_)", short: "Ball", tone: .dim)
        }
        switch contact.kind {
        case .pitch:
            return SlowpitchVerdict(word: "Your pitch", short: "Your pitch", tone: .good)
        case .jam:
            return SlowpitchVerdict(word: "Strike · jams you", short: "Jams you", tone: .warn)
        case .end:
            return SlowpitchVerdict(word: "Strike · off the end", short: "Off the end", tone: .warn)
        case .low:
            return SlowpitchVerdict(word: "Strike · at your knees", short: "Too low", tone: .warn)
        default:
            if let c = contact.contact, c.y > shoulderY {
                return SlowpitchVerdict(word: "Strike · over your shoulders", short: "Too high", tone: .warn)
            }
            return SlowpitchVerdict(word: "Strike · up at your shoulders", short: "Too high", tone: .warn)
        }
    }

    static func judgePitch(_ flight: SlowpitchFlight, _ rule: SlowpitchRuleKey, _ stance: SlowpitchStance) -> SlowpitchPitchReading {
        let call = callPitch(flight, rule, stance.heightIn)
        let contact = meetBall(flight, stance)
        let c = contact.contact
        return SlowpitchPitchReading(
            call: call,
            contact: contact,
            verdict: verdictFor(call, contact, landmarks(stance.heightIn).shoulder, rule),
            lookFor: lookFor(flight, stance, x: 0),
            strikeWindowIn: strikeWindowIn(call),
            apexFt: flight.apex[1] / FT,
            overPlateIn: flight.crossing.y / IN,
            fallingAngleDeg: flight.crossing.angle,
            barrel: c.map { (heightIn: $0.y / IN, outFrontIn: outFrontIn($0.z)) }
        )
    }
}
