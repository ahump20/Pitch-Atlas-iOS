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

/// One camera transform for seam and contacts. Comparison supplies specimen A's
/// contacts to both balls, preserving their geometric relationship.
enum GripStudyOrientation {
    static func quaternion(reference: [SeamAnchoredPoint], view: GripView) -> simd_quatd {
        let lead = reference.filter { $0.finger != .thumb }
        let points = lead.isEmpty ? reference : lead
        let mean = points.reduce(SIMD3<Double>.zero) { $0 + SeamMath.seamPoint($1.seamT * 2 * .pi) }
        var faced = simd_quatd(angle: 0, axis: SIMD3(0, 0, 1))
        if simd_length(mean) > 0.000001 {
            faced = simd_quatd(from: simd_normalize(mean), to: simd_normalize(SIMD3(0, 0.22, 1)))
            faced = simd_quatd(angle: 0.05, axis: SIMD3(0, 0, 1)) * faced
        }
        let angles: SIMD3<Double>
        switch view {
        case .top: angles = SIMD3(-0.08, 0.02, 0.04)
        case .side: angles = SIMD3(-0.2, -0.64, 0.03)
        case .thumb: angles = SIMD3(0.78, 0.16, 0.04)
        }
        return simd_quatd(angle: angles.x, axis: SIMD3(1, 0, 0))
            * simd_quatd(angle: angles.y, axis: SIMD3(0, 1, 0))
            * simd_quatd(angle: angles.z, axis: SIMD3(0, 0, 1)) * faced
    }
}

/// The projected seam outline, rotated in-plane by the spin-axis orientation.
struct SeamShape: Shape {
    /// In-plane spin-axis angle, radians.
    var rotation: Double
    var orientation: GripView = .top
    var hand: Handedness = .right
    var facing: simd_quatd? = nil

    var animatableData: Double {
        get { rotation }
        set { rotation = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) / 2 * 0.92
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        let steps = 480
        var drawing = false
        for i in 0...steps {
            let t = Double(i) / Double(steps) * 2 * .pi
            let p = studyProjection(SeamMath.seamPoint(t), orientation: orientation, facing: facing)
            // rotate the projection in-plane to reflect spin-axis orientation
            let rx = p.x * cos(rotation) - p.y * sin(rotation)
            let ry = p.x * sin(rotation) + p.y * cos(rotation)
            let point = CGPoint(x: c.x + CGFloat(hand == .left ? -rx : rx) * r, y: c.y - CGFloat(ry) * r)
            if p.z >= 0 {
                if drawing { path.addLine(to: point) } else { path.move(to: point) }
                drawing = true
            } else { drawing = false }
        }
        return path
    }
}

/// Herringbone lacing follows the same normalized seam and tangent as the 3D specimen.
/// It is an original visual schematic; spacing is not a measurement of a regulation cover.
private struct SeamLacing: Shape {
    let rotation: Double
    let orientation: GripView
    let hand: Handedness
    let facing: simd_quatd?
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) * 0.46
        func project(_ point: SIMD3<Double>) -> CGPoint {
            let p = studyProjection(simd_normalize(point), orientation: orientation, facing: facing)
            let x = p.x * cos(rotation) - p.y * sin(rotation)
            let y = p.x * sin(rotation) + p.y * cos(rotation)
            return CGPoint(x: rect.midX + CGFloat(hand == .left ? -x : x) * radius,
                           y: rect.midY - CGFloat(y) * radius)
        }
        var path = Path()
        for i in 0..<108 {
            let t = Double(i) / 108 * 2 * .pi
            let p = SeamMath.seamPoint(t)
            guard studyProjection(p, orientation: orientation, facing: facing).z > 0.04 else { continue }
            let tangent = SeamMath.seamTangent(t)
            let across = simd_normalize(simd_cross(p, tangent))
            let tip = p + tangent * 0.018
            let left = p + across * 0.029 - tangent * 0.018
            let right = p - across * 0.029 - tangent * 0.018
            path.move(to: project(left))
            path.addQuadCurve(to: project(tip), control: project(p + across * 0.013 + tangent * 0.013))
            path.addQuadCurve(to: project(right), control: project(p - across * 0.013 + tangent * 0.013))
        }
        return path
    }
}

