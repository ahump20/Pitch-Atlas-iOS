import SwiftUI

/// `.rfx-panel`: press ground, bone .10 hairline, the raking catch (white .4 band
/// at 20%, screen, .55) and a 16% accent rim. No hover, no motion — the web has none.
struct PanelSurface: View {
    static let catchPeakOpacity = 0.4
    static let catchLayerOpacity = 0.55
    static let rimOpacity = 0.16
    var radius: CGFloat = PitchAtlasRadius.panel
    var accent: Color = PitchAtlasTheme.cyan

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        shape.fill(PitchAtlasTheme.press)
            .overlay {
                shape.fill(LinearGradient(stops: [
                    .init(color: .clear, location: 0.06),
                    .init(color: .white.opacity(Self.catchPeakOpacity), location: 0.20),
                    .init(color: .clear, location: 0.40)],
                    startPoint: PitchAtlasMaterials.cssEndpoints(angle: 101, aspect: 2).start,
                    endPoint: PitchAtlasMaterials.cssEndpoints(angle: 101, aspect: 2).end))
                .blendMode(.screen).opacity(Self.catchLayerOpacity)
            }
            .overlay { shape.strokeBorder(accent.opacity(Self.rimOpacity), lineWidth: 1) }
            .overlay { shape.strokeBorder(PitchAtlasTheme.bone.opacity(0.10), lineWidth: 1) }
            .accessibilityHidden(true).allowsHitTesting(false)
    }
}

extension View {
    /// `.rfx-panel-foil`: a 1px still foil edge around a press-2 interior.
    func panelFoil(radius: CGFloat = PitchAtlasRadius.panel) -> some View {
        background(RoundedRectangle(cornerRadius: radius - 1, style: .continuous).fill(PitchAtlasTheme.press2))
            .padding(1)
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(PitchAtlasMaterials.foil(aspect: 2)))
    }
}

/// The web hairline: machined .20 fading out from 64%.
struct Hairline: View {
    var body: some View {
        Rectangle().fill(LinearGradient(stops: [
            .init(color: PitchAtlasTheme.machined, location: 0),
            .init(color: PitchAtlasTheme.machined, location: 0.64),
            .init(color: .clear, location: 1)], startPoint: .leading, endPoint: .trailing))
        .frame(height: 1).accessibilityHidden(true)
    }
}

/// The section kicker: Martian 500, 11, .2em, cyan, led by a 22×2 rule.
struct KickerLabel: View {
    static let ruleSize = CGSize(width: 22, height: 2)
    static let gap: CGFloat = 9
    static let trackingEm: CGFloat = 0.2
    let text: String
    var body: some View {
        HStack(spacing: Self.gap) {
            Rectangle().fill(PitchAtlasTheme.kicker).frame(width: Self.ruleSize.width, height: Self.ruleSize.height)
                .accessibilityHidden(true)
            Text(text.uppercased()).font(PitchAtlasType.kicker)
                .tracking(em: Self.trackingEm, size: 11)
                .foregroundStyle(PitchAtlasTheme.kicker)
        }
        .accessibilityElement(children: .combine).accessibilityAddTraits(.isHeader)
    }
}

/// The web stamp: mono 9, .14em, 4×9 padding, 1px currentColor, radius 3, −1°.
struct InkStamp: View {
    static let fontSize: CGFloat = 9
    static let padding = EdgeInsets(top: 4, leading: 9, bottom: 4, trailing: 9)
    static let rotation: Double = -1
    let text: String
    var color: Color = PitchAtlasTheme.bone2
    var body: some View {
        Text(text.uppercased())
            .font(PitchAtlasType.font(.martian400, size: Self.fontSize, relativeTo: .caption2))
            .tracking(em: 0.14, size: Self.fontSize)
            .foregroundStyle(color)
            .padding(Self.padding)
            .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(color, lineWidth: 1))
            .rotationEffect(.degrees(Self.rotation))
    }
}
