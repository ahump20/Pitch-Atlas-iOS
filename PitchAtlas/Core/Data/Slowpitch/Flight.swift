import Foundation

// =============================================================================
// Slow-pitch Flight Lab — the flight of a lob
// =============================================================================
// Line-for-line port of src/lib/slowpitch/flight.ts (web @ 47e21e6): gravity,
// drag and Magnus lift, integrated from the release point to the ground, and a
// solver that finds the throw for a lob described the way a batter sees it (how
// high it peaks, where it lands).
//
// Lift follows the fit Cl = 1 / (2.32 + 0.4 / S), with S = r * w_perp / v, the
// spin factor. That fit and the constant drag coefficient come from baseball
// aerodynamics; on a softball they are approximate. Spin is a model input only:
// it shapes the path, and no spin figure is ever shown to a visitor.
//
// Precision note: the web keeps the sampled path in Float32Arrays and does all
// arithmetic in doubles. This port does the same — `times`, `positions` and
// `distance` are [Float], and every read widens back to Double before use — so
// it lands on the same samples as the pinned tables.
// =============================================================================

/// A lob described the way a batter reads it.
struct SlowpitchLobParams: Codable, Hashable {
    /// Peak height above the ground, ft.
    var apex: Double
    /// Where it lands, in inches past the plate's front edge.
    var land: Double
    /// Inches across the plate from the middle; negative is inside.
    var side: Double
    /// Backspin, rpm. A model input, never shown.
    var rpm: Double
    /// Tilt of the spin axis off pure backspin, degrees.
    var push: Double
}

/// The result of one integration from the release point to the ground.
struct SlowpitchIntegration {
    /// Where the ball's centre is when its bottom touches the ground.
    let end: SlowpitchVec3
    let endVelocity: SlowpitchVec3
    /// Flight time, s.
    let time: Double
    /// Highest point the ball's centre reached, m.
    let apexHeight: Double
    let apexPoint: SlowpitchVec3
    /// Sample times, filled only when sampling.
    let times: [Double]
    /// Sample positions, flat xyz, filled only when sampling.
    let points: [Double]
}

/// A solved lob, sampled for drawing and for the batter and zone checks.
struct SlowpitchFlight {
    /// Number of samples.
    let count: Int
    /// Sample times, s (Float32, as the web stores them).
    let times: [Float]
    /// Sample positions, flat xyz, metres (Float32, as the web stores them).
    let positions: [Float]
    /// Cumulative path length at each sample, metres (Float32).
    let distance: [Float]
    /// Index of the highest sample.
    let apexIndex: Int
    /// Flight time, s.
    let duration: Double
    /// Unit spin axis ((1, 0, 0) when there is no spin).
    let spinAxis: SlowpitchVec3
    /// Spin rate, rad/s.
    let spinRate: Double
    /// Unit release direction.
    let releaseDirection: SlowpitchVec3
    /// Release speed, mph.
    let releaseMph: Double
    /// The highest point of the path, metres.
    let apex: SlowpitchVec3
    /// Where the ball comes down, metres.
    let land: (x: Double, z: Double)
    /// Where the path crosses the plate's middle line (z = 0): x, height y, and
    /// the angle it is falling at, degrees below horizontal.
    let crossing: (x: Double, y: Double, angle: Double)
    /// How far spin moved the landing spot along the pitch line, inches.
    let spinCarryIn: Double
    /// How far spin moved the landing spot across the plate, inches.
    let spinDriftIn: Double
    /// False when no throw the solver found peaks and lands where asked; the
    /// path drawn is the closest it got.
    let converged: Bool
}

extension Slowpitch {
    /// Integrator step, s.
    private static let DT = 0.002
    /// Step cap: 5 s of flight, far past any lob.
    private static let MAX_STEPS = 2500
    /// Drag and lift share this factor: 0.5 * rho * A / m.
    private static let AERO_K = (0.5 * AIR_DENSITY * BALL_AREA) / BALL_MASS

    /// Lift coefficient for a spin factor S.
    static func liftCoefficient(_ spinFactor: Double) -> Double {
        1 / (2.32 + 0.4 / spinFactor)
    }

