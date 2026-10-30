import SwiftUI

// =============================================================================
// The archive page kit — how every page below the home opens
// =============================================================================
// Web: motion/SeamGuide.tsx (the red thread), layout/Breadcrumb.tsx,
// layout/SectionHero.tsx and archive.css's `.archive-section-hero`. The site
// heads each hall and chapter the same way: where you are, a cyan kicker, a
// Newsreader headline set balanced, a short run of stitches, and a roman sub,
// on a dark field with a faint accent wash and scorebook rules behind it.
// =============================================================================

/// One stitch: a short stroke across the seam line.
struct StitchSegment: Equatable {
    let from: CGPoint
    let to: CGPoint
}

/// The red thread's geometry, computed with the site's own formulas.
enum StitchGeometry {
    /// StitchRow: `count` alternating slashes, evenly spaced across a `width`×16 strip.
    static func row(width: CGFloat, count: Int) -> [StitchSegment] {
        guard count > 0, width > 0 else { return [] }
        let step = width / CGFloat(count)
        return (0..<count).map { i in
            let x = step * CGFloat(i) + step / 2
            return i % 2 == 0
                ? StitchSegment(from: CGPoint(x: x - 3.5, y: 3), to: CGPoint(x: x + 3.5, y: 13))
                : StitchSegment(from: CGPoint(x: x + 3.5, y: 3), to: CGPoint(x: x - 3.5, y: 13))
        }
    }

    /// StitchArc: thirteen ticks across the horseshoe in a 100×64 box, the seam
    /// coming around to close. Coordinates round to a tenth, as the site's path data does.
    static func arc() -> [StitchSegment] {
        let cx = 50.0, cy = 54.0, r = 38.0, ticks = 13
        let start = Double.pi * 1.12, end = -Double.pi * 0.12
        func tenth(_ v: Double) -> CGFloat { CGFloat((v * 10).rounded() / 10) }
        return (0..<ticks).map { i in
            let a = start + (end - start) * Double(i) / Double(ticks - 1)
            let tilt = i % 2 == 0 ? 0.16 : -0.16
            return StitchSegment(
                from: CGPoint(x: tenth(cx + (r - 4.5) * cos(a - tilt * 0.1)), y: tenth(cy - (r - 4.5) * sin(a - tilt * 0.1))),
                to: CGPoint(x: tenth(cx + (r + 4.5) * cos(a + tilt)), y: tenth(cy - (r + 4.5) * sin(a + tilt))))
        }
    }
}

/// SeamGuide: section-scoped stitching in the seam's red. `tear` is the full-width
/// row between sections, `underline` the short run under a heading, `orbit` the
/// arc that closes the archive. It draws in once, left to right, as it arrives;
/// under Reduce Motion it is simply there. Decorative.
struct SeamGuide: View {
    enum Variant { case tear, underline, orbit }

    var variant: Variant = .tear

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stitched = false

    var body: some View {
        stitches
            .mask(alignment: .leading) {
                GeometryReader { geo in
                    Rectangle().frame(width: stitched || reduceMotion ? geo.size.width : 0)
                }
            }
            .onAppear {
                guard !stitched, !reduceMotion else { return }
                withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.9)) { stitched = true }
            }
            .accessibilityHidden(true)
    }

    @ViewBuilder private var stitches: some View {
        switch variant {
        case .underline:
            canvas(StitchGeometry.row(width: 150, count: 9), box: CGSize(width: 150, height: 16))
                .frame(width: 150, height: 16)
        case .orbit:
            canvas(StitchGeometry.arc(), box: CGSize(width: 100, height: 64))
                .frame(width: 100, height: 64)
        case .tear:
            canvas(StitchGeometry.row(width: 1200, count: 68), box: CGSize(width: 1200, height: 16))
                .frame(maxWidth: .infinity)
                .frame(height: 16)
        }
    }

    /// The SVG's `xMidYMid slice` (rows) and `meet` (the arc), clipped to its box.
    private func canvas(_ segments: [StitchSegment], box: CGSize) -> some View {
        Canvas { context, size in
            let scale = variant == .orbit
                ? min(size.width / box.width, size.height / box.height)
                : max(size.width / box.width, size.height / box.height)
            let dx = (size.width - box.width * scale) / 2
            let dy = (size.height - box.height * scale) / 2
            var path = Path()
            for s in segments {
                path.move(to: CGPoint(x: dx + s.from.x * scale, y: dy + s.from.y * scale))
                path.addLine(to: CGPoint(x: dx + s.to.x * scale, y: dy + s.to.y * scale))
            }
            context.stroke(path, with: .color(PitchAtlasTheme.seamBright),
                           style: StrokeStyle(lineWidth: 2 * scale, lineCap: .round))
        }
        .clipped()
    }
}

