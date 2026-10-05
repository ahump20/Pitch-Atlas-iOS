import SwiftUI

/// The web's metallic materials as SwiftUI gradients. CSS angles are honored for
/// the drawn shape's aspect ratio, so a 112° foil rakes the same way on a 5:7 card.
enum PitchAtlasMaterials {
    /// CSS linear-gradient geometry: the gradient line passes through the center
    /// along the angle's direction and its length makes the corners hit 0% and 100%.
    static func cssEndpoints(angle: Double, aspect: CGFloat) -> (start: UnitPoint, end: UnitPoint) {
        let theta = angle * .pi / 180
        let (w, h) = (Double(aspect), 1.0)
        let (dx, dy) = (sin(theta), -cos(theta))
        let half = (abs(w * dx) + abs(h * dy)) / 2
        return (UnitPoint(x: 0.5 - dx * half / w, y: 0.5 - dy * half / h),
                UnitPoint(x: 0.5 + dx * half / w, y: 0.5 + dy * half / h))
    }

    static func gradient(_ g: WebGradient, aspect: CGFloat) -> LinearGradient {
        let ends = cssEndpoints(angle: g.angle, aspect: aspect)
        return LinearGradient(stops: g.stops.map { .init(color: Color(web: $0.color), location: $0.location) },
                              startPoint: ends.start, endPoint: ends.end)
    }

    static func foil(aspect: CGFloat = 5.0 / 7.0) -> LinearGradient { gradient(WebTokens.Gradient.foil, aspect: aspect) }
    static func foilType(aspect: CGFloat = 4) -> LinearGradient { gradient(WebTokens.Gradient.foilType, aspect: aspect) }
    static func ember(aspect: CGFloat = 5.0 / 7.0) -> LinearGradient { gradient(WebTokens.Gradient.ember, aspect: aspect) }

    static func finish(_ name: String?) -> WebCardFinish? {
        switch name {
        case "powder": return WebTokens.CardFinish.powder
        case "teal": return WebTokens.CardFinish.teal
        default: return nil
        }
    }
    static func cardFoil(finish name: String?, aspect: CGFloat = 5.0 / 7.0) -> LinearGradient {
        gradient(finish(name)?.foil ?? WebTokens.Gradient.foil, aspect: aspect)
    }
}
