import SwiftUI

// =============================================================================
// Pitch Atlas — The Pitch Index
// =============================================================================
// The core native surface: a searchable, family-filterable, sortable index of
// every pitch a coach, a pitcher, or the tracking taxonomy would call a pitch.
// Honestly labeled: each row wears its status; the rows that file a fuller
// specimen push to it. Four-state aware: a decode failure, an empty bundle, and
// an empty search each read differently, never as a blank field.
// =============================================================================

enum IndexSort: String, CaseIterable, Identifiable {
    case family, az, documentation, filed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .family: return "Family"
        case .az: return "A-Z"
        case .documentation: return "Documentation"
        case .filed: return "Filed first"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .family: return "Sort by family order"
        case .az: return "Sort A to Z by name"
        case .documentation: return "Sort by documentation depth"
        case .filed: return "Sort filed specimens first"
        }
    }

    func ordered(_ entries: [RepertoireEntry], store: PitchStore) -> [RepertoireEntry] {
        switch self {
        case .family:
            return entries
        case .az:
            return entries.enumerated().sorted { lhs, rhs in
                let names = lhs.element.name.localizedStandardCompare(rhs.element.name)
                return names == .orderedSame ? lhs.offset < rhs.offset : names == .orderedAscending
            }.map(\.element)
        case .documentation:
            return entries.enumerated().sorted { lhs, rhs in
                let left = documentationRank(lhs.element, store: store)
                let right = documentationRank(rhs.element, store: store)
                return left == right ? lhs.offset < rhs.offset : left < right
            }.map(\.element)
        case .filed:
            return entries.enumerated().sorted { lhs, rhs in
                let left = lhs.element.filedSlug == nil ? 1 : 0
                let right = rhs.element.filedSlug == nil ? 1 : 0
                return left == right ? lhs.offset < rhs.offset : left < right
            }.map(\.element)
        }
    }

    func documentationRank(_ entry: RepertoireEntry, store: PitchStore) -> Int {
        guard let slug = entry.filedSlug, let pitch = store.pitch(slug: slug) else { return 4 }
        if pitch.canonical.gripFilm != nil { return 0 }
        if !(pitch.canonical.gripImages ?? []).isEmpty { return 1 }
        return 2
    }
}

struct IndexView: View {
    @Environment(PitchStore.self) private var store

    @State private var query = ""
    @State private var family: RepertoireFamily? = nil
    @State private var sort: IndexSort = .family