    /// Acceleration of the ball at velocity `v` (m/s) with angular velocity `spin`
    /// (rad/s, or nil for no spin): gravity, drag against the motion, and Magnus
    /// lift along spin x velocity.
    static func acceleration(_ v: SlowpitchVec3, _ spin: SlowpitchVec3?) -> SlowpitchVec3 {
        let speed = length(v)
        let drag = AERO_K * DRAG_COEFFICIENT * speed
        var a = SlowpitchVec3(-drag * v[0], -drag * v[1] - GRAVITY, -drag * v[2])
        if let spin {
            let lift = cross(spin, scale(v, 1 / speed))
            let wPerp = length(lift)
            if wPerp > 1e-6 {
                let k = (AERO_K * liftCoefficient((BALL_RADIUS * wPerp) / speed) * speed * speed) / wPerp
                a[0] += k * lift[0]
                a[1] += k * lift[1]
                a[2] += k * lift[2]
            }
        }
        return a
    }

    /// Integrate a throw with initial velocity `v0` and constant spin vector from the
    /// release point until the ball touches the ground (centre at one ball radius).
    /// Midpoint (RK2) step for velocity, trapezoid for position; the final step is cut
    /// back to land exactly on the ground.
    static func integrateToGround(_ v0: SlowpitchVec3, _ spin: SlowpitchVec3?, _ sample: Bool) -> SlowpitchIntegration {
        var p = SlowpitchVec3(RELEASE.x, RELEASE.y, RELEASE.z)
        var v = v0
        var t = 0.0
        var apexHeight = p[1]
        var apexPoint = p
        var times: [Double] = [0]
        var points: [Double] = [p[0], p[1], p[2]]

        for _ in 0..<MAX_STEPS {
            let a1 = acceleration(v, spin)
            let a2 = acceleration(SlowpitchVec3(v[0] + a1[0] * DT * 0.5, v[1] + a1[1] * DT * 0.5, v[2] + a1[2] * DT * 0.5), spin)
            let vNext = SlowpitchVec3(v[0] + a2[0] * DT, v[1] + a2[1] * DT, v[2] + a2[2] * DT)
            let pNext = SlowpitchVec3(
                p[0] + (v[0] + vNext[0]) * 0.5 * DT,
                p[1] + (v[1] + vNext[1]) * 0.5 * DT,
                p[2] + (v[2] + vNext[2]) * 0.5 * DT
            )
            if vNext[1] < 0 && pNext[1] <= BALL_RADIUS {
                // Cut the last step back to the instant the ball touches down.
                let f = (p[1] - BALL_RADIUS) / (p[1] - pNext[1])
                p = SlowpitchVec3(p[0] + (pNext[0] - p[0]) * f, BALL_RADIUS, p[2] + (pNext[2] - p[2]) * f)
                v = SlowpitchVec3(v[0] + (vNext[0] - v[0]) * f, v[1] + (vNext[1] - v[1]) * f, v[2] + (vNext[2] - v[2]) * f)
                t += DT * f
                if sample {
                    times.append(t)
                    points.append(contentsOf: [p[0], p[1], p[2]])
                }
                break
            }
            p = pNext
            v = vNext
            t += DT
            if p[1] > apexHeight {
                apexHeight = p[1]
                apexPoint = p
            }
            if sample {
                times.append(t)
                points.append(contentsOf: [p[0], p[1], p[2]])
            }
        }
        return SlowpitchIntegration(
            end: p, endVelocity: v, time: t, apexHeight: apexHeight, apexPoint: apexPoint, times: times, points: points
        )
    }

    /// The spin vector for a throw: backspin about the axis perpendicular to the
    /// release direction and to a vertical tilted by `push` degrees, at `rpm`.
    /// Nil when the lob carries no spin.
    static func spinVector(_ v0: SlowpitchVec3, rpm: Double, push: Double) -> SlowpitchVec3? {
        if rpm <= 0 { return nil }
        let push = (push * Double.pi) / 180
        let axis = normalize(cross(normalize(v0), SlowpitchVec3(sin(push), cos(push), 0)))
        return scale(axis, rpm * RPM)
    }

    /// `spinVector` for a lob's own rpm and push.
    static func spinVector(_ v0: SlowpitchVec3, _ params: SlowpitchLobParams) -> SlowpitchVec3? {
        spinVector(v0, rpm: params.rpm, push: params.push)
    }

    /// Solve a 3x3 linear system by Gaussian elimination with partial pivoting.
    private static func solve3(_ m: [[Double]], _ rhs: [Double]) -> SlowpitchVec3? {
        var a = m.enumerated().map { i, row in row + [rhs[i]] }
        for col in 0..<3 {
            var pivot = col
            for r in (col + 1)..<3 where abs(a[r][col]) > abs(a[pivot][col]) { pivot = r }
            if abs(a[pivot][col]) < 1e-9 { return nil }
            a.swapAt(col, pivot)
            for r in (col + 1)..<3 {
                let f = a[r][col] / a[col][col]
                for c in col..<4 { a[r][c] -= f * a[col][c] }
            }
        }
        var x = SlowpitchVec3(0, 0, 0)
        for r in stride(from: 2, through: 0, by: -1) {
            var s = a[r][3]
            for c in (r + 1)..<3 { s -= a[r][c] * x[c] }
            x[r] = s / a[r][r]
        }
        return x
    }

