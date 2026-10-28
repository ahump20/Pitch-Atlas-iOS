import SwiftUI

// =============================================================================
// PitchConnections — keep following the pitch
// =============================================================================
// Web: components/pitch/PitchConnections.tsx (styled by world.css
// .archive-connection-heading and .archive-companion) and pages/PitchChapter.tsx
// Pager. The connective tissue at the foot of a specimen, read off the data: a
// companion grip from the same family to set beside this one, the masters who
// owned the pitch, and the rest of the family. A specimen with no filed master
// and no sibling shows none of it rather than an empty rail.
// =============================================================================

struct PitchConnections: View {
    let entry: PitchAtlasEntry
    let accentRGB: UInt32

    @Environment(PitchStore.self) private var store
    @Environment(\.compareSelection) private var comparison

    private var familyLabel: String { entry.canonical.family.label.lowercased() }

    var body: some View {
        let masters = store.masters(forPitch: entry.slug)
        let siblings = store.siblings(of: entry)
        if !masters.isEmpty || !siblings.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                heading.padding(.bottom, 32)
                if let companion = siblings.first { companionCard(companion).padding(.bottom, 40) }
                if !masters.isEmpty { mastersBlock(masters).padding(.bottom, 48) }
                if !siblings.isEmpty { siblingsBlock(siblings) }
            }
            .padding(.vertical, 48)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) { Rectangle().fill(PitchAtlasTheme.bone.opacity(0.08)).frame(height: 1) }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Connections")
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 0) {
            ArchiveEyebrow(text: "Keep following the pitch", ink: ArchiveInk.discoveryEyebrow)
            Text("A hold is a beginning.")
                .font(PitchAtlasType.font(.newsreader400, size: 32, relativeTo: .largeTitle))
                .tracking(em: -0.025, size: 32)
                .foregroundStyle(PitchAtlasTheme.bone)
                .cssLineHeight(1.06, face: .newsreader400, size: 32, relativeTo: .largeTitle)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 12)
                .accessibilityAddTraits(.isHeader)
            Text("Set another grip beside it, meet a practitioner, or add what you noticed to the conversation.")
                .font(PitchAtlasType.font(.hanken400, size: 15, relativeTo: .body))
                .foregroundStyle(ArchiveInk.discoveryLede)
                .cssLineHeight(1.7, face: .hanken400, size: 15, relativeTo: .body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// `.archive-companion`: the first sibling's schematic, set beside this one,
    /// with the one link that puts the two on the comparison table.
    private func companionCard(_ companion: PitchAtlasEntry) -> some View {
        let filed = companion.canonical.gripModel.status != .unfiled
        return VStack(alignment: .leading, spacing: 24) {
            SeamBall(motion: companion.motion, size: 180, contacts: filed ? companion.canonical.fingerPlacement : [],
                     orientation: companion.canonical.gripModel.defaultView, showMovement: false,
                     referenceContacts: filed ? companion.canonical.fingerPlacement : nil,
                     contactMarks: .dots, showsLacing: false)
                .dynamicTypeSize(.large)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                ArchiveEyebrow(text: "Another \(familyLabel) in the collection", ink: ArchiveInk.discoveryEyebrow)
                Text("Set it beside the \(companion.display.shortName.lowercased()).")
                    .font(PitchAtlasType.font(.newsreader400, size: 32, relativeTo: .title))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .cssLineHeight(1.1, face: .newsreader400, size: 32, relativeTo: .title)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                    .padding(.bottom, 18)
                RefractorClaimView(claim: companion.canonical.grip)
                Button { compare(with: companion) } label: {
                    ArchiveLinkLabel(title: "Compare these two grips", ink: PitchAtlasTheme.bone)
                }
                .buttonStyle(.plain)
                .padding(.top, 18)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                ChapterInk.companionFloor
                EllipticalGradient(stops: [.init(color: ChapterInk.companionGlow, location: 0),
                                           .init(color: ChapterInk.companionFloor, location: 0.6)],
                                   center: UnitPoint(x: 0.1, y: 0.5), startRadiusFraction: 0, endRadiusFraction: 1)
            }
        }
        .overlay(Rectangle().strokeBorder(ChapterInk.companionRim, lineWidth: 1))
    }

    /// The site's compareUrl({ a, b }): both pitches on the table, grips view.
    private func compare(with companion: PitchAtlasEntry) {
        guard let url = URL(string: "pitchatlas://compare?a=\(entry.slug)&b=\(companion.slug)") else { return }
        comparison.handle(url, store: store)
        Haptics.selection()
    }

    private func mastersBlock(_ masters: [Craftsman]) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 9) {
                Rectangle().fill(Color(rgb: accentRGB)).frame(width: 22, height: 2)
                Text((masters.count > 1 ? "The people behind the pitch" : "The person behind the pitch").uppercased())
                    .font(PitchAtlasType.font(.martian500, size: 11, relativeTo: .caption))
                    .tracking(em: 0.2, size: 11)
                    .foregroundStyle(PitchAccents.accentInk(accentRGB))
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            VStack(spacing: 16) {
                ForEach(masters) { person in
                    NavigationLink { CraftsmanDetailView(craftsman: person) } label: { masterPlate(person) }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private func masterPlate(_ person: Craftsman) -> some View {
        let tint = person.signaturePitchSlug.map { PitchAccents.triad(for: $0).c3 } ?? accentRGB
        return Plate(accent: Color(rgb: tint)) {
            mono("\(person.specimenNo) · \(person.era)", ink: PitchAtlasTheme.ink3)
            Text(person.name.uppercased())
                .font(PitchAtlasType.font(.anton400, size: 24, relativeTo: .title2))
                .tracking(em: 0.01, size: 24)
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
            Text(person.tagline)
                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
            HStack(spacing: 8) {
                mono(person.signaturePitch, ink: PitchAtlasTheme.bone2)
                mono("Follow the story →", ink: PitchAtlasTheme.cyan)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func mono(_ text: String, ink: some ShapeStyle) -> some View {
        Text(text.uppercased())
            .font(PitchAtlasType.font(.martian400, size: 11, relativeTo: .caption2))
            .tracking(em: 0.14, size: 11)
            .foregroundStyle(ink)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func siblingsBlock(_ siblings: [PitchAtlasEntry]) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            KickerLabel(text: "Others in the \(familyLabel)")
            FlowRow(spacing: 12, lineSpacing: 12) {
                ForEach(siblings) { sibling in
                    NavigationLink { PitchDetailView(entry: sibling) } label: { siblingPill(sibling) }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    /// A sibling: its glowing dot (burnt for the 1/1, its own accent otherwise),
    /// its name, the arrow.
    private func siblingPill(_ sibling: PitchAtlasEntry) -> some View {
        let dot = Color(rgb: SpecimenReads.accentRGB(sibling))
        return HStack(spacing: 10) {
            Circle().fill(dot).frame(width: 10, height: 10).shadow(color: dot, radius: 3)
            Text(sibling.canonical.name)
                .font(PitchAtlasType.font(.hanken700, size: 14, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.bone)
            Text("→")
                .font(PitchAtlasType.font(.martian400, size: 11, relativeTo: .caption2))
                .foregroundStyle(PitchAtlasTheme.ink3)
                .accessibilityHidden(true)
        }
        .padding(.leading, 12)
        .padding(.trailing, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 44)
        .overlay(Capsule().strokeBorder(PitchAtlasTheme.bone.opacity(0.15), lineWidth: 1))
        .contentShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(sibling.canonical.name), open specimen")
    }
}

/// Pager: the previous and next files in filed order, and the way to the hall
/// between them.
struct SpecimenPager: View {
    let entry: PitchAtlasEntry
    @Environment(PitchStore.self) private var store

    var body: some View {
        let around = SpecimenReads.neighbors(of: entry, in: store.pitches)
        VStack(spacing: 16) {
            if let previous = around.previous {
                NavigationLink { PitchDetailView(entry: previous) } label: {
                    neighbor("← Previous specimen", previous.canonical.name, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
            RouteButton(path: "craftsmen") {
                VStack(spacing: 4) {
                    Text("The Craftsmen".uppercased())
                        .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                        .tracking(em: 0.1, size: 10)
                        .foregroundStyle(PitchAtlasTheme.cyan)
                    Text("The arms who defined the craft →")
                        .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                        .foregroundStyle(PitchAtlasTheme.bone2)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 44)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(PitchAtlasTheme.bone.opacity(0.2), lineWidth: 1))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if let next = around.next {
                NavigationLink { PitchDetailView(entry: next) } label: {
                    neighbor("Next specimen →", next.canonical.name, alignment: .trailing)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 48)
        .overlay(alignment: .top) { Rectangle().fill(PitchAtlasTheme.bone.opacity(0.1)).frame(height: 1) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pitch chapters")
    }

    private func neighbor(_ label: String, _ name: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(label.uppercased())
                .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                .tracking(em: 0.1, size: 10)
                .foregroundStyle(PitchAtlasTheme.ink3)
            Text(name.uppercased())
                .font(PitchAtlasTheme.anton(18, relativeTo: .headline))
                .tracking(em: 0.01, size: 18)
                .foregroundStyle(PitchAtlasTheme.bone)
                .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
                .transformEffect(CardSkew.transform(degrees: -7))
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: alignment == .leading ? .leading : .trailing)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