private struct LeatherPores: View {
    // Fixed low-discrepancy sampling, shared across every specimen. No live noise or idle redraw.
    private static let pores: [CGPoint] = (0..<1300).map { index in
        CGPoint(x: (Double(index) * 0.754877666).truncatingRemainder(dividingBy: 1),
                y: (Double(index) * 0.569840296).truncatingRemainder(dividingBy: 1))
    }
    var body: some View {
        Canvas { context, size in
            let dot = max(0.45, size.width * 0.003)
            for p in Self.pores {
                let rect = CGRect(x: p.x * size.width, y: p.y * size.height, width: dot, height: dot * 0.7)
                context.fill(Path(ellipseIn: rect), with: .color(Color(hex: 0x746F63).opacity(0.12)))
                context.fill(Path(ellipseIn: rect.offsetBy(dx: 0, dy: -0.4)), with: .color(.white.opacity(0.16)))
            }
        }.accessibilityHidden(true).allowsHitTesting(false)
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
    var orientation: GripView = .top
    var hand: Handedness = .right
    var showMovement = true
    var referenceContacts: [SeamAnchoredPoint]? = nil

    private var facing: simd_quatd? {
        guard referenceContacts != nil || !contacts.isEmpty else { return nil }
        return GripStudyOrientation.quaternion(reference: referenceContacts ?? contacts, view: orientation)
    }

    /// In-plane orientation of the spin axis (radians).
    private var axisAngle: Double { facing == nil ? atan2(motion.spinAxis.y, motion.spinAxis.x) : 0 }

    /// Project a seam parameter (0…1 around the figure-eight) to a screen point on
    /// the drawn seam — the SAME closed-form + in-plane rotation SeamShape uses, so
    /// a contact dot always lands exactly on the rendered seam line.
    private func seamPoint(at seamT: Double) -> CGPoint {
        let r = size / 2 * 0.92
        let c = CGPoint(x: size / 2, y: size / 2)
        let p = studyProjection(SeamMath.seamPoint(seamT * 2 * .pi), orientation: orientation, facing: facing)
        let rx = p.x * cos(axisAngle) - p.y * sin(axisAngle)
        let ry = p.x * sin(axisAngle) + p.y * cos(axisAngle)
        return CGPoint(x: c.x + CGFloat(hand == .left ? -rx : rx) * r, y: c.y - CGFloat(ry) * r)
    }

    var body: some View {
        ZStack {
            // Off-white, matte hide. Pores are authored surface texture, never pitch data.
            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0xFCFBF5), Color(hex: 0xF0EFE8), Color(hex: 0xD9D8D1),
                                              Color(hex: 0x9B9C96), Color(hex: 0x575B59)],
                                     center: .init(x: 0.33, y: 0.25), startRadius: 0, endRadius: size * 0.70))
                .overlay { LeatherPores().clipShape(Circle()) }
                .overlay { Circle().strokeBorder(Color.white.opacity(0.28), lineWidth: 0.6) }
                .frame(width: size * 0.92, height: size * 0.92)

            // Only the front hemisphere is drawn; the shared seam runs behind the hide.
            SeamShape(rotation: axisAngle, orientation: orientation, hand: hand, facing: facing)
                .stroke(Color(hex: 0x655B51).opacity(0.7),
                        style: StrokeStyle(lineWidth: max(1, size * 0.010), lineCap: .round, lineJoin: .round))
            SeamShape(rotation: axisAngle, orientation: orientation, hand: hand, facing: facing)
                .stroke(Color(hex: 0xF8F3E8).opacity(0.55),
                        style: StrokeStyle(lineWidth: max(0.5, size * 0.0035), lineCap: .round))
                .offset(y: max(0.45, size * 0.003))
            SeamLacing(rotation: axisAngle, orientation: orientation, hand: hand, facing: facing)
                .stroke(Color(hex: 0x573831).opacity(0.6),
                        style: StrokeStyle(lineWidth: max(1, size * 0.0085), lineCap: .round, lineJoin: .round))
            SeamLacing(rotation: axisAngle, orientation: orientation, hand: hand, facing: facing)
                .stroke(Color(hex: 0x9E2B35),
                        style: StrokeStyle(lineWidth: max(0.65, size * 0.0058), lineCap: .round, lineJoin: .round))
            SeamLacing(rotation: axisAngle, orientation: orientation, hand: hand, facing: facing)
                .stroke(Color(hex: 0xD88269).opacity(0.6),
                        style: StrokeStyle(lineWidth: max(0.25, size * 0.0018), lineCap: .round))
                .offset(y: -0.3)

            // Motion overlay: gyro dot / flutter ring / break arrow.
            if showMovement { MotionCueOverlay(motion: motion, size: size) }

            // Finger contacts, numbered, sitting on the seam where the hand grips.
            ForEach(contacts, id: \.self) { contact in
                if studyProjection(SeamMath.seamPoint(contact.seamT * 2 * .pi), orientation: orientation, facing: facing).z >= 0 {
                    contactMarker(contact).position(seamPoint(at: contact.seamT))
                }
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

/// Orthographic camera changes applied identically to seams and finger markers.
private func studyProjection(_ point: SIMD3<Double>, orientation: GripView, facing: simd_quatd? = nil) -> SIMD3<Double> {
    if let facing { return facing.act(point) }
    let projected: SIMD3<Double>
    switch orientation {
    case .top: projected = point
    case .side: projected = SIMD3(point.z, point.y, -point.x)
    case .thumb: projected = SIMD3(point.x, point.z, -point.y)
    }
    return projected
}
