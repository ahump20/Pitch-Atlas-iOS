import SwiftUI
import simd

// =============================================================================
// SeamBall: the native specimen
// =============================================================================
// Draws the baseball seam from the SAME closed-form figure-eight the web ships
// (x = 2 sin t + sin 3t ; y = 2 cos t − cos 3t ; z = 2√2 cos 2t), normalized to
// the ball, then projected to the catcher's eye. The curve itself lives in
// SeamMath — the one seam-point function the 2D schematic, the 3D tube, and the
// contact solver all share, so they can never disagree. The spin axis orients
// the seam; the break arrow is a schematic cue from sourced shape language,
// never a fake measured break value.
// Labeled a seam-informed schematic, because that is what it is.
//
// This is the bundled Reduce Motion specimen and the pitch-detail ball surface.
// =============================================================================

extension Finger {
    /// The pip character the specimens speak: 1 index, 2 middle, 3 ring,
    /// 4 pinky, T thumb — shared by the 2D markers and the 3D pip billboards.
    var pipLabel: String {
        switch self {
        case .index: return "1"
        case .middle: return "2"
        case .ring: return "3"
        case .pinky: return "4"
        case .thumb: return "T"
        }
    }
}

/// The projected seam outline, rotated in-plane by the spin-axis orientation.
struct SeamShape: Shape {
    /// In-plane spin-axis angle, radians.
    var rotation: Double

