import SwiftUI

struct BlazeDogView: View {
    let mood: BlazeMood
    let reduceMotion: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(reduceMotion ? BlazeMood.still.imageName : mood.imageName)
                .resizable()
                .interpolation(.medium)
                .scaledToFit()
                .frame(width: BlazeMotionSettings.companionWidth, height: BlazeMotionSettings.companionWidth * 208 / 192)

            HelmetMark()
                .frame(width: BlazeMotionSettings.companionWidth * 0.48, height: BlazeMotionSettings.companionWidth * 0.34)
                .rotationEffect(reduceMotion ? .degrees(-7) : rotation + .degrees(-7))
                .offset(x: BlazeMotionSettings.companionWidth * 0.05, y: BlazeMotionSettings.companionWidth * 0.27)

            Circle()
                .fill(PitchAtlasTheme.bone)
                .overlay(Circle().stroke(PitchAtlasTheme.seamBright, lineWidth: 0.8))
                .frame(width: BlazeMotionSettings.companionWidth * 0.13)
                .overlay(Circle().fill(PitchAtlasTheme.cyan).frame(width: BlazeMotionSettings.companionWidth * 0.035))
                .offset(x: BlazeMotionSettings.companionWidth * 0.42, y: BlazeMotionSettings.companionWidth * 0.57)
        }
        .rotationEffect(reduceMotion ? .zero : rotation)
        .opacity(mood == .still ? 0.76 : 0.92)
        .accessibilityHidden(true)
    }

    private var rotation: Angle {
        switch mood {
        case .chasing: return .degrees(-2)
        case .caught: return .degrees(2)
        case .concerned: return .degrees(-3)
        default: return .zero
        }
    }
}

private struct HelmetMark: View {
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 4, y: 21))
                path.addCurve(to: CGPoint(x: 27, y: 4), control1: CGPoint(x: 6, y: 8), control2: CGPoint(x: 17, y: 2))
                path.addCurve(to: CGPoint(x: 43, y: 19), control1: CGPoint(x: 37, y: 5), control2: CGPoint(x: 44, y: 10))
                path.addLine(to: CGPoint(x: 35, y: 22))
                path.addCurve(to: CGPoint(x: 8, y: 23), control1: CGPoint(x: 25, y: 17), control2: CGPoint(x: 15, y: 17))
                path.closeSubpath()
            }
            .fill(PitchAtlasTheme.seamBright.opacity(0.78))
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: 4, y: 21))
                    path.addCurve(to: CGPoint(x: 27, y: 4), control1: CGPoint(x: 6, y: 8), control2: CGPoint(x: 17, y: 2))
                    path.addCurve(to: CGPoint(x: 43, y: 19), control1: CGPoint(x: 37, y: 5), control2: CGPoint(x: 44, y: 10))
                    path.addLine(to: CGPoint(x: 35, y: 22))
                    path.addCurve(to: CGPoint(x: 8, y: 23), control1: CGPoint(x: 25, y: 17), control2: CGPoint(x: 15, y: 17))
                    path.closeSubpath()
                }
                .stroke(PitchAtlasTheme.bone.opacity(0.45), lineWidth: 1)
            )

            Path { path in
                path.move(to: CGPoint(x: 3, y: 22))
                path.addCurve(to: CGPoint(x: 31, y: 25), control1: CGPoint(x: 12, y: 19), control2: CGPoint(x: 23, y: 21))
                path.addCurve(to: CGPoint(x: 3, y: 26), control1: CGPoint(x: 24, y: 29), control2: CGPoint(x: 13, y: 30))
                path.closeSubpath()
            }
            .fill(Color(red: 0.17, green: 0.08, blue: 0.04))
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: 3, y: 22))
                    path.addCurve(to: CGPoint(x: 31, y: 25), control1: CGPoint(x: 12, y: 19), control2: CGPoint(x: 23, y: 21))
                }
                .stroke(PitchAtlasTheme.bone.opacity(0.35), lineWidth: 0.8)
            )

            Path { path in
                path.move(to: CGPoint(x: 22, y: 7))
                path.addCurve(to: CGPoint(x: 24, y: 23), control1: CGPoint(x: 27, y: 12), control2: CGPoint(x: 27, y: 18))
                path.move(to: CGPoint(x: 13, y: 13))
                path.addCurve(to: CGPoint(x: 37, y: 16), control1: CGPoint(x: 21, y: 9), control2: CGPoint(x: 30, y: 11))
            }
            .stroke(PitchAtlasTheme.bone.opacity(0.58), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
        }
    }
}
