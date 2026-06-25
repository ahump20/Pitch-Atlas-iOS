import SwiftUI

// =============================================================================
// Pitch Atlas — shared UI primitives
// =============================================================================
// The structural kit every screen builds on: the leather-press card, the Martian
// section label, the vector seal mark, and the four data-surface states. Glass is
// reserved for chrome (tab/nav); content is always leather-press, never frosted.
// =============================================================================

// MARK: - Field background

/// Shared app field: the web's cool black stage with faint rule lines and controlled
/// powder/seam light. It keeps large surfaces from falling back to flat brown.
struct FieldBackdrop: View {
    var body: some View {
        ZStack {
            PitchAtlasTheme.void
            LinearGradient(
                colors: [
                    Color(hex: 0x16121F).opacity(0.30),
                    .clear,
                    PitchAtlasTheme.void,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [
                    PitchAtlasTheme.cyan.opacity(0.095),
                    .clear,
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 340
            )
            RadialGradient(
                colors: [
                    PitchAtlasTheme.seamBright.opacity(0.06),
                    .clear,
                ],
                center: .bottomLeading,
                startRadius: 24,
                endRadius: 360
            )
            RadialGradient(
                colors: [
                    PitchAtlasTheme.violet.opacity(0.045),
                    .clear,
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 320
            )
            FieldRuleMesh()
                .opacity(0.20)
        }
        .ignoresSafeArea()
    }
}

private struct FieldRuleMesh: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 22
            var x: CGFloat = 0
            while x <= size.width {
                var y: CGFloat = 0
                while y <= size.height {
                    let rect = CGRect(x: x, y: y, width: 1.2, height: 1.2)
                    context.fill(Path(ellipseIn: rect), with: .color(PitchAtlasTheme.bone.opacity(0.18)))
                    y += step
                }
                x += step
            }
        }
    }
}

// MARK: - Section label (the Martian eyebrow)

/// All-caps tracked micro-label. The "stamp" that heads a section or card.
struct SectionLabel: View {
    let text: String
    var color: Color = PitchAtlasTheme.bone2
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
                ZStack {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(PitchAtlasTheme.press)
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    PitchAtlasTheme.paper2.opacity(0.72),
                                    PitchAtlasTheme.press.opacity(0.12),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [
                                    PitchAtlasTheme.powder.opacity(0.10),
                                    .clear,
                                ],
                                center: .topTrailing,
                                startRadius: 0,
                                endRadius: 240
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(PitchAtlasTheme.machined, lineWidth: 1)
            )
    }
}

/// The specimen surface: a leather-press card with a refractor edge and inset
/// print rules. This borrows the physical-card language without copying any
/// outside card layout.
struct SpecimenCardFrame: ViewModifier {
    var padding: CGFloat
    var radius: CGFloat
    var foilIntensity: Double
    var foilFillOpacity: Double

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(Color(hex: 0x0B0805))
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(PitchAtlasTheme.foil)
                        .opacity(max(0.02, foilFillOpacity * 0.65))
                        .blendMode(.screen)
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [
                                    PitchAtlasTheme.powder.opacity(0.16),
                                    .clear,
                                ],
                                center: .top,
                                startRadius: 0,
                                endRadius: 260
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(PitchAtlasTheme.foil, lineWidth: 1.5)
                    .opacity(0.48)
            )
            .overlay(
                RoundedRectangle(cornerRadius: max(2, radius - 6), style: .continuous)
                    .inset(by: 6)
                    .strokeBorder(PitchAtlasTheme.bone.opacity(0.20), lineWidth: 1)
            )
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(PitchAtlasTheme.foil)
                    .frame(height: 2)
                    .opacity(0.38)
                    .padding(.horizontal, radius)
                    .padding(.bottom, 5)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .foilRake(radius: radius, intensity: foilIntensity)
    }
}

extension View {
    /// Wrap content as a leather-press card.
    func leatherPress(padding: CGFloat = PitchAtlasSpacing.md,
                      radius: CGFloat = PitchAtlasRadius.card) -> some View {
        modifier(LeatherPress(padding: padding, radius: radius))
    }

