import SwiftUI

// =============================================================================
// The wall mount and the binder (web v2 .v2-mount; sections/BinderSheet.tsx)
// =============================================================================
// The wall: each filed-set card sits in a matte mount, the ember 1-of-1 in a
// burnt cell, dealt in as it scrolls up. The binder: a saddle-leather sheet
// punched for three rings, plastic sleeves two across on a phone. A pocket
// holds the real grip photograph, else the filed specimen's seam schematic,
// else the honest cream slip that says no image is on file. Pockets never carry
// video — a binder page is where the set rests.
// =============================================================================

enum BinderLayout {
    /// `.binder-grid`: three pockets across from a 640pt-wide window, two below.
    static func columns(width: CGFloat) -> Int { width < 640 ? 2 : 3 }
    /// On iPhone a compact vertical size class is landscape, which is ≥ 640 wide.
    static func columns(verticalSizeClass: UserInterfaceSizeClass?) -> Int { verticalSizeClass == .compact ? 3 : 2 }

    /// Neighbors catch the light at different angles (nth-child is 1-based).
    static func foilPosition(index: Int) -> UnitPoint {
        let n = index + 1
        if n % 3 == 0 { return UnitPoint(x: 0.78, y: 0.60) }
        if n % 3 == 2 { return UnitPoint(x: 0.12, y: 0.80) }
        return UnitPoint(x: 0.30, y: 0.25)
    }

    /// A handled page, never a print run. `5n+3` is declared after `4n+1` on the
    /// web, so it wins a pocket both rules match (the 13th).
    static func rotation(index: Int) -> Double {
        let n = index + 1
        if n % 5 == 3 { return 0.45 }
        if n % 4 == 1 { return -0.5 }
        return 0
    }
}

// MARK: - The wall

/// `.v2-mount`: the matte cell a wall card is seated in; the chase cell runs ember.
struct WallMount<Content: View>: View {
    var isChase = false
    @ViewBuilder var content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: PitchAtlasRadius.cardBack, style: .continuous)
        content
            .padding(10)
            .frame(maxWidth: .infinity)
            .background {
                shape.fill(LinearGradient(colors: [ComponentInk.mountTop, ComponentInk.mountBottom], startPoint: .top, endPoint: .bottom))
                    .overlay(alignment: .bottom) {
                        shape.strokeBorder(Color.white.opacity(isChase ? 0.06 : 0.05), lineWidth: 1).mask(alignment: .bottom) { Rectangle().frame(height: 1.5) }
                    }
                    .overlay { shape.strokeBorder(isChase ? ComponentInk.chaseMountBorder : Color.black.opacity(0.4), lineWidth: 1) }
                    .overlay { if isChase { shape.inset(by: 1).strokeBorder(ComponentInk.chaseMountRing, lineWidth: 1) } }
                    .shadow(color: .black.opacity(0.85), radius: 4, y: 10)
                    .shadow(color: isChase ? ComponentInk.chaseMountGlow : .clear, radius: 9)
                    .accessibilityHidden(true)
            }
    }
}

/// A filed-set card in its mount (web WallCard): the card is at most 360pt wide,
/// the ember 1-of-1 at most 520.
struct WallSpecimen: View {
    let entry: PitchAtlasEntry
    /// The width of the cell the mount fills.
    let width: CGFloat
    var index = 0

    static func cardWidth(cell: CGFloat, isChase: Bool) -> CGFloat { min(cell - 22, isChase ? 520 : 360) }

    var body: some View {
        let isChase = entry.display.specimenNo == "00"
        WallMount(isChase: isChase) {
            FlippableSpecimen(entry: entry, width: Self.cardWidth(cell: width, isChase: isChase), index: index)
        }
        .overlay { if isChase { ChaseSweep() } }
        .dealIn()
    }
}

private extension View {
    /// `v2-mount-deal`: a cell rises 14pt out of a 7° lean and a .7 dim as it
    /// scrolls in, and stays put once it has arrived. Reduce Motion: it is there.
    func dealIn() -> some View { modifier(DealIn()) }
}

private struct DealIn: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            // the web settles a cell by `cover 30%`; half-visible is the phone's equivalent
            content.scrollTransition(.interactive.threshold(.visible(0.5)), axis: .vertical) { view, phase in
                let t = phase == .bottomTrailing ? min(1, max(0, phase.value)) : 0
                return view
                    .opacity(1 - t)
                    .offset(y: 14 * t)
                    .rotation3DEffect(.degrees(7 * t), axis: (x: 1, y: 0, z: 0))
                    .brightness(-0.3 * t)
            }
        }
    }
}

