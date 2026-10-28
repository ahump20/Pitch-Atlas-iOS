import SwiftUI

// =============================================================================
// The 5:7 specimen card (web RefractorCard / PitchSpecimenCard)
// =============================================================================
// One card at three widths: the hero, the rail, the wall. Every printed size is
// N·u (u = width/100), so the print scales with the card, never with text size;
// at accessibility sizes the same words print again under the card in scalable
// type (CardWords). What goes in the window is the one resolver the web uses:
// Austin's loop, then his photo, then the seam-informed schematic.
// =============================================================================

/// The face of a filed specimen: foil-rimmed stock, a warm-black field, the head,
/// the arched window, the cream read plate, the strip.
struct SpecimenCardFront: View {
    let content: SpecimenCardContent
    let metrics: SpecimenCardMetrics
    var playsFilm = false
    var light = UnitPoint(x: 0.5, y: 0.32)

    private var ember: Bool { content.frame == .ember }
    private var c2: Color { Color(rgb: content.triad.c2) }
    private var c3: Color { Color(rgb: content.triad.c3) }
    private var c3Ink: Color { PitchAccents.accentInk(content.triad.c3) }

    var body: some View {
        let m = metrics
        ZStack {
            stock
            field.padding(m.stockPadding)
        }
        .frame(width: m.width, height: m.height)
        .clipShape(RoundedRectangle(cornerRadius: PitchAtlasRadius.card, style: .continuous))
        .modifier(EdgeStack(ember: ember))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.accessibilityLabel)
    }

    // Stock: the foil (or ember / throwback foil) at 300%, positioned by the light,
    // a 57° hatch at white .14 overlay, then the rim hairline.
    private var stock: some View {
        let foil: LinearGradient = switch content.frame {
        case .ember: PitchAtlasMaterials.ember()
        case .powder: PitchAtlasMaterials.cardFoil(finish: "powder")
        case .teal: PitchAtlasMaterials.cardFoil(finish: "teal")
        case .standard: PitchAtlasMaterials.foil()
        }
        return RoundedRectangle(cornerRadius: PitchAtlasRadius.card, style: .continuous)
            .fill(foil)
            .scaleEffect(3, anchor: light)
            .overlay { Hatch(angle: 57, spacing: 9).stroke(Color.white.opacity(0.14), lineWidth: 1).blendMode(.overlay) }
            .overlay { RoundedRectangle(cornerRadius: PitchAtlasRadius.card, style: .continuous).strokeBorder(ComponentInk.edgeHairline, lineWidth: 1) }
            .clipped()
            .accessibilityHidden(true)
    }

    private var field: some View {
        let m = metrics
        let fieldShape = RoundedRectangle(cornerRadius: PitchAtlasRadius.cardField)
        return VStack(spacing: 0) {
            head
            window
            readPlate.padding(.top, m.readMarginTop)
            Spacer(minLength: 0)
            strip
        }
        .padding(m.fieldPadding)
        .background {
            fieldShape
                .fill(ember ? LinearGradient(colors: ComponentInk.emberField, startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [c2.opacity(0.34), ComponentInk.fieldBase], startPoint: .top, endPoint: .bottom))
                .overlay { fieldShape.strokeBorder(.black, lineWidth: 2) }
                .overlay { fieldShape.inset(by: 2).strokeBorder((ember ? Color(rgb: WebTokens.Accent.burnt) : c3).opacity(0.42), lineWidth: 1) }
                .overlay { Hatch(angle: 45, spacing: 6).stroke(PitchAtlasTheme.bone, lineWidth: 0.5).opacity(0.075) }
                .overlay { RadialGradient(colors: [.white.opacity(0.3), .clear], center: light, startRadius: 0, endRadius: m.width * 0.6).blendMode(.screen) }
                .clipShape(fieldShape)
        }
    }

    private var head: some View {
        let m = metrics
        return HStack(alignment: .bottom, spacing: 2.22 * m.u) {
            VStack(alignment: .leading, spacing: 0.83 * m.u) {
                Text("FILED SPECIMEN").font(PitchAtlasType.font(.martian400, size: m.overlineSize))
                    .tracking(em: ember ? 0.22 : 0.17, size: m.overlineSize)
                    .foregroundStyle(ember ? ComponentInk.emberOverline : c3Ink.mix(ComponentInk.cardStrip, 0.32))
                Text(content.name.uppercased()).font(PitchAtlasType.font(.anton400, size: m.nameSize))
                    .lineLimit(2).minimumScaleFactor(0.7)
                    .foregroundStyle(ember ? ComponentInk.emberName : ComponentInk.cardName)
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 1, y: 1)
                    .transformEffect(CardSkew.transform(degrees: -5))
            }
            Spacer(minLength: 0)
            HStack(alignment: .bottom, spacing: 1.1 * m.u) {
                Text("FILE").font(PitchAtlasType.font(.martian400, size: m.overlineSize))
                    .foregroundStyle(ember ? ComponentInk.emberFileLabel : ComponentInk.cardFileLabel).padding(.bottom, 0.65 * m.u)
                Text(content.vnum).font(PitchAtlasType.font(.anton400, size: m.numberSize))
                    .foregroundStyle(ember ? ComponentInk.emberName : c3Ink.mix(PitchAtlasTheme.bone, 0.28))
                    .transformEffect(CardSkew.transform(degrees: -6))
            }
        }
        .padding(m.headPadding)
        .accessibilityHidden(true)
    }

    private var window: some View {
        let m = metrics
        let shape = ArchedWindow(topRX: m.stageTopRX, topRY: m.stageTopRY, bottomR: m.stageBottomR)
        return ZStack(alignment: .bottomLeading) {
            RadialGradient(colors: [c2.mix(.black, 0.52), ComponentInk.stageDeep], center: .init(x: 0.5, y: 0.24), startRadius: 0, endRadius: m.width * 0.78)
            HalftoneDots(spacing: 9, color: c3.opacity(0.7)).opacity(0.12)
            faceView
            chip.padding(m.chipInset)
        }
        .aspectRatio(10.0 / 9.0, contentMode: .fit)
        .clipShape(shape)
        .overlay { shape.stroke(c3.opacity(0.22), lineWidth: 1) }
    }

    @ViewBuilder private var faceView: some View {
        switch content.face {
        case .film(let film):
            FocusFill(aspect: BundledImage.load(film.poster).map { $0.size.width / max($0.size.height, 1) } ?? 9.0 / 16.0,
                      focus: FocusCrop.unitPoint(film.focus)) {
                GripLoopFace(film: film, plays: playsFilm)
            }
        case .photo(let photo):
            FocusFill(aspect: BundledImage.load(photo.src).map { $0.size.width / max($0.size.height, 1) } ?? 3.0 / 4.0,
                      focus: FocusCrop.unitPoint(nil)) {
                BundledImage(src: photo.src, alt: photo.alt, contentMode: .fit)
            }
        case .schematic:
            SchematicFace(slug: content.slug, size: metrics.width * 0.62)
        }
    }

    private var chip: some View {
        let m = metrics
        let ink = content.chipIsAustin ? PitchAtlasTheme.cyan : PitchAtlasTheme.sandBright
        return HStack(spacing: 1.39 * m.u) {
            Circle().fill(ink).frame(width: m.dotSize, height: m.dotSize)
            Text(content.chipLabel.uppercased()).font(PitchAtlasType.font(.martian400, size: m.chipSize)).tracking(em: 0.1, size: m.chipSize)
                .foregroundStyle(ink)
        }
        .padding(.horizontal, 2.22 * m.u).padding(.vertical, 0.83 * m.u)
        .background(Capsule().fill(ComponentInk.gripChipFill))
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
    }

    private var readPlate: some View {
        let m = metrics
        let paper = ember ? ComponentInk.emberPaper : ComponentInk.readPaper
        let plate = RoundedRectangle(cornerRadius: m.readRadius)
        return VStack(alignment: .leading, spacing: m.readGap) {
            HStack {
                Text("GRIP TELL"); Spacer(); Text("PA—\(content.vnum)")
            }
            .font(PitchAtlasType.font(.martian400, size: m.readMetaSize)).tracking(em: ember ? 0.24 : 0.15, size: m.readMetaSize)
            .foregroundStyle(ember ? ComponentInk.emberMeta : ComponentInk.readMeta)
            Text(content.cue).font(PitchAtlasType.cardCue(size: m.cueSize)).lineSpacing(m.cueSize * 0.32).lineLimit(2)
                .foregroundStyle(ember ? ComponentInk.emberCue : ComponentInk.readCue)
            HStack(spacing: 1.4 * m.u) {
                Circle().fill(PitchAtlasTheme.cardInk(forConfidence: content.cueTier.rawValue)).frame(width: m.dotSize, height: m.dotSize)
                    .shadow(color: PitchAtlasTheme.cardInk(forConfidence: content.cueTier.rawValue), radius: 4)
                Text(content.cueTier.label.uppercased()).font(PitchAtlasType.font(.martian400, size: m.factSize)).tracking(em: 0.07, size: m.factSize)
                    .foregroundStyle(ember ? ComponentInk.emberFact : ComponentInk.readFact).lineLimit(1)
                if content.approximate {
                    Text("≈ APPROX").font(PitchAtlasType.font(.martian400, size: max(7, 2.58 * m.u)))
                        .foregroundStyle(ember ? ComponentInk.emberMeta : ComponentInk.readFact)
                }
            }
            .padding(.top, 1.67 * m.u)
            .overlay(alignment: .top) { Rectangle().fill(ComponentInk.readRule).frame(height: 1) }
        }
        .padding(m.readPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            plate.fill(paper)
                .overlay { RuledLines(step: m.readRuleStep).stroke(ComponentInk.readRuling, lineWidth: 0.2 * m.u) }
                .overlay { RadialGradient(colors: [.white.opacity(0.62), .clear], center: .top, startRadius: 0, endRadius: m.width * 0.5) }
                .clipShape(plate)
        }
        .accessibilityHidden(true)
    }

    private var strip: some View {
        let m = metrics
        return HStack(spacing: 2.22 * m.u) {
            Text("GRIP / RELEASE / SHAPE").font(PitchAtlasType.font(.martian400, size: m.stripSize * 0.86)).tracking(em: 0.1, size: m.stripSize * 0.86)
                .foregroundStyle(c3Ink.mix(ComponentInk.cardStrip, 0.42)).lineLimit(1)
            Spacer(minLength: 0)
            Text("OPEN SPECIMEN →").font(PitchAtlasType.font(.martian400, size: m.stripSize)).tracking(em: 0.08, size: m.stripSize)
                .foregroundStyle(ComponentInk.cardStrip)
        }
        .padding(.top, m.stripTop)
        .shadow(color: .black.opacity(0.85), radius: 1.5, y: 1)
        .accessibilityHidden(true)
    }
}

