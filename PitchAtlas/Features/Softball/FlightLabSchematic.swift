import SwiftUI

// =============================================================================
// FlightLabSchematic — the Flight Lab, drawn flat
// =============================================================================
// Web: components/flightlab/FlightLabSchematic.tsx, line for line. A side view
// of the zone, the batter's landmarks, an inch ruler, the selected lob's fall,
// where it crosses the plate, where the barrel meets it, and the landing window
// to look for. Every coordinate comes from the same Slowpitch solver the words
// read, so the drawing cannot disagree with them. It lays itself out in real
// points, so its tags stay at 12 and the ruler's numbers at 14 at any width.
// The pitcher is to the right, the catcher to the left, height is up. The app
// has no 3D stage yet, so this is the stage, as it is on the site without WebGL.
// =============================================================================

struct FlightLabSchematic: View {
    let model: FlightLabModel
    /// The throw in the air: elapsed flight time and the lobs thrown, or nil when idle.
    var thrown: (t: Double, indices: [Int])? = nil
    /// Room the page's own overlays take at the top and bottom, points.
    var insetTop: CGFloat = 0
    var insetBottom: CGFloat = 0

    private static func mono(_ size: CGFloat) -> Font {
        .custom(PitchAtlasType.Face.martian400.postScriptName, fixedSize: size)
    }

    var body: some View {
        Canvas { context, size in draw(in: &context, size: size) }
            .accessibilityElement()
            .accessibilityLabel(FlightLabReads.stageLabel(model))
            .accessibilityAddTraits(.isImage)
    }

