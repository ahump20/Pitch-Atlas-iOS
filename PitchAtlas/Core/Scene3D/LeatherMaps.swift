import Foundation
import CoreGraphics
import simd

// =============================================================================
// LeatherMaps — procedural pebbled cowhide, zero bundled texture bytes
// =============================================================================
// Pure-Swift port of the web ball's makeLeatherMaps (Ball.tsx). Three maps,
// baked together so they agree:
//  - albedo: warm off-white hide (238,230,214) with low-frequency mottling and
//    a faint seam-side soiling band where a real cover grays along the stitches
//  - normal: multi-octave grain that reads as visible pebble, plus a recessed
//    seam channel carved along the seam path (the thread sits down in leather)
//  - roughness: pebble tops a touch glossier than the valleys, seam lip matte
//
// Deterministic (seeded 11 / 29, same as the web), generated once per process
// on a utility queue and cached. Renderer-agnostic: CGImage out, no SceneKit.
//
// UV convention — the one trap in the port. The seam-distance field must live
// in the SPHERE GEOMETRY'S UV space or the baked channel misses the geometric
// tube. SceneKit's SCNSphere parameterization was verified empirically against
// its own geometry sources (48-segment probe, max error 5.3e-9 on u, 7.9e-8
// on v):
//
//     u = wrap01( atan2(-x, -z) / 2π )        v = acos(y) / π
//
// This differs from three.js's SphereGeometry (u reads off atan2(z, -x) there),
// so pointToUV below is the SceneKit mapping, not a copy of the web's.
// =============================================================================

struct LeatherMaps {
    let albedo: CGImage
    let normal: CGImage
    let roughness: CGImage

    /// Half-width of the recessed seam lane, in UV units (web CHANNEL).
    static let channelWidth = 0.018

    // MARK: - Shared cache

    /// The maps are pure but expensive (three 512² per-texel bakes), so the
    /// process generates them exactly once, off the main thread, and every
    /// scene build awaits the same task.
    private static let sharedTask = Task<LeatherMaps, Never>.detached(priority: .utility) {
        LeatherMaps.generate(size: 512)
    }

    static func shared() async -> LeatherMaps {
        await sharedTask.value
    }

    // MARK: - Generation

    /// Bake all three maps at `size`² texels. 512 for the scene; tests use a
    /// small size (64) to keep determinism checks fast.
    static func generate(size: Int) -> LeatherMaps {
        let grain = SeededNoise(seed: 11)
        let blotch = SeededNoise(seed: 29)
        let seamDist = SeamDistanceField()

        // Precompute the per-texel fields once; the normal map's finite
        // differences need one extra row at v = 1.0 (the web samples
        // min(1, v + eps) at the last row).
        let n = size
        var fine220 = [Double](repeating: 0, count: n * n)      // albedo pebble
        var wide7 = [Double](repeating: 0, count: n * n)        // albedo mottle
        var fine200 = [Double](repeating: 0, count: (n + 1) * n) // normal + roughness grain
        var sd = [Double](repeating: 0, count: (n + 1) * n)      // seam distance

        for y in 0...n {
            let vv = Double(y) / Double(n)
            for x in 0..<n {
                let u = Double(x) / Double(n)
                let idx = y * n + x
                fine200[idx] = grain.fbm(u: u, v: vv, baseFreq: 200, octaves: 5)
                sd[idx] = seamDist.distance(u: u, v: vv)
                if y < n {
                    fine220[idx] = grain.fbm(u: u, v: vv, baseFreq: 220, octaves: 4)
                    wide7[idx] = blotch.fbm(u: u, v: vv, baseFreq: 7, octaves: 3)
                }
            }
        }

        let channel = channelWidth

        // ── albedo ───────────────────────────────────────────────────────────
        var albedoBytes = [UInt8](repeating: 255, count: n * n * 4)
        for y in 0..<n {
            for x in 0..<n {
                let idx = y * n + x
                let tone = (fine220[idx] - 0.5) * 16 + (wide7[idx] - 0.5) * 14
                let d = sd[idx]
                let soil = d < channel * 3 ? (1 - d / (channel * 3)) * 12 : 0
                let groove = d < channel ? (1 - d / channel) * 26 : 0
                albedoBytes[idx * 4] = clampByte(238 + tone - soil * 1.1 - groove)
                albedoBytes[idx * 4 + 1] = clampByte(230 + tone - soil - groove)
                albedoBytes[idx * 4 + 2] = clampByte(214 + tone * 0.9 - soil * 0.8 - groove * 0.9)
            }
        }

        // ── normal ───────────────────────────────────────────────────────────
        // height field -> tangent-space normal by finite differences, so the
        // pebble and the seam groove are lit consistently with the albedo.
        func height(_ x: Int, _ y: Int) -> Double {
            let idx = y * n + x
            let d = sd[idx]
            let carved = d < channel ? cos((d / channel) * .pi * 0.5) : 0
            return fine200[idx] - carved * 1.4
        }
        let strength = 2.1
        var normalBytes = [UInt8](repeating: 255, count: n * n * 4)
        for y in 0..<n {
            for x in 0..<n {
                let idx = y * n + x
                // eps = 1/size: neighbors are exactly adjacent texels; u wraps,
                // v clamps at the poles (min(1, v+eps) reaches the extra row).
                let hL = height((x - 1 + n) % n, y)
                let hR = height((x + 1) % n, y)
                let hD = height(x, max(0, y - 1))
                let hU = height(x, min(n, y + 1))
                let dx = (hL - hR) * strength
                let dy = (hD - hU) * strength
                let inv = 1 / (dx * dx + dy * dy + 1).squareRoot()
                normalBytes[idx * 4] = clampByte(128 + dx * inv * 127)
                normalBytes[idx * 4 + 1] = clampByte(128 + dy * inv * 127)
                normalBytes[idx * 4 + 2] = clampByte(128 + inv * 127)
            }
        }

        // ── roughness ────────────────────────────────────────────────────────
        var roughBytes = [UInt8](repeating: 255, count: n * n * 4)
        for y in 0..<n {
            for x in 0..<n {
                let idx = y * n + x
                var rough = 0.52 + (0.5 - fine200[idx]) * 0.22
                let d = sd[idx]
                if d < channel { rough += (1 - d / channel) * 0.16 } // matte leather lip
                let r8 = clampByte(rough * 255)
                roughBytes[idx * 4] = r8
                roughBytes[idx * 4 + 1] = r8
                roughBytes[idx * 4 + 2] = r8
            }
        }

        return LeatherMaps(
            albedo: makeImage(bytes: albedoBytes, size: n),
            normal: makeImage(bytes: normalBytes, size: n),
            roughness: makeImage(bytes: roughBytes, size: n)
        )
    }

