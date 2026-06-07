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

// MARK: - Foil rake modifier

/// Lays a holographic foil sheen over a card and rakes it with device tilt. The
/// signature iOS-owned moment. Clipped to a rounded rect, blended so it reads as a
/// material, and silent (no haptic). Falls back to a still, faint sheen when the
/// gyro is unavailable or Reduce Motion is on.
struct FoilRake: ViewModifier {
    @Environment(MotionProvider.self) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var radius: CGFloat = PitchAtlasRadius.card
    var intensity: Double = 1.0

    func body(content: Content) -> some View {
        content.overlay {
            GeometryReader { geo in
                let dx = reduceMotion ? 0 : motion.roll * geo.size.width * 0.45 * intensity
                let dy = reduceMotion ? 0 : motion.pitch * geo.size.height * 0.45 * intensity
                PitchAtlasTheme.foil
                    .scaleEffect(2.0)
                    .offset(x: dx, y: dy)
                    .blendMode(.colorDodge)
                    .opacity(0.16)
                    .animation(.easeOut(duration: 0.12), value: motion.roll)
                    .animation(.easeOut(duration: 0.12), value: motion.pitch)
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
        .accessibilityHidden(false)
    }
}

extension View {
    /// Apply the gyroscope foil rake, clipped to a rounded rect.
    func foilRake(radius: CGFloat = PitchAtlasRadius.card, intensity: Double = 1.0) -> some View {
        modifier(FoilRake(radius: radius, intensity: intensity))
    }
}
