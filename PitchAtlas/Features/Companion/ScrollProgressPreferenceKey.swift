import SwiftUI

// =============================================================================
// Blaze companion — scroll tracking plumbing
// =============================================================================
// The companion sits in a bottom safe-area inset, a sibling of each tab's scroll
// view — and SwiftUI preferences flow UP to ancestors, never sideways to a sibling.
// So the scroll's progress is published as a preference that the TabScaffold (a
// shared ANCESTOR of both the scroll and the inset) reads, converts to 0…1 using
// the viewport it measures, and writes into the shared BlazeCompanionController the
// companion observes. That common-ancestor hand-off is what makes the dog chase the
// scroll — the wiring that was declared but never connected before.
// =============================================================================

/// The named coordinate space the scaffold establishes so the scroll content can
/// report its offset relative to a fixed frame.
enum BlazeScrollSpace {
    static let name = "blazeCompanionScroll"
}

/// Raw scroll metrics emitted from inside a tab's scroll content. `contentTop` is
/// the content's top edge in the scaffold's coordinate space (0 at rest, negative
/// as the page scrolls up); `contentHeight` is the full scrollable content height.
struct BlazeScrollMetrics: Equatable {
    var contentTop: CGFloat = 0
    var contentHeight: CGFloat = 0
}

struct BlazeScrollMetricsKey: PreferenceKey {
    static var defaultValue = BlazeScrollMetrics()
    static func reduce(value: inout BlazeScrollMetrics, nextValue: () -> BlazeScrollMetrics) {
        let next = nextValue()
        // Keep the measurement that actually has a measured content height.
        if next.contentHeight > 0 { value = next }
    }
}

private struct EmitBlazeScrollProgress: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: BlazeScrollMetricsKey.self,
                    value: BlazeScrollMetrics(
                        contentTop: geo.frame(in: .named(BlazeScrollSpace.name)).minY,
                        contentHeight: geo.size.height
                    )
                )
            }
        )
    }
}

extension View {
    /// Apply to a tab's scroll content (the inner VStack/LazyVStack) so the Blaze
    /// companion can chase the scroll. Pair with a `TabScaffold` ancestor.
    func emitsBlazeScrollProgress() -> some View {
        modifier(EmitBlazeScrollProgress())
    }
}