// MARK: - Breadcrumb

/// A crumb: a label and, for every crumb but the last, the site path it opens.
struct Crumb: Hashable {
    let label: String
    var path: String? = nil
    /// The hidden note the last crumb carries (a stage's specimen number).
    var note: HiddenNotePlacement? = nil
}

/// Breadcrumb.tsx: mono 11, upper case, tracked .14em; each crumb but the last
/// opens its page, the last is the page you are on, in bone. A craftsman's
/// stage sets its own inks (bone-2 at 80%, the page in bone-2).
struct Breadcrumb: View {
    let trail: [Crumb]
    var linkInk: Color = PitchAtlasTheme.ink2
    var currentInk: Color = PitchAtlasTheme.bone

    static let font = PitchAtlasType.font(.martian400, size: 11, relativeTo: .caption)
    static let tracking: CGFloat = 11 * 0.14

    var body: some View {
        FlowRow(spacing: 8, lineSpacing: 10) {
            ForEach(Array(trail.enumerated()), id: \.offset) { index, crumb in
                let last = index == trail.count - 1
                HStack(spacing: 8) {
                    if let path = crumb.path, !last {
                        RouteButton(path: path) {
                            Text(crumb.label.uppercased())
                                .foregroundStyle(linkInk)
                                // the site's touch rule: a 44pt target that keeps the line's height
                                .padding(.vertical, 14)
                                .contentShape(Rectangle())
                                .padding(.vertical, -14)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens \(crumb.label)")
                    } else if last, let note = crumb.note {
                        EggButton(note: note) {
                            Text(crumb.label.uppercased()).foregroundStyle(currentInk)
                        }
                    } else {
                        Text(crumb.label.uppercased())
                            .foregroundStyle(last ? currentInk : linkInk)
                            .accessibilityAddTraits(last ? .isSelected : [])
                    }
                    if !last {
                        Text("/").foregroundStyle(linkInk).accessibilityHidden(true)
                    }
                }
            }
        }
        .font(Self.font)
        .tracking(Self.tracking)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Breadcrumb")
    }
}

// MARK: - Balanced lines

/// CSS `text-wrap: balance` for a heading: the narrowest width (not under half
/// the offered one) that keeps the same number of lines, so a two-line title
/// breaks near its middle instead of leaving one word alone.
struct BalancedLines: Layout {
    /// The narrowest width in `[full / 2, full]` whose height matches the full
    /// width's, found by bisection to a quarter point.
    static func balancedWidth(full: CGFloat, height: (CGFloat) -> CGFloat) -> CGFloat {
        guard full.isFinite, full > 0 else { return full }
        let target = height(full)
        var lo = full / 2, hi = full
        if height(lo) <= target { return lo }
        while hi - lo > 0.25 {
            let mid = (lo + hi) / 2
            if height(mid) <= target { hi = mid } else { lo = mid }
        }
        return hi.rounded(.up)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let text = subviews.first else { return .zero }
        guard let full = proposal.width, full.isFinite else { return text.sizeThatFits(proposal) }
        let width = Self.balancedWidth(full: full) { text.sizeThatFits(ProposedViewSize(width: $0, height: nil)).height }
        return text.sizeThatFits(ProposedViewSize(width: width, height: nil))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let text = subviews.first else { return }
        text.place(at: bounds.origin, proposal: ProposedViewSize(width: bounds.width, height: bounds.height))
    }
}

// MARK: - Section hero

/// The wash a section hero takes: powder for the living catalog and the
/// craftsmen, seam for the lost pitches.
enum ArchiveAccent { case powder, seam }

/// SectionHero.tsx: the chapter header on the void field.
struct SectionHero<Badge: View, Extra: View>: View {
    let eyebrow: String
    let title: Text
    var sub: Text? = nil
    var trail: [Crumb] = []
    var accent: ArchiveAccent = .powder
    /// `atmoClassName`: an atmosphere plate over the field (About's archive paper).
    var atmosphere: AtmospherePlate? = nil
    @ViewBuilder var badge: Badge
    @ViewBuilder var extra: Extra