    /// Find the throw that peaks at `apex` ft and lands `land` in past the plate's
    /// front edge, `side` in across, then sample its path. Newton's method on the
    /// release velocity with a finite-difference Jacobian, starting from the
    /// no-drag ballistic guess.
    static func solveLob(_ params: SlowpitchLobParams) -> SlowpitchFlight {
        let apexY = SlowpitchJS.max(params.apex * FT, RELEASE.y + 0.4)
        let landZ = PLATE.front + params.land * IN
        let landX = params.side * IN

        let vUp = (2 * GRAVITY * (apexY - RELEASE.y)).squareRoot()
        let tGuess = vUp / GRAVITY + ((2 * (apexY - BALL_RADIUS)) / GRAVITY).squareRoot()
        var v0 = SlowpitchVec3((landX - RELEASE.x) / tGuess, vUp, (landZ - RELEASE.z) / tGuess)

        let miss = { (v: SlowpitchVec3) -> SlowpitchVec3 in
            let r = integrateToGround(v, spinVector(v, params), false)
            return SlowpitchVec3(r.end[0] - landX, r.apexHeight - apexY, r.end[2] - landZ)
        }

        let TOLERANCE = 4e-4
        let worst = { (f: SlowpitchVec3) -> Double in
            SlowpitchJS.max(SlowpitchJS.max(abs(f[0]), abs(f[1])), abs(f[2]))
        }
        var converged = false
        for _ in 0..<12 {
            let f = miss(v0)
            if worst(f) < TOLERANCE {
                converged = true
                break
            }
            var jac: [[Double]] = [[0, 0, 0], [0, 0, 0], [0, 0, 0]]
            let h = 0.02
            for c in 0..<3 {
                var probe = v0
                probe[c] += h
                let fp = miss(probe)
                for r in 0..<3 { jac[r][c] = (fp[r] - f[r]) / h }
            }
            guard let step = solve3(jac, [-f[0], -f[1], -f[2]]) else { break }
            for c in 0..<3 { v0[c] += SlowpitchJS.max(-1.5, SlowpitchJS.min(1.5, step[c])) }
        }
        // The last step may have landed it; anything still off by more than a few mm is a miss.
        if !converged { converged = worst(miss(v0)) < 2 * TOLERANCE }

        let spin = spinVector(v0, params)
        let path = integrateToGround(v0, spin, true)
        let still = integrateToGround(v0, nil, false)

        let count = path.times.count
        let times = path.times.map { Float($0) }
        let positions = path.points.map { Float($0) }
        var distance = [Float](repeating: 0, count: count)
        for i in 1..<Swift.max(count, 1) {
            distance[i] = Float(
                Double(distance[i - 1])
                    + SlowpitchJS.hypot(
                        Double(positions[i * 3]) - Double(positions[i * 3 - 3]),
                        Double(positions[i * 3 + 1]) - Double(positions[i * 3 - 2]),
                        Double(positions[i * 3 + 2]) - Double(positions[i * 3 - 1])
                    )
            )
        }

        var apexIndex = 0
        for i in 1..<Swift.max(count, 1) where Double(positions[i * 3 + 1]) > Double(positions[apexIndex * 3 + 1]) {
            apexIndex = i
        }

        // Where the path crosses z = 0, the line the plate's sides end on.
        var crossing = (x: 0.0, y: 0.0, angle: 0.0)
        for i in 1..<Swift.max(count, 1) {
            let z0 = Double(positions[i * 3 - 1])
            let z1 = Double(positions[i * 3 + 2])
            if z0 <= 0 && z1 > 0 {
                let f = -z0 / (z1 - z0)
                let x0 = Double(positions[i * 3 - 3]), x1 = Double(positions[i * 3])
                let y0 = Double(positions[i * 3 - 2]), y1 = Double(positions[i * 3 + 1])
                crossing.x = x0 + (x1 - x0) * f
                crossing.y = y0 + (y1 - y0) * f
                crossing.angle = (atan2(y0 - y1, z1 - z0) * 180) / Double.pi
                break
            }
        }

        return SlowpitchFlight(
            count: count,
            times: times,
            positions: positions,
            distance: distance,
            apexIndex: apexIndex,
            duration: path.time,
            spinAxis: spin.map(normalize) ?? SlowpitchVec3(1, 0, 0),
            spinRate: spin.map(length) ?? 0,
            releaseDirection: normalize(v0),
            releaseMph: length(v0) / MPH,
            apex: path.apexPoint,
            land: (x: path.end[0], z: path.end[2]),
            crossing: crossing,
            spinCarryIn: (path.end[2] - still.end[2]) / IN,
            spinDriftIn: (path.end[0] - still.end[0]) / IN,
            converged: converged
        )
    }

