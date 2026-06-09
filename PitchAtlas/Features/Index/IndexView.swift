import SwiftUI

// =============================================================================
// Pitch Atlas — The Pitch Index
// =============================================================================
// The core native surface: a searchable, family-filterable index of every pitch
// a coach, a pitcher, or the tracking taxonomy would call a pitch. Honestly
// labeled — each row wears its status; the rows that file a fuller specimen push
// to it. Four-state aware: a decode failure, an empty bundle, and an empty search
// each read differently, never as a blank field.
// =============================================================================

struct IndexView: View {
    @Environment(PitchStore.self) private var store

    @State private var query = ""
    @State private var family: RepertoireFamily? = nil

    var body: some View {
        ZStack {
            PitchAtlasTheme.void.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xl) {
                    masthead
                    searchField
                    familyChips
                    content
                }
                .padding(.horizontal, PitchAtlasSpacing.lg)
                .padding(.top, PitchAtlasSpacing.md)
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
            }
        }
        .navigationTitle("Index")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: RepertoireEntry.self) { RepertoireDetailView(entry: $0) }
    }

    // MARK: - Masthead

    private var masthead: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            SectionLabel(text: "The Pitch Index")
            Text("INDEX")
                .font(PitchAtlasTheme.anton(54))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
                .padding(.vertical, 2)
            Text("Every pitch a coach, a pitcher, or the tracking taxonomy would call a pitch — honestly labeled.")
                .font(PitchAtlasTheme.newsreaderItalic(17))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
            BlazeInlineCompanionView(style: .search, mood: query.isEmpty ? .sniffing : .chasing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("The Pitch Index. Every pitch a coach, a pitcher, or the tracking taxonomy would call a pitch, honestly labeled.")
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
            .leatherPress(padding: PitchAtlasSpacing.sm, radius: PitchAtlasRadius.card)
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
    /// family order. A family with no matching rows is dropped.
    private var filteredGroups: [FamilyGroup] {
        let entries = filteredEntries
        return store.repertoire.families.compactMap { info in
            let rows = entries.filter { $0.family == info.family }
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
