import SwiftUI

enum BlazeInlineStyle {
    case atlas
    case pitch
    case search
    case grips
}

struct BlazeInlineCompanionView: View {
    let style: BlazeInlineStyle
    let mood: BlazeMood

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var patted = false

    var body: some View {
        Button {
            Haptics.soft()
            guard !reduceMotion else { return }
            withAnimation(.interpolatingSpring(stiffness: 220, damping: 16)) {
                patted = true
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(760))
                withAnimation(.easeOut(duration: 0.18)) {
                    patted = false
                }
            }
        } label: {
            ZStack(alignment: .bottomLeading) {
                routeMark
                    .opacity(0.62)
                    .offset(x: 72, y: -7)

                dottedRail
                    .padding(.leading, 68)
                    .padding(.trailing, 12)
                    .padding(.bottom, 16)

                BaseballChaseRailView(mood: mood, progress: patted ? 0.82 : progress, reduceMotion: reduceMotion)
                    .frame(width: 180, height: 32)
                    .offset(x: 56, y: -4)
                    .opacity(0.72)

                BlazeDogView(mood: patted ? .caught : mood, reduceMotion: reduceMotion)
                    .scaleEffect(patted ? CGSize(width: 1.06, height: 0.94) : CGSize(width: 1, height: 1), anchor: .bottom)
                    .rotationEffect(patted && !reduceMotion ? .degrees(-6) : .zero)
                    .offset(y: patted ? -4 : 0)

                if patted {
                    Text("arf")
                        .font(PitchAtlasTheme.martian(8))
                        .tracking(1)
                        .foregroundStyle(PitchAtlasTheme.bone)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(PitchAtlasTheme.void.opacity(0.88))
                                .overlay(Capsule().stroke(PitchAtlasTheme.bone.opacity(0.3), lineWidth: 1))
                        )
                        .offset(x: 50, y: -36)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(height: 62)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Pat Blaze")
    }

    private var progress: Double {
        switch style {
        case .atlas: return 0.22
        case .pitch: return 0.58
        case .search: return 0.34
        case .grips: return 0.44
        }
    }

    private var dottedRail: some View {
        Rectangle()
            .fill(PitchAtlasTheme.bone2.opacity(0.18))
            .frame(height: 1)
            .overlay(alignment: .leading) {
                HStack(spacing: 14) {
                    ForEach(0..<8, id: \.self) { index in
                        Capsule()
                            .fill(index.isMultiple(of: 2) ? PitchAtlasTheme.seamBright.opacity(0.38) : PitchAtlasTheme.cyan.opacity(0.3))
                            .frame(width: 10, height: 2)
                            .rotationEffect(.degrees(index.isMultiple(of: 2) ? -9 : 8))
                    }
                }
            }
    }

    @ViewBuilder
    private var routeMark: some View {
        switch style {
        case .atlas:
            HomePlateMark()
                .stroke(PitchAtlasTheme.cyan.opacity(0.7), lineWidth: 1.2)
                .frame(width: 38, height: 30)
        case .pitch:
            MoundMark()
                .stroke(PitchAtlasTheme.seamBright.opacity(0.72), lineWidth: 1.6)
                .frame(width: 46, height: 28)
        case .search:
            ScorecardMark()
                .stroke(PitchAtlasTheme.bone2.opacity(0.62), lineWidth: 1.2)
                .frame(width: 44, height: 32)
        case .grips:
            RosinBagMark()
                .stroke(PitchAtlasTheme.sandBright.opacity(0.66), lineWidth: 1.4)
                .frame(width: 42, height: 32)
        }
    }
}

private struct HomePlateMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.1))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.minY + rect.height * 0.1))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private struct MoundMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - 4))
        path.addCurve(to: CGPoint(x: rect.maxX, y: rect.maxY - 4),
                      control1: CGPoint(x: rect.width * 0.3, y: rect.minY),
                      control2: CGPoint(x: rect.width * 0.7, y: rect.minY))
        path.move(to: CGPoint(x: rect.midX - 8, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX + 8, y: rect.midY))
        return path
    }
}

private struct ScorecardMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect.insetBy(dx: 2, dy: 2), cornerSize: CGSize(width: 2, height: 2))
        path.move(to: CGPoint(x: rect.minX + 12, y: rect.minY + 2))
        path.addLine(to: CGPoint(x: rect.minX + 12, y: rect.maxY - 2))
        path.move(to: CGPoint(x: rect.minX + 24, y: rect.minY + 2))
        path.addLine(to: CGPoint(x: rect.minX + 24, y: rect.maxY - 2))
        path.move(to: CGPoint(x: rect.minX + 4, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - 4, y: rect.midY))
        return path
    }
}

private struct RosinBagMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 7, y: rect.maxY - 3))
        path.addLine(to: CGPoint(x: rect.maxX - 7, y: rect.maxY - 3))
        path.addLine(to: CGPoint(x: rect.maxX - 12, y: rect.minY + 10))
        path.addCurve(to: CGPoint(x: rect.minX + 12, y: rect.minY + 10),
                      control1: CGPoint(x: rect.maxX - 20, y: rect.minY),
                      control2: CGPoint(x: rect.minX + 20, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
