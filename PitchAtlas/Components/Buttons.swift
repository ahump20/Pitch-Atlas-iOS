import SwiftUI

// =============================================================================
// Buttons — the web's kinds (spec §1)
// =============================================================================
// Chrome is the one rosin-dusted primary per view; ghost is its quiet partner;
// the wax seal is for About and Not Found only; chapter buttons take their ink
// from the pitch accent; link is mono micro-caps. Every kind keeps a 44pt hit.
// =============================================================================

enum PitchButtonKind: Equatable {
    case chrome, ghost, waxSeal, chapter(fill: UInt32), link

    var minHitHeight: CGFloat { 44 }

    /// Fill and ink for a chapter button (accentButton, 4.5:1); zero for the others.
    var colors: (fill: UInt32, ink: UInt32) {
        if case .chapter(let fill) = self {
            let pair = PitchAccents.accentButton(fill: fill)
            return (pair.background, pair.foreground)
        }
        return (0, 0)
    }
}

struct PitchButtonStyle: ButtonStyle {
    let kind: PitchButtonKind
    func makeBody(configuration: Configuration) -> some View {
        PitchButtonBody(kind: kind, configuration: configuration)
    }
}

extension ButtonStyle where Self == PitchButtonStyle {
    static func pitch(_ kind: PitchButtonKind) -> PitchButtonStyle { PitchButtonStyle(kind: kind) }
}

private struct PitchButtonBody: View {
    let kind: PitchButtonKind
    let configuration: ButtonStyleConfiguration
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var puffs: [UUID] = []

    var body: some View {
        label
            .frame(minHeight: kind.minHitHeight)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed && !reduceMotion && kind != .link ? 0.98 : 1)
            .animation(PitchAtlasMotion.animation(PitchAtlasMotion.tiny, reduceMotion: reduceMotion), value: configuration.isPressed)
            .overlay {
                if kind == .chrome && !reduceMotion {
                    ZStack { ForEach(puffs, id: \.self) { _ in RosinPuffView() } }
                        .allowsHitTesting(false)
                }
            }
            .onChange(of: configuration.isPressed) { _, pressed in
                guard pressed, kind == .chrome, !reduceMotion else { return }
                let id = UUID()
                puffs.append(id)
                DispatchQueue.main.asyncAfter(deadline: .now() + RosinPuff.duration) { puffs.removeAll { $0 == id } }
            }
    }

    @ViewBuilder private var label: some View {
        switch kind {
        case .chrome:
            configuration.label
                .font(PitchAtlasType.chromeCTA).tracking(em: 0.14, size: 11).textCase(.uppercase)
                .foregroundStyle(PitchAtlasTheme.bone)
                .padding(.horizontal, 20).padding(.vertical, 11)
                .background { ChromeFace() }
        case .ghost:
            configuration.label
                .font(PitchAtlasType.chromeCTA).tracking(em: 0.14, size: 11).textCase(.uppercase)
                .foregroundStyle(PitchAtlasTheme.bone)
                .padding(.horizontal, 20).padding(.vertical, 11)
                .background {
                    Capsule().fill(ComponentInk.ghostFill)
                        .overlay { Capsule().strokeBorder(PitchAtlasTheme.bone.opacity(0.4), lineWidth: 1) }
                }
        case .waxSeal:
            configuration.label
                .font(PitchAtlasType.font(.anton400, size: 14, relativeTo: .callout)).tracking(em: 0.06, size: 14).textCase(.uppercase)
                .foregroundStyle(PitchAtlasTheme.bone)
                .padding(.horizontal, 22).padding(.vertical, 13)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [ComponentInk.sealFaceTop, ComponentInk.sealFaceBottom], startPoint: .top, endPoint: .bottom))
                        .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(ComponentInk.sealBorder, lineWidth: 1) }
                        .padding(-3).overlay { RoundedRectangle(cornerRadius: 13).strokeBorder(PitchAtlasTheme.bone, lineWidth: 3) }
                        .padding(-4).overlay { RoundedRectangle(cornerRadius: 17).strokeBorder(ComponentInk.sealHalo, lineWidth: 4) }
                }
                .padding(7)
        case .chapter:
            configuration.label
                .font(PitchAtlasType.font(.martian500, size: 14, relativeTo: .callout))
                .foregroundStyle(Color(rgb: kind.colors.ink))
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(rgb: kind.colors.fill)))
        case .link:
            configuration.label
                .font(PitchAtlasType.font(.martian600, size: 11, relativeTo: .caption)).tracking(em: 0.14, size: 11).textCase(.uppercase)
                .foregroundStyle(PitchAtlasTheme.bone2)
                .opacity(configuration.isPressed ? 0.7 : 1)
        }
    }
}

