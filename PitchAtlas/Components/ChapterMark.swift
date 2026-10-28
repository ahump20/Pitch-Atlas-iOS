import SwiftUI

// =============================================================================
// ChapterMark — the filed index line at the head of a home section
// =============================================================================
// Web: src/components/v2/ChapterMark.tsx and Delivery.tsx. A chapter tick, the
// number, a hairline, the chapter name, in mono micro-caps. On the home the tick
// is Muybridge's pitcher from plate 273: the first time a mark is seen, the
// figure steps from the phase it holds to its own phase of the delivery (set,
// break, cock, release, finish), 90ms a frame. Reduce Motion lands on the
// chapter's phase without stepping. Decorative and additive: the figure is
// hidden from VoiceOver and every section reads complete without it.
// =============================================================================

/// One traced frame of plate 273, drawn from its straight-line outlines.
struct PlateFrameShape: Shape {
    let frame: Plate273Frame

    func path(in rect: CGRect) -> Path {
        guard frame.viewBox.count == 4, frame.viewBox[2] > 0, frame.viewBox[3] > 0 else { return Path() }
        let minX = frame.viewBox[0], minY = frame.viewBox[1]
        let width = frame.viewBox[2], height = frame.viewBox[3]
        // The SVG default: fit the frame's own box, centred (xMidYMid meet).
        let scale = min(rect.width / width, rect.height / height)
        let dx = rect.minX + (rect.width - width * scale) / 2
        let dy = rect.minY + (rect.height - height * scale) / 2
        func point(_ p: [Double]) -> CGPoint { CGPoint(x: dx + (p[0] - minX) * scale, y: dy + (p[1] - minY) * scale) }

        var path = Path()
        for outline in frame.subpaths {
            let points = outline.filter { $0.count == 2 }
            guard let first = points.first else { continue }
            path.move(to: point(first))
            for p in points.dropFirst() { path.addLine(to: point(p)) }
            path.closeSubpath()
        }
        return path
    }
}

/// The pitcher at a chapter mark: holds `delivery.lowerBound`, then steps to
/// `delivery.upperBound` the first time it appears.
struct DeliveryFigure: View {
    let delivery: ClosedRange<Int>
    let tint: Color
    var size: CGFloat = 26

    @Environment(PitchStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var frame: Int
    @State private var stepped = false

    /// The site's step: 90ms a frame.
    static let stepNanoseconds: UInt64 = 90_000_000

    init(delivery: ClosedRange<Int>, tint: Color, size: CGFloat = 26) {
        self.delivery = delivery
        self.tint = tint
        self.size = size
        _frame = State(initialValue: delivery.lowerBound)
    }

    var body: some View {
        ZStack {
            if let plate = store.plate273, plate.frames.indices.contains(frame - 1) {
                PlateFrameShape(frame: plate.frames[frame - 1])
                    .fill(tint, style: FillStyle(eoFill: true))
            }
        }
        .frame(width: size, height: size)
        .padding(.vertical, -6)
        .accessibilityHidden(true)
        .task { await step() }
    }

    @MainActor
    private func step() async {
        guard !stepped else { return }
        stepped = true
        if reduceMotion {
            frame = delivery.upperBound
            return
        }
        while frame < delivery.upperBound {
            try? await Task.sleep(nanoseconds: Self.stepNanoseconds)
            if Task.isCancelled { frame = delivery.upperBound; return }
            frame += 1
        }
    }
}

/// "01 —— THE SPECIMEN": the line at the head of a home section.
struct ChapterMark: View {
    let number: String
    let name: String
    var accent: Color = PitchAtlasTheme.cyan
    /// Plate 273 frames: the phase held before the mark is seen, then the one it steps to.
    var delivery: ClosedRange<Int>? = nil
    var numberInk: Color = PitchAtlasTheme.bone2.opacity(0.7)
    var nameInk: Color = PitchAtlasTheme.bone2
    var ruleInk: Color = PitchAtlasTheme.bone.opacity(0.25)

    /// A mark outside the home's numbered delivery: the square tick in the
    /// section's tint, or a pitcher frame range when the page passes one.
    init(number: String, name: String, accent: Color = PitchAtlasTheme.cyan, delivery: ClosedRange<Int>? = nil,
         numberInk: Color = PitchAtlasTheme.bone2.opacity(0.7),
         nameInk: Color = PitchAtlasTheme.bone2,
         ruleInk: Color = PitchAtlasTheme.bone.opacity(0.25)) {
        self.number = number
        self.name = name
        self.accent = accent
        self.delivery = delivery
        self.numberInk = numberInk
        self.nameInk = nameInk
        self.ruleInk = ruleInk
    }

