import XCTest
import SceneKit
import simd
@testable import PitchAtlas

// =============================================================================
// Scene3D tests — the math, the solver, the maps, the scene, the fallback
// =============================================================================
// The golden block below was captured BEFORE the SeamBall refactor, by running
// the exact inline expressions from SeamBall.swift as they stood
// (x = 2 sin t + sin 3t; y = 2 cos t − cos 3t; z = 2√2 cos 2t; normalized) at
// 32 sample t values via a standalone `swift` script. SeamMath must reproduce
// them to 1e-9, proving the refactor changed the plumbing and not one pixel of
// the 2D schematic.
// =============================================================================

final class Scene3DTests: XCTestCase {

    /// seamPoint at t = i/32 · 2π, i in 0..<32 — captured pre-refactor.
    private static let goldens: [SIMD3<Double>] = [
        SIMD3(0, 0.33333333333333326, 0.94280904158206325),
        SIMD3(0.31525029235061958, 0.37670031616797184, 0.87104197658425109),
        SIMD3(0.56308213241382199, 0.48835854421916114, 0.66666666666666674),
        SIMD3(0.69730858214747826, 0.61934318220707285, 0.36079740009746475),
        SIMD3(0.70710678118654746, 0.70710678118654757, 5.7730403749032898e-17),
        SIMD3(0.61934318220707296, 0.69730858214747815, -0.36079740009746464),
        SIMD3(0.48835854421916119, 0.5630821324138221, -0.66666666666666652),
        SIMD3(0.37670031616797184, 0.31525029235061958, -0.87104197658425109),
        SIMD3(0.33333333333333326, 1.0205389992894607e-16, -0.94280904158206325),
        SIMD3(0.37670031616797184, -0.31525029235061941, -0.8710419765842512),
        SIMD3(0.48835854421916108, -0.5630821324138221, -0.66666666666666696),
        SIMD3(0.61934318220707263, -0.69730858214747826, -0.36079740009746519),
        SIMD3(0.70710678118654746, -0.70710678118654757, -1.7319121124709868e-16),
        SIMD3(0.69730858214747815, -0.61934318220707285, 0.36079740009746486),
        SIMD3(0.56308213241382221, -0.48835854421916119, 0.66666666666666652),
        SIMD3(0.3152502923506203, -0.37670031616797217, 0.87104197658425075),
        SIMD3(2.0410779985789214e-16, -0.33333333333333326, 0.94280904158206325),
        SIMD3(-0.31525029235061991, -0.37670031616797206, 0.87104197658425075),
        SIMD3(-0.56308213241382199, -0.48835854421916114, 0.66666666666666696),
        SIMD3(-0.69730858214747815, -0.61934318220707263, 0.3607974000974653),
        SIMD3(-0.70710678118654779, -0.70710678118654735, 2.8865201874516448e-16),
        SIMD3(-0.61934318220707285, -0.69730858214747826, -0.3607974000974648),
        SIMD3(-0.48835854421916164, -0.56308213241382266, -0.66666666666666596),
        SIMD3(-0.37670031616797189, -0.31525029235062002, -0.87104197658425087),
        SIMD3(-0.33333333333333326, -3.0616169978683822e-16, -0.94280904158206325),
        SIMD3(-0.37670031616797173, 0.31525029235061941, -0.8710419765842512),
        SIMD3(-0.48835854421916136, 0.56308213241382232, -0.66666666666666641),
        SIMD3(-0.61934318220707263, 0.69730858214747815, -0.36079740009746541),
        SIMD3(-0.70710678118654768, 0.70710678118654746, -4.041128262432303e-16),
        SIMD3(-0.69730858214747804, 0.61934318220707341, 0.36079740009746464),
        SIMD3(-0.56308213241382266, 0.48835854421916203, 0.66666666666666552),
        SIMD3(-0.31525029235062041, 0.37670031616797217, 0.87104197658425064),
    ]

    // MARK: - Seam math

    func testSeamPointMatchesPreRefactorGoldens() {
        for (i, expected) in Self.goldens.enumerated() {
            let t = Double(i) / 32.0 * 2 * .pi
            let p = SeamMath.seamPoint(t)
            XCTAssertEqual(p.x, expected.x, accuracy: 1e-9, "x at sample \(i)")
            XCTAssertEqual(p.y, expected.y, accuracy: 1e-9, "y at sample \(i)")
            XCTAssertEqual(p.z, expected.z, accuracy: 1e-9, "z at sample \(i)")
        }
    }