// MARK: - The card's words in scalable type

/// The card's print scales with the card, not with text size. At accessibility
/// sizes the same words also print here, in scalable type, under the card.
struct CardWords: View {
    static func lines(for c: SpecimenCardContent) -> [String] { [c.cue, c.cueTier.label + (c.approximate ? " · approximate" : "")] }
    let content: SpecimenCardContent
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(content.cue).font(PitchAtlasTheme.newsreaderItalic(17, relativeTo: .body)).foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
            ConfidenceDot(confidence: content.cueTier, approximate: content.approximate)
        }
        .accessibilityHidden(true)   // the card's own label already speaks these
    }
}

// MARK: - The card as placed (hero, rail, wall)

/// The specimen card at a placement width, leaning like the web's set. Callers
/// wrap it in their own NavigationLink, as before.
struct PitchSpecimenCard: View {
    enum Style { case hero, rail, wall(width: CGFloat) }

    let entry: PitchAtlasEntry
    var style: Style = .hero

    @Environment(PitchStore.self) private var store
    @Environment(\.compareSelection) private var comparison
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    static func width(for style: Style) -> CGFloat {
        switch style {
        case .hero: 320
        case .rail: 268
        case .wall(let w): min(w, 360)
        }
    }

    private var isHero: Bool { if case .hero = style { true } else { false } }

