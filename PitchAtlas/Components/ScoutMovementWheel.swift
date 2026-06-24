import SwiftUI

// =============================================================================
// ScoutMovementWheel - native return-wave shell
// =============================================================================
// Direction-only movement card for the scout back. It mirrors the web wheel's
// contract: real PitchMotion enums in, no velocity, spin-rate, or break-inches
// numbers out.
// =============================================================================

struct ScoutMovementWheel: View {
    let motion: PitchMotion?
    var accent: Color = PitchAtlasTheme.cyan
    var size: CGFloat = 112

    var body: some View {
        VStack(spacing: PitchAtlasSpacing.xs) {
            ZStack {
                wheelBase

                if let motion {
                    movementVector(for: motion)
                    spinAxisGuide(for: motion)
                } else {
                    emptyMark
                }
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)

            VStack(spacing: 2) {
                Text(directionLabel.uppercased())
                    .font(PitchAtlasTheme.martian(9))
                    .tracking(1.4)
                    .foregroundStyle(motion == nil ? PitchAtlasTheme.ink3 : accent)
                Text(subtitle.uppercased())
                    .font(PitchAtlasTheme.martian(7))
                    .tracking(1.2)
                    .foregroundStyle(PitchAtlasTheme.ink3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var wheelBase: some View {
        ZStack {
            ForEach([1.0, 0.66, 0.33], id: \.self) { scale in
                Circle()
                    .stroke(PitchAtlasTheme.machined, lineWidth: 1)
                    .frame(width: size * scale, height: size * scale)
            }
            Path { path in
                path.move(to: CGPoint(x: size / 2, y: 8))
                path.addLine(to: CGPoint(x: size / 2, y: size - 8))
                path.move(to: CGPoint(x: 8, y: size / 2))
                path.addLine(to: CGPoint(x: size - 8, y: size / 2))
            }
            .stroke(PitchAtlasTheme.machined.opacity(0.65), style: StrokeStyle(lineWidth: 1, dash: [4, 7]))
        }
    }

    private var emptyMark: some View {
        Circle()
            .stroke(PitchAtlasTheme.ink3.opacity(0.55), style: StrokeStyle(lineWidth: 1, dash: [5, 6]))
            .frame(width: size * 0.42, height: size * 0.42)
    }

    private func movementVector(for motion: PitchMotion) -> some View {
        let endpoint = point(for: motion)
        return Path { path in
            path.move(to: center)
            path.addLine(to: endpoint)
        }
        .stroke(accent, style: StrokeStyle(lineWidth: 2.25, lineCap: .round, lineJoin: .round))
        .overlay(alignment: .center) {
            Circle()
                .fill(accent)
                .frame(width: 6, height: 6)
                .offset(x: endpoint.x - center.x, y: endpoint.y - center.y)
        }
    }

    private func spinAxisGuide(for motion: PitchMotion) -> some View {
        let angle = atan2(motion.spinAxis.y, motion.spinAxis.x)
        let radius = size * 0.36
        let a = CGPoint(x: center.x - cos(angle) * radius, y: center.y - sin(angle) * radius)
        let b = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)

        return Path { path in
            path.move(to: a)
            path.addLine(to: b)
        }
        .stroke(accent.opacity(0.45), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [3, 4]))
    }

    private var center: CGPoint { CGPoint(x: size / 2, y: size / 2) }

    private func point(for motion: PitchMotion) -> CGPoint {
        if motion.gyro == true {
            return CGPoint(x: center.x, y: center.y - size * 0.10)
        }

        let x: CGFloat
        switch motion.horizontalDir {
        case .armSide: x = 0.30
        case .gloveSide: x = -0.30
        case .none: x = 0
        }

        let y: CGFloat
        switch motion.verticalShape ?? .flat {
        case .ride: y = -0.40
        case .drop: y = 0.40
        case .flat: y = 0
        }

        return CGPoint(x: center.x + x * size, y: center.y + y * size)
    }

    private var directionLabel: String {
        guard let motion else { return "Motion not filed" }
        if motion.gyro == true { return "Gyro" }

        let vertical = motion.verticalShape?.label ?? "flat"
        let horizontal: String
        switch motion.horizontalDir {
        case .armSide: horizontal = "arm-side"
        case .gloveSide: horizontal = "glove-side"
        case .none: horizontal = ""
        }
        return [vertical, horizontal].filter { !$0.isEmpty }.joined(separator: " / ")
    }

    private var subtitle: String {
        guard let motion else { return "source gap - no estimate" }
        return "\(motion.forceLabel) - direction only"
    }

    private var accessibilityLabel: String {
        guard motion != nil else {
            return "Movement wheel. Motion not filed. Source gap. No estimate shown."
        }
        return "Movement wheel. \(directionLabel). \(subtitle). No velocity, spin rate, or break inches shown."
    }
}
