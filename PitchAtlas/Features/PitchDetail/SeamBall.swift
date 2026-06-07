import SwiftUI

// =============================================================================
// SeamBall — the native specimen
// =============================================================================
// Draws the baseball seam from the SAME closed-form figure-eight the web ships
// (x = 2 sin t + sin 3t ; y = 2 cos t − cos 3t ; z = 2√2 cos 2t), normalized to
// the ball, then projected to the catcher's eye. The spin axis orients the seam;
// the break arrow is derived from the sourced motion (never stored, never faked).
// Labeled a seam-informed schematic, because that is what it is.
//
// This is the offline / Reduce-Motion specimen and the target the WebView island
// dissolves into — same math, so the two can never disagree.
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

    /// In-plane orientation of the spin axis (radians).
    private var axisAngle: Double { atan2(motion.spinAxis.y, motion.spinAxis.x) }

    /// Catcher's-eye break direction. Vertical from IVB, horizontal from the dir.
    private var breakAngle: Double {
        let horiz: Double
        switch motion.horizontalDir {
        case .armSide: horiz = 1
        case .gloveSide: horiz = -1
        case .none: horiz = 0
        }
        let vert = motion.ivbInches  // + rides above, − drops
        return atan2(vert, horiz * max(motion.horizontalInches, 0.001))
    }

    private var breakMagnitude: CGFloat {
        let mag = (motion.ivbInches * motion.ivbInches
                   + motion.horizontalInches * motion.horizontalInches).squareRoot()
        // normalize against a generous 24" envelope, clamp to the ball
        return CGFloat(min(max(mag / 24.0, 0.15), 0.85))
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
            } else {
                BreakArrow(angle: breakAngle, magnitude: breakMagnitude,
                           color: PitchAtlasTheme.cyan, radius: size / 2)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = ["Seam-informed schematic of the pitch."]
        parts.append(motion.forceLabel)
        if motion.gyro == true {
            parts.append("Gyro-dominant: the spin points toward the catcher.")
        } else {
            let v = motion.ivbInches >= 0 ? "rides" : "drops"
            parts.append("Induced vertical break \(v) \(abs(Int(motion.ivbInches.rounded()))) inches; horizontal \(Int(motion.horizontalInches.rounded())) inches \(motion.horizontalDir == .armSide ? "arm-side" : motion.horizontalDir == .gloveSide ? "glove-side" : "")")
        }
        return parts.joined(separator: " ")
    }
}
