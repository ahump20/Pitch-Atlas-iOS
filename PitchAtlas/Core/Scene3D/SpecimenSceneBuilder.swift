import SceneKit
import UIKit
import simd

// =============================================================================
// SpecimenSceneBuilder — the 3D specimen, assembled headless
// =============================================================================
// Builds the SCNScene for one filed pitch: the procedural leather sphere, the
// raised waxed-thread seam tube swept along the shared figure-eight, 216
// herringbone stitches merged into one geometry, per-contact pressure pads with
// shadow decals and numbered pips, an optional spin-axis group, and the studio
// light rig ported from the web (warm key / cool fill / white rim + a vertical
// gradient environment). All math comes from SeamMath / ContactPoseSolver /
// LeatherMaps — this file and SpecimenBallView are the only two that import
// SceneKit.
//
// Node graph: root → orbitNode (drag) → faceNode (presentation tilt) →
// spinNode (idle backspin) → [sphere, tube, stitches, pads]. The spin-axis
// group hangs off faceNode, OUTSIDE the spin, so the axis stays fixed while
// the cover turns beneath it — same as the web's Vectors.
// =============================================================================

enum SpecimenSceneBuilder {

    /// The assembled scene plus the nodes the view drives at runtime.
    struct Built {
        let scene: SCNScene
        let orbitNode: SCNNode
        let spinNode: SCNNode
        let axisNode: SCNNode
        /// The pitch's authored unit spin axis, for the idle rotation.
        let spinAxis: SIMD3<Double>
    }

    // Geometry spec (mirrors the web ball).
    static let tubeSegments = 512
    static let tubeRadialSegments = 12
    static let tubeRadius = 0.0135
    static let stitchCount = 216
    static let stitchTemplateVertexCount = stitchTemplate.positions.count

    // Node names, shared with the view and the tests.
    static let tubeNodeName = "specimen-tube"
    static let stitchNodeName = "specimen-stitches"
    static let contactPadNodeName = "contact-pad"
    static let axisNodeName = "spin-axis"

    /// Assemble the scene for one filed specimen. Returns nil if any geometry
    /// fails to build — the caller falls back to the 2D schematic silently.
    static func build(entry: PitchAtlasEntry, maps: LeatherMaps, showAxis: Bool) -> Built? {
        let scene = SCNScene()
        scene.background.contents = nil // transparent: the stage sits on the app's void

        // ── camera ────────────────────────────────────────────────────────────
        let camera = SCNCamera()
        camera.fieldOfView = 32
        camera.wantsHDR = true
        // Pinned exposure: adaptation reads the dark void and blows the leather
        // out to a bleached practice ball. The negative offset holds the warm
        // aged-hide read the albedo carries.
        camera.wantsExposureAdaptation = false
        camera.exposureOffset = -0.85
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 6.4)
        scene.rootNode.addChildNode(cameraNode)

        // ── node graph ────────────────────────────────────────────────────────
        let orbitNode = SCNNode()
        orbitNode.name = "orbit"
        let faceNode = SCNNode()
        faceNode.name = "face"
        faceNode.simdOrientation = simd_quatf(
            simd_quatd(angle: SeamMath.viewTiltAngle, axis: SeamMath.viewTiltAxis)
        )
        let spinNode = SCNNode()
        spinNode.name = "spin"
        scene.rootNode.addChildNode(orbitNode)
        orbitNode.addChildNode(faceNode)
        faceNode.addChildNode(spinNode)

        // ── the cover ─────────────────────────────────────────────────────────
        let sphere = SCNSphere(radius: 1)
        sphere.segmentCount = 96
        sphere.isGeodesic = false
        let leather = SCNMaterial()
        leather.lightingModel = .physicallyBased
        leather.diffuse.contents = maps.albedo
        leather.normal.contents = maps.normal
        leather.normal.intensity = 0.85
        leather.roughness.contents = maps.roughness
        leather.metalness.contents = 0.0
        leather.clearCoat.contents = 0.35
        leather.clearCoatRoughness.contents = 0.42
        sphere.materials = [leather]
        let sphereNode = SCNNode(geometry: sphere)
        spinNode.addChildNode(sphereNode)