    func testSeamPointStaysOnUnitSphere() {
        for i in 0..<257 {
            let t = Double(i) / 257.0 * 2 * .pi
            XCTAssertEqual(simd_length(SeamMath.seamPoint(t)), 1, accuracy: 1e-12)
        }
    }

    func testSeamCurveCloses() {
        let start = SeamMath.seamPoint(0)
        let end = SeamMath.seamPoint(2 * .pi)
        XCTAssertEqual(simd_length(start - end), 0, accuracy: 1e-9)
    }

    func testSeamSamplesHaveNoDuplicatedClosingPoint() {
        let samples = SeamMath.seamSamples(108)
        XCTAssertEqual(samples.count, 108)
        XCTAssertGreaterThan(simd_length(samples.first! - samples.last!), 1e-3,
                             "the last sample must not repeat the first — samples are open, polylines close")
    }

    // MARK: - Contact solver

    private func contact(
        finger: Finger = .index, seamT: Double = 0.305, lift: Double = 0.02,
        seamOffset: Double = 0, azimuth: Double = 80,
        engagement: FingerEngagement = .pad, pressureTier: PressureTier = .support
    ) -> GripContactModel {
        GripContactModel(
            finger: finger, label: "Test", seamT: seamT, lift: lift,
            seamRelation: "test", pressureRole: "test", cue: "test", curl: 0.18,
            seamOffset: seamOffset, azimuth: azimuth,
            engagement: engagement, pressureTier: pressureTier
        )
    }

    func testZeroOffsetContactLandsExactlyOnTheSeam() {
        let c = contact(seamOffset: 0)
        let pose = ContactPoseSolver.solve(c)
        let onSeam = SeamMath.seamPoint(c.seamT * 2 * .pi)
        XCTAssertEqual(simd_length(pose.contact - onSeam), 0, accuracy: 1e-9)
    }

    func testContactStaysOnUnitSphereForOffsets() {
        for offset in [-0.2, -0.05, 0.0, 0.04, 0.18, 0.5] {
            let pose = ContactPoseSolver.solve(contact(seamOffset: offset))
            XCTAssertEqual(simd_length(pose.contact), 1, accuracy: 1e-9, "offset \(offset)")
            XCTAssertEqual(simd_length(pose.normal), 1, accuracy: 1e-9)
        }
    }

    func testSpineDirIsTangentToTheSphere() {
        for (seamT, offset, azimuth) in [(0.305, 0.0, 80.0), (0.62, 0.08, 0.0), (0.11, -0.12, 45.0)] {
            let pose = ContactPoseSolver.solve(contact(seamT: seamT, seamOffset: offset, azimuth: azimuth))
            XCTAssertEqual(simd_dot(pose.spineDir, pose.normal), 0, accuracy: 1e-9)
            XCTAssertEqual(simd_length(pose.spineDir), 1, accuracy: 1e-9)
        }
    }

    func testAzimuth90CrossesTheSeamSquare() {
        let seamT = 0.305
        let pose = ContactPoseSolver.solve(contact(seamT: seamT, seamOffset: 0, azimuth: 90))
        let tangent = SeamMath.seamTangent(seamT * 2 * .pi)
        XCTAssertEqual(simd_dot(pose.spineDir, tangent), 0, accuracy: 1e-9)
    }

    func testLeftHandednessMirrorsXOnly() {
        let c = contact(seamT: 0.42, seamOffset: 0.06, azimuth: 35)
        let right = ContactPoseSolver.solve(c, handedness: .right)
        let left = ContactPoseSolver.solve(c, handedness: .left)
        for (r, l) in [(right.contact, left.contact), (right.normal, left.normal), (right.spineDir, left.spineDir)] {
            XCTAssertEqual(r.x, -l.x, accuracy: 1e-12)
            XCTAssertEqual(r.y, l.y, accuracy: 1e-12)
            XCTAssertEqual(r.z, l.z, accuracy: 1e-12)
        }
        XCTAssertEqual(right.padRadius, left.padRadius)
        XCTAssertEqual(right.lift, left.lift)
    }

