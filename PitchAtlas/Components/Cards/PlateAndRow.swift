import SwiftUI
import simd

// =============================================================================
// Plates and index rows — Tier B and Tier C of the refractor family
// =============================================================================
// `.rfx-plate` (index.css 1988-2010, the catch at 3053-3063) is the directory
// card the Craftsmen and Lost Pitches halls file their arms and pitches on;
// `.rfx-entry` (1931-1972) is the Pitch Index row. Both are dark objects, so
// secondary type inside them reads bone-2 / bone-3 (`.inkContext(.object)`).
// Touch has no hover, so neither lifts; the web's :hover never fires on a phone.
// =============================================================================

/// How an entry rests: seeded off its id, never the clock (web PitchIndex.tsx
/// `restFor`): h = (h·31 + UTF-16 code) mod 1000, then sin(h), in −1…1.
func restFor(_ id: String) -> Double {
    var h = 0
    for unit in id.utf16 { h = (h * 31 + Int(unit)) % 1000 }
    return sin(Double(h))
}

/// `box-shadow: 0 y blur spread color` outside an object. The shape grows by
/// `spread` (a negative spread shrinks it, so the shadow only peeks out below),
/// then is offset and blurred; a CSS blur radius is twice the deviation.
private struct DropShadow: View {
    let radius: CGFloat
    let y: CGFloat
    let blur: CGFloat
    let spread: CGFloat
    let color: Color
    var body: some View {
        RoundedRectangle(cornerRadius: max(0, radius + spread), style: .continuous)
            .fill(color)
            .padding(-spread)
            .offset(y: y)
            .blur(radius: blur / 2)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }
}

/// The plates' mono micro-label (`.mono-label`): Martian 11, 0.18em, uppercase.
struct PlateMono: View {
    let text: String
    let ink: AnyShapeStyle
    init<S: ShapeStyle>(_ text: String, ink: S) {
        self.text = text
        self.ink = AnyShapeStyle(ink)
    }
    var body: some View {
        Text(text)
            .font(PitchAtlasType.font(.martian400, size: 11, relativeTo: .caption2))
            .tracking(em: 0.18, size: 11)
            .textCase(.uppercase)
            .foregroundStyle(ink)
    }
}

// MARK: - Tier B plate

enum PlateVariant: Equatable {
    /// is-filed: a filed specimen (gold). is-edge: banned / alias / illusion / lost.
    /// is-dashed: a may-not-exist or showman frame.
    case standard, filed, edge, dashed, edgeDashed

    var isDashed: Bool { self == .dashed || self == .edgeDashed }
}

/// Tier B `.rfx-plate`: a matte 160° field tinted 8% by the accent, a 3pt accent
/// lip inside the top edge, a bottom inner shade, the raking catch with a 16%
/// accent rim, and a black .55 hairline (dashed for a may-not-exist frame).
struct Plate<Content: View>: View {
    static func edgeColor(accent: Color, variant: PlateVariant) -> Color {
        switch variant {
        case .filed: ComponentInk.filedBone.opacity(0.82)
        case .edge, .edgeDashed: PitchAtlasTheme.seamBright.opacity(0.82)
        case .standard, .dashed: accent.opacity(0.78)
        }
    }

    let accent: Color
    let variant: PlateVariant
    /// The plate's corner: 13 on a directory plate, 6 on a "Keep reading" link.
    var radius: CGFloat
    /// The corner ticks; a featured or link plate goes without.
    var ticks: Bool
    /// The site's 20pt padding inside its 1pt border: the content sits 21 in.
    var insets: EdgeInsets
    var alignment: HorizontalAlignment
    var spacing: CGFloat
    let content: Content

    init(accent: Color, variant: PlateVariant = .standard, radius: CGFloat = PitchAtlasRadius.plate,
         ticks: Bool = true, insets: EdgeInsets = EdgeInsets(top: 21, leading: 21, bottom: 21, trailing: 21),
         alignment: HorizontalAlignment = .leading, spacing: CGFloat = 14, @ViewBuilder content: () -> Content) {
        self.accent = accent
        self.variant = variant
        self.radius = radius
        self.ticks = ticks
        self.insets = insets
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) { content }
            .padding(insets)
            .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
            .overlay(alignment: .topLeading) { if ticks { CornerTick().padding(10) } }
            .overlay(alignment: .topTrailing) { if ticks { CornerTick().scaleEffect(x: -1).padding(10) } }
            .background { PlateField(accent: accent, variant: variant, radius: radius) }
            .inkContext(.object)
    }
}

