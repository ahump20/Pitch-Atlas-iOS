import SwiftUI

// =============================================================================
// TightLines — a title at the site's line-height, below the face's own box
// =============================================================================
// The site sets its athletic titles near line-height 1 (FieldNotes.tsx's band
// title is 1.02, a chapter title .98), but Anton's own line box is about 1.5 of
// its size and SwiftUI's Text cannot pull lines closer than that. So the words
// are broken into lines here, the way CSS breaks them (at spaces, and after a
// hyphen), and each line box is the CSS pitch tall with the face centered in
// it, overhanging above and below exactly as the web's line box does.
// =============================================================================

struct TightLines: View {
    struct Token: Equatable {
        let text: String
        /// A space follows before the next word (none after a hyphen break).
        let spaceAfter: Bool
    }

    let text: String
    let face: PitchAtlasType.Face
    let size: CGFloat
    /// CSS line-height, as a multiple of the size.
    let lineHeight: CGFloat
    var relativeTo: Font.TextStyle = .title2
    var trackingEm: CGFloat = 0
    /// Nil follows .multilineTextAlignment, as Text does.
    var alignment: TextAlignment?
    /// CSS text-wrap: balance.
    var balanced = false

    @ScaledMetric private var scaled: CGFloat
    @Environment(\.multilineTextAlignment) private var environmentAlignment

    init(_ text: String, face: PitchAtlasType.Face, size: CGFloat, lineHeight: CGFloat,
         relativeTo: Font.TextStyle = .title2, trackingEm: CGFloat = 0,
         alignment: TextAlignment? = nil, balanced: Bool = false) {
        self.text = text
        self.face = face
        self.size = size
        self.lineHeight = lineHeight
        self.relativeTo = relativeTo
        self.trackingEm = trackingEm
        self.alignment = alignment
        self.balanced = balanced
        _scaled = ScaledMetric(wrappedValue: size, relativeTo: relativeTo)
    }

    /// The break opportunities CSS uses here: runs of spaces collapse to one
    /// break, and a hyphen inside a word offers a break with no space.
    static func tokens(_ text: String) -> [Token] {
        var tokens: [Token] = []
        for word in text.split(whereSeparator: { $0.isWhitespace }) {
            var pieces: [String] = []
            var current = ""
            for (i, ch) in word.enumerated() {
                current.append(ch)
                if ch == "-", i < word.count - 1 {
                    pieces.append(current)
                    current = ""
                }
            }
            if !current.isEmpty { pieces.append(current) }
            for (i, piece) in pieces.enumerated() {
                tokens.append(Token(text: piece, spaceAfter: i == pieces.count - 1))
            }
        }
        if let last = tokens.last { tokens[tokens.count - 1] = Token(text: last.text, spaceAfter: false) }
        return tokens
    }

    var body: some View {
        let tokens = Self.tokens(text)
        TightLinesLayout(spaceAfter: tokens.map(\.spaceAfter), pitch: lineHeight * scaled,
                         alignment: alignment ?? environmentAlignment, balanced: balanced) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in word(token.text) }
            // The space's advance, measured once; a blank glyph, never seen.
            word("\u{00A0}")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    private func word(_ s: String) -> some View {
        Text(s)
            .font(PitchAtlasType.font(face, size: size, relativeTo: relativeTo))
            .tracking(trackingEm * scaled)
            .lineLimit(1)
            .fixedSize()
    }
}

/// Places the words of a TightLines: greedy CSS line breaking, an optional
/// balance, and each line at the CSS pitch. The last subview is the measured
/// space.
struct TightLinesLayout: Layout {
    let spaceAfter: [Bool]
    let pitch: CGFloat
    var alignment: TextAlignment = .leading
    var balanced = false

    /// Greedy line breaking: a word moves to the next line only when it would
    /// overflow this one; a word wider than the line still takes a line.
    static func lines(widths: [CGFloat], spaceAfter: [Bool], space: CGFloat, maxWidth: CGFloat) -> [Range<Int>] {
        var lines: [Range<Int>] = []
        var start = 0
        var lineWidth: CGFloat = 0
        for i in widths.indices {
            if i == start {
                lineWidth = widths[i]
                continue
            }
            let gap = spaceAfter[i - 1] ? space : 0
            if lineWidth + gap + widths[i] > maxWidth + 0.5 {
                lines.append(start..<i)
                start = i
                lineWidth = widths[i]
            } else {
                lineWidth += gap + widths[i]
            }
        }
        if !widths.isEmpty { lines.append(start..<widths.count) }
        return lines
    }