/// The ember 1-of-1 flares once on arrival: a burnt band sweeps across its cell
/// as it scrolls in — heat in the material, never in letters.
struct ChaseSweep: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        if !reduceMotion {
            LinearGradient(stops: [.init(color: .clear, location: 0.30),
                                   .init(color: ComponentInk.chaseSweep, location: 0.50),
                                   .init(color: .clear, location: 0.70)],
                           startPoint: UnitPoint(x: 0, y: 0.42), endPoint: UnitPoint(x: 1, y: 0.58))
                .blendMode(.screen)
                .visualEffect { band, proxy in
                    band.offset(x: ChaseSweep.sweepOffset(frame: proxy.frame(in: .scrollView(axis: .vertical)),
                                                          viewport: proxy.bounds(of: .scrollView(axis: .vertical))?.height,
                                                          width: proxy.size.width))
                }
                .clipShape(RoundedRectangle(cornerRadius: PitchAtlasRadius.cardBack, style: .continuous))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    /// `translateX(-120% → 120%)` over the cell's entry from 10% in to 35% covered.
    nonisolated static func sweepOffset(frame: CGRect, viewport: CGFloat?, width: CGFloat) -> CGFloat {
        guard let viewport, viewport > 0 else { return width * 1.2 }
        let cover = max(frame.height + viewport, 1)
        let progress = (viewport - frame.minY) / cover          // 0 as its top edge enters, 1 once it has left
        let start = 0.10 * frame.height / cover                  // `entry 10%`, in cover terms
        let t = min(1, max(0, (progress - start) / max(0.35 - start, 0.01)))
        return width * (-1.2 + 2.4 * t)
    }
}

// MARK: - The binder

/// One Pitch Index entry's face in a sleeve, honest by construction.
enum PocketFace: Equatable {
    case photo(String)
    case schematic(PitchAtlasEntry)
    case slip

    static func resolve(_ entry: RepertoireEntry, store: PitchStore) -> PocketFace {
        let grip = store.gripEntry(forRepertoire: entry)
        if let still = grip?.photos.first?.src ?? grip?.film?.poster { return .photo(still) }
        if let slug = entry.filedSlug, let filed = store.pitch(slug: slug) { return .schematic(filed) }
        return .slip
    }

    /// What the pocket opens: the filed specimen, else the entry's basic file.
    static func openLabel(for entry: RepertoireEntry) -> String { entry.filedSlug == nil ? "Basic file" : "Open specimen" }
    static func accessibilityLabel(for entry: RepertoireEntry) -> String { "\(entry.name): \(openLabel(for: entry))" }
}

extension PitchStore {
    /// The grip-library entry filed against an index entry (web gripEntryForRepertoire).
    func gripEntry(forRepertoire entry: RepertoireEntry) -> GripEntry? {
        let key = entry.filedSlug ?? entry.id
        return grips.entries.first { $0.id == key || $0.specimenSlug == key || $0.repertoireId == key }
    }
}

extension RepertoireStatus {
    /// The banned, alias, illusion and not-a-pitch entries take the seam.
    var isEdge: Bool { WebTokens.Status.edge.contains(rawValue) }
}

/// `.binder-sheet`: saddle leather, three ring holes, a stitched dashed edge;
/// pockets two across on a phone (three in landscape).
struct BinderSheet<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        let cols = BinderLayout.columns(verticalSizeClass: verticalSizeClass)
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8, alignment: .top), count: cols), spacing: 8) {
            content
        }
        .padding(.vertical, 14).padding(.trailing, 14).padding(.leading, 36)
        .background {
            let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
            shape.fill(LinearGradient(stops: [.init(color: ComponentInk.sheetTop, location: 0), .init(color: ComponentInk.sheetBottom, location: 0.7)],
                                      startPoint: UnitPoint(x: 0.37, y: 0), endPoint: UnitPoint(x: 0.63, y: 1)))
                .overlay { shape.strokeBorder(Color.black.opacity(0.6), lineWidth: 1) }
                .overlay(alignment: .top) {
                    shape.strokeBorder(PitchAtlasTheme.bone.opacity(0.09), lineWidth: 1).mask(alignment: .top) { Rectangle().frame(height: 1.5) }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(ComponentInk.sheetStitch, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .padding(8)
                }
                .overlay(alignment: .leading) { RingHoles().padding(.leading, 11) }
                .shadow(color: .black.opacity(0.55), radius: 11, y: 26)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }
}

/// Three punched ring holes down the gutter, 6% in from top and bottom.
private struct RingHoles: View {
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                hole; Spacer(minLength: 0); hole; Spacer(minLength: 0); hole
            }
            .padding(.vertical, geo.size.height * 0.06)
            .frame(width: 16)
        }
        .frame(width: 16)
    }

    private var hole: some View {
        Circle()
            .fill(RadialGradient(colors: [ComponentInk.holeCenter, .black], center: UnitPoint(x: 0.38, y: 0.32), startRadius: 0, endRadius: 8))
            .frame(width: 14, height: 14)
            .overlay(alignment: .bottom) { Circle().strokeBorder(PitchAtlasTheme.bone.opacity(0.08), lineWidth: 1).mask(alignment: .bottom) { Rectangle().frame(height: 2) } }
    }
}