    // swiftlint:disable:next function_body_length
    private func draw(in ctx: inout GraphicsContext, size: CGSize) {
        let W = Double(size.width), H = Double(size.height)
        let narrow = W < 560
        let sel = model.selected
        let flight = sel.flight
        let reading = sel.reading
        let zone = model.zone, marks = model.marks
        let senior = model.rule == .senior
        let contact = reading.contact.contact
        let R = Slowpitch.BALL_RADIUS
        let plate = Slowpitch.PLATE, mat = Slowpitch.MAT
        let bone = PitchAtlasTheme.bone, amber = FlightLabInk.amber

        // The window of the field to draw, metres: depth z (catcher left) and height.
        let zNear = SlowpitchJS.min(2.4, SlowpitchJS.max(SlowpitchJS.max(plate.back + 0.55, (model.hotZ?.1 ?? 0) + 0.2), senior ? mat.length + 0.3 : 0))
        let zFar = SlowpitchJS.min(SlowpitchJS.min(-1.25, (contact?.z ?? -0.8) - 0.45), (model.hotZ?.0 ?? 0) - 0.25)
        let yTop = SlowpitchJS.max(zone.top + 0.3, (contact?.y ?? 0) + 0.22)

        let rulerW = 52.0, padL = rulerW + 4, padR = 18.0
        let padT = Double(insetTop) + 18, padB = Double(insetBottom) + 66
        let s = SlowpitchJS.max(10, SlowpitchJS.min((W - padL - padR) / (zNear - zFar), (H - padT - padB) / yTop))
        let plotW = (zNear - zFar) * s
        let x0 = padL + SlowpitchJS.max(0, (W - padL - padR - plotW) / 2)
        let spare = SlowpitchJS.max(0, H - padT - padB - yTop * s)
        let groundY = H - padB - spare / 2
        func X(_ z: Double) -> Double { x0 + (zNear - z) * s }
        func Y(_ y: Double) -> Double { groundY - y * s }
        let xMin = X(zNear), xMax = X(zFar)
        func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
        func line(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double, _ color: Color, width: Double = 1, dash: [CGFloat] = []) {
            var path = Path()
            path.move(to: p(x1, y1))
            path.addLine(to: p(x2, y2))
            ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, dash: dash))
        }
        func rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> CGRect { CGRect(x: x, y: y, width: w, height: h) }

        // ground
        let ground = rect(0, groundY, W, SlowpitchJS.max(0, H - groundY))
        ctx.fill(Path(ground), with: .linearGradient(Gradient(colors: [FlightLabInk.groundTop, FlightLabInk.groundBottom]),
                                                      startPoint: p(0, groundY), endPoint: p(0, H)))
        line(0, groundY, W, groundY, bone.opacity(0.25))

        // landmark lines across the view
        if !senior {
            line(xMin, Y(zone.top), xMax, Y(zone.top), bone.opacity(0.45))
            line(xMin, Y(zone.bottom), xMax, Y(zone.bottom), bone.opacity(0.45))
        }
        line(xMin, Y(marks.chest), xMax, Y(marks.chest), amber.opacity(0.5))
        line(xMin, Y(marks.belt), xMax, Y(marks.belt), amber.opacity(0.5))

        // the zone over the plate, and the ball's-edge margin
        if !senior {
            let box = Path(rect(X(plate.back), Y(zone.top), (plate.back - plate.front) * s, (zone.top - zone.bottom) * s))
            ctx.fill(box, with: .color(bone.opacity(0.09)))
            ctx.stroke(box, with: .color(bone.opacity(0.7)), lineWidth: 1)
            let edge = Path(rect(X(plate.back + R), Y(zone.top + R), (plate.back - plate.front + 2 * R) * s, (zone.top - zone.bottom + 2 * R) * s))
            ctx.stroke(edge, with: .color(bone.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        }

        // the barrel's sweet band, belt to chest, where it meets the ball
        if let contact {
            let band = Path(rect(X(contact.z) - 4, Y(marks.chest), 8, (marks.chest - marks.belt) * s))
            ctx.fill(band, with: .color(amber.opacity(0.28)))
            ctx.stroke(band, with: .color(amber.opacity(0.8)), lineWidth: 1)
        }

        // plate and mat on the ground
        if senior { ctx.fill(Path(rect(X(mat.length), groundY - 3, mat.length * s, 4)), with: .color(FlightLabInk.mat)) }
        ctx.fill(Path(rect(X(plate.back), groundY - 3, (plate.back - plate.front) * s, 4)), with: .color(bone))

        // the strike lane (hatched) and the look-for window, on the ground
        if let lane = model.laneZ {
            let left = SlowpitchJS.max(xMin, X(lane.1))
            let r = rect(left, groundY + 8, SlowpitchJS.max(2, SlowpitchJS.min(xMax, X(lane.0)) - left), 7)
            ctx.fill(Path(r), with: .color(bone.opacity(0.10)))
            var hatch = ctx
            hatch.clip(to: Path(r))
            var stripes = Path()
            var hx = r.minX - r.height
            while hx < r.maxX + r.height {
                stripes.move(to: CGPoint(x: hx, y: r.maxY))
                stripes.addLine(to: CGPoint(x: hx + r.height, y: r.minY))
                hx += 8 / 2.squareRoot()
            }
            hatch.stroke(stripes, with: .color(bone.opacity(0.55)), lineWidth: 2)
        }
        if let hotZ = model.hotZ {
            let left = SlowpitchJS.max(xMin, X(hotZ.1))
            ctx.fill(Path(rect(left, groundY + 18, SlowpitchJS.max(2, SlowpitchJS.min(xMax, X(hotZ.0)) - left), 7)),
                     with: .color(amber.opacity(0.75)))
        }

        // the lob, and any thrown balls with their trails, clipped to the window
        func polyline(_ f: SlowpitchFlight, through last: Int) -> Path {
            var path = Path()
            var started = false
            for i in 0...Swift.min(last, f.count - 1) {
                let z = Double(f.positions[i * 3 + 2])
                if z < zFar - 2 || z > zNear + 0.5 { continue }
                let pt = p(X(z), Y(Double(f.positions[i * 3 + 1])))
                if started { path.addLine(to: pt) } else { path.move(to: pt); started = true }
            }
            return path
        }
        let thrownLobs = (thrown?.indices ?? []).compactMap { model.lobs.indices.contains($0) ? model.lobs[$0] : nil }
        var clipped = ctx
        clipped.clip(to: Path(rect(xMin, 0, SlowpitchJS.max(0, xMax - xMin), SlowpitchJS.max(0, groundY + 2))))
        clipped.stroke(polyline(flight, through: flight.count - 1),
                       with: .color(FlightLabInk.lob(sel.color).opacity(thrownLobs.isEmpty ? 0.95 : 0.3)),
                       style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        if let thrown {
            for lob in thrownLobs {
                let t = SlowpitchJS.min(thrown.t, lob.flight.duration)
                let at = Slowpitch.positionAt(lob.flight, t)
                let prog = Slowpitch.progressAt(lob.flight, t)
                let n = Swift.max(2, Int((prog * Double(lob.flight.count - 1)).rounded(.down)))
                clipped.stroke(polyline(lob.flight, through: n), with: .color(FlightLabInk.lob(lob.color)),
                               style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                let r = SlowpitchJS.max(4, R * s)
                let ball = Path(ellipseIn: rect(X(at.z) - r, Y(at.y) - r, 2 * r, 2 * r))
                clipped.fill(ball, with: .color(FlightLabInk.ball))
                clipped.stroke(ball, with: .color(FlightLabInk.ballEdge.opacity(0.4)), lineWidth: 1)
            }
        }

        // marks: over the plate, and the barrel
        let crossing = flight.land.z > 0 ? flight.crossing : nil
        if let crossing {
            ctx.stroke(Path(ellipseIn: rect(X(0) - 9, Y(crossing.y) - 9, 18, 18)), with: .color(bone), lineWidth: 2)
        }
        if let contact {
            ctx.stroke(Path(ellipseIn: rect(X(contact.z) - 13, Y(contact.y) - 13, 26, 26)), with: .color(amber), lineWidth: 3)
            ctx.fill(Path(ellipseIn: rect(X(contact.z) - 3.5, Y(contact.y) - 3.5, 7, 7)), with: .color(amber))
        }

        // ruler: every inch, long ticks at 6
        let inch = Slowpitch.IN
        let rulerTop = SlowpitchJS.min(yTop, zone.top + 0.12)
        ctx.fill(Path(rect(0, Y(rulerTop) - 6, rulerW, SlowpitchJS.max(0, groundY - Y(rulerTop) + 6))),
                 with: .color(FlightLabInk.stage.opacity(0.55)))
        line(rulerW, Y(rulerTop), rulerW, groundY, bone.opacity(0.9), width: 1.5)
        var i = 0
        while Double(i) * inch <= rulerTop + 1e-6 {
            let len: Double = i % 6 == 0 ? 16 : i % 3 == 0 ? 10 : 5
            let ty = Y(Double(i) * inch)
            line(rulerW - len, ty, rulerW, ty, bone.opacity(0.85), width: len >= 16 ? 1.5 : 1)
            if i % 6 == 0 && i > 0 {
                ctx.draw(Text(String(i)).font(Self.mono(14)).foregroundStyle(bone), at: p(rulerW - 20, ty), anchor: .trailing)
            }
            i += 1
        }

        // tags
        func tagWidth(_ text: String) -> Double {
            Double(ctx.resolve(tagText(text, bone)).measure(in: CGSize(width: 2000, height: 40)).width) + 14
        }
        func tag(_ x: Double, _ y: Double, _ text: String, anchor: HorizontalAlignment = .leading, color: Color = bone) {
            let w = tagWidth(text)
            let left = anchor == .leading ? x : anchor == .center ? x - w / 2 : x - w
            let box = Path(roundedRect: rect(left, y - 12 * 0.95, w, 12 * 1.9), cornerRadius: 2)
            ctx.fill(box, with: .color(FlightLabInk.panel))
            ctx.stroke(box, with: .color(color.opacity(0.35)), lineWidth: 1)
            ctx.draw(tagText(text, color), at: p(left + 7, y), anchor: .leading)
        }
        for t in FlightLabReads.landmarkTags(model, narrow: narrow) {
            tag(x0 + 6, Y(t.y), t.text, color: t.amber ? amber : bone)
        }
        if let crossing, let text = FlightLabReads.crossingText(model, narrow: narrow) {
            tag(SlowpitchJS.min(X(0) + 16, W - tagWidth(text) - 6), SlowpitchJS.min(Y(crossing.y) + 22, groundY - 14), text)
        }
        if let contact, let text = FlightLabReads.barrelText(model, narrow: narrow) {
            let w = tagWidth(text)
            tag(SlowpitchJS.min(W - 6 - w / 2, SlowpitchJS.max(x0 + 6 + w / 2, X(contact.z))), SlowpitchJS.max(padT + 8, Y(contact.y) - 32),
                text, anchor: .center, color: amber)
        }
        let strike = FlightLabReads.strikeLine(model)
        if let strike {
            ctx.draw(Text(strike).font(Self.mono(12)).foregroundStyle(bone.opacity(0.55)), at: p(x0 + 6, groundY + 34), anchor: .topLeading)
        }
        if let pitch = FlightLabReads.pitchLine(model) {
            ctx.draw(Text(pitch).font(Self.mono(12)).foregroundStyle(amber), at: p(x0 + 6, groundY + (strike == nil ? 34 : 50)),
                     anchor: .topLeading)
        }
    }

    private func tagText(_ text: String, _ color: Color) -> Text {
        Text(text.uppercased()).font(Self.mono(12)).tracking(0.48).foregroundStyle(color)
    }
}