    static func width(of line: Range<Int>, widths: [CGFloat], spaceAfter: [Bool], space: CGFloat) -> CGFloat {
        line.reduce(0) { sum, i in
            sum + widths[i] + (i > line.lowerBound && spaceAfter[i - 1] ? space : 0)
        }
    }

    /// The narrowest width in [max / 2, max] that keeps the line count.
    static func balancedWidth(widths: [CGFloat], spaceAfter: [Bool], space: CGFloat, maxWidth: CGFloat) -> CGFloat {
        guard maxWidth.isFinite, maxWidth > 0 else { return maxWidth }
        let target = lines(widths: widths, spaceAfter: spaceAfter, space: space, maxWidth: maxWidth).count
        guard target > 1 else { return maxWidth }
        var lo = maxWidth / 2, hi = maxWidth
        if lines(widths: widths, spaceAfter: spaceAfter, space: space, maxWidth: lo).count <= target { return lo }
        while hi - lo > 0.25 {
            let mid = (lo + hi) / 2
            if lines(widths: widths, spaceAfter: spaceAfter, space: space, maxWidth: mid).count <= target { hi = mid } else { lo = mid }
        }
        return hi
    }

    static func height(lineCount: Int, pitch: CGFloat) -> CGFloat { CGFloat(lineCount) * pitch }

    /// The top of a line's own box: its CSS line box, with the face centered in it.
    static func lineTop(index: Int, pitch: CGFloat, natural: CGFloat) -> CGFloat {
        CGFloat(index) * pitch + (pitch - natural) / 2
    }

    private func measure(_ subviews: Subviews) -> (widths: [CGFloat], natural: CGFloat, space: CGFloat) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let words = sizes.dropLast()
        return (words.map(\.width), words.map(\.height).max() ?? 0, sizes.last?.width ?? 0)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let m = measure(subviews)
        var maxWidth = proposal.width ?? .infinity
        if balanced {
            maxWidth = Self.balancedWidth(widths: m.widths, spaceAfter: spaceAfter, space: m.space, maxWidth: maxWidth)
        }
        let lines = Self.lines(widths: m.widths, spaceAfter: spaceAfter, space: m.space, maxWidth: maxWidth)
        let widest = lines.map { Self.width(of: $0, widths: m.widths, spaceAfter: spaceAfter, space: m.space) }.max() ?? 0
        return CGSize(width: min(widest, proposal.width ?? widest), height: Self.height(lineCount: lines.count, pitch: pitch))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let m = measure(subviews)
        let lines = Self.lines(widths: m.widths, spaceAfter: spaceAfter, space: m.space, maxWidth: bounds.width)
        for (row, line) in lines.enumerated() {
            let lineWidth = Self.width(of: line, widths: m.widths, spaceAfter: spaceAfter, space: m.space)
            var x: CGFloat = switch alignment {
            case .leading: bounds.minX
            case .center: bounds.minX + (bounds.width - lineWidth) / 2
            case .trailing: bounds.maxX - lineWidth
            }
            let y = bounds.minY + Self.lineTop(index: row, pitch: pitch, natural: m.natural)
            for i in line {
                if i > line.lowerBound, spaceAfter[i - 1] { x += m.space }
                subviews[i].place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += m.widths[i]
            }
        }
        subviews.last?.place(at: bounds.origin, proposal: .unspecified)
    }

    /// The first and last lines' baselines, so a title sits on a row's baseline
    /// the way its CSS line box does (`items-baseline`). Left to the default,
    /// the measured space, placed at the top, would answer instead.
    func explicitAlignment(of guide: VerticalAlignment, in bounds: CGRect, proposal: ProposedViewSize,
                           subviews: Subviews, cache: inout ()) -> CGFloat? {
        guard guide == .firstTextBaseline || guide == .lastTextBaseline, subviews.count > 1 else { return nil }
        let m = measure(subviews)
        let lines = Self.lines(widths: m.widths, spaceAfter: spaceAfter, space: m.space, maxWidth: bounds.width)
        let row = guide == .firstTextBaseline ? 0 : max(lines.count - 1, 0)
        let baseline = subviews[0].dimensions(in: .unspecified)[VerticalAlignment.firstTextBaseline]
        return bounds.minY + Self.lineTop(index: row, pitch: pitch, natural: m.natural) + baseline
    }
}