    var body: some View {
        let content = SpecimenCardContent.make(entry: entry, grip: store.gripEntry(forSpecimen: entry.slug))
        let metrics = SpecimenCardMetrics(width: Self.width(for: style), frame: content.frame)
        VStack(alignment: .leading, spacing: 12) {
            SpecimenCardFront(content: content, metrics: metrics, playsFilm: isHero)
                .rotationEffect(.degrees(isHero && content.frame == .ember ? CardLean.hero : CardLean.rest(index: 0)))
            if dynamicTypeSize.isAccessibilitySize {
                CardWords(content: content).frame(width: metrics.width, alignment: .leading)
            }
        }
        .contextMenu { Button("Compare this pitch") { comparison.add(entry.slug); Haptics.selection() } }
        .accessibilityAction(named: "Compare this pitch") { comparison.add(entry.slug) }
    }
}

// MARK: - Media framing

/// CSS `object-fit: cover` + `object-position`, as plain geometry.
enum FocusCrop {
    static func unitPoint(_ f: FilmFocus?) -> UnitPoint {
        guard let f else { return .center }
        return UnitPoint(x: f.x / 100, y: f.y / 100)
    }

    /// The media's frame inside a box, in the box's coordinates.
    static func layout(box: CGSize, aspect: CGFloat, focus: UnitPoint) -> CGRect {
        guard box.width > 0, box.height > 0, aspect > 0 else { return CGRect(origin: .zero, size: box) }
        let media = box.width / box.height > aspect
            ? CGSize(width: box.width, height: box.width / aspect)
            : CGSize(width: box.height * aspect, height: box.height)
        return CGRect(x: (box.width - media.width) * focus.x,
                      y: (box.height - media.height) * focus.y,
                      width: media.width, height: media.height)
    }
}

