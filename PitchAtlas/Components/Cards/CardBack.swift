import SwiftUI

// =============================================================================
// The card back (web refractor/SpecimenBack.tsx + v2/ChromeWall's WallCard)
// =============================================================================
// The sourced back of a specimen: the dark scout record. Name and number, the
// grip cue and the shape with their claim tiers, then the two source links and
// the route into the full file. Matte black stock, the counterpoint to the
// front's foil. The web's movement wheel is not here: index.css hides it under
// 560px and on every standard wall card, so a phone never shows it.
// =============================================================================

/// Which face is toward the reader at a turn about the vertical axis.
enum FlipFace: Equatable {
    case front, back
    static func visible(angle: Double) -> FlipFace {
        let turn = angle.truncatingRemainder(dividingBy: 360)
        let a = turn < 0 ? turn + 360 : turn
        return a >= 90 && a < 270 ? .back : .front
    }
}

/// The scout file printed on the back — only sourced or categorical facts.
struct ScoutFile: Equatable {
    struct Row: Equatable {
        let key: String
        let value: String
        let tier: ClaimConfidence
        let approximate: Bool
    }
    struct Link: Equatable {
        let label: String
        let url: URL
    }
    let rows: [Row]
    let sourceLinks: [Link]

    static func headline(for e: PitchAtlasEntry) -> String {
        "No. \(e.display.specimenNo) · \(e.canonical.family.label)"
    }

    static func make(entry e: PitchAtlasEntry) -> ScoutFile {
        let grip = e.canonical.gripDetails.first ?? e.canonical.grip
        var rows = [Row(key: "Grip cue", value: grip.value, tier: grip.confidence, approximate: grip.approximate ?? false)]
        var links: [Link] = []
        if let s = grip.source, let url = URL(string: s.url) { links.append(Link(label: "Grip: \(s.label)", url: url)) }
        if let shape = e.canonical.physics.shape {
            rows.append(Row(key: "Shape", value: shape.value, tier: shape.confidence, approximate: shape.approximate ?? false))
            if let s = shape.source, let url = URL(string: s.url) { links.append(Link(label: "Shape: \(s.label)", url: url)) }
        }
        return ScoutFile(rows: rows, sourceLinks: links)
    }
}

enum FlipButton {
    static func title(flipped: Bool) -> String { flipped ? "↺ Card" : "↺ Source" }
    static func label(name: String, flipped: Bool) -> String {
        flipped ? "Flip \(name) back to its card" : "Flip \(name) to its sourced back"
    }
}

// MARK: - The back