        // ── the seam tube ─────────────────────────────────────────────────────
        guard let tube = makeSeamTube() else { return nil }
        let thread = SCNMaterial()
        thread.lightingModel = .physicallyBased
        thread.diffuse.contents = UIColor(hexRGB: 0xB81127)
        thread.roughness.contents = 0.42
        thread.metalness.contents = 0.0
        thread.clearCoat.contents = 0.5
        thread.clearCoatRoughness.contents = 0.22
        thread.isDoubleSided = true
        tube.materials = [thread]
        let tubeNode = SCNNode(geometry: tube)
        tubeNode.name = tubeNodeName
        spinNode.addChildNode(tubeNode)

        // ── the 216 stitches, one merged geometry ─────────────────────────────
        guard let stitches = makeStitchGeometry() else { return nil }
        let stitchMaterial = SCNMaterial()
        stitchMaterial.lightingModel = .physicallyBased
        stitchMaterial.diffuse.contents = UIColor(hexRGB: 0xD6213B)
        stitchMaterial.roughness.contents = 0.34
        stitchMaterial.metalness.contents = 0.0
        stitchMaterial.clearCoat.contents = 0.6
        stitchMaterial.clearCoatRoughness.contents = 0.16
        // a tiny deep-red emission: the waxed crown catching rim light — a
        // glint, not a glow (web: emissive #3a0810 × 0.15)
        stitchMaterial.emission.contents = UIColor(hexRGB: 0x3A0810)
        stitchMaterial.emission.intensity = 0.15
        stitchMaterial.isDoubleSided = true
        stitches.materials = [stitchMaterial]
        let stitchNode = SCNNode(geometry: stitches)
        stitchNode.name = stitchNodeName
        spinNode.addChildNode(stitchNode)

        // ── contact pads: the authored grip, cast onto the leather ───────────
        for contact in entry.canonical.gripModel.contacts {
            let pose = ContactPoseSolver.solve(contact)
            spinNode.addChildNode(makeContactGroup(contact: contact, pose: pose))
        }

        // ── spin axis (optional overlay, outside the spin) ────────────────────
        let axisNode = makeAxisGroup(spinAxis: simd_normalize(entry.motion.spinAxis.simd))
        axisNode.isHidden = !showAxis
        faceNode.addChildNode(axisNode)

        // ── studio rig ────────────────────────────────────────────────────────
        scene.lightingEnvironment.contents = makeEnvironmentGradient()
        scene.lightingEnvironment.intensity = 1.0
        addDirectionalLight(to: scene, color: UIColor(hexRGB: 0xFFF1DD), intensity: 2900,
                            from: SCNVector3(2.6, 3.2, 5.2))   // warm key
        addDirectionalLight(to: scene, color: UIColor(hexRGB: 0xC8DAF2), intensity: 550,
                            from: SCNVector3(-4.2, -1.4, 2.2)) // cool fill
        addDirectionalLight(to: scene, color: .white, intensity: 1300,
                            from: SCNVector3(-1.6, -2.2, -5.4)) // rim, behind-low