    var body: some View {
        ZStack {
            FieldBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xl) {
                    masthead
                    searchField
                    familyChips
                    sortControls
                    content
                }
                .padding(.horizontal, PitchAtlasSpacing.lg)
                .padding(.top, PitchAtlasSpacing.md)
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                .emitsBlazeScrollProgress()
            }
        }
        .navigationTitle("Index")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: RepertoireEntry.self) { RepertoireDetailView(entry: $0) }
    }

    // MARK: - Masthead

    private var masthead: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            SectionLabel(text: "The Pitch Index", color: PitchAtlasTheme.powder)
            Text("INDEX")
                .font(PitchAtlasTheme.anton(54))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
                .padding(.vertical, 2)
            Text("Names and families are the map. The game is still the hand, the ball, and the hitter's clock.")
                .font(PitchAtlasTheme.newsreaderItalic(17))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
            BlazeInlineCompanionView(style: .search, mood: query.isEmpty ? .sniffing : .chasing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("The Pitch Index. Names and families are the map. The game is still the hand, the ball, and the hitter's clock.")
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: PitchAtlasSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(PitchAtlasTheme.ink3)
                .accessibilityHidden(true)

            TextField("", text: $query, prompt: searchPrompt)
                .font(PitchAtlasTheme.hanken(16))
                .foregroundStyle(PitchAtlasTheme.bone)
                .tint(PitchAtlasTheme.cyan)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .submitLabel(.search)
                .accessibilityLabel("Search pitches")

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(PitchAtlasTheme.ink3)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .leatherPress(padding: PitchAtlasSpacing.sm, radius: PitchAtlasRadius.chip)
    }

    private var searchPrompt: Text {
        Text("Search pitches")
            .font(PitchAtlasTheme.hanken(16))
            .foregroundStyle(PitchAtlasTheme.ink3)
    }

    // MARK: - Family filter chips

    private var familyChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PitchAtlasSpacing.xs) {
                FilterChip(label: "All", dot: nil, selected: family == nil) {
                    Haptics.toggle()
                    family = nil
                }
                ForEach(store.repertoire.families) { info in
                    FilterChip(label: info.label,
                               dot: info.family.accent,
                               selected: family == info.family) {
                        Haptics.toggle()
                        family = (family == info.family) ? nil : info.family
                    }
                }
            }
            .padding(.horizontal, 1)
        }
    }

    // MARK: - Sort controls

    private var sortControls: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs2) {
            Text("Sort")
                .font(PitchAtlasTheme.martian(9))
                .tracking(1.3)
                .foregroundStyle(PitchAtlasTheme.ink3)
                .textCase(.uppercase)
                .accessibilityHidden(true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PitchAtlasSpacing.xs) {
                    ForEach(IndexSort.allCases) { option in
                        FilterChip(label: option.label, dot: nil, selected: sort == option) {
                            Haptics.toggle()
                            sort = option
                        }
                        .accessibilityLabel(option.accessibilityLabel)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    // MARK: - Content (the four states)

    @ViewBuilder
    private var content: some View {
        if case .failed(let msg) = store.status {
            ErrorStateView(reason: msg)
        } else if store.repertoire.entries.isEmpty {
            EmptyStateView(message: "The index couldn't load.")
        } else if filteredGroups.isEmpty {
            EmptyStateView(message: emptyResultMessage)
        } else {
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.xl2) {
                ForEach(filteredGroups, id: \.info.id) { group in
                    familyGroup(group)
                }
            }
        }
    }

    private func familyGroup(_ group: FamilyGroup) -> some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs2) {
                HStack(spacing: PitchAtlasSpacing.xs) {
                    FamilyDot(color: group.info.family.accent)
                    SectionLabel(text: group.info.label, color: group.info.family.accent)
                }
                Text(group.info.blurb)
                    .font(PitchAtlasTheme.newsreaderItalic(14))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(group.info.label). \(group.info.blurb)")

            VStack(spacing: 0) {
                ForEach(Array(group.entries.enumerated()), id: \.element.id) { idx, entry in
                    if idx > 0 { HairlineDivider() }
                    NavigationLink(value: entry) {
                        RepertoireRow(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
            }
            .specimenCardFrame(
                padding: PitchAtlasSpacing.xs,
                radius: PitchAtlasRadius.card,
                foilIntensity: 0.08,
                foilFillOpacity: 0
            )
        }
    }

    // MARK: - Filtering + grouping

    /// Entries matching the live search query (name + aka), case-insensitive.
    private var searchedEntries: [RepertoireEntry] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return store.repertoire.entries }
        return store.repertoire.entries.filter { entry in
            if entry.name.lowercased().contains(q) { return true }
            if let aka = entry.aka, aka.contains(where: { $0.lowercased().contains(q) }) { return true }
            return false
        }
    }

    /// The searched set, restricted to the selected family chip if one is active.
    private var filteredEntries: [RepertoireEntry] {
        guard let family else { return searchedEntries }
        return searchedEntries.filter { $0.family == family }
    }

    /// Groups the filtered entries under their family info, preserving the bundle's
    /// family order. Sort changes row order within each group, never the groups.
    private var filteredGroups: [FamilyGroup] {
        let entries = filteredEntries
        return store.repertoire.families.compactMap { info in
            let rows = sort.ordered(entries.filter { $0.family == info.family }, store: store)
            return rows.isEmpty ? nil : FamilyGroup(info: info, entries: rows)
        }
    }

    private var emptyResultMessage: String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "No pitches in this family."
        }
        return "No pitches match \(trimmed)."
    }

    private struct FamilyGroup {
        let info: RepertoireFamilyInfo
        let entries: [RepertoireEntry]
    }
}

// MARK: - Filter chip

/// A selectable family filter chip. The accent dot reads the family color; the
/// selected state fills cyan-tinted, the resting state is a hairline outline.
private struct FilterChip: View {
    let label: String
    let dot: Color?
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: PitchAtlasSpacing.xs) {
                if let dot { FamilyDot(color: dot, size: 6) }
                Text(label.uppercased())
                    .font(PitchAtlasTheme.martian(9))
                    .tracking(1.2)
                    .foregroundStyle(selected ? PitchAtlasTheme.void : PitchAtlasTheme.bone2)
            }
            .padding(.horizontal, PitchAtlasSpacing.sm)
            .padding(.vertical, PitchAtlasSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: PitchAtlasRadius.chip, style: .continuous)
                    .fill(selected ? PitchAtlasTheme.cyan : PitchAtlasTheme.press)
            )
            .overlay(
                RoundedRectangle(cornerRadius: PitchAtlasRadius.chip, style: .continuous)
                    .strokeBorder(selected ? Color.clear : PitchAtlasTheme.machined, lineWidth: 1)
            )
            // Guarantee a 44pt hit area (Fitts) without ballooning the painted pill.
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }
}
