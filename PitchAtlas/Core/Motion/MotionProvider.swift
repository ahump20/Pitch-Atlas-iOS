import SwiftUI
import CoreMotion

// =============================================================================
// MotionProvider — the gyroscope feed for the foil rake
// =============================================================================
// Publishes normalized tilt (−1…1) from device motion so the holographic foil can
// rake across a card as the phone turns — the one thing the web cannot do. Honors
// Reduce Motion (never starts), caps the tilt envelope, and runs a single shared
// CMMotionManager injected through the environment.
// =============================================================================

@Observable
final class MotionProvider {
    /// Normalized left/right tilt, −1…1 (capped at ~±9° of roll).
    var roll: Double = 0
    /// Normalized fore/aft tilt, −1…1.
    var pitch: Double = 0

    private let manager = CMMotionManager()
    private let cap = Double.pi / 20  // ~9° envelope

    func start() {
        // Respect Reduce Motion: if on, never run the gyro — the foil stays still.
        if UIAccessibility.isReduceMotionEnabled { return }
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.roll = max(-1, min(1, motion.attitude.roll / self.cap))
            self.pitch = max(-1, min(1, motion.attitude.pitch / self.cap))
        }
    }

    func stop() {
        if manager.isDeviceMotionActive { manager.stopDeviceMotionUpdates() }
    }
}
