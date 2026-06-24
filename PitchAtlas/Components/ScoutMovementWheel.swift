import SwiftUI

// =============================================================================
// ScoutMovementWheel — native scaffold for the elevated card back
// =============================================================================
// TODO(fable5): port the web movement wheel from Pitch-Atlas:
// src/components/sections/ScoutMovementWheel.tsx
//
// Contract:
// - Direction + character language only.
// - No velocity, spin-rate, break inches, or fabricated magnitude.
// - Missing motion must render as an honest unfiled state.
// - Use this inside the card back after the web card language is final.
// =============================================================================

struct ScoutMovementWheel: View {
    let shapeLabel: String
    let verticalShape: String
    let horizontalDirection: String
    let character: String
    let familyLabel: String
    let sourceTierLabel: String
    let editionLabel: String
    var isFiled: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            HStack(alignment: .center, spacing: PitchAtlasSpacing.md) {
                ZStack {
                    Circle()
                        .stroke(PitchAtlasTheme.ink3.opacity(isFiled ? 0.7 : 0.35), lineWidth: 1)
                    Circle()
                        .stroke(PitchAtlasTheme.cyan.opacity(isFiled ? 0.5 : 0.2), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                    Rectangle()
                        .fill(PitchAtlasTheme.cyan.opacity(isFiled ? 0.8 : 0.25))
                        .frame(width: 1, height: 52)
                    Circle()
                        .fill(PitchAtlasTheme.paper2)
                        .frame(width: 7, height: 7)
                }
                .frame(width: 82, height: 82)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
                    Text("Movement wheel · no invented numbers".uppercased())
                        .font(PitchAtlasTheme.martian(7))
                        .tracking(0.9)
                        .foregroundStyle(PitchAtlasTheme.ink3)
                    Text(shapeLabel)
                        .font(PitchAtlasTheme.hankenMedium(15))
                        .foregroundStyle(PitchAtlasTheme.bone)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs2) {
                wheelRow("Vertical", verticalShape)
                wheelRow("Horizontal", horizontalDirection)
                wheelRow("Character", character)
            }

            HStack(spacing: PitchAtlasSpacing.xs) {
                StatusPill(text: familyLabel, tone: PitchAtlasTheme.cyan)
                StatusPill(text: sourceTierLabel, tone: PitchAtlasTheme.amberBright)
                StatusPill(text: editionLabel, tone: PitchAtlasTheme.ink3)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(PitchAtlasSpacing.md)
        .background(PitchAtlasTheme.ink2.opacity(0.55), in: RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous)
                .strokeBorder(PitchAtlasTheme.ink3.opacity(0.45), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Movement wheel, \(shapeLabel), vertical \(verticalShape), horizontal \(horizontalDirection), \(character), \(sourceTierLabel)")
    }

    private func wheelRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label.uppercased())
                .font(PitchAtlasTheme.martian(7))
                .tracking(0.8)
                .foregroundStyle(PitchAtlasTheme.ink3)
                .frame(width: 76, alignment: .leading)
            Text(value)
                .font(PitchAtlasTheme.hanken(12))
                .foregroundStyle(PitchAtlasTheme.bone2)
        }
    }
}
