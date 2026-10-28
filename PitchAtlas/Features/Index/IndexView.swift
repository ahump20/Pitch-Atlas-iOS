import SwiftUI

// =============================================================================
// Pitch Atlas — The Pitch Index
// =============================================================================
// Web: pages/RepertoirePage.tsx and sections/PitchIndex.tsx. The front door in
// the site's order: where you are, the title and its lede, the search with the
// filter-and-sort pill and the rows/binder toggle, the count, then every pitch
// by family — a filed pitch opens its specimen, any other its basic file. Then
// the Lost Pitches wing, the conversation shelf, the whole-repertoire map and
// the archive's back cover.
// Four-state aware: a decode failure, an empty bundle and an empty search each
// read differently, never as a blank field.
// =============================================================================

struct IndexView: View {
    @Environment(PitchStore.self) private var store

    private static let topScrollTarget = "index:top"
    private static let scrollCoordinateSpace = "pitch-index-scroll"

    @State private var query = IndexQuery()
    @State private var filtersOpen = false
    @State private var scrollRestoration = IndexScrollRestoration()
    @State private var selectedEntry: RepertoireEntry?
    @State private var selectedPitch: PitchAtlasEntry?

    var body: some View {
        ZStack {
            FieldBackdrop()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                            .id(Self.topScrollTarget)
                        VStack(alignment: .leading, spacing: 0) {
                            controls
                            if filtersOpen {
                                filterPanel.padding(.top, 16)
                            }
                            content(query.groups(in: store))
                            lostWing.padding(.top, 48)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 56)
                        // web: ExternalMediaRail, placement "repertoire", two posts
                        MediaRail(eyebrow: "Filed conversation",
                                  title: "Voices beside the taxonomy.",
                                  intro: "The index names the families. These credited lessons show how pitchers and teachers keep testing, describing, and handing the craft forward.",
                                  items: MediaShelf.query(store.externalMedia.items, placement: .repertoire, limit: 2))
                        // web: LineageMap, the whole accepted catalog as one map
                        LineageMap(groups: LineageMapOrder.groups(in: store),
                                   restorationSpace: Self.scrollCoordinateSpace) { open($0) }
                        SiteFooter(path: "/repertoire")
                    }
                    .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                    .emitsScrollProgress()
                }
                .coordinateSpace(.named(Self.scrollCoordinateSpace))
                .onPreferenceChange(IndexScrollFramesPreferenceKey.self) { frames in
                    scrollRestoration.observe(frames: frames)
                }
                .onAppear { restoreScrollPositionIfNeeded(using: proxy) }
                .onDisappear { scrollRestoration.indexDidDisappear() }
                .onChange(of: query.text) { applyFilterChange(.query, using: proxy) }
                .onChange(of: query.family) { applyFilterChange(.family, using: proxy) }
                .onChange(of: query.status) { applyFilterChange(.status, using: proxy) }
                .onChange(of: query.sort) { applyFilterChange(.sort, using: proxy) }
                .onChange(of: query.layout) { applyFilterChange(.layout, using: proxy) }
            }
        }
        // The site's header carries the brand on every page; the title still names
        // the back button on the pages the Index opens.
        .navigationTitle("The Pitch Index")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { BrandLockup(markSize: 26, wordSize: 20) }
        }
        .navigationDestination(item: Binding(
            get: { selectedEntry },
            set: { entry in
                selectedEntry = entry
                if entry == nil { scrollRestoration.navigationDidEnd() }
            }
        )) { RepertoireDetailView(entry: $0) }
        .navigationDestination(item: Binding(
            get: { selectedPitch },
            set: { pitch in
                selectedPitch = pitch
                if pitch == nil { scrollRestoration.navigationDidEnd() }
            }
        )) { PitchDetailView(entry: $0) }
        // A pitchatlas://repertoire/<id> link pushes by value (DeepLinkRouter);
        // a row tap keeps the item bindings above so the scroll anchor holds.
        .navigationDestination(for: RepertoireEntry.self) { RepertoireDetailView(entry: $0) }
    }

    // MARK: - Header

    /// The breadcrumb, the athletic title with "Index" in gold, and the lede, its
    /// counts read from the bundle. (The site's worn-seam photograph and its credit
    /// stay on the site.)
    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Breadcrumb(trail: [Crumb(label: "Pitch Atlas", path: "home"), Crumb(label: "The Pitch Index")])
                .padding(.bottom, 24)
            (Text("The Pitch ") + Text("Index").foregroundColor(ArchiveInk.indexTitleAccent))
                .font(PitchAtlasTheme.anton(40, relativeTo: .largeTitle))
                .textCase(.uppercase)
                .tracking(40 * 0.01)
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
                // .rfx-athletic sets the line at .9: Anton's own line is 1.5
                .padding(.vertical, -12)
                .padding(.top, 12)
                .accessibilityAddTraits(.isHeader)
            Text("Find the pitch you know, or follow a name you have never heard. Browse \(IndexScope.shelfLabel(store)): filed specimens open into grip study; basic files preserve the account we have.")
                .font(PitchAtlasTheme.hanken(15))
                .lineSpacing(15 * (1.625 - 1.303))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .frame(maxWidth: 58 * 0.56 * 15, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 18)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Rectangle().fill(PitchAtlasTheme.bone.opacity(0.08)).frame(height: 1).accessibilityHidden(true)
        }
    }

    // MARK: - Controls

    /// Search, then the filter-and-sort pill, the rows/binder toggle and Reset,
    /// then the live count.
    private var controls: some View {
        let total = query.groups(in: store).reduce(0) { $0 + $1.entries.count }
        return VStack(alignment: .leading, spacing: 0) {
            PitchSearchField(text: $query.text, prompt: "Search a pitch, an alias, a family…")
            FlowRow(spacing: 10, lineSpacing: 10) {
                FilterSortPill(isOpen: filtersOpen, activeCount: query.advancedCount) {
                    Haptics.toggle()
                    filtersOpen.toggle()
                }
                PillToggle(selection: $query.layout, options: [
                    (value: IndexLayout.rows, label: "Rows", systemImage: "list.bullet"),
                    (value: IndexLayout.binder, label: "Binder", systemImage: "book"),
                ])
                .accessibilityLabel("Index view")
                if query.hasActiveState {
                    Button(action: reset) {
                        Label("Reset", systemImage: "xmark")
                            .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                            .textCase(.uppercase)
                            .tracking(10 * 0.1)
                            .foregroundStyle(PitchAtlasTheme.bone2)
                            .padding(.horizontal, 12)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Reset the index")
                }
            }
            .padding(.top, 12)
            Text(query.countLabel(total: total).uppercased())
                .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                .tracking(10 * 0.1)
                .foregroundStyle(PitchAtlasTheme.ink3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .accessibilityLabel(query.countLabel(total: total))
        }
        .padding(.top, 36)
        .padding(.bottom, 12)
    }

    // MARK: - Filter panel

    /// The site's filter panel: family (with "Filed specimens"), sort, the status
    /// tiers present in the bundle, and the two notes on what the axes mean.
    private var filterPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            facetRow("Family") {
                ForEach(IndexFamilyFilter.ordered, id: \.self) { option in
                    PitchChip(kind: .filter, label: option.label, selected: query.family == option) {
                        Haptics.toggle()
                        query.family = option
                    }
                }
            }
            facetRow("Sort") {
                ForEach(IndexSort.allCases) { option in
                    PitchChip(kind: .filter, label: option.label, selected: query.sort == option) {
                        Haptics.toggle()
                        query.sort = option
                    }
                    .accessibilityLabel(option.accessibilityLabel)
                }
            }
            if presentStatuses.count > 1 {
                facetRow("Status") {
                    PitchChip(kind: .filter, label: "All", selected: query.status == nil) {
                        Haptics.toggle()
                        query.status = nil
                    }
                    .accessibilityLabel("All statuses")
                    ForEach(presentStatuses, id: \.self) { tier in
                        PitchChip(kind: .filter, label: tier.displayLabel, selected: query.status == tier) {
                            Haptics.toggle()
                            query.status = tier
                        }
                    }
                }
            }
            // web PitchIndex.tsx, verbatim
            VStack(alignment: .leading, spacing: 8) {
                Text("Documentation depth is how richly the atlas has preserved a grip, richest first: filmed in the pitcher's own hand, then a first-party still, then a filed reference. The lone ember 1 of 1 is the four-seam, specimen 00.")
                Text("Status is the atlas's filing label for an entry. Banned, alias, illusion, and not-a-pitch entries are honest edges, labeled for what they are, never dressed up as a chase.")
            }
            .font(PitchAtlasTheme.hanken(11.5, relativeTo: .footnote))
            .lineSpacing(2)
            .foregroundStyle(PitchAtlasTheme.bone2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 12)
            .overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1) }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(ArchiveInk.indexPanelFill))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
    }

    private func facetRow<Chips: View>(_ label: String, @ViewBuilder chips: () -> Chips) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(label.uppercased())
                .font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2))
                .tracking(9 * 0.14)
                .foregroundStyle(PitchAtlasTheme.ink3)
                .frame(width: 56, alignment: .leading)
                .accessibilityHidden(true)
            FlowRow(spacing: 6, lineSpacing: 6) { chips() }
                .accessibilityElement(children: .contain)
                .accessibilityLabel(label)
        }
    }

    /// The tiers actually present in the bundle, in the legend's order.
    private var presentStatuses: [RepertoireStatus] {
        let present = Set(store.repertoire.entries.map(\.status))
        let order: [RepertoireStatus] = [.standard, .niche, .rare, .nearExtinct, .banned, .alias, .illusion, .notAPitch]
        return order.filter(present.contains)
    }

    private func reset() {
        Haptics.toggle()
        query = IndexQuery()
        UIAccessibility.post(notification: .announcement, argument: "Index reset")
    }

    // MARK: - Content (the four states)

    @ViewBuilder
    private func content(_ groups: [IndexGroup]) -> some View {
        if case .failed(let reason) = store.status {
            ErrorStateView(reason: reason).padding(.top, 36)
        } else if store.repertoire.entries.isEmpty {
            EmptyStateView(message: "The index couldn't load.").padding(.top, 36)
        } else if groups.isEmpty {
            emptyResult.padding(.vertical, 48)
        } else {
            ForEach(groups, id: \.info.id) { group in
                familySection(group).padding(.top, 36)
            }
        }
    }

    /// The empty search names the lever to pull: the term, or the filters.
    private var emptyResult: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
                .foregroundStyle(Color(rgb: WebTokens.Accent.burnt))
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color(rgb: WebTokens.Accent.burnt).opacity(0.12)))
                .accessibilityHidden(true)
            Text(query.emptyTitle.uppercased())
                .font(PitchAtlasTheme.anton(30, relativeTo: .title))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .multilineTextAlignment(.center)
                .antonSkew()
                .accessibilityAddTraits(.isHeader)
            Text(query.emptyDescription(indexed: store.repertoire.entries.count))
                .font(PitchAtlasTheme.hanken(13, relativeTo: .footnote))
                .foregroundStyle(PitchAtlasTheme.ink3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: reset) {
                Label("Reset index", systemImage: "xmark")
                    .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                    .textCase(.uppercase)
                    .tracking(10 * 0.12)
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 44)
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(PitchAtlasTheme.bone.opacity(0.2), lineWidth: 1))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 56)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(ArchiveInk.indexPanelFill))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
    }

    // MARK: - A family

    /// The family header (Anton in the family's ink, "N in family", an accent rule)
    /// over its rows or its binder sheet.
    private func familySection(_ group: IndexGroup) -> some View {
        let accent = group.info.family.accent
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Text(group.info.label.uppercased())
                    .font(PitchAtlasTheme.anton(24, relativeTo: .title2))
                    .tracking(24 * 0.01)
                    .foregroundStyle(accent)
                    .antonSkew()
                    .padding(.vertical, -7)
                Text("\(group.entries.count) in family".uppercased())
                    .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                    .tracking(10 * 0.12)
                    .foregroundStyle(PitchAtlasTheme.ink3)
            }
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottom) { Rectangle().fill(accent.opacity(0.36)).frame(height: 1).accessibilityHidden(true) }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .padding(.bottom, 16)

            switch query.layout {
            case .rows: rows(group)
            case .binder: binder(group)
            }
        }
    }

    /// Each row is its own card (the web's rows grid, 11pt apart); a filed row
    /// carries Compare beneath it, outside the row's button, under a white .067
    /// rule (compare.css, max-width 600px).
    private func rows(_ group: IndexGroup) -> some View {
        VStack(spacing: 11) {
            ForEach(group.entries) { entry in
                VStack(alignment: .leading, spacing: 0) {
                    Button { open(entry) } label: { IndexRow(entry: entry) }
                        .buttonStyle(.plain)
                    if let slug = entry.filedSlug {
                        CompareButton(slug: slug).padding(.leading, 64)
                    }
                }
                .padding(.bottom, 8)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color.white.opacity(17.0 / 255)).frame(height: 1).accessibilityHidden(true)
                }
                .modifier(RestorationAnchor(target: scrollTarget(for: entry), space: Self.scrollCoordinateSpace))
            }
        }
    }

    /// The binder spread: the family as a leather sheet of sleeves.
    private func binder(_ group: IndexGroup) -> some View {
        BinderSheet(label: "\(group.info.label) family, binder sheet") {
            ForEach(Array(group.entries.enumerated()), id: \.element.id) { index, entry in
                VStack(spacing: 6) {
                    RepertoirePocket(entry: entry, index: index) { open($0) }
                    if let slug = entry.filedSlug { CompareButton(slug: slug) }
                }
                .modifier(RestorationAnchor(target: scrollTarget(for: entry), space: Self.scrollCoordinateSpace))
            }
        }
    }

    /// A filed pitch opens its specimen, as the site links it to /pitch/<slug>;
    /// any other opens its basic file. The reader's row is captured first.
    private func open(_ entry: RepertoireEntry) {
        // Capture before the push can relayout this scroll view. Button activation
        // includes VoiceOver and Switch Control.
        scrollRestoration.beginNavigation()
        if let pitch = entry.filedSlug.flatMap(store.pitch(slug:)) {
            selectedPitch = pitch
        } else {
            selectedEntry = entry
        }
    }

    // MARK: - The Lost Pitches wing

    /// The callout under the families: a wing of its own, its count from the bundle.
    private var lostWing: some View {
        RouteButton(path: "lost-pitches") {
            VStack(alignment: .leading, spacing: 0) {
                Text("A wing of its own".uppercased())
                    .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                    .tracking(10 * 0.18)
                    .foregroundStyle(ArchiveInk.tealGlow)
                Text("Lost Pitches of the Negro Leagues".uppercased())
                    .font(PitchAtlasTheme.anton(24, relativeTo: .title2))
                    .tracking(24 * 0.01)
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .antonSkew()
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, -7)
                    .padding(.top, 8)
                Text("The statistics are being recovered; the technique mostly never will be. A box score survives; a grip does not. So every entry wears a documentation tier (Documented, Partial, or Legend) instead of faking a precision the record cannot support. The tier is the feature.")
                    .font(PitchAtlasTheme.hanken(14))
                    .lineSpacing(14 * (1.625 - 1.303))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)
                HStack(spacing: 8) {
                    Text("Enter the wing".uppercased()).foregroundStyle(PitchAtlasTheme.bone)
                    Text("→").foregroundStyle(ArchiveInk.tealGlow).accessibilityHidden(true)
                    Text("· \(store.lostPitches.entries.count) filed".uppercased()).foregroundStyle(PitchAtlasTheme.ink3)
                }
                .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                .tracking(10 * 0.12)
                .padding(.top, 16)
            }
            .multilineTextAlignment(.leading)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    Color(web: WebTokens.Palette.press)
                    EllipticalGradient(colors: [ArchiveInk.lostCalloutGlow, ArchiveInk.lostCalloutFloor],
                                       center: UnitPoint(x: 0.75, y: 0.1), startRadiusFraction: 0, endRadiusFraction: 0.8)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .accessibilityHidden(true)
            }
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(ArchiveInk.lostCalloutRim, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens Lost Pitches of the Negro Leagues")
    }

    // MARK: - Scroll restoration

    private func scrollTarget(for entry: RepertoireEntry) -> String {
        "index:entry:\(entry.id)"
    }

    private func restoreScrollPositionIfNeeded(using proxy: ScrollViewProxy) {
        guard let position = scrollRestoration.indexDidAppear() else { return }
        switch position {
        case .top:
            proxy.scrollTo(Self.topScrollTarget, anchor: .top)
        case .row(let target):
            proxy.scrollTo(target, anchor: .top)
        }
    }

    private func applyFilterChange(_ change: IndexFilterChange, using proxy: ScrollViewProxy) {
        scrollRestoration.invalidate()
        if change.resetsToTop { proxy.scrollTo(Self.topScrollTarget, anchor: .top) }
    }
}

/// Marks a row (or a family on the map) as a place the Index can return to: its
/// scroll id, and its frame in the scroll view for IndexScrollRestoration to read.
struct RestorationAnchor: ViewModifier {
    let target: String
    let space: String

    func body(content: Content) -> some View {
        content
            .id(target)
            .background {
                GeometryReader { geometry in
                    Color.clear.preference(key: IndexScrollFramesPreferenceKey.self,
                                           value: [target: geometry.frame(in: .named(space))])
                }
            }
    }
}

/// What changed in the Index controls. Typing narrows the list where the reader
/// already is; a new family, status, sort or view is a new list and starts at the top.
enum IndexFilterChange {
    case query, family, status, sort, layout
    var resetsToTop: Bool { self != .query }
}

private struct IndexScrollFramesPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, next in next })
    }
}
