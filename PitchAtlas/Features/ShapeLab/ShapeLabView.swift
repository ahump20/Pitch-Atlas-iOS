import SwiftUI

// =============================================================================
// ShapeLabView — turn spin into shape
// =============================================================================
// Web: pages/SandboxPage.tsx at the site's phone width, in its order: the hero,
// the stock tilts and the spin-tilt slider beside its dial, the ball from the side
// and the shape plot from the pitcher's eye, the two shape reads and the note, a
// grip to study, then the teaching-model line. No rpm, no speed, no inches: the
// one input is the clock, the one output is a shape word. There is no hand
// toggle; 3:00 is arm side and lands on the right, a right-hander's view from the
// mound, and the words say so.
// =============================================================================

struct ShapeLabView: View {
    @Environment(PitchStore.self) private var store
    @State private var tilt: Int
    @State private var referenceSlug: String?

    init(tilt: Int = 0, pitch: String? = nil) {
        _tilt = State(initialValue: tilt)
        _referenceSlug = State(initialValue: pitch)
    }

    private var result: ShapeBreak { ShapeLab.buildBreak(tiltDegrees: tilt) }
    private var reference: PitchAtlasEntry? { ShapeLab.reference(referenceSlug, store: store) }

    var body: some View {
        ZStack {
            FieldBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHero(eyebrow: "The lab",
                                title: Text("Turn spin into shape."),
                                sub: Text(ShapeLab.heroSub),
                                trail: [Crumb(label: "The Atlas", path: "home"), Crumb(label: "Shape Lab")])
                    VStack(alignment: .leading, spacing: 40) {
                        controls
                        figures
                        referencePanel
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 64)
                    teaching
                        .padding(.horizontal, 20)
                        .padding(.bottom, 80)
                    SiteFooter(path: "/sandbox")
                }
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                .emitsScrollProgress()
            }
        }
        .navigationTitle("Shape Lab")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { BrandLockup(size: .sm) }
        }
    }

    // MARK: The controls

    private var controls: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionKick(text: "Stock tilts")
            FlowRow(spacing: 8, lineSpacing: 0) {
                ForEach(ShapeLab.presets, id: \.self) { preset in
                    PitchChip(label: preset.label, selected: preset.tilt == tilt) {
                        tilt = preset.tilt
                        Haptics.selection()
                    }
                }
            }
            .padding(.top, 12)
            Text(ShapeLab.presetNote)
                .font(PitchAtlasType.font(.hanken400, size: 12, relativeTo: .caption))
                .foregroundStyle(PitchAtlasTheme.ink2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            HStack(alignment: .bottom, spacing: 16) {
                slider
                TiltDial(tilt: tilt)
                    .frame(width: 80, height: 80)
                    .accessibilityHidden(true)
            }
            .padding(.top, 32)
        }
    }

    private var slider: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                monoLabel("Spin tilt")
                Spacer(minLength: 12)
                Text(result.clock)
                    .font(PitchAtlasType.font(.martian400, size: 14, relativeTo: .subheadline))
                    .monospacedDigit()
                    .foregroundStyle(PitchAtlasTheme.bone)
            }
            .accessibilityHidden(true)
            Slider(value: Binding(get: { Double(tilt) }, set: { tilt = Int($0.rounded()) }),
                   in: Double(ShapeLab.tiltRange.lowerBound)...Double(ShapeLab.tiltRange.upperBound),
                   step: Double(ShapeLab.tiltStep))
                .tint(PitchAtlasTheme.cyan)
                .frame(minHeight: 44)
                .padding(.top, 8)
                .accessibilityLabel("Spin tilt")
                .accessibilityValue(ShapeLab.spokenTilt(tilt))
            Text(ShapeLab.tiltHint)
                .font(PitchAtlasType.font(.hanken400, size: 12, relativeTo: .caption))
                .foregroundStyle(PitchAtlasTheme.ink2)
                .cssLineHeight(1.375, face: .hanken400, size: 12, relativeTo: .caption)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: The figures, the reads, the note

    private var figures: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 8) {
                AxisBall(result: result)
                    .frame(width: 160, height: 160)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(ShapeLab.ballLabel(tilt))
                    .accessibilityAddTraits(.isImage)
                Text(ShapeLab.ballCaption.uppercased())
                    .font(PitchAtlasType.font(.martian400, size: 11, relativeTo: .caption2))
                    .tracking(em: 0.18, size: 11)
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background {
                ZStack {
                    SiteKitInk.stage
                    RadialGradient(colors: [ShapeLabInk.stageSpot, .clear], center: UnitPoint(x: 0.5, y: 0.4),
                                   startRadius: 0, endRadius: 200 * 0.6)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 2))
            VStack(spacing: 4) {
                ShapePlotView(result: result)
                    .aspectRatio(ShapePlot.width / ShapePlot.height, contentMode: .fit)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(ShapePlot.label(result, pitchName: "custom pitch"))
                    .accessibilityAddTraits(.isImage)
                monoLabel(ShapeLab.plotCaption).accessibilityHidden(true)
            }
            .padding(12)
            .background { PanelSurface() }
            VStack(spacing: 8) {
                stat("Vertical shape", value: result.verticalShape.rawValue, sub: "ride, drop, or flat")
                stat("Side shape", value: result.horizontalDir.rawValue, sub: "arm-side, glove-side, or true")
            }
            Text(result.shapeNote)
                .font(PitchAtlasType.font(.hanken400, size: 16, relativeTo: .body))
                .foregroundStyle(PitchAtlasTheme.bone)
                .cssLineHeight(1.625, face: .hanken400, size: 16, relativeTo: .body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// SandboxPage's Stat: a panel with the label, the word in athletic capitals, the range.
    private func stat(_ label: String, value: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            monoLabel(label)
            Text(value.uppercased())
                .font(PitchAtlasType.font(.anton400, size: 24, relativeTo: .title2))
                .foregroundStyle(PitchAtlasTheme.bone)
            Text(sub)
                .font(PitchAtlasType.font(.hanken400, size: 12, relativeTo: .caption))
                .foregroundStyle(PitchAtlasTheme.ink2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background { PanelSurface() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value). \(sub)")
    }

    // MARK: A grip to study

    private var referencePanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionKick(text: "A grip to study")
            monoLabel("Pitch reference").padding(.top, 16).accessibilityHidden(true)
            Menu {
                Button("Choose a filed pitch") { referenceSlug = nil }
                ForEach(store.pitches) { entry in
                    Button { referenceSlug = entry.slug } label: {
                        if entry.slug == reference?.slug {
                            Label(entry.display.shortName, systemImage: "checkmark")
                        } else {
                            Text(entry.display.shortName)
                        }
                    }
                }
            } label: {
                HStack {
                    Text(reference?.display.shortName ?? "Choose a filed pitch")
                        .font(PitchAtlasType.font(.martian400, size: 13, relativeTo: .footnote))
                        .foregroundStyle(PitchAtlasTheme.bone)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(PitchAtlasTheme.ink2)
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 10).fill(SiteKitInk.card))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(PitchAtlasTheme.cyan.opacity(0.4), lineWidth: 1))
                .contentShape(Rectangle())
            }
            .padding(.top, 8)
            .accessibilityLabel("Pitch reference")
            .accessibilityValue(reference?.display.shortName ?? "Choose a filed pitch")
            .accessibilityHint(ShapeLab.referenceNote)
            Text(ShapeLab.referenceNote)
                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.ink2)
                .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
            if let reference {
                VStack(alignment: .leading, spacing: 16) {
                    RefractorClaimView(claim: reference.canonical.grip)
                    FlowRow(spacing: 12, lineSpacing: 12) {
                        NavigationLink { PitchDetailView(entry: reference, opensAt: .grip) } label: {
                            Text("Inspect grip")
                        }
                        .buttonStyle(ArchiveActionStyle())
                        CompareButton(slug: reference.slug)
                    }
                }
                .padding(.top, 20)
            }
        }
        .padding(20)
        .background { PanelSurface() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("A grip to study")
    }

    // MARK: The honest line

    private var teaching: some View {
        VStack(alignment: .leading, spacing: 8) {
            EggButton(note: .stitches) { monoLabel("Teaching model", ink: PitchAtlasTheme.bone2) }
            Text(ShapeLab.anchorNote)
            Text(ShapeLab.sideNote)
        }
        .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
        .foregroundStyle(PitchAtlasTheme.ink2)
        .lineSpacing(14 * 0.625 - 4)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background { PanelSurface() }
        .overlay(alignment: .leading) { PitchAtlasTheme.bone.opacity(0.15).frame(width: 2) }
    }

    /// `.mono-label`: mono 11, tracked .18em, capitals, ink-2.
    private func monoLabel(_ text: String, ink: Color = PitchAtlasTheme.ink2) -> some View {
        Text(text.uppercased())
            .font(PitchAtlasType.font(.martian400, size: 11, relativeTo: .caption2))
            .tracking(em: 0.18, size: 11)
            .foregroundStyle(ink)
    }
}