    private static func clampByte(_ value: Double) -> UInt8 {
        UInt8(max(0, min(255, value.rounded())))
    }

    private static func makeImage(bytes: [UInt8], size: Int) -> CGImage {
        let data = Data(bytes)
        let provider = CGDataProvider(data: data as CFData)!
        return CGImage(
            width: size,
            height: size,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: size * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )!
    }
}

// MARK: - Seeded, U-tileable fractional Brownian value noise

/// Port of the web's makeNoise: cheap deterministic value noise, wrapped on the
/// U axis per octave so the leather grain has no visible wrap seam.
struct SeededNoise {
    let seed: Double

    init(seed: Double) {
        self.seed = seed
    }

    private func hash(_ x: Double, _ y: Double) -> Double {
        let s = sin(x * 127.1 + y * 311.7 + seed * 74.7) * 43758.5453
        return s - s.rounded(.down)
    }

    private func valueNoise(x: Double, y: Double, period: Double) -> Double {
        let xi = x.rounded(.down)
        let yi = y.rounded(.down)
        let xf = x - xi
        let yf = y - yi
        func wrap(_ v: Double) -> Double {
            (v.truncatingRemainder(dividingBy: period) + period)
                .truncatingRemainder(dividingBy: period)
        }
        let a = hash(wrap(xi), yi)
        let b = hash(wrap(xi + 1), yi)
        let c = hash(wrap(xi), yi + 1)
        let d = hash(wrap(xi + 1), yi + 1)
        let ux = xf * xf * (3 - 2 * xf)
        let uy = yf * yf * (3 - 2 * yf)
        return a * (1 - ux) * (1 - uy) + b * ux * (1 - uy) + c * (1 - ux) * uy + d * ux * uy
    }

    func fbm(u: Double, v: Double, baseFreq: Double, octaves: Int) -> Double {
        var amp = 0.5
        var freq = baseFreq
        var sum = 0.0
        var norm = 0.0
        for _ in 0..<octaves {
            sum += amp * valueNoise(x: u * freq, y: v * freq, period: freq)
            norm += amp
            amp *= 0.5
            freq *= 2
        }
        return sum / norm
    }
}

// MARK: - Seam-distance field (bucketed nearest-sample lookup)

/// The per-texel distance to the seam in UV space: 900 seam samples bucketed
/// into a 64×64 grid, nearest distance searched over the 3×3 neighborhood with
/// U wraparound — same structure as the web, in SceneKit's sphere UV space.
struct SeamDistanceField {
    private static let gridSize = 64
    private let bucketed: [[Int]]
    private let samples: [SIMD2<Double>]

    init() {
        let grid = Self.gridSize
        var uv: [SIMD2<Double>] = []
        uv.reserveCapacity(900)
        for p in SeamMath.seamSamples(900) {
            uv.append(Self.pointToUV(p))
        }
        var buckets = [[Int]](repeating: [], count: grid * grid)
        for (i, p) in uv.enumerated() {
            let gx = min(grid - 1, Int(p.x * Double(grid)))
            let gy = min(grid - 1, Int(p.y * Double(grid)))
            buckets[gy * grid + gx].append(i)
        }
        samples = uv
        bucketed = buckets
    }

    /// Equirectangular UV of a unit point under SceneKit's SCNSphere mapping —
    /// verified empirically against the geometry sources, not copied from the
    /// web (three.js reads u off atan2(z, -x); SceneKit off atan2(-x, -z)).
    static func pointToUV(_ p: SIMD3<Double>) -> SIMD2<Double> {
        let q = simd_normalize(p)
        var u = atan2(-q.x, -q.z) / (2 * .pi)
        if u < 0 { u += 1 }
        let v = acos(max(-1, min(1, q.y))) / .pi
        return SIMD2(u, v)
    }

    func distance(u: Double, v: Double) -> Double {
        let grid = Self.gridSize
        let gx = Int(u * Double(grid))
        let gy = Int(v * Double(grid))
        var best = 1.0
        for dy in -1...1 {
            let by = gy + dy
            if by < 0 || by >= grid { continue }
            for dx in -1...1 {
                let bx = ((gx + dx) % grid + grid) % grid // wrap U
                for i in bucketed[by * grid + bx] {
                    let s = samples[i]
                    var du = abs(s.x - u)
                    if du > 0.5 { du = 1 - du } // shortest path around the wrap
                    let dv = s.y - v
                    let d = (du * du + dv * dv).squareRoot()
                    if d < best { best = d }
                }
            }
        }
        return best
    }
}