/// `.v2-back`: the scout file on matte black stock; the chase back runs warm.
/// `fitsContent` lets the record grow past 5:7 for accessibility text sizes.
struct SpecimenCardBack: View {
    let entry: PitchAtlasEntry
    let metrics: SpecimenCardMetrics
    var isChase = false
    var fitsContent = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        let file = ScoutFile.make(entry: entry)
        let c3 = Color(rgb: PitchAccents.triad(for: entry.slug).c3)
        VStack(alignment: .leading, spacing: 0) {
            head(c3: c3)
            ScoutRows(accent: c3, rows: file.rows.enumerated().map { i, row in
                AnyView(BackRow(row: row, keyInk: c3.mix(PitchAtlasTheme.bone2, 0.4),
                                twin: i == 0 ? twin : nil, twinWidth: twinWidth, clamps: !fitsContent))
            })
            .padding(.top, 9)
            Spacer(minLength: 10)
            foot(file)
        }
        .padding(15)
        .frame(width: metrics.width, alignment: .topLeading)
        .frame(minHeight: metrics.height, maxHeight: fitsContent ? nil : metrics.height, alignment: .topLeading)
        .background { BackStock(isChase: isChase) }
        .clipShape(RoundedRectangle(cornerRadius: PitchAtlasRadius.cardBack, style: .continuous))
        .inkContext(.object)
    }

    private func head(c3: Color) -> some View {
        let layout = fitsContent ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                                 : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
        return layout {
            Text(entry.display.shortName.uppercased())
                .font(PitchAtlasType.font(.anton400, size: 20, relativeTo: .title3))
                .foregroundStyle(PitchAtlasTheme.bone)
                .lineLimit(1).minimumScaleFactor(0.7)
                .transformEffect(CardSkew.transform(degrees: -5))
            Spacer(minLength: 0)
            Text(ScoutFile.headline(for: entry).uppercased())
                .font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2)).tracking(em: 0.14, size: 9)
                .foregroundStyle(PitchAtlasTheme.bone2).lineLimit(1).fixedSize(horizontal: !fitsContent, vertical: false)
        }
        .padding(.bottom, 7)
        .overlay(alignment: .bottom) {
            Rectangle().fill(c3.mix(PitchAtlasTheme.bone, 0.15).opacity(0.47)).frame(height: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    /// The filed grip, shrunk to a twin that leads the grip row; decorative.
    private var twin: AnyView? {
        guard entry.canonical.gripModel.status == .filed, !entry.canonical.fingerPlacement.isEmpty else { return nil }
        return AnyView(SeamBall(motion: entry.motion, size: twinWidth, contacts: entry.canonical.fingerPlacement,
                                showMovement: false, contactMarks: .dots)
            .dynamicTypeSize(.large)
            .accessibilityHidden(true))
    }

    /// `clamp(38px, 22%, 44px)` of the row's value column.
    private var twinWidth: CGFloat {
        let column = metrics.width - 30 - 18 - ScoutRow.keyWidth - 9
        return min(44, max(38, column * 0.22))
    }

    private func foot(_ file: ScoutFile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(file.sourceLinks, id: \.label) { link in
                Button { openURL(link.url) } label: {
                    (Text(link.label.uppercased()) + Text(" ↗"))
                        .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2)).tracking(em: 0.1, size: 10)
                        .underline(color: PitchAtlasTheme.bone2.opacity(0.4))
                        .foregroundStyle(PitchAtlasTheme.bone2).lineLimit(fitsContent ? nil : 1).truncationMode(.tail)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(link.label)
                .accessibilityHint("Opens the source in your browser.")
            }
            NavigationLink(value: entry) {
                (Text("OPEN THE FULL FILE") + Text(" →"))
                    .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2)).tracking(em: 0.14, size: 10)
                    .foregroundStyle(PitchAtlasTheme.bone).lineLimit(fitsContent ? nil : 1)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open the full file on \(entry.display.shortName)")
        }
    }
}

/// One scout row on the back: the 56pt key, then the value (two lines, the grip
/// twin beside it when filed) and the claim tier under both.
private struct BackRow: View {
    let row: ScoutFile.Row
    let keyInk: Color
    let twin: AnyView?
    let twinWidth: CGFloat
    /// The two-line clamp of `.rfx-scout-value`; off when the back grows to fit.
    let clamps: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Text(row.key.uppercased())
                .font(PitchAtlasType.font(.martian400, size: 8, relativeTo: .caption2)).tracking(em: 0.12, size: 8)
                .foregroundStyle(keyInk).frame(width: ScoutRow.keyWidth, alignment: .leading)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 9) {
                    if let twin { twin.frame(width: twinWidth, height: twinWidth) }
                    Text(row.value).font(PitchAtlasType.body(size: 12)).lineSpacing(12 * 0.42 - 2)
                        .foregroundStyle(PitchAtlasTheme.bone).lineLimit(clamps ? 2 : nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack(spacing: 6) {
                    Circle().fill(PitchAtlasTheme.color(forConfidence: row.tier.rawValue)).frame(width: 6, height: 6)
                    Text(row.tier.label.uppercased())
                        .font(PitchAtlasType.font(.martian400, size: 8, relativeTo: .caption2)).tracking(em: 0.1, size: 8)
                        .foregroundStyle(PitchAtlasTheme.bone2)
                    if row.approximate {
                        Text("· APPROX").font(PitchAtlasType.font(.martian400, size: 8, relativeTo: .caption2)).tracking(em: 0.1, size: 8)
                            .foregroundStyle(PitchAtlasTheme.bone2.opacity(0.6))
                    }
                }
            }
        }
        .padding(.horizontal, 9).padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(row.key): \(row.value)")
        .accessibilityValue(ConfidenceDot.accessibilityText(for: row.tier, approximate: row.approximate))
    }
}