    /// The solver tables must equal the web's gripPose.ts constants exactly —
    /// the parity contract that keeps the two platforms one atlas.
    func testEngagementAndPressureTablesMatchTheWeb() {
        XCTAssertEqual(ContactPoseSolver.engagementLift[.tip], 0.006)
        XCTAssertEqual(ContactPoseSolver.engagementLift[.pad], 0.004)
        XCTAssertEqual(ContactPoseSolver.engagementLift[.inside], 0.003)
        XCTAssertEqual(ContactPoseSolver.engagementLift[.nail], 0.04)
        XCTAssertEqual(ContactPoseSolver.engagementLift[.knuckle], 0.055)

        XCTAssertEqual(ContactPoseSolver.pressureRadiusFactor[.primary], 1.1)
        XCTAssertEqual(ContactPoseSolver.pressureRadiusFactor[.support], 1.0)
        XCTAssertEqual(ContactPoseSolver.pressureRadiusFactor[.light], 0.92)

        XCTAssertEqual(ContactPoseSolver.fingerRadius[.thumb], 0.155)
        XCTAssertEqual(ContactPoseSolver.fingerRadius[.index], 0.125)
        XCTAssertEqual(ContactPoseSolver.fingerRadius[.middle], 0.13)
        XCTAssertEqual(ContactPoseSolver.fingerRadius[.ring], 0.12)
        XCTAssertEqual(ContactPoseSolver.fingerRadius[.pinky], 0.1)
    }

    // MARK: - Leather maps

    func testLeatherMapsAreDeterministicAndSized() throws {
        let a = LeatherMaps.generate(size: 64)
        let b = LeatherMaps.generate(size: 64)
        XCTAssertEqual(a.albedo.width, 64)
        XCTAssertEqual(a.albedo.height, 64)
        XCTAssertEqual(a.normal.width, 64)
        XCTAssertEqual(a.roughness.width, 64)

        func firstRow(_ image: CGImage) throws -> [UInt8] {
            let data = try XCTUnwrap(image.dataProvider?.data) as Data
            return Array(data.prefix(image.bytesPerRow))
        }
        try XCTAssertEqual(firstRow(a.albedo), firstRow(b.albedo),
                           "same seed must produce byte-identical albedo")
        try XCTAssertEqual(firstRow(a.normal), firstRow(b.normal))
        try XCTAssertEqual(firstRow(a.roughness), firstRow(b.roughness))
    }

    // MARK: - Scene assembly (headless)

    func testSceneBuildsForEveryFiledPitch() {
        let store = PitchStore()
        XCTAssertFalse(store.pitches.isEmpty, "no pitches decoded")
        let maps = LeatherMaps.generate(size: 64)

        for entry in store.pitches {
            guard let built = SpecimenSceneBuilder.build(entry: entry, maps: maps, showAxis: false) else {
                XCTFail("\(entry.slug) failed to build a scene")
                continue
            }

            // the seam tube: 513 vertex rings (loop closed by reusing ring 0) × 12
            let tube = built.scene.rootNode.childNode(
                withName: SpecimenSceneBuilder.tubeNodeName, recursively: true
            )
            let tubeVertices = tube?.geometry?.sources(for: .vertex).first?.vectorCount
            XCTAssertEqual(tubeVertices, 513 * 12, "\(entry.slug) tube vertex count")

            // 216 stitches merged into one geometry
            let stitches = built.scene.rootNode.childNode(
                withName: SpecimenSceneBuilder.stitchNodeName, recursively: true
            )
            let stitchVertices = stitches?.geometry?.sources(for: .vertex).first?.vectorCount
            XCTAssertEqual(stitchVertices,
                           216 * SpecimenSceneBuilder.stitchTemplateVertexCount,
                           "\(entry.slug) merged stitch geometry")

            // one pad group per authored contact
            var padCount = 0
            built.scene.rootNode.enumerateChildNodes { node, _ in
                if node.name == SpecimenSceneBuilder.contactPadNodeName { padCount += 1 }
            }
            XCTAssertEqual(padCount, entry.canonical.gripModel.contacts.count,
                           "\(entry.slug) pad group per contact")

            // the axis group exists and honors the toggle default (hidden)
            XCTAssertTrue(built.axisNode.isHidden)
            XCTAssertEqual(simd_length(built.spinAxis), 1, accuracy: 1e-6)
        }
    }

    // MARK: - Fallback ladder

    func testStageModeRoutesEveryDegradedCaseToTheSchematic() {
        // any single failure → the honest 2D floor
        XCTAssertEqual(SpecimenStage.mode(reduceMotion: true, metalAvailable: true, sceneBuilt: true), .schematic)
        XCTAssertEqual(SpecimenStage.mode(reduceMotion: false, metalAvailable: false, sceneBuilt: true), .schematic)
        XCTAssertEqual(SpecimenStage.mode(reduceMotion: false, metalAvailable: true, sceneBuilt: false), .schematic)
        XCTAssertEqual(SpecimenStage.mode(reduceMotion: true, metalAvailable: false, sceneBuilt: false), .schematic)
        // the full stack present → dimensional
        XCTAssertEqual(SpecimenStage.mode(reduceMotion: false, metalAvailable: true, sceneBuilt: true), .dimensional)
    }
}
