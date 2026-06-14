import SwiftUI

// =============================================================================
// SeamBall: the native specimen
// =============================================================================
// Draws the baseball seam from the SAME closed-form figure-eight the web ships
// (x = 2 sin t + sin 3t ; y = 2 cos t − cos 3t ; z = 2√2 cos 2t), normalized to
// the ball, then projected to the catcher's eye. The spin axis orients the seam;
// the break arrow is a schematic cue from sourced shape language, never a fake
// measured break value.
// Labeled a seam-informed schematic, because that is what it is.
//
// This is the bundled Reduce Motion specimen and the pitch-detail ball surface.
// =============================================================================

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
            let x = 2 * sin(t) + sin(3 * t)
            let y = 2 * cos(t) - cos(3 * t)
            let z = 2 * 2.0.squareRoot() * cos(2 * t)
            let len = (x * x + y * y + z * z).squareRoot()
            let nx = x / len
            let ny = y / len
            // rotate the projection in-plane to reflect spin-axis orientation
            let rx = nx * cos(rotation) - ny * sin(rotation)
            let ry = nx * sin(rotation) + ny * cos(rotation)
            let p = CGPoint(x: c.x + CGFloat(rx) * r, y: c.y - CGFloat(ry) * r)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
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
        let t = seamT * 2 * .pi
        let x = 2 * sin(t) + sin(3 * t)
        let y = 2 * cos(t) - cos(3 * t)
        let z = 2 * 2.0.squareRoot() * cos(2 * t)
        let len = (x * x + y * y + z * z).squareRoot()
        let nx = x / len
        let ny = y / len
        let rx = nx * cos(axisAngle) - ny * sin(axisAngle)
        let ry = nx * sin(axisAngle) + ny * cos(axisAngle)
        return CGPoint(x: c.x + CGFloat(rx) * r, y: c.y - CGFloat(ry) * r)
    }

    private func fingerInitial(_ finger: Finger) -> String {
        switch finger {
        case .index: return "1"
        case .middle: return "2"
        case .ring: return "3"
        case .pinky: return "4"
        case .thumb: return "T"
        }
    }

    /// Catcher's-eye movement direction. Prefer measured values if an older bundle
    /// carries them; otherwise use the current qualitative shape fields.
    private var breakVector: (horizontal: Double, vertical: Double) {
        let direction: Double
        switch motion.horizontalDir {
        case .armSide: direction = 1
        case .gloveSide: direction = -1
        case .none: direction = 0
        }

        if let ivb = motion.ivbInches, let horizontal = motion.horizontalInches {
            return (direction * max(horizontal, 0.001), ivb)
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
        if let ivb = motion.ivbInches, let horizontal = motion.horizontalInches {
            let mag = (ivb * ivb + horizontal * horizontal).squareRoot()
            return CGFloat(min(max(mag / 24.0, 0.15), 0.85))
        }

        let vector = breakVector
        let mag = (vector.vertical * vector.vertical + vector.horizontal * vector.horizontal).squareRoot()
        return CGFloat(min(max(mag / 1.4, 0.25), 0.65))
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

            // Motion overlay: gyro shows a dot toward the viewer; others show a break arrow.
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
        return Text(fingerInitial(contact.finger))
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
