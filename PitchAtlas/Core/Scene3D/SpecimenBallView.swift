import SwiftUI
import SceneKit
import simd

// =============================================================================
// SpecimenBallView — the SCNView bridge
// =============================================================================
// UIViewRepresentable wrapper for the built specimen scene. Owns the runtime
// behavior only — all geometry and materials come pre-assembled from
// SpecimenSceneBuilder (the only other file that imports SceneKit):
//  - drag orbit: pan → yaw/pitch on the orbit node, pitch clamped ±80°,
//    ~0.4s velocity decay after release, 8pt minimum drag before engaging
//  - idle spin: ~0.55 rad/s about the pitch's authored spin axis
//  - gyro parallax at rest: +roll×4° yaw, +pitch×3° pitch, eased — riding the
//    same injected MotionProvider the foil rake uses (it already honors
//    Reduce Motion by never starting)
//  - power discipline: 30fps at rest, 60 during drag, render scale capped at
//    2.0, and isPlaying driven from outside (visibility / scenePhase)
// No pinch zoom: the specimen sits at its filed distance.
// =============================================================================

struct SpecimenBallView: UIViewRepresentable {
    let built: SpecimenSceneBuilder.Built
    let motion: MotionProvider
    var isPlaying: Bool
    var showAxis: Bool

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = built.scene
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.contentScaleFactor = min(UIScreen.main.scale, 2.0)
        view.preferredFramesPerSecond = 30
        view.rendersContinuously = true
        view.isAccessibilityElement = false
        view.delegate = context.coordinator

        let pan = UIPanGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)

        context.coordinator.view = view
        context.coordinator.apply(built: built, motion: motion)
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.apply(built: built, motion: motion)
        built.axisNode.isHidden = !showAxis
        view.isPlaying = isPlaying
        view.rendersContinuously = isPlaying
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - Coordinator (render loop + gestures)

    final class Coordinator: NSObject, SCNSceneRendererDelegate, @unchecked Sendable {
        weak var view: SCNView?
        private var built: SpecimenSceneBuilder.Built?
        private var motion: MotionProvider?

        // orbit state
        private var yaw = 0.0
        private var pitch = 0.0
        private var yawVelocity = 0.0
        private var pitchVelocity = 0.0
        private var dragging = false
        private var dragEngaged = false
        private var lastTranslation = CGPoint.zero

        // idle + parallax state
        private var spinAngle = 0.0
        private var parallaxYaw = 0.0
        private var parallaxPitch = 0.0
        private var lastTime: TimeInterval?

        private let radiansPerPoint = 0.008
        private let pitchLimit = 80.0 * .pi / 180
        private let minimumDragDistance: CGFloat = 8

        func apply(built: SpecimenSceneBuilder.Built, motion: MotionProvider) {
            if let current = self.built, current.scene !== built.scene {
                // a different specimen took the stage: reset the pose
                yaw = 0; pitch = 0; yawVelocity = 0; pitchVelocity = 0; spinAngle = 0
            }
            self.built = built
            self.motion = motion
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view else { return }
            let translation = gesture.translation(in: view)
            switch gesture.state {
            case .began:
                dragEngaged = false
                lastTranslation = translation
            case .changed:
                if !dragEngaged {
                    // 8pt of slop before the orbit engages, so vertical page
                    // scrolls that graze the stage don't grab the ball.
                    guard hypot(translation.x, translation.y) >= minimumDragDistance else { return }
                    dragEngaged = true
                    dragging = true
                    lastTranslation = translation
                    view.preferredFramesPerSecond = 60
                    return
                }
                let dx = Double(translation.x - lastTranslation.x)
                let dy = Double(translation.y - lastTranslation.y)
                lastTranslation = translation
                yaw += dx * radiansPerPoint
                pitch = clampPitch(pitch + dy * radiansPerPoint)
            case .ended, .cancelled, .failed:
                if dragEngaged {
                    let velocity = gesture.velocity(in: view)
                    yawVelocity = Double(velocity.x) * radiansPerPoint
                    pitchVelocity = Double(velocity.y) * radiansPerPoint
                }
                dragging = false
                dragEngaged = false
                view.preferredFramesPerSecond = 30
            default:
                break
            }
        }

        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            guard let built else { return }
            let dt = lastTime.map { min(0.1, time - $0) } ?? 0
            lastTime = time
            guard dt > 0 else { return }

            // released momentum, decaying over ~0.4s
            if !dragging, abs(yawVelocity) + abs(pitchVelocity) > 1e-4 {
                yaw += yawVelocity * dt
                pitch = clampPitch(pitch + pitchVelocity * dt)
                let decay = exp(-dt / 0.13)
                yawVelocity *= decay
                pitchVelocity *= decay
            }

            // gyro parallax at rest: eased toward +roll×4°, +pitch×3°
            let targetYaw = dragging ? 0 : (motion?.roll ?? 0) * 4 * .pi / 180
            let targetPitch = dragging ? 0 : (motion?.pitch ?? 0) * 3 * .pi / 180
            let ease = min(1, dt * 4)
            parallaxYaw += (targetYaw - parallaxYaw) * ease
            parallaxPitch += (targetPitch - parallaxPitch) * ease

            let orbit = simd_quatd(angle: yaw + parallaxYaw, axis: SIMD3(0, 1, 0))
                * simd_quatd(angle: pitch + parallaxPitch, axis: SIMD3(1, 0, 0))
            built.orbitNode.simdOrientation = simd_quatf(orbit)

            // idle backspin about the authored axis, under everything else
            spinAngle += 0.55 * dt
            built.spinNode.simdOrientation = simd_quatf(
                simd_quatd(angle: spinAngle, axis: built.spinAxis)
            )
        }

        private func clampPitch(_ value: Double) -> Double {
            max(-pitchLimit, min(pitchLimit, value))
        }
    }
}
