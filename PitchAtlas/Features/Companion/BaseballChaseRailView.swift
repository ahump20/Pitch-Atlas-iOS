import SwiftUI

struct BaseballChaseRailView: View {
    let mood: BlazeMood
    let progress: Double
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            let clamped = BlazeCompanionController.clampProgress(progress)
            let ballX = max(18, min(proxy.size.width - 18, 92 + (proxy.size.width - 132) * clamped))

            ZStack(alignment: .bottomLeading) {
                Path { path in
                    let y = proxy.size.height - 17
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                }
                .stroke(PitchAtlasTheme.bone2.opacity(0.22), style: StrokeStyle(lineWidth: 1, dash: [10, 10]))

                BaseballMark()
                    .stroke(PitchAtlasTheme.seamBright, lineWidth: 1.2)
                    .background(
                        Circle()
                            .fill(PitchAtlasTheme.bone.opacity(0.92))
                    )
                    .frame(width: 23, height: 23)
                    .rotationEffect(reduceMotion ? .zero : .degrees(clamped * 540))
                    .position(x: ballX, y: proxy.size.height - 17)
                    .opacity(mood == .still ? 0.32 : 0.84)
            }
        }
        .frame(height: BlazeMotionSettings.railHeight)
        .accessibilityHidden(true)
    }
}

private struct BaseballMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let left = rect.insetBy(dx: rect.width * 0.24, dy: rect.height * 0.2)
        path.addArc(center: CGPoint(x: left.minX, y: left.midY),
                    radius: rect.height * 0.43,
                    startAngle: .degrees(-62),
                    endAngle: .degrees(62),
                    clockwise: false)
        path.addArc(center: CGPoint(x: left.maxX, y: left.midY),
                    radius: rect.height * 0.43,
                    startAngle: .degrees(118),
                    endAngle: .degrees(242),
                    clockwise: false)
        return path
    }
}