/// Fills its box with media of a known aspect the way CSS `object-fit: cover`
/// with `object-position` does: the media covers the box, and the point at
/// `focus` of the media lines up with the same point of the box. The web crops
/// each grip loop this way so the fingertips stay on the seam (GripClip.focus).
struct FocusFill<Content: View>: View {
    let aspect: CGFloat
    let focus: UnitPoint
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { geo in
            let r = FocusCrop.layout(box: geo.size, aspect: aspect, focus: focus)
            content.frame(width: r.width, height: r.height).offset(x: r.minX, y: r.minY)
        }
        .clipped()
    }
}

// MARK: - Card print helpers

enum CardSkew {
    /// The web's `skewX(deg)`: a horizontal shear of the athletic type.
    static func transform(degrees: Double) -> CGAffineTransform {
        CGAffineTransform(a: 1, b: 0, c: CGFloat(tan(degrees * .pi / 180)), d: 1, tx: 0, ty: 0)
    }
}

/// Parallel lines at `angle` degrees every `spacing` points (the stock and field hatch).
struct Hatch: Shape {
    var angle: Double
    var spacing: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let diag = hypot(rect.width, rect.height)
        let rad = angle * .pi / 180
        let dir = CGPoint(x: cos(rad), y: sin(rad))
        let normal = CGPoint(x: -dir.y, y: dir.x)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var d = -diag
        while d <= diag {
            let o = CGPoint(x: center.x + normal.x * d, y: center.y + normal.y * d)
            p.move(to: CGPoint(x: o.x - dir.x * diag, y: o.y - dir.y * diag))
            p.addLine(to: CGPoint(x: o.x + dir.x * diag, y: o.y + dir.y * diag))
            d += max(spacing, 1)
        }
        return p
    }
}

/// Horizontal rules every `step` points (the read plate's ruled paper).
struct RuledLines: Shape {
    var step: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        var y = rect.minY + step
        while y < rect.maxY {
            p.move(to: CGPoint(x: rect.minX, y: y)); p.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += max(step, 1)
        }
        return p
    }
}

/// The window's halftone: small dots on a grid, fading out from the top.
struct HalftoneDots: View {
    var spacing: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, size in
            var y: CGFloat = spacing / 2
            while y < size.height {
                var x: CGFloat = spacing / 2
                while x < size.width {
                    ctx.fill(Path(ellipseIn: CGRect(x: x - 0.7, y: y - 0.7, width: 1.4, height: 1.4)), with: .color(color))
                    x += spacing
                }
                y += spacing
            }
        }
        .mask(RadialGradient(colors: [.white, .clear], center: .top, startRadius: 0, endRadius: 260))
        .accessibilityHidden(true)
    }
}

/// The seam-informed schematic as the window face where no first-party media is filed.
private struct SchematicFace: View {
    let slug: String
    let size: CGFloat
    @Environment(PitchStore.self) private var store
    var body: some View {
        ZStack {
            if let motion = store.pitch(slug: slug)?.motion {
                SeamBall(motion: motion, size: size, showMovement: false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityHidden(true)
    }
}

/// The card's edge: a black ring, the stacked card-stock edges, the drop shadow;
/// the ember 1/1 swaps in its burnt ring and glow.
private struct EdgeStack: ViewModifier {
    let ember: Bool
    func body(content: Content) -> some View {
        let stack = ComponentInk.edgeStack
        let layer = { (i: Int) in stack.isEmpty ? Color.black : stack[min(i, stack.count - 1)] }
        content
            .shadow(color: ComponentInk.edgeRing, radius: 0, x: 0, y: 1)
            .shadow(color: ember ? ComponentInk.emberRing : layer(0), radius: 0, x: 0, y: 3)
            .shadow(color: layer(1), radius: 0, x: 0, y: 5)
            .shadow(color: layer(2), radius: 0, x: 0, y: 7)
            .shadow(color: layer(3), radius: 0, x: 0, y: 9)
            .shadow(color: .black.opacity(0.55), radius: 14, x: 0, y: 16)
            .shadow(color: ember ? Color(rgb: WebTokens.Accent.burnt).opacity(0.3) : .clear, radius: 12)
    }
}
