import SwiftUI

/// The first in-app frame after iOS hands off from the static launch screen.
/// It mirrors the web field: cool black, bone rules, seam red, powder accent,
/// and the baseball seal. No spinner; the app has bundled content, so this is a
/// confidence bridge, not a fake progress report.
struct LaunchLoadingGate<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShowing = true
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .overlay {
                if isShowing {
                    LaunchLoadingView()
                        .transition(.opacity)
                }
            }
            .task {
                let delay: UInt64 = reduceMotion ? 220_000_000 : 780_000_000
                try? await Task.sleep(nanoseconds: delay)
                if reduceMotion {
                    isShowing = false
                } else {
                    withAnimation(.easeOut(duration: 0.32)) {
                        isShowing = false
                    }
                }
            }
    }
}

struct LaunchLoadingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sweep = false

    var body: some View {
        ZStack {
            FieldBackdrop()
            FieldRules()
                .opacity(0.08)
                .ignoresSafeArea()

            VStack(spacing: PitchAtlasSpacing.md) {
                BrandSealMark(size: 142)
                    .scaleEffect(reduceMotion ? 1 : (sweep ? 1.015 : 0.985))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                               value: sweep)
                    .padding(.bottom, PitchAtlasSpacing.xs)

                VStack(spacing: PitchAtlasSpacing.xs) {
                    Text("PITCH ATLAS")
                        .font(PitchAtlasTheme.anton(38))
                        .foregroundStyle(PitchAtlasTheme.bone)
                        .antonSkew()
                        .accessibilityAddTraits(.isHeader)

                    Text("Sourced, not corrected.")
                        .font(PitchAtlasTheme.newsreaderItalic(18))
                        .foregroundStyle(PitchAtlasTheme.bone2)
                }

                LoadingRule()
                    .frame(width: 220)
                    .padding(.top, PitchAtlasSpacing.sm)
            }
            .padding(.horizontal, PitchAtlasSpacing.xl)
            .offset(y: -12)
        }
        .onAppear { if !reduceMotion { sweep = true } }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pitch Atlas. Sourced, not corrected.")
    }
}

private struct FieldRules: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 22
            var path = Path()
            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }
            context.stroke(path, with: .color(PitchAtlasTheme.bone.opacity(0.14)), lineWidth: 0.5)
        }
    }
}

private struct LoadingRule: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAtEnd = false

    var body: some View {
        GeometryReader { proxy in
            let dashWidth = min(max(proxy.size.width * 0.34, 64), 84)
            let travel = max(proxy.size.width - dashWidth, 0)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(PitchAtlasTheme.bone.opacity(0.16))
                    .frame(height: 2)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                PitchAtlasTheme.seamBright,
                                PitchAtlasTheme.cyan,
                                PitchAtlasTheme.bone,
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: dashWidth, height: 2)
                    .offset(x: reduceMotion ? travel * 0.5 : (isAtEnd ? travel : 0))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                               value: isAtEnd)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 8)
        .onAppear { if !reduceMotion { isAtEnd = true } }
        .accessibilityHidden(true)
    }
}

#Preview {
    LaunchLoadingView()
        .preferredColorScheme(.dark)
}
