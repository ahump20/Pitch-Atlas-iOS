import SwiftUI

/// Web motion tokens: 120/190/400/700/900 ms on the settle curve (.22,1,.36,1),
/// the card ease (.2,.8,.2,1) and the specimen ease (.16,1,.3,1).
enum PitchAtlasMotion {
    static func settle(_ ms: Double) -> Animation {
        let c = WebTokens.Motion.settle
        return .timingCurve(c[0], c[1], c[2], c[3], duration: ms / 1000)
    }
    static let tiny = settle(WebTokens.Motion.tinyMs)
    static let short = settle(WebTokens.Motion.shortMs)
    static let medium = settle(WebTokens.Motion.mediumMs)
    static let slow = settle(WebTokens.Motion.slowMs)
    static let sweep = settle(WebTokens.Motion.sweepMs)
    static let cardEase = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.4)
    static let specimenEase = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.4)
    /// The web tilt spring, ω = 20 rad/s, ζ = 0.7 → response 2π/20.
    static let tiltSpring = Animation.spring(response: 0.314, dampingFraction: 0.7)

    /// Reduce Motion: no animation at all (the state lands still).
    static func animation(_ base: Animation, reduceMotion: Bool) -> Animation? { reduceMotion ? nil : base }
}