/// One Pitch Index entry in a sleeve: the photograph or schematic pocket card,
/// or the honest slip. The press slides the card up out of its sleeve.
struct RepertoirePocket: View {
    let entry: RepertoireEntry
    let index: Int
    let onOpen: (RepertoireEntry) -> Void
    @Environment(PitchStore.self) private var store

    var body: some View {
        let face = PocketFace.resolve(entry, store: store)
        let filedNo = entry.filedSlug.flatMap { store.pitch(slug: $0) }?.display.specimenNo
        Pocket {
            Button { onOpen(entry) } label: {
                switch face {
                case .slip: PocketSlip(entry: entry)
                case .photo, .schematic: PocketCard(entry: entry, face: face, filedNo: filedNo, index: index)
                }
            }
            .buttonStyle(SleevePull())
            .accessibilityLabel(PocketFace.accessibilityLabel(for: entry))
        }
    }
}

/// `.pocket`: a plastic sleeve — inset edge, one fixed diagonal gloss streak.
private struct Pocket<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        content
            .padding(5)
            .background {
                shape.fill(PitchAtlasTheme.bone.opacity(0.025))
                    .overlay { shape.strokeBorder(PitchAtlasTheme.bone.opacity(0.10), lineWidth: 1) }
                    .overlay(alignment: .top) {
                        LinearGradient(colors: [.black.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom)
                            .frame(height: 8).clipShape(shape)
                    }
                    .accessibilityHidden(true)
            }
            .overlay {
                shape.fill(LinearGradient(stops: [.init(color: .clear, location: 0.30),
                                                  .init(color: .white.opacity(0.075), location: 0.42),
                                                  .init(color: .white.opacity(0.02), location: 0.55),
                                                  .init(color: .clear, location: 0.62)],
                                          startPoint: UnitPoint(x: 0.06, y: 0.27), endPoint: UnitPoint(x: 0.94, y: 0.73)))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
    }
}

/// `.pocket-pull`: pressed, the card slides 12pt up out of its sleeve and turns
/// −0.6°, its shadow dropping with it. Reduce Motion holds it seated.
private struct SleevePull: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        let pulled = configuration.isPressed && !reduceMotion
        configuration.label
            .offset(y: pulled ? -12 : 0)
            .rotationEffect(.degrees(pulled ? -0.6 : 0))
            .shadow(color: .black.opacity(pulled ? 0.55 : 0), radius: 8, y: 14)
            .animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.26), value: pulled)
    }
}

/// `.pocket-card`: a thin foil frame (240%, positioned per pocket), the face,
/// the varsity number of a filed specimen, and the name strip.
struct PocketCard: View {
    let entry: RepertoireEntry
    let face: PocketFace
    /// The varsity number, printed only when the entry is a filed specimen.
    let filedNo: String?
    let index: Int

    var body: some View {
        let edge = entry.status.isEdge
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                faceView
                if let filedNo { number(filedNo) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            VStack(spacing: 2) {
                Text(entry.name.uppercased())
                    .font(PitchAtlasType.font(.anton400, size: 11, relativeTo: .caption)).tracking(em: 0.05, size: 11)
                    .foregroundStyle(ComponentInk.pocketNameInk).multilineTextAlignment(.center).lineLimit(2)
                Text(entry.status.displayLabel.uppercased())
                    .font(PitchAtlasType.font(.martian400, size: 7.5, relativeTo: .caption2)).tracking(em: 0.14, size: 7.5)
                    .foregroundStyle(edge ? ComponentInk.pocketStatusEdge : ComponentInk.pocketStatus)
            }
            .padding(.horizontal, 5).padding(.top, 5).padding(.bottom, 6)
            .frame(maxWidth: .infinity)
            .background {
                LinearGradient(stops: [.init(color: PitchAtlasTheme.bone.opacity(0.1), location: 0), .init(color: .clear, location: 0.6)],
                               startPoint: .top, endPoint: .bottom)
                    .background(ComponentInk.pocketNameFill)
            }
            .overlay(alignment: .top) { Rectangle().fill(PitchAtlasTheme.bone.opacity(0.22)).frame(height: 1) }
        }
        .background(LinearGradient(colors: [ComponentInk.pocketInnerTop, ComponentInk.pocketInnerBottom],
                                   startPoint: UnitPoint(x: 0.41, y: 0), endPoint: UnitPoint(x: 0.59, y: 1)))
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .padding(2)
        .background {
            Rectangle().fill(PitchAtlasMaterials.foil())
                .scaleEffect(2.4, anchor: BinderLayout.foilPosition(index: index))
                .clipShape(RoundedRectangle(cornerRadius: PitchAtlasRadius.card, style: .continuous))
                .accessibilityHidden(true)
        }
        .aspectRatio(5.0 / 7.0, contentMode: .fit)
        .rotationEffect(.degrees(BinderLayout.rotation(index: index)))
        .shadow(color: .black.opacity(0.8), radius: 5, y: 8)
    }

