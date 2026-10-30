import SwiftUI

// =============================================================================
// Pitch Atlas — the brand lockup
// =============================================================================
// Web: components/brand/BrandMark.tsx. A leather-edged diamond holding a cream
// ball whose seam reads as atlas meridians, and the skewed wordmark beside it:
// PITCH in bone, ATLAS in the holo type. Static, as the site keeps it. The mark
// carries no words, so it is hidden and the lockup speaks "Pitch Atlas".
// =============================================================================

/// The lockup: the diamond and the wordmark, `gap-3`.
struct BrandLockup: View {
    /// MARK_PX and WORDMARK_SIZE: sm in the masthead, md in the footer.
    enum Size {
        case sm, md
        var mark: CGFloat { self == .sm ? 32 : 44 }
        var word: CGFloat { self == .sm ? 20 : 30 }
    }

    var size: Size = .md

    var body: some View {
        HStack(spacing: 12) {
            BrandDiamondMark(size: size.mark)
            // .rfx-athletic .rfx-skew leading-none text-bone
            (Text("Pitch ") + Text("Atlas").foregroundStyle(PitchAtlasMaterials.holoType()))
                .font(PitchAtlasTheme.anton(size.word, relativeTo: .title))
                .tracking(0.01 * size.word)
                .textCase(.uppercase)
                .foregroundStyle(PitchAtlasTheme.bone)
                .modifier(CSSSkewX())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pitch Atlas")
    }
}

/// The mark, drawn in the site's 100-unit box.
struct BrandDiamondMark: View {
    var size: CGFloat = 44

    struct Stitch: Equatable {
        let from: CGPoint
        let to: CGPoint
    }

    /// Six stitch pairs down each side of the seam, tucked toward the ball's center.
    static let stitches: [Stitch] = (0..<6).flatMap { i -> [Stitch] in
        let y = 39 + Double(i) * 4.4
        let drift = abs(Double(i) - 2.5) * 0.5
        return [Stitch(from: CGPoint(x: 35.5 + drift, y: y), to: CGPoint(x: 39.5 + drift, y: y - 1.5)),
                Stitch(from: CGPoint(x: 60.5 - drift, y: y), to: CGPoint(x: 64.5 - drift, y: y - 1.5))]
    }

    var body: some View {
        Canvas { context, canvas in
            context.scaleBy(x: canvas.width / 100, y: canvas.height / 100)
            draw(in: &context)
        }
        .frame(width: size, height: size)
        .shadow(color: BrandInk.shadow, radius: 3, x: 0, y: 2)
        .accessibilityHidden(true)
    }

    private func draw(in context: inout GraphicsContext) {
        // the leather edge and the warm-black bezel: rounded squares turned 45°
        let half = 36 * 2.0.squareRoot()
        context.fill(Self.diamond(inset: 14, radius: 16),
                     with: .linearGradient(Gradient(stops: BrandInk.leather),
                                           startPoint: CGPoint(x: 50, y: 50 - half), endPoint: CGPoint(x: 50, y: 50 + half)))
        context.fill(Self.diamond(inset: 19, radius: 13), with: .color(BrandInk.bezel))

        // the ball, lit from its upper left
        context.fill(Path(ellipseIn: CGRect(x: 28, y: 28, width: 44, height: 44)),
                     with: .radialGradient(Gradient(stops: BrandInk.ball),
                                           center: CGPoint(x: 28 + 0.40 * 44, y: 28 + 0.32 * 44), startRadius: 0, endRadius: 0.75 * 44))

        // meridians: the seam reads as a map
        context.stroke(Path(ellipseIn: CGRect(x: 41, y: 28, width: 18, height: 44)),
                       with: .color(BrandInk.meridian.opacity(0.45)), lineWidth: 1)
        context.stroke(Path(ellipseIn: CGRect(x: 32, y: 28, width: 36, height: 44)),
                       with: .color(BrandInk.meridian.opacity(0.3)), lineWidth: 1)

        // the real red horseshoe seam and its stitches
        var seam = Path()
        seam.move(to: CGPoint(x: 34, y: 36))
        seam.addQuadCurve(to: CGPoint(x: 34, y: 64), control: CGPoint(x: 44, y: 50))
        seam.move(to: CGPoint(x: 66, y: 36))
        seam.addQuadCurve(to: CGPoint(x: 66, y: 64), control: CGPoint(x: 56, y: 50))
        context.stroke(seam, with: .color(BrandInk.seam), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))

        var stitches = Path()
        for stitch in Self.stitches {
            stitches.move(to: stitch.from)
            stitches.addLine(to: stitch.to)
        }
        context.stroke(stitches, with: .color(BrandInk.seam.opacity(0.9)), lineWidth: 1.1)
    }

    /// `<rect x=inset y=inset rx=radius transform="rotate(45 50 50)">`
    private static func diamond(inset: CGFloat, radius: CGFloat) -> Path {
        let side = 100 - 2 * inset
        let turn = CGAffineTransform(translationX: 50, y: 50).rotated(by: .pi / 4).translatedBy(x: -50, y: -50)
        return Path(roundedRect: CGRect(x: inset, y: inset, width: side, height: side), cornerRadius: radius, style: .circular).applying(turn)
    }
}