    init(_ chapter: HomeChapter, accent: Color = PitchAtlasTheme.cyan,
         numberInk: Color = PitchAtlasTheme.bone2.opacity(0.7),
         nameInk: Color = PitchAtlasTheme.bone2,
         ruleInk: Color = PitchAtlasTheme.bone.opacity(0.25)) {
        self.number = chapter.number
        self.name = chapter.name
        self.accent = accent
        self.delivery = chapter.delivery
        self.numberInk = numberInk
        self.nameInk = nameInk
        self.ruleInk = ruleInk
    }

    var body: some View {
        HStack(spacing: 10) {
            if let delivery {
                DeliveryFigure(delivery: delivery, tint: accent)
            } else {
                Text("■").foregroundStyle(accent).accessibilityHidden(true)
            }
            Text(number)
                .monospacedDigit()
                .foregroundStyle(numberInk)
            Rectangle()
                .fill(ruleInk)
                .frame(width: 20, height: 1)
                .accessibilityHidden(true)
            Text(name.uppercased())
                .foregroundStyle(nameInk)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
        .tracking(2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Chapter \(number), \(name)")
    }
}

/// The close's record: the ten lateral frames of plate 273 laid out the way the
/// 1887 plate did (a pale figure on a gridded black ground, five to a row on a
/// phone), exposing left to right like his battery of shutters when it comes into
/// view, with the credit and its source.
struct DeliveryPlate: View {
    @Environment(PitchStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var landed = false

    var body: some View {
        if let plate = store.plate273 {
            VStack(spacing: 14) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 5), spacing: 3) {
                    ForEach(Array(plate.frames.enumerated()), id: \.element.id) { index, frame in
                        PlateCell(frame: frame)
                            .opacity(landed || reduceMotion ? 1 : 0.16)
                            .animation(reduceMotion ? nil : .easeOut(duration: 0.46).delay(Double(index) * 0.09), value: landed)
                    }
                }
                .padding(3)
                .background(ArchiveInk.plateStrip, in: RoundedRectangle(cornerRadius: 2))
                .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Plate \(plate.plate), \(plate.title) (\(String(plate.year)))".uppercased())
                        .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                        .tracking(1.4)
                        .foregroundStyle(ArchiveInk.plateTitle)
                    (Text("\(plate.maker) photographed this delivery for ")
                     + Text(plate.work).italic()
                     + Text(". The pitcher at each chapter mark above is traced from it. Public domain."))
                        .font(PitchAtlasTheme.hanken(12, relativeTo: .footnote))
                        .foregroundStyle(ArchiveInk.plateCaption)
                        .lineSpacing(3)
                    if let url = URL(string: plate.source.url) {
                        Link(destination: url) {
                            Text("Source ↗\u{FE0E}")
                                .font(PitchAtlasTheme.hanken(12, relativeTo: .footnote))
                                .underline()
                                .foregroundStyle(ArchiveInk.plateLink)
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Source: \(plate.source.label)")
                        .accessibilityHint("Opens in Safari")
                    }
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
            .onAppear { landed = true }
        }
    }
}

/// One frame on the plate: the figure on its 9 × 9 registration grid.
private struct PlateCell: View {
    let frame: Plate273Frame

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack(alignment: .topLeading) {
                ArchiveInk.plateFrameFill
                Path { path in
                    for i in 0..<9 {
                        let x = w * CGFloat(i) / 9, y = h * CGFloat(i) / 9
                        path.addRect(CGRect(x: x, y: 0, width: 1, height: h))
                        path.addRect(CGRect(x: 0, y: y, width: w, height: 1))
                    }
                }
                .fill(ArchiveInk.plateGrid)
                // .delivery-plate-frame padding: 10% top, 8% sides, 4% bottom.
                PlateFrameShape(frame: frame)
                    .fill(ArchiveInk.plateFigure, style: FillStyle(eoFill: true))
                    .padding(EdgeInsets(top: h * 0.10, leading: w * 0.08, bottom: h * 0.04, trailing: w * 0.08))
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
