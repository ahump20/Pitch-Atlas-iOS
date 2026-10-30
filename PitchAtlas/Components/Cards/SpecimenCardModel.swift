import SwiftUI

/// Which stock a card is cut from. The ember 1/1 supersedes a throwback finish.
enum CardFrame: Equatable {
    case standard, ember, powder, teal
    static func of(slug: String, grade: SpecimenGradeKey) -> CardFrame {
        if grade == .gold { return .ember }
        switch PitchAccents.triad(for: slug).finish {
        case "powder": return .powder
        case "teal": return .teal
        default: return .standard
        }
    }
}

/// Every printed size on the card is N·u with u = width/100 (the web's --rfxu);
/// micro-type floors apply after scaling (spec Appendix F).
struct SpecimenCardMetrics: Equatable {
    let width: CGFloat
    let frame: CardFrame
    init(width: CGFloat, frame: CardFrame) { self.width = width; self.frame = frame }
    var u: CGFloat { width / 100 }
    var height: CGFloat { width * 7 / 5 }
    var stockPadding: CGFloat { frame == .ember ? 16 : 13 }
    var fieldPadding: EdgeInsets { EdgeInsets(top: 3.06 * u, leading: 3.06 * u, bottom: 2.5 * u, trailing: 3.06 * u) }
    var headPadding: EdgeInsets { EdgeInsets(top: 0.83 * u, leading: 0.83 * u, bottom: 2.22 * u, trailing: 0.83 * u) }
    var overlineSize: CGFloat { max(7, 2 * u) }
    var nameSize: CGFloat { 7.2 * u }
    var numberSize: CGFloat { 5.2 * u }
    var stageTopRX: CGFloat { 21.67 * u }
    var stageTopRY: CGFloat { 23 * u }
    var stageBottomR: CGFloat { 3.89 * u }
    var chipSize: CGFloat { max(7, 2.22 * u) }
    var chipInset: CGFloat { 2.5 * u }
    var readMarginTop: CGFloat { 2.5 * u }
    var readPadding: EdgeInsets { EdgeInsets(top: 2.5 * u, leading: 3.33 * u, bottom: 2.22 * u, trailing: 3.33 * u) }
    var readRadius: CGFloat { 2.22 * u }
    var readGap: CGFloat { 1.75 * u }
    var readRuleStep: CGFloat { 4.7 * u }
    var readMetaSize: CGFloat { max(7, 2.05 * u) }
    var cueSize: CGFloat { 3.9 * u }
    var factSize: CGFloat { max(8, 2.5 * u) }
    var dotSize: CGFloat { 2.22 * u }
    var stripSize: CGFloat { max(8, 2.5 * u) }
    var stripTop: CGFloat { 1.67 * u }
}

enum CardLean {
    /// `rotate: sin((i + 1) · 2.1) · 0.45deg` — every web card passes i = 0.
    static func rest(index: Int) -> Double { sin(Double(index + 1) * 2.1) * 0.45 }
    static let hero: Double = -0.28
}

enum CardFace: Equatable { case film(GripFilm), photo(VisualReference), schematic }

/// What the card prints, resolved like the web's specimenFace(): Austin's clip,
/// then his photo, then the schematic. The cue is his short cue when he filed
/// the grip, else the reference grip claim — never anything invented.
struct SpecimenCardContent: Equatable {
    let slug: String
    let name: String
    let vnum: String
    let family: PitchFamily
    let frame: CardFrame
    let triad: WebAccent
    let face: CardFace
    let chipLabel: String
    let chipIsAustin: Bool
    let cue: String
    let cueTier: ClaimConfidence
    let approximate: Bool

    static func make(entry: PitchAtlasEntry, grip: GripEntry?) -> SpecimenCardContent {
        let film = grip?.film
        let photo = grip?.photos.first
        let austin = film != nil || photo != nil
        let reference = entry.canonical.gripDetails.first ?? entry.canonical.grip
        let face: CardFace = film.map(CardFace.film) ?? photo.map(CardFace.photo) ?? .schematic
        return SpecimenCardContent(
            slug: entry.slug, name: entry.display.shortName, vnum: entry.display.specimenNo,
            family: entry.canonical.family,
            frame: CardFrame.of(slug: entry.slug, grade: entry.specimenGrade.key),
            triad: PitchAccents.triad(for: entry.slug), face: face,
            chipLabel: film != nil ? "Austin video" : photo != nil ? "Austin photo" : "Reference schematic",
            chipIsAustin: austin,
            cue: austin ? grip!.shortCue : reference.value,
            cueTier: austin ? grip!.claimTier : reference.confidence,
            approximate: austin ? false : (reference.approximate ?? false))
    }

    var accessibilityLabel: String {
        "\(name), filed specimen No. \(vnum). Grip tell: \(cue). Source: \(cueTier.label)\(approximate ? ", approximate" : ""). \(chipLabel)."
    }
}

/// The card window: elliptical top corners (21.67u × 23u), small bottom radius.
struct ArchedWindow: Shape {
    var topRX: CGFloat
    var topRY: CGFloat
    var bottomR: CGFloat
    func path(in r: CGRect) -> Path {
        let rx = min(topRX, r.width / 2), ry = min(topRY, r.height - bottomR), br = min(bottomR, r.width / 2, r.height / 2)
        let k: CGFloat = 0.5523
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY + ry))
        p.addCurve(to: CGPoint(x: r.minX + rx, y: r.minY),
                   control1: CGPoint(x: r.minX, y: r.minY + ry - k * ry), control2: CGPoint(x: r.minX + rx - k * rx, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - rx, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + ry),
                   control1: CGPoint(x: r.maxX - rx + k * rx, y: r.minY), control2: CGPoint(x: r.maxX, y: r.minY + ry - k * ry))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - br))
        p.addArc(center: CGPoint(x: r.maxX - br, y: r.maxY - br), radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: r.minX + br, y: r.maxY))
        p.addArc(center: CGPoint(x: r.minX + br, y: r.maxY - br), radius: br, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.closeSubpath()
        return p
    }
}