/// The matte stock: a radial from #15120F, a wide dull wash (not the front's hot
/// streak), a bone hairline; the 1-of-1 back warms its plate and frame.
struct BackStock: View {
    var isChase = false
    var radius: CGFloat = PitchAtlasRadius.cardBack

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        GeometryReader { geo in
            let reach = max(geo.size.width, geo.size.height) * 1.2
            shape.fill(RadialGradient(stops: [.init(color: isChase ? ComponentInk.chaseBackTop : ComponentInk.backTop, location: 0),
                                              .init(color: ComponentInk.backBottom, location: isChase ? 0.62 : 1)],
                                      center: .top, startRadius: 0, endRadius: reach))
                .overlay {
                    shape.fill(LinearGradient(stops: [.init(color: .clear, location: 0.14),
                                                      .init(color: isChase ? ComponentInk.chaseWash : PitchAtlasTheme.bone.opacity(0.06), location: isChase ? 0.40 : 0.38),
                                                      .init(color: .clear, location: isChase ? 0.66 : 0.64)],
                                              startPoint: UnitPoint(x: 0, y: 0.34), endPoint: UnitPoint(x: 1, y: 0.66)))
                        .blendMode(.screen).opacity(isChase ? 0.4 : 0.35)
                }
                .overlay(alignment: .top) {
                    shape.strokeBorder(Color.white.opacity(0.04), lineWidth: 1).mask(alignment: .top) { Rectangle().frame(height: 2) }
                }
                .overlay {
                    shape.strokeBorder(isChase ? ComponentInk.chaseBackBorder : PitchAtlasTheme.bone.opacity(0.10), lineWidth: 1)
                }
                .overlay {
                    if isChase { shape.inset(by: 1).strokeBorder(ComponentInk.chaseWash, lineWidth: 1) }
                }
        }
        .shadow(color: isChase ? ComponentInk.chaseGlow : .clear, radius: 8)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

// MARK: - The wall card: front, back and the action row

/// A filed-set card: the front links to the file, the flip turns it to the
/// sourced back, and the controls stay outside the turn (web WallCard).
struct FlippableSpecimen: View {
    let entry: PitchAtlasEntry
    let width: CGFloat
    var index = 0

    @Environment(PitchStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.compareSelection) private var comparison
    @State private var angle: Double = 0
    @State private var light = CardTiltState.rest.light
    @State private var backLight = CardTiltState.rest.light

    private var flipped: Bool { FlipFace.visible(angle: angle) == .back }
    private var isChase: Bool { entry.display.specimenNo == "00" }

    /// The web's flip: `.72s cubic-bezier(.2,.8,.2,1)`.
    static let turn = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.72)