// MARK: - The figures

/// SandboxPage's TiltDial: a small compass that turns the tilt into a direction.
private struct TiltDial: View {
    let tilt: Int

    var body: some View {
        Canvas { context, size in
            let k = size.width / 80
            let c = CGPoint(x: 40 * k, y: 40 * k)
            let r = 30 * k
            let rad = Double(tilt) * .pi / 180
            context.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)),
                           with: .color(PitchAtlasTheme.navyLine), lineWidth: 1)
            for (angle, label) in [(0.0, "12"), (90.0, "3"), (180.0, "6"), (270.0, "9")] {
                let a = angle * .pi / 180
                let at = CGPoint(x: c.x + sin(a) * (r + 8 * k), y: c.y - cos(a) * (r + 8 * k))
                context.draw(Text(label).font(PitchAtlasType.font(.martian400, size: 7 * k, relativeTo: .caption2))
                                .foregroundStyle(PitchAtlasTheme.ink3), at: at)
            }
            let end = CGPoint(x: c.x + sin(rad) * r, y: c.y - cos(rad) * r)
            context.fill(Path(ellipseIn: CGRect(x: c.x - 2.5 * k, y: c.y - 2.5 * k, width: 5 * k, height: 5 * k)),
                         with: .color(PitchAtlasTheme.navyLine))
            var hand = Path()
            hand.move(to: c)
            hand.addLine(to: end)
            context.stroke(hand, with: .color(PitchAtlasTheme.seamBright),
                           style: StrokeStyle(lineWidth: 2 * k, lineCap: .round))
            context.fill(Path(ellipseIn: CGRect(x: end.x - 3 * k, y: end.y - 3 * k, width: 6 * k, height: 6 * k)),
                         with: .color(PitchAtlasTheme.seamBright))
        }
    }
}