    @State private var width: CGFloat = 440

    /// `clamp(2.2rem, 8.5vw, 4.8rem)` on the page's width.
    static func titleSize(width: CGFloat) -> CGFloat { min(76.8, max(35.2, width * 0.085)) }
    static var subSize: CGFloat { 18 }

    var body: some View {
        let size = Self.titleSize(width: width)
        VStack(alignment: .leading, spacing: 0) {
            if !trail.isEmpty {
                Breadcrumb(trail: trail).padding(.bottom, 24)
            }
            KickerLabel(text: eyebrow)
            if Badge.self != EmptyView.self {
                badge.padding(.top, 16)
            }
            BalancedLines {
                title
                    .font(PitchAtlasType.font(.newsreader400, size: size, relativeTo: .largeTitle))
                    .tracking(-0.035 * size)
                    .lineSpacing(0.02 * size)
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .fixedSize(horizontal: false, vertical: true)
                    // already display size: inside the accessibility sizes a single
                    // word ("underneath") outgrows the balanced measure and splits
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
            .frame(maxWidth: 18 * 0.5665 * size, alignment: .leading)
            .padding(.top, 20)
            .accessibilityAddTraits(.isHeader)
            SeamGuide(variant: .underline).padding(.top, 24)
            if let sub {
                // text-lg, leading-relaxed: the line box's half-leading sits above
                // the first line and below the last.
                sub
                    .font(PitchAtlasType.font(.newsreader400, size: Self.subSize, relativeTo: .title3))
                    .lineSpacing(Self.subSize * (1.625 - 1))
                    .foregroundStyle(PitchAtlasTheme.ink2)
                    .frame(maxWidth: 60 * 0.5665 * Self.subSize, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, Self.subSize * 0.625 / 2)
                    .padding(.top, 24)
            }
            extra
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 48)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                SectionHeroField(accent: accent)
                atmosphere
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(PitchAtlasTheme.bone.opacity(0.12)).frame(height: 1).accessibilityHidden(true)
        }
        .readsWidth(into: $width)
    }
}

extension SectionHero where Badge == EmptyView, Extra == EmptyView {
    init(eyebrow: String, title: Text, sub: Text? = nil, trail: [Crumb] = [], accent: ArchiveAccent = .powder,
         atmosphere: AtmospherePlate? = nil) {
        self.init(eyebrow: eyebrow, title: title, sub: sub, trail: trail, accent: accent, atmosphere: atmosphere,
                  badge: { EmptyView() }, extra: { EmptyView() })
    }
}

extension SectionHero where Badge == EmptyView {
    init(eyebrow: String, title: Text, sub: Text? = nil, trail: [Crumb] = [], accent: ArchiveAccent = .powder,
         atmosphere: AtmospherePlate? = nil, @ViewBuilder extra: () -> Extra) {
        self.init(eyebrow: eyebrow, title: title, sub: sub, trail: trail, accent: accent, atmosphere: atmosphere,
                  badge: { EmptyView() }, extra: extra)
    }
}

/// `.pa-atmo`: a macro cut from Austin's own game ball, a whisper over a hero's
/// field — cover-fit, centered, faded at its edges by
/// radial-gradient(110% 90% at 50% 40%, #000 30%, transparent 95%).
struct AtmospherePlate: View {
    let src: String
    let opacity: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            if let image = BundledImage.load(src) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()
                    .mask {
                        let rx = max(w * 1.1, 1), ry = max(h * 0.9, 1)
                        RadialGradient(stops: [.init(color: .black, location: 0.3), .init(color: .clear, location: 0.95)],
                                       center: .center, startRadius: 0, endRadius: rx)
                            .frame(width: rx * 2, height: rx * 2)
                            .scaleEffect(x: 1, y: ry / rx)
                            .position(x: w * 0.5, y: h * 0.4)
                    }
                    .opacity(opacity)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// `.archive-section-hero`'s field: #141411 under a faint accent wash at 70% 30%
/// and the scorebook's vertical rules every 64pt, the two at half strength.
struct SectionHeroField: View {
    let accent: ArchiveAccent

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            // `circle at 70% 30%` reaches to the farthest corner; the wash fades out by 40%.
            let reach = hypot(size.width * 0.7, size.height * 0.7)
            ZStack {
                ArchiveInk.sectionHeroField
                ZStack {
                    RadialGradient(colors: [accent == .seam ? ArchiveInk.heroWashSeam : ArchiveInk.heroWashPowder, .clear],
                                   center: UnitPoint(x: 0.7, y: 0.3), startRadius: 0, endRadius: reach * 0.4)
                    ScorebookRules(spacing: 64)
                }
                .opacity(0.5)
            }
        }
        .accessibilityHidden(true)
    }
}

