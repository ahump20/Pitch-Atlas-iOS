import SwiftUI
import Observation

// =============================================================================
// Scroll progress — how far down its page a tab has been read, 0…1
// =============================================================================
// Preferences flow up to ancestors, never sideways, so the scroll content
// publishes its metrics and the TabScaffold (an ancestor of the scroll) turns
// them into 0…1 for anything below it that moves with the page — the Muybridge
// pitcher on Atlas. It is a position, like a scrollbar; nothing reads it to
// judge a visitor.
// =============================================================================

enum ScrollProgressSpace { static let name = "pitchAtlasTabScroll" }

struct ScrollMetrics: Equatable {
    var contentTop: CGFloat = 0
    var contentHeight: CGFloat = 0
}

struct ScrollMetricsKey: PreferenceKey {
    static var defaultValue = ScrollMetrics()
    static func reduce(value: inout ScrollMetrics, nextValue: () -> ScrollMetrics) {
        let next = nextValue()
        // Keep the measurement that actually has a measured content height.
        if next.contentHeight > 0 { value = next }
    }
}

@Observable final class ScrollProgressController {
    private(set) var progress: Double = 0

    func update(progress: Double) { self.progress = min(1, max(0, progress)) }

    static func progress(contentTop: CGFloat, contentHeight: CGFloat, viewport: CGFloat) -> Double {
        let span = max(1, contentHeight - viewport)
        let scrolled = max(0, -contentTop)
        return min(1, Double(scrolled / span))
    }
}

private struct EmitScrollProgress: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: ScrollMetricsKey.self,
                    value: ScrollMetrics(contentTop: geo.frame(in: .named(ScrollProgressSpace.name)).minY,
                                         contentHeight: geo.size.height)
                )
            }
        )
    }
}

extension View {
    /// Apply to a tab's scroll content so its read position reaches the TabScaffold.
    func emitsScrollProgress() -> some View { modifier(EmitScrollProgress()) }
}

/// Each tab's root: owns that tab's scroll progress and shares it below.
struct TabScaffold<Content: View>: View {
    let tab: AppTab
    @ViewBuilder var content: Content
    @State private var progress = ScrollProgressController()

    var body: some View {
        GeometryReader { outer in
            content
                .coordinateSpace(name: ScrollProgressSpace.name)
                .onPreferenceChange(ScrollMetricsKey.self) { m in
                    progress.update(progress: ScrollProgressController.progress(
                        contentTop: m.contentTop, contentHeight: m.contentHeight, viewport: outer.size.height))
                }
        }
        .environment(progress)
    }
}