/// The seam ball turned to the tilt, with the spin axis dashed through it.
private struct AxisBall: View {
    let result: ShapeBreak

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let angle = atan2(result.spinAxis.y, result.spinAxis.x)
            ZStack {
                SeamBall(motion: result.motion, size: side, showMovement: false)
                Path { path in
                    let c = CGPoint(x: side / 2, y: side / 2)
                    let reach = side / 2
                    path.move(to: CGPoint(x: c.x - cos(angle) * reach, y: c.y + sin(angle) * reach))
                    path.addLine(to: CGPoint(x: c.x + cos(angle) * reach, y: c.y - sin(angle) * reach))
                }
                .stroke(PitchAtlasTheme.bone2.opacity(0.8), style: StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// MovementPlot.tsx in its 360 × 240 frame: the axis guides, the pole words, the
/// spinless ball at the center, and the pitch offset toward the way it breaks.
private struct ShapePlotView: View {
    let result: ShapeBreak

    var body: some View {
        GeometryReader { geo in
            let k = geo.size.width / ShapePlot.width
            let c = ShapePlot.center
            let offset = ShapePlot.offset(result)
            let ball = CGPoint(x: (c.x + offset.dx) * k, y: (c.y + offset.dy) * k)
            let r = ShapePlot.ballRadius * k
            ZStack(alignment: .topLeading) {
                Canvas { context, _ in
                    func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * k, y: y * k) }
                    let span = ShapePlot.clamp + 14
                    var guides = Path()
                    guides.move(to: at(c.x, c.y - span)); guides.addLine(to: at(c.x, c.y + span))
                    guides.move(to: at(c.x - span, c.y)); guides.addLine(to: at(c.x + span, c.y))
                    context.stroke(guides, with: .color(PitchAtlasTheme.ink3), lineWidth: 1)
                    func pole(_ word: String, _ x: CGFloat, _ y: CGFloat) {
                        context.draw(Text(word).font(PitchAtlasType.font(.martian400, size: 8 * k, relativeTo: .caption2))
                                        .tracking(1.5 * k).foregroundStyle(PitchAtlasTheme.ink2),
                                     at: at(x, y), anchor: .bottom)
                    }
                    pole("RIDE", c.x, c.y - ShapePlot.clamp - 20 + 3)
                    pole("DROP", c.x, c.y + ShapePlot.clamp + 28 + 3)
                    pole("GLOVE", c.x - ShapePlot.clamp - 18, c.y - 6 + 3)
                    pole("ARM", c.x + ShapePlot.clamp + 18, c.y - 6 + 3)
                    let spinless = Path(ellipseIn: CGRect(x: c.x * k - r, y: c.y * k - r, width: 2 * r, height: 2 * r))
                    context.opacity = 0.65
                    context.fill(spinless, with: .color(ShapeLabInk.spinless))
                    context.stroke(spinless, with: .color(PitchAtlasTheme.ink2),
                                   style: StrokeStyle(lineWidth: 1, dash: [3 * k, 3 * k]))
                    context.opacity = 0.8
                    context.draw(Text("NO SPIN").font(PitchAtlasType.font(.martian400, size: 7 * k, relativeTo: .caption2))
                                    .tracking(0.5 * k).foregroundStyle(PitchAtlasTheme.ink2), at: at(c.x, c.y))
                    context.opacity = 0.6
                    var link = Path()
                    link.move(to: at(c.x, c.y)); link.addLine(to: ball)
                    context.stroke(link, with: .color(PitchAtlasTheme.seamBright),
                                   style: StrokeStyle(lineWidth: 1.25 * k, dash: [2 * k, 3 * k]))
                    context.opacity = 1
                    let pitch = Path(ellipseIn: CGRect(x: ball.x - r, y: ball.y - r, width: 2 * r, height: 2 * r))
                    context.fill(pitch, with: .radialGradient(
                        Gradient(stops: [.init(color: ShapeLabInk.leatherHigh, location: 0),
                                         .init(color: ShapeLabInk.leatherMid, location: 0.62),
                                         .init(color: ShapeLabInk.leatherLow, location: 1)]),
                        center: CGPoint(x: ball.x - r + 0.38 * 2 * r, y: ball.y - r + 0.32 * 2 * r),
                        startRadius: 0, endRadius: 0.72 * 2 * r))
                    context.stroke(pitch, with: .color(PitchAtlasTheme.ink3), lineWidth: 0.8 * k)
                }
                SeamShape(rotation: atan2(result.spinAxis.y, result.spinAxis.x))
                    .stroke(PitchAtlasTheme.seamBright, style: StrokeStyle(lineWidth: 1.7 * k, lineCap: .round))
                    .frame(width: 2 * r, height: 2 * r)
                    .position(ball)
            }
        }
    }
}
