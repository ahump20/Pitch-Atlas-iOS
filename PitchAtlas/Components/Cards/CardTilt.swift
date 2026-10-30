import SwiftUI

// =============================================================================
// Card tilt (web useCardTilt)
// =============================================================================
// The card answers the hand with mass. On the page a horizontal drag rocks the
// card to ±14° (a vertical drag stays the page's scroll); the hero card also
// leans with the phone, ±10°. On the bench the card is grabbed on both axes to
// ±28° and glides home on a softer spring. The light follows the tilt. Reduce
// Motion holds every card at rest.
//
// The hand's tilt is a UIKit pan that only begins on a mostly sideways stroke.
// A SwiftUI DragGesture on a card, even a simultaneous one, kept a vertical
// stroke that started on the card from ever scrolling the page (diag/home-scroll,
// run 40668248341: the home moved only with the tilt switched off). iOS 17 has
// no representable gesture, so there a page card leans with the phone only.
// =============================================================================

enum CardTiltMode: Equatable {
    case rest, hero, inspector

    var dragMax: Double { self == .inspector ? 28 : 14 }
    /// The spring: ω 20 ζ 0.7 on the page, ω 11 ζ 0.62 on the bench (response = 2π/ω).
    var spring: Animation {
        switch self {
        case .inspector: .spring(response: 2 * .pi / 11, dampingFraction: 0.62)
        case .rest, .hero: PitchAtlasMotion.tiltSpring
        }
    }
}

struct CardTiltState: Equatable {
    var rx = 0.0, ry = 0.0, mx = 50.0, my = 32.0
    static let rest = CardTiltState()
    static let dragMax = 14.0, gyroMax = 10.0
    static let threshold: CGFloat = 8

    private static func clamp(_ v: Double, _ m: Double) -> Double { min(m, max(-m, v)) }
    /// The light is a function of the tilt, always against the page's 14° range.
    private static func lit(rx: Double, ry: Double) -> CardTiltState {
        CardTiltState(rx: rx, ry: ry, mx: 50 + rx / dragMax * 42, my: 32 + ry / dragMax * 30)
    }

    /// Page cards: horizontal drags tilt; a mostly-vertical drag is a scroll and returns nil.
    static func drag(translation t: CGSize, width: CGFloat) -> CardTiltState? {
        guard abs(t.width) >= threshold, abs(t.width) > abs(t.height), width > 0 else { return nil }
        let rx = clamp(Double(t.width / width) * dragMax * 2.4, dragMax)
        return lit(rx: rx, ry: clamp(rx * -0.22, dragMax))
    }

    /// The bench: any drag past the threshold grabs the card on both axes.
    static func grab(translation t: CGSize, size: CGSize) -> CardTiltState? {
        guard abs(t.width) >= threshold || abs(t.height) >= threshold, size.width > 0, size.height > 0 else { return nil }
        let m = CardTiltMode.inspector.dragMax
        let rx = clamp(Double(t.width / size.width) * m * 2.4, m)
        let ry = clamp(Double(-t.height / size.height) * m * 2.4, m)
        return lit(rx: rx, ry: ry)
    }

    static func gyro(roll: Double, pitch: Double) -> CardTiltState {
        lit(rx: clamp(roll * gyroMax, gyroMax), ry: clamp(-pitch * gyroMax, gyroMax))
    }

    var light: UnitPoint { UnitPoint(x: mx / 100, y: my / 100) }
}

private struct CardTiltModifier: ViewModifier {
    let mode: CardTiltMode
    let size: CGSize
    @Binding var light: UnitPoint
    var rake = true
    @Environment(MotionProvider.self) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drag: CardTiltState?

    private var state: CardTiltState {
        if reduceMotion { return .rest }
        if let drag { return drag }
        return mode == .hero ? .gyro(roll: motion.roll, pitch: motion.pitch) : .rest
    }

    private func tilt(for translation: CGSize) -> CardTiltState? {
        mode == .inspector
            ? CardTiltState.grab(translation: translation, size: size)
            : CardTiltState.drag(translation: translation, width: size.width)
    }

    private var gesture: some Gesture {
        DragGesture(minimumDistance: CardTiltState.threshold)
            .onChanged { v in drag = tilt(for: v.translation) }
            .onEnded { _ in drag = nil }
    }

    @ViewBuilder
    private func handTilt<V: View>(_ view: V) -> some View {
        if reduceMotion {
            view
        } else if #available(iOS 18.0, *) {
            view.gesture(TiltPan(sidewaysOnly: mode != .inspector,
                                 changed: { drag = tilt(for: $0) },
                                 ended: { drag = nil }))
        } else if mode == .inspector {
            // the bench stands outside any scroll view, so the drag can't take one over
            view.simultaneousGesture(gesture)
        } else {
            view
        }
    }

    func body(content: Content) -> some View {
        let s = state
        handTilt(content
            .rotation3DEffect(.degrees(s.rx), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
            .rotation3DEffect(.degrees(s.ry), axis: (x: 1, y: 0, z: 0), perspective: 0.4)
            .overlay {
                // the rim rake: a bone glint at the light, on the frame ring only
                if rake {
                    RadialGradient(colors: [.white.opacity(0.5), .clear], center: s.light, startRadius: 0, endRadius: 190)
                        .blendMode(.screen).opacity(0.46)
                        .mask(RoundedRectangle(cornerRadius: PitchAtlasRadius.card, style: .continuous).strokeBorder(lineWidth: 13))
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            })
            .animation(PitchAtlasMotion.animation(mode.spring, reduceMotion: reduceMotion), value: s)
            .onChange(of: s) { _, new in light = new.light }
    }
}

/// The hand's tilt as a system pan. On a page it begins only when the stroke is
/// more sideways than vertical, so a vertical stroke that starts on a card stays
/// the page's scroll; on the bench any stroke grabs the card.
@available(iOS 18.0, *)
private struct TiltPan: UIGestureRecognizerRepresentable {
    let sidewaysOnly: Bool
    let changed: (CGSize) -> Void
    let ended: () -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        context.coordinator.sidewaysOnly = sidewaysOnly
        return pan
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        context.coordinator.sidewaysOnly = sidewaysOnly
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        switch recognizer.state {
        case .began, .changed:
            let t = recognizer.translation(in: recognizer.view)
            changed(CGSize(width: t.x, height: t.y))
        default:
            ended()
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var sidewaysOnly = true

        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard sidewaysOnly, let pan = recognizer as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }

        func gestureRecognizer(_ recognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    }
}

extension View {
    /// Tilt a card by the hand (and, on the hero, by the phone). The motion
    /// provider's lifecycle belongs to the app; this only reads it. The matte
    /// back has no frame ring, so it turns without the rim rake.
    func cardTilt(_ mode: CardTiltMode, size: CGSize, light: Binding<UnitPoint>, rake: Bool = true) -> some View {
        modifier(CardTiltModifier(mode: mode, size: size, light: light, rake: rake))
    }
}
