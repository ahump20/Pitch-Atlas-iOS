import SwiftUI

// =============================================================================
// ReturnWaveCardChrome - native card-port shells
// =============================================================================
// TODO(fable5): Wire these into ContentCards/CardBackPanel when porting the web
// return-wave cards. Keep the same rules: dark theme, real grip material,
// source-tier chips, reduced-motion safe foil, no invented pitch metrics.
// =============================================================================

struct ReturnWaveAttributeChip: Identifiable, Hashable {
    let label: String
    let value: String

    var id: String { "\(label)-\(value)" }
}

struct ReturnWaveAttributeRow: View {
    let chips: [ReturnWaveAttributeChip]
    var isGold: Bool = false

    var body: some View {
        FlowLayout(spacing: 5, rowSpacing: 5) {
            ForEach(chips) { chip in
                Text("\(chip.label) - \(chip.value)".uppercased())
                    .font(PitchAtlasTheme.martian(7))
                    .tracking(0.7)
                    .foregroundStyle(isGold ? Color(hex: 0xFFE9B0) : PitchAtlasTheme.bone2)
                    .lineLimit(1)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(isGold ? Color(hex: 0x2A1D05, opacity: 0.48) : Color.black.opacity(0.32))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(isGold ? Color(hex: 0xCAA14A, opacity: 0.45) : PitchAtlasTheme.machined, lineWidth: 1)
                    )
            }
        }
    }
}

struct ReturnWaveNameplate: View {
    let title: String
    var isGold: Bool = false

    var body: some View {
        Text(title.uppercased())
            .font(PitchAtlasTheme.anton(26))
            .foregroundStyle(isGold ? Color(hex: 0x2A1D05) : PitchAtlasTheme.bone)
            .lineLimit(1)
            .minimumScaleFactor(0.68)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(nameplateFill, in: Capsule())
            .overlay(Capsule().strokeBorder(nameplateStroke, lineWidth: 1))
            .shadow(color: .black.opacity(0.55), radius: 12, x: 0, y: 7)
            .antonSkew()
            .accessibilityLabel(title)
    }

    private var nameplateStroke: Color {
        isGold ? Color(hex: 0xCAA14A, opacity: 0.7) : PitchAtlasTheme.machined
    }

    private var nameplateFill: LinearGradient {
        if isGold {
            return LinearGradient(
                colors: [Color(hex: 0xFFF0C2), Color(hex: 0xE8C468), Color(hex: 0x7C5A1C)],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        return LinearGradient(
            colors: [Color.white.opacity(0.32), PitchAtlasTheme.paper3, Color.black.opacity(0.75)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat
    var rowSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = layoutRows(in: proposal.width ?? .infinity, subviews: subviews)
        return CGSize(width: rows.width, height: rows.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + rowSpacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }

    private func layoutRows(in width: CGFloat, subviews: Subviews) -> CGSize {
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentWidth > 0, currentWidth + spacing + size.width > width {
                totalWidth = max(totalWidth, currentWidth)
                totalHeight += currentHeight + rowSpacing
                currentWidth = size.width
                currentHeight = size.height
            } else {
                currentWidth += (currentWidth > 0 ? spacing : 0) + size.width
                currentHeight = max(currentHeight, size.height)
            }
        }

        totalWidth = max(totalWidth, currentWidth)
        totalHeight += currentHeight
        return CGSize(width: min(totalWidth, width.isFinite ? width : totalWidth), height: totalHeight)
    }
}