    /// Index pair (lo, hi) bracketing time `t` in the samples, and the fraction between.
    private static func bracketTime(_ flight: SlowpitchFlight, _ t: Double) -> (Int, Int, Double) {
        var lo = 0
        var hi = flight.count - 1
        while hi - lo > 1 {
            let mid = (lo + hi) >> 1
            if Double(flight.times[mid]) <= t { lo = mid } else { hi = mid }
        }
        let tLo = Double(flight.times[lo])
        let f = (t - tLo) / SlowpitchJS.orOne(Double(flight.times[hi]) - tLo)
        return (lo, hi, f)
    }

    /// Ball position at time `t` (s), clamped to the release and the landing.
    static func positionAt(_ flight: SlowpitchFlight, _ t: Double) -> SlowpitchVec3 {
        let p = flight.positions
        if t <= 0 {
            return SlowpitchVec3(Double(p[0]), Double(p[1]), Double(p[2]))
        }
        if t >= flight.duration {
            let last = (flight.count - 1) * 3
            return SlowpitchVec3(Double(p[last]), Double(p[last + 1]), Double(p[last + 2]))
        }
        let (lo, hi, f) = bracketTime(flight, t)
        var out = SlowpitchVec3(0, 0, 0)
        for k in 0..<3 {
            let a = Double(p[lo * 3 + k])
            out[k] = a + (Double(p[hi * 3 + k]) - a) * f
        }
        return out
    }

    /// Fraction of the path length covered by time `t`, 0..1 (for drawing a trail).
    static func progressAt(_ flight: SlowpitchFlight, _ t: Double) -> Double {
        if t <= 0 { return 0 }
        if t >= flight.duration { return 1 }
        let (lo, hi, f) = bracketTime(flight, t)
        let d = flight.distance
        let dLo = Double(d[lo])
        return (dLo + (Double(d[hi]) - dLo) * f) / Double(d[flight.count - 1])
    }

    /// The falling ball's (x, height) where it reaches depth `z` on the way down.
    /// Before the apex it reports the apex (the ball has not started falling yet);
    /// past the landing spot it returns nil.
    static func descentAtDepth(_ flight: SlowpitchFlight, _ z: Double) -> (Double, Double)? {
        let p = flight.positions
        let top = flight.apexIndex
        let last = flight.count - 1
        if z < Double(p[top * 3 + 2]) { return (Double(p[top * 3]), Double(p[top * 3 + 1])) }
        if z > Double(p[last * 3 + 2]) { return nil }
        var lo = top
        var hi = last
        while hi - lo > 1 {
            let mid = (lo + hi) >> 1
            if Double(p[mid * 3 + 2]) <= z { lo = mid } else { hi = mid }
        }
        let z0 = Double(p[lo * 3 + 2])
        let f = (z - z0) / SlowpitchJS.orOne(Double(p[hi * 3 + 2]) - z0)
        let x0 = Double(p[lo * 3]), y0 = Double(p[lo * 3 + 1])
        return (x0 + (Double(p[hi * 3]) - x0) * f, y0 + (Double(p[hi * 3 + 1]) - y0) * f)
    }

    /// The depth z where the falling ball passes height `y`, or nil when it never does.
    static func descentDepthAtHeight(_ flight: SlowpitchFlight, _ y: Double) -> Double? {
        let p = flight.positions
        let top = flight.apexIndex
        let last = flight.count - 1
        if y > Double(p[top * 3 + 1]) || y < Double(p[last * 3 + 1]) { return nil }
        var lo = top
        var hi = last
        while hi - lo > 1 {
            let mid = (lo + hi) >> 1
            if Double(p[mid * 3 + 1]) >= y { lo = mid } else { hi = mid }
        }
        let y0 = Double(p[lo * 3 + 1])
        let f = (y0 - y) / SlowpitchJS.orOne(y0 - Double(p[hi * 3 + 1]))
        let zLo = Double(p[lo * 3 + 2])
        return zLo + (Double(p[hi * 3 + 2]) - zLo) * f
    }
}