/// `.v2-cta`: a dark lacquer face inside a 1px foil rim, a top lip, a specular
/// band, a deep drop and a faint cyan halo.
private struct ChromeFace: View {
    var body: some View {
        Capsule()
            .fill(LinearGradient(colors: [ComponentInk.chromeFaceTop, ComponentInk.chromeFaceBottom], startPoint: .top, endPoint: .bottom))
            .overlay {
                Capsule().fill(LinearGradient(stops: [
                    .init(color: .clear, location: 0.10),
                    .init(color: .white.opacity(0.45), location: 0.22),
                    .init(color: .clear, location: 0.34)], startPoint: .leading, endPoint: .trailing))
                .blendMode(.screen).opacity(0.6)
            }
            .overlay(alignment: .top) {
                Capsule().fill(Color.white.opacity(0.16)).frame(height: 1).padding(.horizontal, 14).padding(.top, 1)
            }
            .overlay { Capsule().strokeBorder(PitchAtlasMaterials.foil(aspect: 4), lineWidth: 1) }
            .shadow(color: .black.opacity(0.9), radius: 11, y: 8)
            .shadow(color: PitchAtlasTheme.cyan.opacity(0.35), radius: 12)
            .accessibilityHidden(true)
    }
}

struct RosinGrain: Equatable {
    let x: Double
    let y: Double
    let radius: Double
    let alpha: Double
}

/// The web's rosin puff (spec Appendix C) with a fixed seed so it is repeatable.
enum RosinPuff {
    static let grainCount = 30
    static let duration = 0.8
    static let box: CGFloat = 180

    private static func unit(_ i: Int, _ salt: Int) -> Double {
        let v = sin(Double(i * 127 + salt * 311) * 12.9898) * 43758.5453
        return v - floor(v)
    }

    static func grain(_ i: Int, at t: Double) -> RosinGrain? {
        let a = unit(i, 1) * 2 * .pi
        let v = 28 + unit(i, 2) * 90
        let vx = cos(a) * v, vy = sin(a) * v * 0.6 - 38
        let r = 0.45 + unit(i, 3) * 1.15
        let life = 0.5 + unit(i, 4) * 0.35
        let u = t / life
        guard u < 1 else { return nil }
        let travel = (1 - exp(-3.2 * t)) / 3.2
        return RosinGrain(x: 90 + vx * travel, y: 90 + vy * travel + 46 * t * t, radius: r, alpha: 0.8 * (1 - u) * (1 - u))
    }
}

private struct RosinPuffView: View {
    @State private var start = Date()
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSince(start)
            Canvas { ctx, _ in
                let k = min(t / RosinPuff.duration, 1)
                let radius = 10 + 40 * k
                let center = CGPoint(x: 90, y: 90 - 10 * k)
                ctx.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: 2 * radius, height: 2 * radius)),
                         with: .radialGradient(Gradient(colors: [ComponentInk.rosin.opacity(0.2 * (1 - k)), .clear]),
                                               center: center, startRadius: 0, endRadius: radius))
                for i in 0..<RosinPuff.grainCount {
                    guard let g = RosinPuff.grain(i, at: t) else { continue }
                    ctx.fill(Path(ellipseIn: CGRect(x: g.x - g.radius, y: g.y - g.radius, width: 2 * g.radius, height: 2 * g.radius)),
                             with: .color(PitchAtlasTheme.bone.opacity(g.alpha)))
                }
            }
            .frame(width: RosinPuff.box, height: RosinPuff.box)
        }
        .accessibilityHidden(true)
    }
}