    var animatableData: Double {
        get { rotation }
        set { rotation = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) / 2 * 0.92
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        let steps = 240
        for i in 0...steps {
            let t = Double(i) / Double(steps) * 2 * .pi
            let p = SeamMath.seamPoint(t)
            // rotate the projection in-plane to reflect spin-axis orientation
            let rx = p.x * cos(rotation) - p.y * sin(rotation)
            let ry = p.x * sin(rotation) + p.y * cos(rotation)
            let point = CGPoint(x: c.x + CGFloat(rx) * r, y: c.y - CGFloat(ry) * r)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

/// A simple directional arrow from the ball center.
private struct BreakArrow: View {
    let angle: Double      // radians, 0 = right, CCW positive (screen y is flipped in math below)
    let magnitude: CGFloat // 0...1 of the radius
    let color: Color
    let radius: CGFloat

    var body: some View {
        let dx = cos(angle) * Double(magnitude) * Double(radius)
        let dy = sin(angle) * Double(magnitude) * Double(radius)
        let end = CGPoint(x: radius + CGFloat(dx), y: radius - CGFloat(dy))
        Path { p in
            p.move(to: CGPoint(x: radius, y: radius))
            p.addLine(to: end)
        }
        .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        .overlay(
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .position(end)
                .shadow(color: color.opacity(0.7), radius: 4)
        )
    }
}

/// The screen-space movement cue: gyro shows a dot toward the viewer, an
/// indeterminate pitch shows a dashed flutter ring, everything else shows the
/// schematic break arrow. Shared verbatim between the 2D schematic and the 3D
/// stage so both specimens speak the same break language — a cue from sourced
/// shape fields, never a measured break-in-inches figure.
struct MotionCueOverlay: View {
    let motion: PitchMotion
    let size: CGFloat

    /// Catcher's-eye movement direction, read from the qualitative shape fields.
    private var breakVector: (horizontal: Double, vertical: Double) {
        let direction: Double
        switch motion.horizontalDir {
        case .armSide: direction = 1
        case .gloveSide: direction = -1
        case .none: direction = 0
        }

        let vertical: Double
        switch motion.verticalShape ?? .flat {
        case .ride: vertical = 0.85
        case .flat: vertical = 0.0
        case .drop: vertical = -0.85
        }

        return (direction * 0.85, vertical)
    }

    /// Catcher's-eye break direction.
    private var breakAngle: Double {
        let vector = breakVector
        return atan2(vector.vertical, vector.horizontal == 0 ? 0.001 : vector.horizontal)
    }

    private var breakMagnitude: CGFloat {
        let vector = breakVector
        let mag = (vector.vertical * vector.vertical + vector.horizontal * vector.horizontal).squareRoot()
        return CGFloat(min(max(mag / 1.4, 0.25), 0.65))
    }

    var body: some View {
        ZStack {
            if motion.gyro == true {
                Circle()
                    .fill(PitchAtlasTheme.cyan)
                    .frame(width: 12, height: 12)
                    .shadow(color: PitchAtlasTheme.cyan.opacity(0.8), radius: 6)
            } else if motion.indeterminateBreak == true {
                Circle()
                    .stroke(PitchAtlasTheme.cyan,
                            style: StrokeStyle(lineWidth: 2.2, lineCap: .round, dash: [4, 6]))
                    .frame(width: size * 0.46, height: size * 0.46)
                    .shadow(color: PitchAtlasTheme.cyan.opacity(0.45), radius: 6)
            } else {
                BreakArrow(angle: breakAngle, magnitude: breakMagnitude,
                           color: PitchAtlasTheme.cyan, radius: size / 2)
            }
        }
        .frame(width: size, height: size)
    }
}

struct SeamBall: View {
    let motion: PitchMotion
    var size: CGFloat = 220
    /// Seam-anchored finger contacts to mark on the specimen. Empty by default so
    /// the small rail/Atlas balls stay clean; the large detail specimen passes the
    /// pitch's real `fingerPlacement` so a reader can see where the hand sits.
    var contacts: [SeamAnchoredPoint] = []

    /// In-plane orientation of the spin axis (radians).
    private var axisAngle: Double { atan2(motion.spinAxis.y, motion.spinAxis.x) }

    /// Project a seam parameter (0…1 around the figure-eight) to a screen point on
    /// the drawn seam — the SAME closed-form + in-plane rotation SeamShape uses, so
    /// a contact dot always lands exactly on the rendered seam line.
    private func seamPoint(at seamT: Double) -> CGPoint {
        let r = size / 2 * 0.92
        let c = CGPoint(x: size / 2, y: size / 2)
        let p = SeamMath.seamPoint(seamT * 2 * .pi)
        let rx = p.x * cos(axisAngle) - p.y * sin(axisAngle)
        let ry = p.x * sin(axisAngle) + p.y * cos(axisAngle)
        return CGPoint(x: c.x + CGFloat(rx) * r, y: c.y - CGFloat(ry) * r)
    }

    var body: some View {
        ZStack {
            // Leather body
            Circle()
                .fill(
                    RadialGradient(
                        colors: [PitchAtlasTheme.paper3, PitchAtlasTheme.press, PitchAtlasTheme.void],
                        center: .init(x: 0.38, y: 0.34),
                        startRadius: 2,
                        endRadius: size * 0.62
                    )
                )
                .overlay(
                    Circle().strokeBorder(PitchAtlasTheme.machined, lineWidth: 1)
                )

            // The seam
            SeamShape(rotation: axisAngle)
                .stroke(PitchAtlasTheme.seamBright,
                        style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                .shadow(color: PitchAtlasTheme.seamBright.opacity(0.35), radius: 3)

            // Motion overlay: gyro dot / flutter ring / break arrow.
            MotionCueOverlay(motion: motion, size: size)

            // Finger contacts, numbered, sitting on the seam where the hand grips.
            ForEach(Array(contacts.enumerated()), id: \.offset) { _, contact in
                contactMarker(contact)
                    .position(seamPoint(at: contact.seamT))
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    /// A numbered finger pip: a dark disc so the seam reads under it, a gold ring,
    /// and the finger's number/letter. Scaled to the ball so it works at 110 or 240.
    private func contactMarker(_ contact: SeamAnchoredPoint) -> some View {
        let dot = max(14, size * 0.085)
        return Text(contact.finger.pipLabel)
            .font(PitchAtlasTheme.martian(max(8, size * 0.042)))
            .foregroundStyle(PitchAtlasTheme.cyan)
            .frame(width: dot, height: dot)
            .background(Circle().fill(PitchAtlasTheme.void.opacity(0.82)))
            .overlay(Circle().strokeBorder(PitchAtlasTheme.cyan, lineWidth: 1.5))
            .shadow(color: PitchAtlasTheme.void.opacity(0.6), radius: 2)
    }

    private var accessibilityText: String {
        var parts = ["Seam-informed schematic of the pitch."]
        parts.append(motion.forceLabel)
        if motion.gyro == true {
            parts.append("Gyro-dominant: the spin points toward the catcher.")
        } else if motion.indeterminateBreak == true {
            parts.append("Movement cue: indeterminate flutter, shown without measured inches.")
        } else {
            let vertical = motion.verticalShape?.label ?? "flat"
            let horizontal: String
            switch motion.horizontalDir {
            case .armSide: horizontal = "arm-side"
            case .gloveSide: horizontal = "glove-side"
            case .none: horizontal = "no horizontal cue"
            }
            parts.append("Schematic movement cue: \(vertical), \(horizontal). No measured inches shown.")
        }
        if !contacts.isEmpty {
            let placements = contacts.map { "\($0.label) on the seam" }.joined(separator: ", ")
            parts.append("Finger placement: \(placements).")
        }
        return parts.joined(separator: " ")
    }
}