    @ViewBuilder private var faceView: some View {
        switch face {
        case .photo(let src):
            FocusFill(aspect: BundledImage.load(src).map { $0.size.width / max($0.size.height, 1) } ?? 3.0 / 4.0,
                      focus: UnitPoint(x: 0.5, y: 0.42)) {
                BundledImage(src: src, alt: "", contentMode: .fit)
            }
            .accessibilityHidden(true)
        case .schematic(let filed):
            GeometryReader { geo in
                SeamBall(motion: filed.motion, size: min(geo.size.width, geo.size.height) * 0.86,
                         contacts: filed.canonical.fingerPlacement, showMovement: false, contactMarks: .dots)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            .dynamicTypeSize(.large)
            .accessibilityHidden(true)
        case .slip:
            EmptyView()
        }
    }

    private func number(_ no: String) -> some View {
        Text(no)
            .font(PitchAtlasType.font(.anton400, size: 17, relativeTo: .headline))
            .foregroundStyle(PitchAtlasTheme.bone)
            .shadow(color: .black, radius: 0, x: 1, y: 1).shadow(color: .black, radius: 0, x: -1, y: -1)
            .shadow(color: .black.opacity(0.75), radius: 0, x: 2, y: 2)
            .padding(.top, 4).padding(.leading, 6)
            .dynamicTypeSize(.large)
            .accessibilityHidden(true)
    }
}

/// `.pocket-slip`: a typed cream file slip for an entry the atlas has not
/// photographed — paper, a status stamp, rule lines. Explicitly not an image.
struct PocketSlip: View {
    let entry: RepertoireEntry

    var body: some View {
        let edge = entry.status.isEdge
        let shape = RoundedRectangle(cornerRadius: PitchAtlasRadius.card, style: .continuous)
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.status.displayLabel.uppercased())
                .font(PitchAtlasType.font(.martian400, size: 8, relativeTo: .caption2)).tracking(em: 0.16, size: 8)
                .foregroundStyle(edge ? ComponentInk.slipEdgeStatus : ComponentInk.slipInk.opacity(0.55))
            Text(entry.name.uppercased())
                .font(PitchAtlasType.font(.anton400, size: 13, relativeTo: .subheadline))
                .foregroundStyle(ComponentInk.slipInk).lineLimit(3).minimumScaleFactor(0.8)
            Text("NO IMAGE FILED")
                .font(PitchAtlasType.font(.martian400, size: 7.5, relativeTo: .caption2)).tracking(em: 0.12, size: 7.5)
                .foregroundStyle(ComponentInk.slipInk.opacity(0.6))
            Spacer(minLength: 0)
            Text("\(PocketFace.openLabel(for: entry).uppercased()) →")
                .font(PitchAtlasType.font(.martian400, size: 7.5, relativeTo: .caption2)).tracking(em: 0.12, size: 7.5)
                .foregroundStyle(ComponentInk.slipInk.opacity(0.78))
        }
        .padding(7)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            shape.fill(ComponentInk.slipPaper)
                .overlay {
                    shape.fill(RadialGradient(stops: [.init(color: ComponentInk.slipShine, location: 0), .init(color: .clear, location: 0.55)],
                                              center: .top, startRadius: 0, endRadius: 160))
                }
                .overlay {
                    GeometryReader { g in
                        SlipRules()
                            .frame(width: max(0, g.size.width - 20), height: g.size.height * 0.26)
                            .position(x: g.size.width / 2, y: g.size.height - 9 - g.size.height * 0.13)
                    }
                }
                .overlay { shape.strokeBorder(edge ? ComponentInk.slipEdgeRing : ComponentInk.slipInk.opacity(0.28), lineWidth: 1) }
                .shadow(color: .black.opacity(0.7), radius: 3, y: 8)
                .accessibilityHidden(true)
        }
        .aspectRatio(5.0 / 7.0, contentMode: .fit)
    }
}

/// The slip's ruled lower 26%: a 1pt rule every 10pt, so it reads as a file slip.
private struct SlipRules: View {
    var body: some View {
        GeometryReader { geo in
            Path { p in
                var y: CGFloat = 9.5
                while y < geo.size.height {
                    p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: geo.size.width, y: y))
                    y += 10
                }
            }
            .stroke(ComponentInk.slipInk.opacity(0.13), lineWidth: 1)
        }
    }
}