    /// Wrap content as a foil-edged specimen card.
    func specimenCardFrame(padding: CGFloat = PitchAtlasSpacing.md,
                           radius: CGFloat = PitchAtlasRadius.card,
                           foilIntensity: Double = 0.75,
                           foilFillOpacity: Double = 0.055) -> some View {
        modifier(SpecimenCardFrame(
            padding: padding,
            radius: radius,
            foilIntensity: foilIntensity,
            foilFillOpacity: foilFillOpacity
        ))
    }
}

// MARK: - Seal mark (the vector brand fallback)

struct BrandSealMark: View {
    var size: CGFloat = 72
    var shadow: Bool = true

    var body: some View {
        Image("BrandSeal")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.20, style: .continuous)
                    .strokeBorder(PitchAtlasTheme.bone.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: shadow ? PitchAtlasTheme.seamBright.opacity(0.18) : .clear,
                    radius: 18, x: 0, y: 8)
            .accessibilityHidden(true)
    }
}

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
                .stroke(PitchAtlasTheme.bone2.opacity(0.7), lineWidth: 1.5)
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

/// Loading: a source-tagged skeleton, never a bare spinner. The pulse is the one
/// looping animation in the kit, so it stays gated by Reduce Motion — a person who
/// asked for stillness gets a steady, legible skeleton, not a forever-breathing tile.
struct LoadingTile: View {
    var label: String = "Loading"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(i == 0 ? PitchAtlasTheme.powder.opacity(0.22) : PitchAtlasTheme.machined)
                    .frame(height: 14)
                    .frame(maxWidth: i == 2 ? 180 : .infinity)
            }
            SectionLabel(text: label, size: 9)
        }
        .opacity(reduceMotion ? 0.7 : (pulse ? 0.45 : 0.9))
        .animation(reduceMotion ? nil : .easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)
        .onAppear { if !reduceMotion { pulse = true } }
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
            BrandSealMark(size: 58)
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
            BrandSealMark(size: 50)
            Text(message)
                .font(PitchAtlasTheme.hanken(15))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PitchAtlasSpacing.xl2)
        .leatherPress()
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

// MARK: - Holographic wordmark (the refractor sheen)

/// The Atlas masthead wordmark. Rather than paint the full 8-stop foil across the
/// glyphs at once (an even "RGB strip"), this shows a metallic *slice* of the foil:
/// the gradient is oversized and offset so only a band sits inside the letters,
/// matching the web's `.rfx-chrome-text`. The brushed-metal slice rides the
/// gyroscope so the wordmark catches light as the phone tilts — the gold tin's
/// real behavior, and the one move the web can only fake. Reduce Motion holds
/// the slice still; the static slice still reads as machined metal.
struct HoloWordmark: View {
    @Environment(MotionProvider.self) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let text: String
    var size: CGFloat = 56
    var lineSpacing: CGFloat = -6

    private var glyphs: Text {
        Text(text).font(PitchAtlasTheme.anton(size))
    }

    var body: some View {
        // Type is set in metal, never in foil: the rainbow stays on the cards,
        // where holographic refractors physically exist. The gyro still rakes
        // light across the letters — brushed chrome answering a tilt is the
        // gold tin's real behavior, so the motion keeps its referent.
        let rake = reduceMotion ? 0.0 : motion.roll
        let tip = reduceMotion ? 0.0 : motion.pitch
        glyphs
            .foregroundStyle(.clear)
            .lineSpacing(lineSpacing)
            .overlay {
                PitchAtlasTheme.chrome
                    .scaleEffect(2.2)
                    .offset(x: CGFloat(rake) * 70, y: CGFloat(tip) * 22)
                    .animation(.easeOut(duration: 0.14), value: motion.roll)
                    .animation(.easeOut(duration: 0.14), value: motion.pitch)
                    .mask(glyphs.lineSpacing(lineSpacing))
            }
            .fixedSize(horizontal: false, vertical: true)
            .antonSkew()
            .accessibilityLabel(text.replacingOccurrences(of: "\n", with: " "))
            .accessibilityAddTraits(.isHeader)
    }
}