        return Built(
            scene: scene,
            orbitNode: orbitNode,
            spinNode: spinNode,
            axisNode: axisNode,
            spinAxis: simd_normalize(entry.motion.spinAxis.simd)
        )
    }

    // MARK: - Seam tube

    /// The raised waxed thread: a closed tube swept along the shared seam curve.
    /// 512 curve segments × 12 radial segments; frames use the radial normal
    /// (N = normalized position), NOT Frenet, so seam inflections never flip the
    /// cross-section. The loop closes by reusing ring 0's vertices at ring 512,
    /// giving 513 × 12 vertex rings.
    private static func makeSeamTube() -> SCNGeometry? {
        let segments = tubeSegments
        let radial = tubeRadialSegments
        let r = tubeRadius

        var ring0Positions: [SIMD3<Double>] = []
        var ring0Normals: [SIMD3<Double>] = []
        var positions: [SCNVector3] = []
        var normals: [SCNVector3] = []
        positions.reserveCapacity((segments + 1) * radial)
        normals.reserveCapacity((segments + 1) * radial)

        for i in 0...segments {
            if i == segments {
                // close the loop by reusing ring 0
                for j in 0..<radial {
                    positions.append(SCNVector3(ring0Positions[j]))
                    normals.append(SCNVector3(ring0Normals[j]))
                }
                continue
            }
            let t = Double(i) / Double(segments) * 2 * .pi
            let center = SeamMath.seamPoint(t)
            let tangent = SeamMath.seamTangent(t)
            let n = center // radial frame: outward from the sphere's center
            let b = simd_normalize(simd_cross(n, tangent))
            for j in 0..<radial {
                let theta = Double(j) / Double(radial) * 2 * .pi
                let offset = n * cos(theta) + b * sin(theta)
                let p = center + offset * r
                positions.append(SCNVector3(p))
                normals.append(SCNVector3(simd_normalize(offset)))
                if i == 0 {
                    ring0Positions.append(p)
                    ring0Normals.append(simd_normalize(offset))
                }
            }
        }

        var indices: [UInt32] = []
        indices.reserveCapacity(segments * radial * 6)
        for i in 0..<segments {
            for j in 0..<radial {
                let a = UInt32(i * radial + j)
                let b = UInt32(i * radial + (j + 1) % radial)
                let c = UInt32((i + 1) * radial + j)
                let d = UInt32((i + 1) * radial + (j + 1) % radial)
                indices.append(contentsOf: [a, c, b, b, c, d])
            }
        }

        let geometry = SCNGeometry(
            sources: [
                SCNGeometrySource(vertices: positions),
                SCNGeometrySource(normals: normals),
            ],
            elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)]
        )
        return geometry
    }

    // MARK: - Stitches

    /// A low-poly capsule template, transformed 216 times on the CPU and merged
    /// into a single geometry — one draw call for the whole herringbone.
    static let stitchTemplate: (positions: [SIMD3<Double>], normals: [SIMD3<Double>], indices: [UInt32]) =
        makeCapsuleTemplate(radius: 0.0125, cylinderLength: 0.05, radialSegments: 8, capSegments: 3)

    /// Axis-Y capsule as lat-long rings (bottom cap → cylinder wall → top cap).
    private static func makeCapsuleTemplate(
        radius: Double, cylinderLength: Double, radialSegments: Int, capSegments: Int
    ) -> (positions: [SIMD3<Double>], normals: [SIMD3<Double>], indices: [UInt32]) {
        let h = cylinderLength / 2
        var rings: [(y: Double, r: Double, capCenterY: Double)] = []
        for i in 0...capSegments {
            let phi = -Double.pi / 2 + Double(i) / Double(capSegments) * (.pi / 2)
            rings.append((y: -h + radius * sin(phi), r: radius * cos(phi), capCenterY: -h))
        }
        for i in 0...capSegments {
            let phi = Double(i) / Double(capSegments) * (.pi / 2)
            rings.append((y: h + radius * sin(phi), r: radius * cos(phi), capCenterY: h))
        }

        var positions: [SIMD3<Double>] = []
        var normals: [SIMD3<Double>] = []
        for ring in rings {
            for j in 0..<radialSegments {
                let theta = Double(j) / Double(radialSegments) * 2 * .pi
                let p = SIMD3(ring.r * cos(theta), ring.y, ring.r * sin(theta))
                positions.append(p)
                normals.append(simd_normalize(p - SIMD3(0, ring.capCenterY, 0)))
            }
        }

        var indices: [UInt32] = []
        for i in 0..<(rings.count - 1) {
            for j in 0..<radialSegments {
                let a = UInt32(i * radialSegments + j)
                let b = UInt32(i * radialSegments + (j + 1) % radialSegments)
                let c = UInt32((i + 1) * radialSegments + j)
                let d = UInt32((i + 1) * radialSegments + (j + 1) % radialSegments)
                indices.append(contentsOf: [a, c, b, b, c, d])
            }
        }
        return (positions, normals, indices)
    }

    /// 216 stitches: 108 pairs straddling the seam (offset 0.034R at 1.005R),
    /// slanted ±0.62 rad into the herringbone and pressed flat against the
    /// leather with the web's (1.25, 1, 0.55) scale. Pairs are distributed by
    /// arc length along the seam, matching the web's arc-length-parameterized
    /// curve sampling.
    private static func makeStitchGeometry() -> SCNGeometry? {
        let template = stitchTemplate
        let arc = SeamArcTable(resolution: 2048)
        let pairs = stitchCount / 2
        let flatten = SIMD3<Double>(1.25, 1, 0.55)
        let yUp = SIMD3<Double>(0, 1, 0)

        var positions: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var indices: [UInt32] = []
        positions.reserveCapacity(stitchCount * template.positions.count)
        normals.reserveCapacity(stitchCount * template.positions.count)
        indices.reserveCapacity(stitchCount * template.indices.count)

        for i in 0..<pairs {
            let u = Double(i) / Double(pairs)
            let t = arc.parameter(atFraction: u)
            let pos = SeamMath.seamPoint(t)
            let tan = SeamMath.seamTangent(t)
            let nrm = simd_normalize(pos)
            let bin = simd_normalize(simd_cross(nrm, tan))

            for side in [1.0, -1.0] {
                let center = pos * 1.005 + bin * (0.034 * side)
                let slant = side * 0.62
                let dir = simd_normalize(tan * cos(slant) + bin * (sin(slant) * side))
                // web transform, exactly: R = align(yUp→dir) · align(yUp→nrm)⁻¹,
                // scale applied in the capsule's local frame before rotating.
                let rot = simd_quatd(from: yUp, to: dir) * simd_quatd(from: yUp, to: nrm).inverse

                let base = UInt32(positions.count)
                for k in 0..<template.positions.count {
                    let p = center + rot.act(template.positions[k] * flatten)
                    // inverse-transpose for normals under the non-uniform scale
                    let nLocal = simd_normalize(template.normals[k] / flatten)
                    positions.append(SCNVector3(p))
                    normals.append(SCNVector3(rot.act(nLocal)))
                }
                indices.append(contentsOf: template.indices.map { base + $0 })
            }
        }

        return SCNGeometry(
            sources: [
                SCNGeometrySource(vertices: positions),
                SCNGeometrySource(normals: normals),
            ],
            elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)]
        )
    }

    // MARK: - Contact pads

    /// One authored contact rendered as three coordinated pieces: a soft shadow
    /// decal on the leather, a pressed leather-toned pad (a pressure impression,
    /// never skin-colored), and the numbered pip — the same 1/2/3/4/T language
    /// the 2D SeamBall speaks.
    private static func makeContactGroup(contact: GripContactModel, pose: ContactPose) -> SCNNode {
        let group = SCNNode()
        group.name = contactPadNodeName

        // orthonormal surface frame: X = spineDir, Y = normal
        let x = pose.spineDir
        let y = pose.normal
        let z = simd_normalize(simd_cross(x, y))
        let frame = simd_quatd(simd_double3x3(columns: (x, y, z)))

        // (a) radial-gradient shadow decal, flush to the leather
        let decalSize = CGFloat(pose.padRadius * 3.2)
        let decal = SCNPlane(width: decalSize, height: decalSize)
        let decalMaterial = SCNMaterial()
        decalMaterial.lightingModel = .constant
        decalMaterial.diffuse.contents = Self.shadowDecalImage
        decalMaterial.writesToDepthBuffer = false
        decalMaterial.isDoubleSided = true
        decal.materials = [decalMaterial]
        let decalNode = SCNNode(geometry: decal)
        decalNode.simdPosition = SIMD3<Float>(pose.contact * 1.004)
        // the plane's +Z faces along the surface normal
        decalNode.simdOrientation = simd_quatf(simd_quatd(from: SIMD3(0, 0, 1), to: pose.normal))
        decalNode.opacity = shadowOpacity(for: contact.pressureTier)
        group.addChildNode(decalNode)

        // (b) the pressed pad: a squashed sphere, elongated along the spine
        let pad = SCNSphere(radius: 1)
        pad.segmentCount = 24
        let padMaterial = SCNMaterial()
        padMaterial.lightingModel = .physicallyBased
        // leather-toned, slightly deeper than the cover's warm hide
        padMaterial.diffuse.contents = UIColor(hexRGB: 0xCFC4AC)
        padMaterial.roughness.contents = 0.58
        padMaterial.metalness.contents = 0.0
        pad.materials = [padMaterial]
        let padNode = SCNNode(geometry: pad)
        padNode.simdPosition = SIMD3<Float>(pose.contact * 1.012)
        padNode.simdOrientation = simd_quatf(frame)
        let r = Float(pose.padRadius)
        padNode.simdScale = SIMD3<Float>(r * 1.3, r * 0.4, r) // flat to the leather, long on the spine
        group.addChildNode(padNode)

        // (c) the numbered pip, billboarded — same language as the 2D pips
        let pipSize: CGFloat = 0.22
        let pip = SCNPlane(width: pipSize, height: pipSize)
        let pipMaterial = SCNMaterial()
        pipMaterial.lightingModel = .constant
        pipMaterial.diffuse.contents = pipImage(label: contact.finger.pipLabel)
        pipMaterial.isDoubleSided = true
        pip.materials = [pipMaterial]
        let pipNode = SCNNode(geometry: pip)
        pipNode.simdPosition = SIMD3<Float>(pose.contact * 1.06)
        pipNode.constraints = [SCNBillboardConstraint()]
        group.addChildNode(pipNode)

        return group
    }

    private static func shadowOpacity(for tier: PressureTier) -> CGFloat {
        switch tier {
        case .primary: return 0.36
        case .support: return 0.24
        case .light: return 0.15
        }
    }

    /// Soft radial shadow, rasterized once per process.
    private static let shadowDecalImage: UIImage = {
        let size = CGSize(width: 64, height: 64)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [UIColor.black.withAlphaComponent(0.9).cgColor,
                          UIColor.black.withAlphaComponent(0).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: colors as CFArray, locations: [0, 1])!
            ctx.cgContext.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: 32, y: 32), startRadius: 0,
                endCenter: CGPoint(x: 32, y: 32), endRadius: 32,
                options: []
            )
        }
    }()

    /// Pip label: cyan ring, void disc, Martian Mono numeral — the 2D pip,
    /// rasterized for the 3D stage.
    private static func pipImage(label: String) -> UIImage {
        let size = CGSize(width: 64, height: 64)
        let cyan = UIColor(hexRGB: 0x37D6FF)
        let void = UIColor(hexRGB: 0x070509).withAlphaComponent(0.82)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let disc = CGRect(x: 3, y: 3, width: 58, height: 58)
            void.setFill()
            ctx.cgContext.fillEllipse(in: disc)
            cyan.setStroke()
            ctx.cgContext.setLineWidth(4)
            ctx.cgContext.strokeEllipse(in: disc)

            let font = UIFont(name: "MartianMono-Regular", size: 26)
                ?? UIFont.monospacedSystemFont(ofSize: 26, weight: .regular)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: cyan,
            ]
            let text = NSAttributedString(string: label, attributes: attributes)
            let bounds = text.boundingRect(with: size, options: [], context: nil)
            text.draw(at: CGPoint(x: (size.width - bounds.width) / 2,
                                  y: (size.height - bounds.height) / 2))
        }
    }

    // MARK: - Spin axis overlay

    /// Double arrow through the poles in bone, plus a thin equatorial ring —
    /// the plane the seams sweep through as the cover turns. Port of the web's
    /// Vectors axis group; the Magnus arrow stays a web-only surface for now.
    private static func makeAxisGroup(spinAxis: SIMD3<Double>) -> SCNNode {
        let group = SCNNode()
        group.name = axisNodeName

        let bone = UIColor(hexRGB: 0xC7BEA8)
        let length = 1.5
        let head = min(0.15, length * 0.5)
        let shaft = max(0.001, length - head)
        let radius: CGFloat = 0.013

        func arrow(along dir: SIMD3<Double>) -> SCNNode {
            let node = SCNNode()
            let material = SCNMaterial()
            material.lightingModel = .physicallyBased
            material.diffuse.contents = bone
            material.roughness.contents = 0.5
            material.metalness.contents = 0.0

            let cylinder = SCNCylinder(radius: radius, height: CGFloat(shaft))
            cylinder.materials = [material]
            let shaftNode = SCNNode(geometry: cylinder)
            shaftNode.position = SCNVector3(0, shaft / 2, 0)
            node.addChildNode(shaftNode)

            let cone = SCNCone(topRadius: 0, bottomRadius: radius * 3, height: CGFloat(head))
            cone.materials = [material]
            let headNode = SCNNode(geometry: cone)
            headNode.position = SCNVector3(0, shaft + head / 2, 0)
            node.addChildNode(headNode)

            node.simdOrientation = simd_quatf(simd_quatd(from: SIMD3(0, 1, 0), to: dir))
            return node
        }

        group.addChildNode(arrow(along: spinAxis))
        group.addChildNode(arrow(along: -spinAxis))

        // equatorial ring: normal along the axis (SCNTorus's axis is local Y)
        let torus = SCNTorus(ringRadius: 1.1975, pipeRadius: 0.012)
        let ringMaterial = SCNMaterial()
        ringMaterial.lightingModel = .constant
        ringMaterial.diffuse.contents = bone
        ringMaterial.transparency = 0.32
        ringMaterial.isDoubleSided = true
        torus.materials = [ringMaterial]
        let ringNode = SCNNode(geometry: torus)
        ringNode.simdOrientation = simd_quatf(simd_quatd(from: SIMD3(0, 1, 0), to: spinAxis))
        group.addChildNode(ringNode)

        return group
    }

    // MARK: - Studio

    /// The vertical gradient the leather reflects: warm dusk overhead, a bright
    /// horizon band, cool stage underfoot (the web Studio's ramp, 4×256).
    private static func makeEnvironmentGradient() -> CGImage {
        let width = 4
        let height = 256
        let stops: [(Double, (Double, Double, Double))] = [
            (0.00, (0x3A, 0x31, 0x28)), // warm dusk overhead
            (0.42, (0x6A, 0x5F, 0x50)),
            (0.52, (0xA8, 0x94, 0x78)), // bright horizon band
            (0.62, (0x5A, 0x54, 0x48)),
            (1.00, (0x0C, 0x0D, 0x12)), // cool stage underfoot
        ]
        var bytes = [UInt8](repeating: 255, count: width * height * 4)
        for y in 0..<height {
            let f = Double(y) / Double(height - 1)
            var lo = stops[0]
            var hi = stops[stops.count - 1]
            for i in 0..<(stops.count - 1) where f >= stops[i].0 && f <= stops[i + 1].0 {
                lo = stops[i]
                hi = stops[i + 1]
                break
            }
            let span = max(1e-9, hi.0 - lo.0)
            let mix = (f - lo.0) / span
            let r = UInt8(lo.1.0 + (hi.1.0 - lo.1.0) * mix)
            let g = UInt8(lo.1.1 + (hi.1.1 - lo.1.1) * mix)
            let b = UInt8(lo.1.2 + (hi.1.2 - lo.1.2) * mix)
            for x in 0..<width {
                let idx = (y * width + x) * 4
                bytes[idx] = r
                bytes[idx + 1] = g
                bytes[idx + 2] = b
            }
        }
        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        return CGImage(
            width: width, height: height,
            bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent
        )!
    }

    private static func addDirectionalLight(
        to scene: SCNScene, color: UIColor, intensity: CGFloat, from position: SCNVector3
    ) {
        let light = SCNLight()
        light.type = .directional
        light.color = color
        light.intensity = intensity
        let node = SCNNode()
        node.light = light
        node.position = position
        node.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(node)
    }
}

