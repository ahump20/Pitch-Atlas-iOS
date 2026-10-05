import SwiftUI

enum ChipKind { case tag, filter }

/// `.rfx-chip` (tag: cyan) and the Index filter-panel chip (filter: burnt).
struct ChipAppearance {
    let fill: Color?
    let ink: Color
    let border: Color
    let weight: PitchAtlasType.Face
    static func of(_ kind: ChipKind, selected: Bool) -> ChipAppearance {
        switch (kind, selected) {
        case (.tag, true): ChipAppearance(fill: PitchAtlasTheme.cyan, ink: ComponentInk.onCyanInk, border: .clear, weight: .martian600)
        case (.tag, false): ChipAppearance(fill: nil, ink: PitchAtlasTheme.bone, border: PitchAtlasTheme.cyan.opacity(0.4), weight: .martian400)
        case (.filter, true): ChipAppearance(fill: Color(rgb: WebTokens.Accent.burnt), ink: Color(rgb: WebTokens.Palette.white.rgb), border: .clear, weight: .martian500)
        case (.filter, false): ChipAppearance(fill: nil, ink: PitchAtlasTheme.bone2, border: Color.white.opacity(0.14), weight: .martian400)
        }
    }
}

struct PitchChip: View {
    static let hitHeight: CGFloat = 44
    var kind: ChipKind = .tag
    let label: String
    var dot: Color? = nil
    let selected: Bool
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let look = ChipAppearance.of(kind, selected: selected)
        Button(action: action) {
            HStack(spacing: 6) {
                if let dot { FamilyDot(color: dot, size: 6) }
                Text(label.uppercased()).font(PitchAtlasType.font(look.weight, size: 9.5, relativeTo: .caption2)).tracking(em: 0.1, size: 9.5)
            }
            .foregroundStyle(look.ink)
            .padding(.horizontal, kind == .tag ? 13 : 12).padding(.vertical, kind == .tag ? 7 : 6)
            .frame(minHeight: kind == .filter ? 32 : nil)
            .background { if let f = look.fill { Capsule().fill(f) } }
            .overlay { Capsule().strokeBorder(look.border, lineWidth: 1) }
            .frame(minHeight: Self.hitHeight).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(PitchAtlasMotion.animation(PitchAtlasMotion.short, reduceMotion: reduceMotion), value: selected)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }
}

/// `.pi-toggle` — the Index ROWS/BINDER group. On = burnt with white ink.
struct PillToggle<Value: Hashable>: View {
    static var hitHeight: CGFloat { 44 }
    @Binding var selection: Value
    let options: [(value: Value, label: String, systemImage: String)]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { i in
                let o = options[i]
                let on = o.value == selection
                Button { selection = o.value; Haptics.selection() } label: {
                    Label(o.label.uppercased(), systemImage: o.systemImage)
                        .font(PitchAtlasType.font(.martian500, size: 12, relativeTo: .caption)).tracking(em: 0.06, size: 12)
                        .foregroundStyle(on ? Color(rgb: WebTokens.Palette.white.rgb) : PitchAtlasTheme.bone)
                        .padding(.horizontal, 10).frame(height: 32)
                        .background { if on { Capsule().fill(Color(rgb: WebTokens.Accent.burnt)) } }
                        .frame(minHeight: Self.hitHeight).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(.horizontal, 2)
        .background(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 1).frame(height: 38))
    }
}

/// `.rfx-seg` — the specimen VIEW and HAND toggles. On = cyan, on-cyan ink, inset lip.
struct SegmentToggle<Value: Hashable>: View {
    static var hitHeight: CGFloat { 44 }
    @Binding var selection: Value
    let options: [(value: Value, label: String)]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { i in
                let o = options[i]
                let on = o.value == selection
                Button { selection = o.value; Haptics.selection() } label: {
                    Text(o.label.uppercased())
                        .font(PitchAtlasType.segment).tracking(em: 0.06, size: 12)
                        .foregroundStyle(on ? ComponentInk.onCyanInk : PitchAtlasTheme.bone)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background { if on { RoundedRectangle(cornerRadius: 9).fill(PitchAtlasTheme.cyan)
                            .overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.35)).frame(height: 1).padding(.horizontal, 4) } } }
                        .frame(minHeight: Self.hitHeight).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? [.isSelected, .isButton] : .isButton)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(PitchAtlasTheme.bone.opacity(0.25), lineWidth: 1).padding(.vertical, 4))
    }
}

/// The Index "Filter & sort" pill: 36pt painted, 44pt hit; burnt rim when open.
struct FilterSortPill: View {
    static let hitHeight: CGFloat = 44
    static func title(activeCount: Int) -> String { activeCount > 0 ? "Filter & sort (\(activeCount))" : "Filter & sort" }
    let isOpen: Bool
    let activeCount: Int
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(Self.title(activeCount: activeCount).uppercased(), systemImage: "slider.horizontal.3")
                .font(PitchAtlasType.chip).tracking(em: 0.1, size: 9.5)
                .foregroundStyle(isOpen ? PitchAtlasTheme.bone : PitchAtlasTheme.bone2)
                .padding(.horizontal, 14).frame(height: 36)
                .overlay(Capsule().strokeBorder(isOpen ? Color(rgb: WebTokens.Accent.burnt) : Color.white.opacity(0.14), lineWidth: 1))
                .frame(minHeight: Self.hitHeight).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isOpen ? "Open" : "Closed")
    }
}
