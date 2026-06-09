import SwiftUI

struct BlazeCompanionView: View {
    let selectedTab: AppTab
    var seriousFlow = false

    @AppStorage(BlazeMotionSettings.appStorageKey) private var enabled = BlazeMotionSettings.defaultEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var controller = BlazeCompanionController()

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
            .onPreferenceChange(ScrollProgressPreferenceKey.self) { next in
                controller.update(progress: next)
            }
        }
    }
}

#Preview {
    ZStack {
        PitchAtlasTheme.void.ignoresSafeArea()
        BlazeCompanionView(selectedTab: .atlas)
    }
    .preferredColorScheme(.dark)
}
