import Foundation

/// The reader's row is captured before navigation starts. Framework layout while
/// the Index is covered must never replace it with an offscreen/top-layout row.
/// Restoration is by row (or masthead), not an exact intra-row pixel offset.
struct IndexScrollRestoration {
    enum Position: Equatable {
        case top
        case row(String)
    }

    private(set) var position: Position = .top
    private var savedPosition: Position?
    private var isVisible = false
    private var isNavigating = false

    mutating func observe(frames: [String: CGRect]) {
        guard isVisible, !isNavigating, !frames.isEmpty else { return }
        if let crossing = frames
            .filter({ $0.value.minY <= 0 && $0.value.maxY > 0 })
            .max(by: { $0.value.minY < $1.value.minY }) {
            position = .row(crossing.key)
        } else if frames.values.allSatisfy({ $0.minY > 0 }) {
            // Eager row layout means this is the header/control region, including
            // a manual reverse-scroll. An earlier deep row is now stale.
            position = .top
        }
        // Rows above and below the edge without an intersection indicate a
        // divider/family-heading gap. Keep the last genuinely crossed row.
    }

    mutating func beginNavigation() {
        suspend()
        isNavigating = true
    }

    mutating func indexDidDisappear() {
        // Preserve the activation snapshot during push or a cancelled edge-swipe.
        // Also retain position when leaving the Index through a tab change.
        suspend()
        isVisible = false
    }

    mutating func indexDidAppear() -> Position? {
        isVisible = true
        let restoration = savedPosition
        if let restoration { position = restoration }
        if !isNavigating { savedPosition = nil }
        return restoration
    }

    mutating func navigationDidEnd() {
        isNavigating = false
        // SwiftUI can clear its item before or after the Index appears. Until
        // both have happened, offscreen preferences remain unable to record.
        if isVisible { savedPosition = nil }
    }

    mutating func invalidate() {
        position = .top
        if savedPosition != nil { savedPosition = .top }
    }

    private mutating func suspend() {
        if savedPosition == nil { savedPosition = position }
    }
}
