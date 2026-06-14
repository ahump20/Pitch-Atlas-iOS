import SwiftUI

/// Wraps a tab's content with the bottom companion and the shared scroll-tracking
/// controller. As an ancestor of both the scroll (inside `content`) and the inset
/// companion, it is the one place that can read the scroll's emitted metrics and
/// feed the companion — the hand-off the old per-view @State controller never got.
struct TabScaffold<Content: View>: View {
    let tab: AppTab
    @ViewBuilder var content: Content
    @State private var companion = BlazeCompanionController()

    var body: some View {
        GeometryReader { outer in
            content
                .coordinateSpace(name: BlazeScrollSpace.name)
                .onPreferenceChange(BlazeScrollMetricsKey.self) { metrics in
                    let span = max(1, metrics.contentHeight - outer.size.height)
                    let scrolled = max(0, -metrics.contentTop)
                    companion.update(progress: min(1, scrolled / span))
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    BlazeCompanionView(selectedTab: tab)
                }
        }
        .environment(companion)
    }
}

struct BlazeCompanionView: View {
    let selectedTab: AppTab
    var seriousFlow = false

    @AppStorage(BlazeMotionSettings.appStorageKey) private var enabled = BlazeMotionSettings.defaultEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(BlazeCompanionController.self) private var controller

    var body: some View {
        let baseMood = BlazeMood.mood(for: selectedTab, seriousFlow: seriousFlow)
        let mood = BlazeCompanionController.effectiveMood(
            base: baseMood,
            enabled: enabled,
            reduceMotion: reduceMotion
        )
        let lacksSafeRail = horizontalSizeClass == .compact && (mood == .sniffing || mood == .idle || mood == .chasing)

        if mood != .hidden && !lacksSafeRail {
            GeometryReader { proxy in
                let railWidth = min(BlazeMotionSettings.maxRailWidth, max(0, proxy.size.width - PitchAtlasSpacing.md * 2))
                let usableWidth = max(0, railWidth - 88)
                let x = reduceMotion || mood == .still ? 0 : CGFloat(controller.scrollProgress) * usableWidth

                HStack(alignment: .bottom, spacing: 0) {
                    ZStack(alignment: .bottomLeading) {
                        BaseballChaseRailView(
                            mood: mood,
                            progress: controller.scrollProgress,
                            reduceMotion: reduceMotion
                        )
                        BlazeDogView(mood: mood, reduceMotion: reduceMotion)
                            .offset(x: x, y: 0)
                    }
                    .frame(width: railWidth, height: BlazeMotionSettings.companionBandHeight, alignment: .bottomLeading)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, PitchAtlasSpacing.md)
                .frame(width: proxy.size.width, height: BlazeMotionSettings.companionBandHeight, alignment: .bottomLeading)
            }
            .frame(height: BlazeMotionSettings.companionBandHeight)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

#Preview {
    ZStack {
        PitchAtlasTheme.void.ignoresSafeArea()
        BlazeCompanionView(selectedTab: .atlas)
    }
    .environment(BlazeCompanionController())
    .preferredColorScheme(.dark)
}