    var body: some View {
        let content = SpecimenCardContent.make(entry: entry, grip: store.gripEntry(forSpecimen: entry.slug))
        let metrics = SpecimenCardMetrics(width: width, frame: content.frame)
        let size = CGSize(width: metrics.width, height: metrics.height)
        VStack(spacing: 12) {
            if dynamicTypeSize.isAccessibilitySize {
                // A 5:7 face can't hold accessibility-size text: the card stays
                // still and the sourced back unfolds beneath it, nothing clipped.
                front(content, metrics)
                CardWords(content: content).frame(width: metrics.width, alignment: .leading)
                if flipped { SpecimenCardBack(entry: entry, metrics: metrics, isChase: isChase, fitsContent: true) }
            } else {
                FlipTurn(angle: angle,
                         front: front(content, metrics).cardTilt(.rest, size: size, light: $light),
                         back: SpecimenCardBack(entry: entry, metrics: metrics, isChase: isChase)
                            .cardTilt(.rest, size: size, light: $backLight, rake: false))
                    .rotationEffect(.degrees(CardLean.rest(index: index)))
            }
            actions(content)
                .frame(width: metrics.width)
        }
        .accessibilityAction(named: "Compare this pitch") { comparison.add(entry.slug) }
    }

    private func front(_ content: SpecimenCardContent, _ metrics: SpecimenCardMetrics) -> some View {
        NavigationLink(value: entry) {
            SpecimenCardFront(content: content, metrics: metrics, light: light)
        }
        .buttonStyle(.plain)
    }

    private func actions(_ content: SpecimenCardContent) -> some View {
        HStack(spacing: 12) {
            Button(action: toggle) {
                Text(FlipButton.title(flipped: flipped).uppercased())
                    .font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2)).tracking(em: 0.12, size: 9)
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(Capsule().fill(ComponentInk.flipFill))
                    .overlay(Capsule().strokeBorder(Color(rgb: content.triad.c3).mix(PitchAtlasTheme.bone, 0.3).opacity(0.6), lineWidth: 1))
                    .overlay(alignment: .top) {
                        Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1).mask(alignment: .top) { Rectangle().frame(height: 1.5) }
                    }
                    .shadow(color: .black.opacity(0.9), radius: 6, y: 8)
                    .frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
            }
            .buttonStyle(PressScale())
            .accessibilityLabel(FlipButton.label(name: entry.display.shortName, flipped: flipped))
            .accessibilityAddTraits(.isToggle)
            .accessibilityValue(flipped ? "Showing sources" : "Showing card")
            Spacer(minLength: 0)
            CompareButton(slug: entry.slug)
        }
    }

    private func toggle() {
        Haptics.selection()
        let target: Double = flipped ? 0 : 180
        if reduceMotion || dynamicTypeSize.isAccessibilitySize { angle = target } else { withAnimation(Self.turn) { angle = target } }
    }
}

/// Turns the pair about the vertical centre line. It reads the animating angle,
/// so the faces swap at the visual 90° rather than when the tap lands.
private struct FlipTurn<Front: View, Back: View>: View, Animatable {
    var angle: Double
    let front: Front
    let back: Back

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        let face = FlipFace.visible(angle: angle)
        ZStack {
            front
                .opacity(face == .front ? 1 : 0)
                .allowsHitTesting(face == .front)
                .accessibilityHidden(face != .front)
            back
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(face == .back ? 1 : 0)
                .allowsHitTesting(face == .back)
                .accessibilityHidden(face != .back)
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.35)
    }
}

/// The web's `:active { transform: scale(.95) }`.
private struct PressScale: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - The back's stock as a reading panel

/// `.v2-back` as a reading panel (the Atlas grading scale, the pitch file's
/// reference blocks): content padded 15 on the matte stock, light inks.
struct CardBackPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(PitchAtlasTheme.cardbackInk)
            .background { BackStock() }
            .inkContext(.object)
    }
}

/// The card-back header strip: a slab title between two bone hairlines.
struct CardBackRules: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(PitchAtlasTheme.anton(15))
            .foregroundStyle(PitchAtlasTheme.bone)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
            .overlay(alignment: .top) { Rectangle().fill(PitchAtlasTheme.cardbackLine).frame(height: 1) }
            .overlay(alignment: .bottom) { Rectangle().fill(PitchAtlasTheme.cardbackLine).frame(height: 1) }
            .accessibilityAddTraits(.isHeader)
    }
}