private struct PlateField: View {
    let accent: Color
    let variant: PlateVariant
    let radius: CGFloat
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        GeometryReader { geo in
            let aspect = geo.size.width / max(geo.size.height, 1)
            let field = variant == .filed
                ? Self.linear(120, aspect, [.init(color: ComponentInk.filedBone.opacity(0.10), location: 0),
                                            .init(color: PitchAtlasTheme.press, location: 1)])
                : Self.linear(160, aspect, [.init(color: accent.mix(ComponentInk.plateBase, 0.92), location: 0),
                                            .init(color: ComponentInk.plateEnd, location: 1)])
            shape
                .fill(field
                    .shadow(.inner(color: Plate<EmptyView>.edgeColor(accent: accent, variant: variant), radius: 0, x: 0, y: 3))
                    .shadow(.inner(color: .black.opacity(0.45), radius: 3, x: 0, y: -2)))
                .overlay {
                    // the raking catch: a narrow bone band raked off the top-left, screen-blended
                    shape.fill(Self.linear(101, aspect, [.init(color: .clear, location: 0.06),
                                                         .init(color: PitchAtlasTheme.bone.opacity(0.16), location: 0.20),
                                                         .init(color: .clear, location: 0.40)]))
                        .blendMode(.screen).opacity(0.55)
                }
                .overlay { shape.inset(by: 1).strokeBorder(accent.opacity(0.16), lineWidth: 1) }
                .overlay {
                    shape.strokeBorder(Color.black.opacity(0.55),
                                       style: StrokeStyle(lineWidth: 1, dash: variant.isDashed ? [3, 3] : []))
                }
        }
        .background { DropShadow(radius: radius, y: 16, blur: 30, spread: -22, color: .black.opacity(0.8)) }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    static func linear(_ angle: Double, _ aspect: CGFloat, _ stops: [Gradient.Stop]) -> LinearGradient {
        let ends = PitchAtlasMaterials.cssEndpoints(angle: angle, aspect: aspect)
        return LinearGradient(stops: stops, startPoint: ends.start, endPoint: ends.end)
    }
}

/// The 12pt corner tick a plate wears top-left and top-right (white .15).
private struct CornerTick: View {
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: 0.5, y: 12))
            p.addLine(to: CGPoint(x: 0.5, y: 0.5))
            p.addLine(to: CGPoint(x: 12, y: 0.5))
        }
        .stroke(Color.white.opacity(0.15), lineWidth: 1)
        .frame(width: 12, height: 12)
        .accessibilityHidden(true)
    }
}

// MARK: - Tier C index row

enum IndexRowStyle {
    enum Tone: Equatable { case seam, quiet, bone2 }

    /// The web STATUS map: bone-2 for the field tiers, seam for banned, ink-3 for
    /// the things that are not quite pitches.
    static func statusTone(_ status: RepertoireStatus) -> Tone {
        switch status {
        case .banned: .seam
        case .alias, .illusion, .notAPitch: .quiet
        case .standard, .niche, .rare, .nearExtinct: .bone2
        }
    }

    /// ink-3 inside the row resolves to the dark-object scope's #969080, not the void's.
    static func statusInk(_ status: RepertoireStatus) -> AnyShapeStyle {
        switch statusTone(status) {
        case .seam: AnyShapeStyle(PitchAtlasTheme.seamBright)
        case .quiet: AnyShapeStyle(PitchAtlasTheme.text3)
        case .bone2: AnyShapeStyle(PitchAtlasTheme.bone2)
        }
    }

    static func topRule(filed: Bool) -> CGFloat { filed ? 2 : 0 }
    static func topRadius(filed: Bool) -> CGFloat { filed ? 0 : PitchAtlasRadius.indexRow }

    /// A filed pitch wears its own specimen world; a basic file wears the family ink.
    static func markTint(for entry: RepertoireEntry) -> Color {
        entry.filedSlug.map { Color(rgb: PitchAccents.triad(for: $0).c3) } ?? entry.family.accent
    }

