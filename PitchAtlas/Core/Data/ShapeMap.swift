import Foundation
import CoreGraphics

// =============================================================================
// ShapeMap — every filed pitch, placed by the direction it breaks
// =============================================================================
// Web: sections/MovementMap.tsx (its 640 × 500 field, the zones, the fan, the label
// offsets, the shape words) and the copy of pages/MovementMapPage.tsx. Drawn as the
// pitcher sees it from the mound: a right-hander's arm side lands on the right.
// Handedness is a mirror, not new data — it flips which side arm-side lands on and
// swaps the poles. A map of direction, never a measured magnitude.
// =============================================================================

enum ShapeMap {
    static let width: CGFloat = 640
    static let height: CGFloat = 500
    static let center = CGPoint(x: 320, y: 250)
    /// Horizontal zone offset (arm-side / glove-side) and vertical (ride / drop).
    static let column: CGFloat = 180
    static let row: CGFloat = 132
    /// The axis guides' half-extent.
    static let clamp: CGFloat = 220
    /// The invisible hit circle around a dot: it meets the fan's 38 spacing exactly.
    static let hitRadius: CGFloat = 19

    enum Anchor { case start, middle, end }

    struct LabelOffset: Equatable {
        let dx: CGFloat
        let dy: CGFloat
        let anchor: Anchor
    }

    struct Dot: Equatable {
        let entry: PitchAtlasEntry
        let point: CGPoint
        let label: LabelOffset
    }

    /// MovementMap's LABELS: the names set off the axis or off a neighbour.
    static let labels: [String: LabelOffset] = [
        "four-seam": LabelOffset(dx: 14, dy: 0, anchor: .start),
        "knuckleball": LabelOffset(dx: -14, dy: -14, anchor: .end),
        "two-seam": LabelOffset(dx: 0, dy: -14, anchor: .middle),
        "circle-change": LabelOffset(dx: 10, dy: 2, anchor: .start),
        "splitter": LabelOffset(dx: 16, dy: 18, anchor: .start),
        "splinker": LabelOffset(dx: -16, dy: 22, anchor: .end),
        "forkball": LabelOffset(dx: -16, dy: -16, anchor: .end),
        "eephus": LabelOffset(dx: 14, dy: 6, anchor: .start),
    ]
    static let defaultLabel = LabelOffset(dx: 0, dy: -14, anchor: .middle)

    /// Where a direction's zone sits for this hand.
    static func zone(_ vertical: VerticalShape?, _ horizontal: HorizontalDir, hand: Handedness) -> CGPoint {
        let side: CGFloat = horizontal == .armSide ? 1 : horizontal == .gloveSide ? -1 : 0
        let mirror: CGFloat = hand == .right ? 1 : -1
        let lift: CGFloat = vertical == .ride ? -row : vertical == .drop ? row : 0
        return CGPoint(x: center.x + side * mirror * column, y: center.y + lift)
    }

    /// The i-th pitch in a zone: the first on it, then rings of six every 60°, at 38,
    /// then 62, and so on.
    static func fan(_ i: Int) -> CGVector {
        guard i > 0 else { return CGVector(dx: 0, dy: 0) }
        let angle = Double(i % 6) * .pi / 3
        let radius = 38 + Double((i - 1) / 6) * 24
        return CGVector(dx: cos(angle) * radius, dy: sin(angle) * radius)
    }

    static func dots(_ pitches: [PitchAtlasEntry], hand: Handedness) -> [Dot] {
        var counts: [String: Int] = [:]
        return pitches.map { entry in
            let m = entry.motion
            let base = zone(m.verticalShape, m.horizontalDir, hand: hand)
            let key = "\(m.verticalShape?.rawValue ?? "")|\(m.horizontalDir.rawValue)"
            let i = counts[key, default: 0]
            counts[key] = i + 1
            let step = fan(i)
            return Dot(entry: entry, point: CGPoint(x: base.x + step.dx, y: base.y + step.dy),
                       label: labels[entry.slug] ?? defaultLabel)
        }
    }

    /// The poles follow the mirror.
    static func poles(hand: Handedness) -> (left: String, right: String) {
        hand == .right ? ("GLOVE", "ARM") : ("ARM", "GLOVE")
    }

    /// The pitch's own sourced shape words, never a magnitude.
    static func shapeWords(_ entry: PitchAtlasEntry) -> String {
        let m = entry.motion
        let vertical = m.verticalShape == .ride ? "rides" : m.verticalShape == .drop ? "drops" : "holds flat"
        let side = m.horizontalDir == .armSide ? "runs arm-side" : m.horizontalDir == .gloveSide ? "sweeps glove-side" : "stays true"
        return "\(vertical), \(side)"
    }

    static func markerLabel(_ entry: PitchAtlasEntry) -> String {
        "\(entry.canonical.name). \(entry.canonical.family.label), \(shapeWords(entry)). Open specimen."
    }

    // MARK: The site's words

    static func mapLabel(hand: Handedness) -> String {
        "Shape map of the filed pitches as a \(hand == .right ? "right-handed" : "left-handed") pitcher sees them from the mound. Each pitch sits in the direction it breaks (ride up top, drop below, arm-side and glove-side across) against a spinless ball at center. A map of direction, not a measured magnitude."
    }

    static let heroSub = "One field, as the pitcher sees it from the mound: whether each filed pitch rides or drops, and whether it runs or sweeps, against a spinless ball at center. Flip the handedness to see the mirror; a slider runs the other way for the other arm."
    static let scrollHint = "Scroll the map sideways to read every pitch. The pitch links below open the same files."
    static let footnote = "A schematic arranged by each pitch's sourced shape language, not a measured trajectory. To read the poles (what ride, drop, run, and sweep mean, and why a tilt of the spin axis produces them), see"
}
