import Foundation

@Observable
final class BlazeCompanionController {
    private(set) var scrollProgress: Double = 0

    func update(progress: Double) {
        scrollProgress = Self.clampProgress(progress)
    }

    static func clampProgress(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(1, max(0, value))
    }

    static func effectiveMood(base: BlazeMood, enabled: Bool, reduceMotion: Bool) -> BlazeMood {
        guard enabled else { return .hidden }
        guard reduceMotion else { return base }
        switch base {
        case .hidden:
            return .hidden
        case .concerned, .still:
            return base
        default:
            return .still
        }
    }
}