    /// The aliases are load-bearing for pitch identity, so VoiceOver hears every one.
    static func accessibilityLabel(for entry: RepertoireEntry) -> String {
        var parts = [entry.name, entry.family.label, entry.filedSlug == nil ? "Basic file" : "Filed specimen",
                     entry.status.displayLabel]
        if let aka = entry.aka, !aka.isEmpty { parts.append("also known as \(aka.joined(separator: ", "))") }
        return parts.joined(separator: ", ")
    }
}

/// Tier C `.rfx-entry`: warm charcoal with the family accent glowing off the
/// top-left, a woven hatch at .13, the status outlined top-right; filed rows
/// trade the top corners for a 2pt family-accent rule over a paper wash.
struct IndexRow: View {
    let entry: RepertoireEntry
    @Environment(PitchStore.self) private var store

    var body: some View {
        let filed = entry.filedSlug != nil
        let grip = store.gripEntry(forRepertoire: entry)
        // the same photo the binder pocket resolves: first still, else the film's poster
        let still = grip?.photos.first?.src ?? grip?.film?.poster
        let rest = restFor(entry.id)
        let tint = IndexRowStyle.markTint(for: entry)
        HStack(alignment: .top, spacing: 13) {
            if let still {
                GripThumb(src: still, tint: tint, rest: rest)
            } else {
                IndexSeamMark(tint: tint, turn: rest * 48)
            }
            VStack(alignment: .leading, spacing: 0) {
                nameLine(filed: filed)
                if let aka = entry.aka, !aka.isEmpty {
                    Text(aka.joined(separator: ", "))
                        .font(PitchAtlasType.font(.hanken400, size: 11.5, relativeTo: .caption))
                        .foregroundStyle(PitchAtlasTheme.text3)
                        .cssLineHeight(1.375, face: .hanken400, size: 11.5, relativeTo: .caption)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
                if let grip {
                    Text(grip.shortCue)
                        .font(PitchAtlasType.font(.hanken400i, size: 13, relativeTo: .subheadline))
                        .foregroundStyle(PitchAtlasTheme.bone2)
                        .cssLineHeight(1.375, face: .hanken400i, size: 13, relativeTo: .subheadline)
                        .lineLimit(2)
                        .padding(.top, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { IndexRowField(accent: entry.family.accent, filed: filed) }
        .inkContext(.object)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(IndexRowStyle.accessibilityLabel(for: entry))
        .accessibilityAddTraits(.isButton)
    }

    /// Name and the Filed tag on one line when they fit, the tag beneath when they
    /// don't (the web's flex-wrap, gap 8). The status badge holds the top-right
    /// corner and the name keeps clear of it: the site's pr-20 at least, more when
    /// the badge runs wider than 72 — on the site a long name runs under "Not a pitch".
    private func nameLine(filed: Bool) -> some View {
        let name = Text(entry.name)
            .font(PitchAtlasType.font(.hanken700, size: 15, relativeTo: .headline))
            .foregroundStyle(PitchAtlasTheme.bone)
            .cssLineHeight(1.5, face: .hanken700, size: 15, relativeTo: .headline)
        return HStack(alignment: .top, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    name.fixedSize()
                    if filed { FiledTag() }
                }
                VStack(alignment: .leading, spacing: 8) {
                    name.fixedSize(horizontal: false, vertical: true)
                    if filed { FiledTag() }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            StatusOutline(status: entry.status)
                .frame(minWidth: 72, alignment: .trailing)
                // the row pads 16 and 15; the site pins the badge 14 in from both
                .offset(x: 2, y: -1)
        }
    }
}

/// The row's "Filed" tag: filed bone, mono 10 at 0.1em, radius 4.
private struct FiledTag: View {
    var body: some View {
        Text("Filed")
            .font(PitchAtlasType.font(.martian500, size: 10, relativeTo: .caption2))
            .tracking(em: 0.1, size: 10)
            .textCase(.uppercase)
            .foregroundStyle(ComponentInk.filedInk)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(ComponentInk.filedBone))
            .fixedSize()
    }
}

/// The status, outlined in its own ink: a 20pt pill, mono 9.5 at 0.08em.
private struct StatusOutline: View {
    let status: RepertoireStatus
    var body: some View {
        let ink = IndexRowStyle.statusInk(status)
        Text(status.displayLabel)
            .font(PitchAtlasType.font(.martian500, size: 9.5, relativeTo: .caption2))
            .tracking(em: 0.08, size: 9.5)
            .textCase(.uppercase)
            .foregroundStyle(ink)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .frame(minHeight: 20)
            .overlay(Capsule().strokeBorder(ink, lineWidth: 1))
            .fixedSize()
    }
}

private struct IndexRowField: View {
    let accent: Color
    let filed: Bool
    var body: some View {
        let top = IndexRowStyle.topRadius(filed: filed)
        let r = PitchAtlasRadius.indexRow
        let shape = UnevenRoundedRectangle(topLeadingRadius: top, bottomLeadingRadius: r,
                                           bottomTrailingRadius: r, topTrailingRadius: top, style: .continuous)
        GeometryReader { geo in
            let aspect = geo.size.width / max(geo.size.height, 1)
            ZStack {
                if filed {
                    shape.fill(PlateField.linear(120, aspect, [.init(color: ComponentInk.filedBone.opacity(0.13), location: 0),
                                                               .init(color: PitchAtlasTheme.press, location: 1)]))
                } else {
                    shape.fill(PlateField.linear(120, aspect, [.init(color: accent.mix(PitchAtlasTheme.press, 0.9), location: 0),
                                                               .init(color: PitchAtlasTheme.press, location: 1)]))
                    shape.fill(PlateField.linear(135, aspect, [.init(color: .white.opacity(0.05), location: 0),
                                                               .init(color: .clear, location: 0.28)]))
                }
                // radial-gradient(140% 100% at 0% 0%): the family accent off the top-left
                RadialGradient(colors: [accent.opacity(filed ? 0.16 : 0.18), .clear], center: .topLeading,
                               startRadius: 0, endRadius: geo.size.height * 0.44)
                    .scaleEffect(x: 1.4 * geo.size.width / max(geo.size.height, 1), y: 1, anchor: .topLeading)
                    .clipShape(shape)
                WovenHatch(accent: accent).opacity(0.13).blendMode(.screen).clipShape(shape)
                // inset 0 1px 0 white .08, and the soft shade at the foot
                shape.fill(Color.clear.shadow(.inner(color: .white.opacity(0.08), radius: 0, x: 0, y: 1)))
                LinearGradient(colors: [.clear, .black.opacity(0.14)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 20).frame(maxHeight: .infinity, alignment: .bottom).clipShape(shape)
                shape.strokeBorder(filed ? ComponentInk.filedBone.opacity(0.42) : Color.white.opacity(0.09), lineWidth: 1)
                if filed {
                    Rectangle().fill(accent).frame(height: IndexRowStyle.topRule(filed: true))
                        .frame(maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .background { DropShadow(radius: PitchAtlasRadius.indexRow, y: 16, blur: 28, spread: -24, color: .black.opacity(0.82)) }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// The row's woven ground: bone threads at 45° every 8pt, accent threads at −45° every 18pt.
private struct WovenHatch: View {
    let accent: Color
    var body: some View {
        ZStack {
            Hatch(angle: 45, spacing: 8).stroke(PitchAtlasTheme.bone.opacity(0.75), lineWidth: 1)
            Hatch(angle: -45, spacing: 18).stroke(accent.opacity(0.6), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}

/// A real grip photograph at thumbnail scale, leaning its own degree; a missing
/// file falls back to the seam mark, never a broken-image hole in the column.
struct GripThumb: View {
    let src: String
    let tint: Color
    let rest: Double
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        if let image = BundledImage.load(src) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .background(ComponentInk.thumbFill)
                .clipShape(shape)
                .overlay(shape.inset(by: -0.5).stroke(tint.opacity(0.38), lineWidth: 1))
                .rotationEffect(.degrees(rest * 2))
                .accessibilityHidden(true)
        } else {
            IndexSeamMark(tint: tint, turn: rest * 48)
        }
    }
}

/// The unphotographed mark: a dark leather disc carrying the real projected seam
/// (the same curve every 2D ball is drawn from), inked in the entry's accent and
/// set down at its own turn. Static; the rotation is how the ball rests.
struct IndexSeamMark: View {
    struct Run: Equatable {
        let front: Bool
        /// Unit-disc coordinates, y down.
        let points: [CGPoint]
    }

    /// The oriented seam (SEAM_VIEW_TILT), 160 segments, split into front and back
    /// runs once and shared by every mark (web MARK_SEAM).
    static let runs: [Run] = {
        var runs: [Run] = []
        var current: [CGPoint] = []
        var currentFront: Bool?
        for i in 0...160 {
            let t = Double(i) / 160 * 2 * .pi
            let p = SeamMath.rotate(SeamMath.seamPoint(t), aboutAxis: SeamMath.viewTiltAxis, by: SeamMath.viewTiltAngle)
            let point = CGPoint(x: p.x, y: -p.y)
            let front = p.z >= 0
            if let face = currentFront, face != front {
                current.append(point)
                runs.append(Run(front: face, points: current))
                current = [point]
            } else {
                current.append(point)
            }
            currentFront = front
        }
        if current.count > 1 { runs.append(Run(front: currentFront ?? true, points: current)) }
        return runs
    }()

    let tint: Color
    let turn: Double

    var body: some View {
        ZStack {
            Circle().fill(ComponentInk.seamMarkDisc).frame(width: 27.6, height: 27.6)
            Circle().stroke(tint.opacity(0.38), lineWidth: 1).frame(width: 27.6, height: 27.6)
            ZStack {
                MarkSeam(front: false).stroke(tint.opacity(0.26), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                MarkSeam(front: true).stroke(tint.opacity(0.9), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
            .rotationEffect(.degrees(turn))
        }
        .frame(width: 40, height: 40)
        .accessibilityHidden(true)
    }
}

private struct MarkSeam: Shape {
    let front: Bool
    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) * 13.2 / 40
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        for run in IndexSeamMark.runs where run.front == front {
            guard let first = run.points.first else { continue }
            path.move(to: CGPoint(x: c.x + first.x * r, y: c.y + first.y * r))
            for p in run.points.dropFirst() { path.addLine(to: CGPoint(x: c.x + p.x * r, y: c.y + p.y * r)) }
        }
        return path
    }
}

// MARK: - The craftsman's era

/// The real years in a craftsman's era string (web lib/era.ts). Nothing is
/// invented: a span that cannot be read is nil and the band is simply omitted.
struct EraSpan: Equatable {
    let start: Int
    /// nil = open-ended ("present"): the bar runs to the axis edge with an open cap.
    let end: Int?

    /// The fixed window the careers are laid against — a still frame, not a clock.
    static let axis = (start: 1925.0, end: 2030.0)
    private static let fourDigits = try! NSRegularExpression(pattern: "[0-9]{4}")

    static func parse(_ era: String) -> EraSpan? {
        let text = era as NSString
        let years = fourDigits.matches(in: era, range: NSRange(location: 0, length: text.length))
            .compactMap { Int(text.substring(with: $0.range)) }
        guard let start = years.first else { return nil }
        if years.count == 1, era.range(of: "present|active|since|now", options: [.regularExpression, .caseInsensitive]) != nil {
            return EraSpan(start: start, end: nil)
        }
        if years.count >= 2 { return EraSpan(start: start, end: years[1]) }
        // a lone year with no open cue ("Designed 2001") is a single point
        return EraSpan(start: start, end: start)
    }

    /// Fractional position 0…1 of a year along the fixed axis.
    static func axisPosition(_ year: Double) -> Double {
        min(1, max(0, (year - axis.start) / (axis.end - axis.start)))
    }
}

/// The era band: the still axis with this arm's active years lit in his
/// signature-pitch accent. The bar's length is the career's length; an open
/// career runs to the edge and fades. Decorative — the era text says it exactly.
struct EraBand: View {
    let span: EraSpan
    let accent: Color

    static func geometry(_ span: EraSpan) -> (left: Double, width: Double, open: Bool) {
        let left = EraSpan.axisPosition(Double(span.start))
        let right = span.end.map { EraSpan.axisPosition(Double($0)) } ?? 1
        return (left, max(0.025, right - left), span.end == nil)
    }

    var body: some View {
        let g = Self.geometry(span)
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.white.opacity(0.07))
                ForEach(1...4, id: \.self) { q in
                    Rectangle().fill(Color.white.opacity(0.10)).frame(width: 1)
                        .offset(x: w * CGFloat(q) / 4 - 1)
                }
                Capsule()
                    .fill(g.open
                          ? AnyShapeStyle(LinearGradient(stops: [.init(color: accent, location: 0.6),
                                                                 .init(color: accent.opacity(0.12), location: 1)],
                                                         startPoint: .leading, endPoint: .trailing))
                          : AnyShapeStyle(accent))
                    .frame(width: w * g.width)
                    .shadow(color: accent.opacity(0.45), radius: 3)
                    .offset(x: w * g.left)
            }
            .clipShape(Capsule())
        }
        .frame(height: 5)
        .padding(.top, 10)
        .accessibilityHidden(true)
    }
}

// MARK: - Craftsman plate

enum CraftsmanPlate {
    /// The master wears his signature pitch's accent; the legend takes the one teal
    /// jolt so it never reads as a verified person.
    static func accentRGB(_ c: Craftsman) -> UInt32 {
        if c.kind == .legend { return WebTokens.Palette.tealGlow.rgb }
        return c.signaturePitchSlug.map { PitchAccents.triad(for: $0).c3 } ?? WebTokens.Palette.cyan.rgb
    }

    static func labelInk(_ c: Craftsman) -> Color {
        c.kind == .legend ? Color(web: WebTokens.Palette.tealGlow) : PitchAccents.accentInk(accentRGB(c))
    }

    static func label(_ c: Craftsman) -> String { "\(c.kind == .legend ? "Legend" : "Master") · \(c.specimenNo)" }

    static func variant(_ c: Craftsman) -> PlateVariant { c.kind == .legend ? .dashed : .standard }

    /// A master charts against history by his real era; the legend is a design, not a career.
    static func span(_ c: Craftsman) -> EraSpan? { c.kind == .legend ? nil : EraSpan.parse(c.era) }

    static func footerNotes(_ c: Craftsman, hasFilm: Bool) -> [String] {
        (hasFilm ? ["Film filed"] : []) + (c.hand.map { ["\($0.rawValue.capitalized)-handed"] } ?? [])
    }

    static func accessibilityLabel(_ c: Craftsman, hasFilm: Bool) -> String {
        let kind = c.kind == .legend ? "Legend" : "Master"
        let parts: [String] = [kind, c.specimenNo, c.name, c.signaturePitch, c.era] + footerNotes(c, hasFilm: hasFilm)
        return parts.joined(separator: ", ") + ". " + c.tagline
    }
}

/// A craftsman, filed as a Tier B plate. When the atlas has his signature pitch on
/// file, its seam schematic is the card's actor — never a player likeness.
struct CraftsmanCard: View {
    let craftsman: Craftsman
    @Environment(PitchStore.self) private var store

    var body: some View {
        let accent = Color(rgb: CraftsmanPlate.accentRGB(craftsman))
        let signature = craftsman.signaturePitchSlug.flatMap { store.pitch(slug: $0) }
        let hasFilm = !store.craftsmanMedia(forCraftsman: craftsman.slug).isEmpty
        Plate(accent: accent, variant: CraftsmanPlate.variant(craftsman)) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    PlateMono(CraftsmanPlate.label(craftsman), ink: CraftsmanPlate.labelInk(craftsman))
                    Spacer(minLength: 0)
                    PlateMono(craftsman.era, ink: PitchAtlasTheme.text3)
                }
                if let span = CraftsmanPlate.span(craftsman) { EraBand(span: span, accent: accent) }
            }
            HStack(spacing: 16) {
                Group {
                    if let signature {
                        SeamBall(motion: signature.motion, size: 44, showMovement: false, showsLacing: false)
                    } else {
                        ArchiveSealMark(size: 48).opacity(0.8)
                    }
                }
                .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 6) {
                    // .rfx-platetitle under text-2xl: 24 on a 32 line, tighter than Anton's own box
                    TightLines(craftsman.name.uppercased(), face: .anton400, size: 24, lineHeight: 32.0 / 24.0,
                               relativeTo: .title2, trackingEm: 0.01)
                        .foregroundStyle(PitchAtlasTheme.bone)
                    PlateMono(craftsman.signaturePitch, ink: PitchAtlasTheme.bone2)
                }
            }
            Text(craftsman.tagline)
                .font(PitchAtlasType.body(size: 14))
                .lineSpacing(5)
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
            PlateFoot(notes: footNotes(hasFilm: hasFilm))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(CraftsmanPlate.accessibilityLabel(craftsman, hasFilm: hasFilm))
        .accessibilityAddTraits(.isButton)
    }

    /// Film in bone-2, the hand in ink-3 — the web's footer inks.
    private func footNotes(hasFilm: Bool) -> [PlateFoot.Note] {
        var notes: [PlateFoot.Note] = []
        if hasFilm { notes.append(.init(text: "Film filed", ink: AnyShapeStyle(PitchAtlasTheme.bone2))) }
        if let hand = craftsman.hand {
            notes.append(.init(text: "\(hand.rawValue.capitalized)-handed", ink: AnyShapeStyle(PitchAtlasTheme.text3)))
        }
        return notes
    }
}

// MARK: - Lost pitch plate

enum LostPitchPlate {
    static func kindLabel(_ kind: LostPitchKind) -> String {
        switch kind {
        case .pitch: "Lost pitch"
        case .pitcher: "The arm"
        case .doctored: "The doctored family"
        }
    }

    /// A legend takes the seam jolt and a dashed frame so a showman label never
    /// reads as a verified record.
    static func variant(_ pitch: LostPitch) -> PlateVariant { pitch.tier == .legend ? .edgeDashed : .standard }

    static func accessibilityLabel(_ pitch: LostPitch) -> String {
        let parts: [String] = [pitch.specimenNo, pitch.name, kindLabel(pitch.kind), pitch.tier.label, pitch.era]
        return parts.joined(separator: ", ") + ". " + pitch.tagline
    }
}

/// A lost pitch or an arm, filed as a Tier B plate on the sand archive accent. No
/// likeness, ever: the visual mark is the Atlas seal. The tier is the shelf the
/// plate is filed on, so the plate itself carries no tier pill (LostPitchCard.tsx).
struct LostPitchCard: View {
    let pitch: LostPitch

    var body: some View {
        let legend = pitch.tier == .legend
        Plate(accent: PitchAtlasTheme.sandBright, variant: LostPitchPlate.variant(pitch)) {
            // The number holds its width; the era takes the rest, wrapping there
            // when it runs long and pushed to the edge when it doesn't.
            HStack(alignment: .center, spacing: 12) {
                PlateMono(pitch.specimenNo, ink: legend ? PitchAtlasTheme.seamBright : PitchAtlasTheme.bone2)
                    .fixedSize()
                Spacer(minLength: 0)
                PlateMono(pitch.era, ink: PitchAtlasTheme.text3)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
            }
            HStack(spacing: 16) {
                ArchiveSealMark(size: 48).opacity(0.8)
                VStack(alignment: .leading, spacing: 6) {
                    TightLines(pitch.name.uppercased(), face: .anton400, size: 24, lineHeight: 32.0 / 24.0,
                               relativeTo: .title2, trackingEm: 0.01)
                        .foregroundStyle(PitchAtlasTheme.bone)
                    PlateMono(LostPitchPlate.kindLabel(pitch.kind), ink: PitchAtlasTheme.bone2)
                }
            }
            Text(pitch.tagline)
                .font(PitchAtlasType.body(size: 14))
                .lineSpacing(5)
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
            PlateFoot()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(LostPitchPlate.accessibilityLabel(pitch))
        .accessibilityAddTraits(.isButton)
    }
}

/// The plate's foot: a white .10 rule, then "Open the file →" in cyan 12pt below
/// it with any notes after a dot; at phone width the notes drop to their own line.
private struct PlateFoot: View {
    struct Note {
        let text: String
        let ink: AnyShapeStyle
    }
    var notes: [Note] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle().fill(Color.white.opacity(0.10)).frame(height: 1)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    open
                    ForEach(notes.indices, id: \.self) { i in
                        FootDot()
                        note(i)
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    open
                    HStack(spacing: 12) {
                        ForEach(notes.indices, id: \.self) { i in
                            if i > 0 { FootDot() }
                            note(i)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    open
                    ForEach(notes.indices, id: \.self) { i in note(i) }
                }
            }
        }
    }

    private var open: some View { PlateMono("Open the file →", ink: PitchAtlasTheme.cyan).fixedSize() }
    private func note(_ i: Int) -> some View { PlateMono(notes[i].text, ink: notes[i].ink).fixedSize() }
}

private struct FootDot: View {
    var body: some View {
        Text("·").font(PitchAtlasType.font(.martian400, size: 11)).foregroundStyle(PitchAtlasTheme.text3)
            .accessibilityHidden(true)
    }
}