// MARK: - Arc-length parameterization of the seam

/// Cumulative-length lookup so stitch pairs land evenly by surface distance,
/// not by curve parameter — the web gets this for free from its arc-length-
/// parameterized curve sampling; this table is the native equivalent.
struct SeamArcTable {
    private let cumulative: [Double]
    private let total: Double

    init(resolution: Int) {
        var lengths = [Double](repeating: 0, count: resolution + 1)
        var previous = SeamMath.seamPoint(0)
        for i in 1...resolution {
            let t = Double(i) / Double(resolution) * 2 * .pi
            let p = SeamMath.seamPoint(t)
            lengths[i] = lengths[i - 1] + simd_length(p - previous)
            previous = p
        }
        cumulative = lengths
        total = lengths[resolution]
    }

    /// The curve parameter t (radians) at a given fraction [0,1) of total arc length.
    func parameter(atFraction fraction: Double) -> Double {
        let target = fraction * total
        var lo = 0
        var hi = cumulative.count - 1
        while lo + 1 < hi {
            let mid = (lo + hi) / 2
            if cumulative[mid] < target { lo = mid } else { hi = mid }
        }
        let span = max(1e-12, cumulative[hi] - cumulative[lo])
        let mix = (target - cumulative[lo]) / span
        let steps = Double(cumulative.count - 1)
        return (Double(lo) + mix) / steps * 2 * .pi
    }
}

// MARK: - Small bridges

extension Vec3 {
    /// The decoded content vector as simd, for the scene math.
    var simd: SIMD3<Double> { SIMD3(x, y, z) }
}

extension SCNVector3 {
    init(_ v: SIMD3<Double>) {
        self.init(Float(v.x), Float(v.y), Float(v.z))
    }
}

extension simd_quatf {
    init(_ q: simd_quatd) {
        self.init(vector: SIMD4<Float>(Float(q.vector.x), Float(q.vector.y),
                                       Float(q.vector.z), Float(q.vector.w)))
    }
}

extension SIMD3 where Scalar == Float {
    init(_ v: SIMD3<Double>) {
        self.init(Float(v.x), Float(v.y), Float(v.z))
    }
}

private extension UIColor {
    convenience init(hexRGB hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