/// The scorebook's vertical rules: a 1pt bone line at 7% every `spacing` points.
struct ScorebookRules: View {
    var spacing: CGFloat = 64

    var body: some View {
        Canvas { context, size in
            var x: CGFloat = 0
            var path = Path()
            while x < size.width {
                path.addRect(CGRect(x: x, y: 0, width: 1, height: size.height))
                x += spacing
            }
            context.fill(path, with: .color(PitchAtlasTheme.bone.opacity(0.07)))
        }
        .accessibilityHidden(true)
    }
}

// MARK: - The bound paper

/// A CSS `linear-gradient(<angle>)` line as unit points on a box: through its
/// center, at the angle (0° up, 90° right), long enough that the far corners
/// fall on 0% and 100%.
enum CSSGradientLine {
    static func points(degrees: Double, size: CGSize) -> (start: UnitPoint, end: UnitPoint) {
        let radians = degrees * .pi / 180
        let dx = sin(radians), dy = -cos(radians)
        let w = max(size.width, 1), h = max(size.height, 1)
        let half = (abs(w * dx) + abs(h * dy)) / 2
        return (UnitPoint(x: 0.5 - dx * half / w, y: 0.5 - dy * half / h),
                UnitPoint(x: 0.5 + dx * half / w, y: 0.5 + dy * half / h))
    }
}

/// `.archive-paper`'s stock: linear-gradient(120deg, #222327, #17171a).
struct PaperStock: View {
    var body: some View {
        GeometryReader { geo in
            let line = CSSGradientLine.points(degrees: 120, size: geo.size)
            LinearGradient(colors: [ArchiveInk.paperStockTop, ArchiveInk.paperStockBottom],
                           startPoint: line.start, endPoint: line.end)
        }
        .accessibilityHidden(true)
    }
}

extension View {
    /// `.archive-paper`: a bound reading section on charcoal stock between two
    /// hairlines (its border-block), the claim kit inside re-inked for it.
    func archivePaper() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 1)
            .background { PaperStock() }
            .overlay(alignment: .top) { Rectangle().fill(ArchiveInk.paperEdge).frame(height: 1).accessibilityHidden(true) }
            .overlay(alignment: .bottom) { Rectangle().fill(ArchiveInk.paperEdge).frame(height: 1).accessibilityHidden(true) }
            .inkContext(.paper)
    }
}

// MARK: - Width

private struct ArchiveWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

extension View {
    /// Reports this view's laid-out width (the site sizes type off the viewport).
    func readsWidth(into width: Binding<CGFloat>) -> some View {
        background {
            GeometryReader { geo in Color.clear.preference(key: ArchiveWidthKey.self, value: geo.size.width) }
        }
        .onPreferenceChange(ArchiveWidthKey.self) { if $0 > 0 { width.wrappedValue = $0 } }
    }
}
