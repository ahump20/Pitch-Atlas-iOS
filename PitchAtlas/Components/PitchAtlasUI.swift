import SwiftUI

// =============================================================================
// Pitch Atlas — shared UI primitives
// =============================================================================
// The structural kit every screen builds on: the leather-press card, the Martian
// section label, the vector seal mark, and the four data-surface states. Glass is
// reserved for chrome (tab/nav); content is always leather-press, never frosted.
// =============================================================================

// MARK: - Section label (the Martian eyebrow)

/// All-caps tracked micro-label. The "stamp" that heads a section or card.
struct SectionLabel: View {
    let text: String
    var color: Color = PitchAtlasTheme.ink3
    var size: CGFloat = 10

    var body: some View {
        Text(text.uppercased())
            .font(PitchAtlasTheme.martian(size))
            .tracking(2)
            .foregroundStyle(color)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Leather-press card

/// The content surface: solid press fill + 1px bone hairline. Never glass.
struct LeatherPress: ViewModifier {
    var padding: CGFloat
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(PitchAtlasTheme.press)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(PitchAtlasTheme.machined, lineWidth: 1)
            )
    }
}

extension View {
    /// Wrap content as a leather-press card.
    func leatherPress(padding: CGFloat = PitchAtlasSpacing.md,
                      radius: CGFloat = PitchAtlasRadius.card) -> some View {
        modifier(LeatherPress(padding: padding, radius: radius))
    }
}

// MARK: - Seal mark (the vector brand fallback)

/// The seam S-curve, drawn so a missing photo shows a brand mark, never a gray box.
struct SeamArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.20, y: h * 0.18))
        p.addCurve(to: CGPoint(x: w * 0.80, y: h * 0.82),
                   control1: CGPoint(x: w * 0.95, y: h * 0.30),
                   control2: CGPoint(x: w * 0.05, y: h * 0.70))
        return p
    }
}

/// A small diamond + seam mark used as the visual actor when no photo exists.
struct SealMark: View {
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(PitchAtlasTheme.ink3.opacity(0.8), lineWidth: 1.5)
                .frame(width: size * 0.62, height: size * 0.62)
                .rotationEffect(.degrees(45))
            SeamArc()
                .stroke(PitchAtlasTheme.seamBright,
                        style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .frame(width: size * 0.5, height: size * 0.5)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Four data-surface states

/// Loading: a source-tagged skeleton, never a bare spinner.
struct LoadingTile: View {
    var label: String = "Loading"
    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(PitchAtlasTheme.machined)
                    .frame(height: 14)
                    .frame(maxWidth: i == 2 ? 180 : .infinity)
            }
            SectionLabel(text: label, size: 9)
        }
        .opacity(pulse ? 0.45 : 0.9)
        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
        .leatherPress()
        .accessibilityLabel("\(label)…")
    }
}

/// Error: names what failed and whether it is transient — never a blank box.
struct ErrorStateView: View {
    let title: String
    let reason: String

    init(title: String = "Couldn't load this", reason: String) {
        self.title = title
        self.reason = reason
    }

    var body: some View {
        VStack(spacing: PitchAtlasSpacing.sm) {
            SealMark(size: 52)
            Text(title)
                .font(PitchAtlasTheme.newsreader(18))
                .foregroundStyle(PitchAtlasTheme.bone)
            Text(reason)
                .font(PitchAtlasTheme.hanken(14))
                .foregroundStyle(PitchAtlasTheme.ink3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PitchAtlasSpacing.xl2)
        .leatherPress()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(reason)")
    }
}

/// Empty: explains *why* there is nothing here.
struct EmptyStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: PitchAtlasSpacing.sm) {
            SealMark(size: 44)
            Text(message)
                .font(PitchAtlasTheme.hanken(15))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PitchAtlasSpacing.xl2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

// MARK: - Hairline divider

struct HairlineDivider: View {
    var body: some View {
        Rectangle()
            .fill(PitchAtlasTheme.navyLine)
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}
