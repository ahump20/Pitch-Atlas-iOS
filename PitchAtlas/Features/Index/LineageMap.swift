import SwiftUI

// =============================================================================
// LineageMap — the whole repertoire on one screen
// =============================================================================
// Web: components/repertoire/LineageMap.tsx, the last section of
// pages/RepertoirePage.tsx. Every family in the bundle's order, each read
// workhorses first and honest edges last: a solid dot is a filed specimen, a
// hollow dot a basic file, a dashed node an edge. No lineage lines are drawn;
// the relationships live as sourced prose on each file. Every node opens its
// specimen or its basic file, so the map works by touch, VoiceOver or Switch
// Control alike.
// =============================================================================

struct LineageMap: View {
    let groups: [IndexGroup]
    /// The Index's scroll space: each family is a place the Index returns to
    /// after a pitch opened from the map.
    let restorationSpace: String
    let open: (RepertoireEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("The whole repertoire".uppercased())
                .font(PitchAtlasType.font(.martian400, size: 11, relativeTo: .caption2))
                .tracking(em: 0.18, size: 11)
                .foregroundStyle(PitchAtlasTheme.cyan)
            // .rfx-stitle at clamp(24px, 3.6vw, 40px), leading 1.04
            TightLines("Every pitch, by family.".uppercased(), face: .anton400, size: 24, lineHeight: 1.04,
                       relativeTo: .title2)
                .foregroundStyle(PitchAtlasTheme.bone)
                .padding(.top, 12)
                .accessibilityAddTraits(.isHeader)
            Text("The accepted catalog at a glance, grouped by family and read by how common the pitch is. A solid dot is a filed specimen; a hollow dot is a basic file; a dashed node is an edge case - an alias, an illusion, or a name that is not really a distinct pitch.")
                .font(PitchAtlasTheme.hanken(16))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 16)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)
            legend.padding(.top, 20)
            VStack(alignment: .leading, spacing: 40) {
                ForEach(groups, id: \.info.id) { group in
                    family(group)
                        .modifier(RestorationAnchor(target: "index:map:\(group.info.family.rawValue)", space: restorationSpace))
                }
            }
            .padding(.top, 36)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 64)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The key, in the site's words. VoiceOver already heard it in the lede
    /// above, and every node says what it is, so the marks stay silent.
    private var legend: some View {
        FlowRow(spacing: 20, lineSpacing: 8) {
            legendItem("Filed specimen") {
                Circle().fill(PitchAtlasTheme.bone).frame(width: 6, height: 6)
            }
            legendItem("Basic file") {
                Circle().strokeBorder(PitchAtlasTheme.bone2, lineWidth: 1).frame(width: 6, height: 6)
            }
            legendItem("Edge case") {
                Circle().strokeBorder(PitchAtlasTheme.bone.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                    .frame(width: 12, height: 12)
            }
        }
        .accessibilityHidden(true)
    }

    private func legendItem<Mark: View>(_ label: String, @ViewBuilder mark: () -> Mark) -> some View {
        HStack(spacing: 6) {
            mark()
            Text(label.uppercased())
                .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                .tracking(em: 0.1, size: 10)
                .foregroundStyle(PitchAtlasTheme.bone2.opacity(0.75))
        }
    }

    /// The family head (a 4×12 accent bar, the label in Anton, the count), its
    /// blurb, then its nodes.
    private func family(_ group: IndexGroup) -> some View {
        let accent = group.info.family.accent
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Capsule().fill(accent).frame(width: 4, height: 12)
                // .rfx-athletic at text-lg: Anton 18 on a 28pt line
                Text(group.info.label.uppercased())
                    .font(PitchAtlasTheme.anton(18, relativeTo: .headline))
                    .tracking(em: 0.01, size: 18)
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .cssLineHeight(28.0 / 18, face: .anton400, size: 18, relativeTo: .headline)
                Text("\(group.entries.count)")
                    .font(PitchAtlasType.font(.martian400, size: 11, relativeTo: .caption2))
                    .tracking(em: 0.18, size: 11)
                    .foregroundStyle(PitchAtlasTheme.bone2.opacity(0.75))
            }
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottom) {
                Rectangle().fill(PitchAtlasTheme.bone.opacity(0.12)).frame(height: 1)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(group.info.label), \(group.entries.count) \(group.entries.count == 1 ? "pitch" : "pitches")")
            .accessibilityAddTraits(.isHeader)
            Text(group.info.blurb)
                .font(PitchAtlasTheme.hanken(13.5, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.bone2.opacity(0.8))
                .cssLineHeight(1.625, face: .hanken400, size: 13.5, relativeTo: .subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
            FlowRow(spacing: 8, lineSpacing: 8) {
                ForEach(group.entries) { entry in
                    LineageNode(entry: entry, accent: accent) { open(entry) }
                }
            }
            .padding(.top, 16)
        }
    }
}

/// One pitch on the map: a pill at a full 44pt, its dot in the family accent.
/// A filed specimen reads bone on a firmer rim; a basic file bone-2; an edge
/// dims and dashes.
private struct LineageNode: View {
    let entry: RepertoireEntry
    let accent: Color
    let action: () -> Void

    var body: some View {
        let filed = entry.filedSlug != nil
        let edge = entry.status.isEdge
        Button(action: action) {
            HStack(spacing: 6) {
                ZStack {
                    if filed {
                        Circle().fill(accent)
                    } else {
                        Circle().strokeBorder(accent, lineWidth: 1)
                    }
                }
                .frame(width: 6, height: 6)
                .opacity(edge ? 0.5 : 1)
                Text(entry.name)
                    .font(PitchAtlasType.font(.hanken400, size: 12, relativeTo: .footnote))
                    .foregroundStyle(edge ? PitchAtlasTheme.bone2.opacity(0.6) : filed ? PitchAtlasTheme.bone : PitchAtlasTheme.bone2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .frame(minHeight: 44)
            .overlay {
                Capsule().strokeBorder(PitchAtlasTheme.bone.opacity(edge ? 0.2 : filed ? 0.3 : 0.15),
                                       style: StrokeStyle(lineWidth: 1, dash: edge ? [3, 3] : []))
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(LineageMapOrder.accessibilityLabel(for: entry))
    }
}
