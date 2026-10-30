import SwiftUI

// =============================================================================
// Pitch Atlas — The Grip Library
// =============================================================================
// Web: pages/GripsPage.tsx and sections/GripLibrary.tsx, in their order. The
// section header; then, in the dark room a grip is read in, the jump row, the
// library (the through-line and the arsenal, "Find a grip", then each grip in
// Austin's own words with its film and photographs), the credited lessons filed
// beside it, how he put the grips to work, and the way into the comparison; the
// site's footer. Every photograph and clip is Austin's own hand, owned outright;
// the circle change, which he never photographed, shows its labeled gap instead
// of a borrowed picture. Four-state aware: a decode failure shows the error, an
// empty bundle says why.
// =============================================================================

struct GripsView: View {
    @Environment(PitchStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var query = ""

    /// Verbatim, GripsPage.tsx's SectionHero sub.
    static let heroSub = "The grip is the one thing a hitter never gets to see. These are the real ones, photographed in one pitcher’s hand, on his own ball, owned outright and captioned in his own words. Not the textbook’s idea of correct; one arm’s actual hold."

    /// The page's own coordinate space: the coal room's rows place their slice of it.
    static let pageSpace = "gripsPage"
    /// The room's top (the hero's foot) and bottom (the footer's head), as measured.
    @State private var room = CoalRoomEdges()

    var body: some View {
        ZStack {
            FieldBackdrop()

            ScrollViewReader { proxy in
                ScrollView {
                    // One eager column. A lazy stack forgets the height of a grip it has
                    // dropped and guesses it from the grips still built, so the page
                    // jumped back a screen or two past a film; nested inside an eager
                    // stack, its prefetch spun the main thread past the sixth grip. The
                    // photographs and posters draw only near the reader (NearScreen), so
                    // building every grip at once never decodes the whole library.
                    VStack(alignment: .leading, spacing: 0) {
                        SectionHero(eyebrow: "Grip library",
                                    title: Text("Grips, from the hand."),
                                    sub: Text(Self.heroSub),
                                    trail: [Crumb(label: "The Atlas", path: "home"), Crumb(label: "Grip Library")])
                            .background { CoalRoomEdges.mark("top", edge: \.maxY, in: Self.pageSpace) }
                        rows(proxy)
                        SiteFooter(path: "/grips")
                            .background { CoalRoomEdges.mark("bottom", edge: \.minY, in: Self.pageSpace) }
                    }
                    .coordinateSpace(name: Self.pageSpace)
                    .onPreferenceChange(CoalRoomEdges.Key.self) { room.take($0) }
                    .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                    .emitsScrollProgress()
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        // The site's header carries the brand on every page; the title still names
        // the back button on the pages this one opens.
        .navigationTitle("Grips")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { BrandLockup(size: .sm) }
        }
        .navigationDestination(for: PitchAtlasEntry.self) { PitchDetailView(entry: $0) }
        .navigationDestination(for: RepertoireEntry.self) { RepertoireDetailView(entry: $0) }
    }

    // MARK: - Four states

    /// The page's rows between the hero and the footer. In the dark room a grip is
    /// read in (.scene-coal), each row paints its own slice of the room.
    @ViewBuilder
    private func rows(_ proxy: ScrollViewProxy) -> some View {
        if case .failed(let msg) = store.status {
            ErrorStateView(reason: msg).padding(20)
        } else if store.grips.entries.isEmpty {
            EmptyStateView(message: "The grip library couldn't load.").padding(20)
        } else {
            let file = store.grips
            let shown = GripLibraryReads.matches(file.entries, query: query)
            Group {
                GripJumpRow(entries: file.entries) { jump(proxy, to: $0) }
                libraryHead(file, shown: shown)
                ForEach(shown) { entry in
                    GripArticle(entry: entry, gap: GripLibraryReads.gap(for: entry, in: file))
                        .padding(.horizontal, 20)
                        .padding(.top, 48)
                }
                // the library's foot (py-14)
                Color.clear.frame(height: 56)
                MediaRail(eyebrow: "Grip lessons in motion",
                          title: "More hands in the conversation.",
                          intro: "First-party photographs remain the evidence in this library. These official, credited embeds add outside teaching and history without becoming the canonical grip.",
                          items: MediaShelf.query(store.externalMedia.items, placement: .grips, limit: 4),
                          allowsSuggestion: true)
                AttackPlanSection(file: file)
                GripCompareEntry()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { CoalRoomSlice(roomTop: room.top, roomHeight: room.height, space: Self.pageSpace) }
        }
    }

    /// A chip's jump: every grip is built, so the jump lands on the grip's top rule.
    private func jump(_ proxy: ScrollViewProxy, to id: String) {
        withAnimation((reduceMotion || dynamicTypeSize.isAccessibilitySize) ? nil : .easeOut(duration: 0.25)) {
            proxy.scrollTo(id, anchor: .top)
        }
    }

    // MARK: - The library

    /// The library's head (py-14 px-5): the through-line and the arsenal, then
    /// "Find a grip". Each grip follows as its own row of the page.
    private func libraryHead(_ file: GripsFile, shown: [GripEntry]) -> some View {
        VStack(alignment: .leading, spacing: 48) {
            VStack(alignment: .leading, spacing: 16) {
                Text(file.intro)
                    .font(PitchAtlasType.font(.hanken400, size: 16, relativeTo: .body))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .cssLineHeight(1.625, face: .hanken400, size: 16, relativeTo: .body)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(file.arsenal)
                    .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    // px-5 py-4 inside the 1pt border
                    .padding(.horizontal, 21)
                    .padding(.vertical, 17)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(PitchAtlasTheme.press.opacity(0.6)))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(PitchAtlasTheme.bone.opacity(0.10), lineWidth: 1))
            }
            GripLibrarySearch(query: $query, shown: shown.count, total: file.entries.count,
                              loops: GripLibraryReads.loops(shown, reduceMotion: reduceMotion))
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
    }
}

/// The coal room's two edges in the page's space, read off the rows that bound
/// it as they lay out.
struct CoalRoomEdges: Equatable {
    var top: CGFloat = 0
    var bottom: CGFloat?
    /// Until the footer has been laid out, the room is taken as this tall.
    static let assumedHeight: CGFloat = 36_000

    var height: CGFloat { max(1, (bottom ?? top + Self.assumedHeight) - top) }

    mutating func take(_ edges: [String: CGFloat]) {
        if let t = edges["top"] { top = t }
        if let b = edges["bottom"] { bottom = b }
    }

    struct Key: PreferenceKey {
        static var defaultValue: [String: CGFloat] = [:]
        static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
            value.merge(nextValue()) { _, new in new }
        }
    }

    static func mark(_ name: String, edge: KeyPath<CGRect, CGFloat>, in space: String) -> some View {
        GeometryReader { geo in
            Color.clear.preference(key: Key.self, value: [name: geo.frame(in: .named(space))[keyPath: edge]])
        }
    }
}

// MARK: - Jump to a grip

/// GripLibraryIndex: "Jump to a grip" and a chip per grip; a chip scrolls the
/// library to that grip.
private struct GripJumpRow: View {
    let entries: [GripEntry]
    let jump: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MonoCaps(text: "Jump to a grip", trackingEm: 0.14, ink: PitchAtlasTheme.cyan)
                .accessibilityAddTraits(.isHeader)
            FlowRow(spacing: 8, lineSpacing: 8) {
                ForEach(entries) { entry in
                    Button { jump(entry.id) } label: {
                        Text(entry.label.uppercased())
                            .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                            .tracking(em: 0.1, size: 10)
                            .foregroundStyle(PitchAtlasTheme.bone2)
                            .padding(.horizontal, 13)
                            .frame(minHeight: 44)
                            .background(Capsule().fill(Color.black.opacity(0.2)))
                            .overlay(Capsule().strokeBorder(PitchAtlasTheme.bone.opacity(0.15), lineWidth: 1))
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(entry.label)
                    .accessibilityHint("Scrolls to the grip")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Rectangle().fill(PitchAtlasTheme.bone.opacity(0.08)).frame(height: 1).accessibilityHidden(true)
        }
    }
}

// MARK: - Find a grip

/// `.archive-library-search`: the label set large, the field, the count, a way
/// out of an empty search, and Pause while a grip on show moves.
private struct GripLibrarySearch: View {
    @Binding var query: String
    let shown: Int
    let total: Int
    let loops: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Find a grip")
                .font(PitchAtlasType.font(.newsreader400, size: 30, relativeTo: .title))
                .foregroundStyle(ArchiveInk.librarySearchLabel)
                .cssLineHeight(1.1, face: .newsreader400, size: 30, relativeTo: .title)
                .accessibilityHidden(true)
            TextField("", text: $query,
                      prompt: Text("Pitch name or grip cue").foregroundStyle(PitchAtlasTheme.placeholder))
                .font(PitchAtlasType.font(.hanken400, size: 16, relativeTo: .body))
                .foregroundStyle(ArchiveInk.librarySearchInk)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                // 12pt in from the 1pt rim; the site's field renders 50 tall
                .padding(.horizontal, 13)
                .padding(.vertical, 12)
                .frame(minHeight: 50)
                .background(ArchiveInk.librarySearchWell)
                .overlay(Rectangle().strokeBorder(ArchiveInk.librarySearchWellRim, lineWidth: 1))
                .accessibilityLabel("Find a grip")
                .padding(.top, 12)
            Text(GripLibraryReads.countLine(shown: shown, of: total))
                .font(PitchAtlasType.font(.martian400, size: 11, relativeTo: .caption2))
                .foregroundStyle(ArchiveInk.librarySearchCount)
                .cssLineHeight(1.5, face: .martian400, size: 11, relativeTo: .caption2)
                .padding(.top, 12)
            if shown == 0 {
                Button("Clear search") { query = "" }
                    .buttonStyle(StudyButtonStyle())
                    .foregroundStyle(PitchAtlasTheme.bone)
            }
            if loops {
                PauseMotionButton().padding(.top, 12)
            }
        }
        // 24pt inside the 1pt border
        .padding(25)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ArchiveInk.librarySearchField)
        .overlay(Rectangle().strokeBorder(ArchiveInk.libraryRule, lineWidth: 1))
        // role="status": the count speaks when it changes
        .onChange(of: shown) { _, count in
            AccessibilityNotification.Announcement(GripLibraryReads.countLine(shown: count, of: total)).post()
        }
    }
}

// MARK: - One grip

/// An `.archive-library-entry`: the name, its Compare and its link; Austin's
/// words; how it moved; then the theater — the film at its own portrait, the
/// photographs large beneath it — or, for the circle change, the labeled gap.
private struct GripArticle: View {
    let entry: GripEntry
    let gap: GripDistinction?
    @Environment(PitchStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            quote.padding(.top, 16)
            MonoCaps(text: "Austin H. · in his own words")
                .padding(.leading, 16)
                .padding(.top, 8)
            if let movement = entry.movement, !movement.isEmpty {
                movementBox(movement).padding(.top, 20)
            }
            if entry.film != nil || !entry.photos.isEmpty {
                theater.padding(.top, 28)
            } else if let gap {
                gapBox(gap).padding(.top, 28)
            }
        }
        .padding(.top, 36)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) {
            Rectangle().fill(ArchiveInk.libraryRule).frame(height: 1).accessibilityHidden(true)
        }
    }

    // MARK: The name, Compare, the link

    /// `flex flex-wrap items-baseline justify-between`: the name and Compare at
    /// the ends of the first line, the link beneath when the line runs out.
    private var header: some View {
        GripHeaderRow(columnGap: 16, rowGap: 8) {
            TightLines(entry.label.uppercased(), face: .anton400, size: 24, lineHeight: 0.98,
                       relativeTo: .title2, balanced: true)
                .foregroundStyle(PitchAtlasTheme.bone)
                .accessibilityAddTraits(.isHeader)
            if let slug = entry.specimenSlug { CompareButton(slug: slug) }
            if let link = GripLibraryReads.link(entry) { linkView(link) }
        }
    }

    @ViewBuilder
    private func linkView(_ link: GripLibraryReads.Link) -> some View {
        switch link {
        case .specimen(let slug):
            if let pitch = store.pitch(slug: slug) {
                NavigationLink(value: pitch) { linkLabel(link) }.buttonStyle(.plain)
            }
        case .file(let id):
            if let file = store.repertoireEntry(id: id) {
                NavigationLink(value: file) { linkLabel(link) }.buttonStyle(.plain)
            }
        }
    }

    private func linkLabel(_ link: GripLibraryReads.Link) -> some View {
        Text("\(link.label.uppercased()) →")
            .font(PitchAtlasType.font(.martian400, size: 11, relativeTo: .caption2))
            .tracking(em: 0.1, size: 11)
            .foregroundStyle(PitchAtlasTheme.cyan)
            .cssLineHeight(1.5, face: .martian400, size: 11, relativeTo: .caption2)
            // the site's touch rule: a 44pt target that keeps the line's height
            .padding(.vertical, 14)
            .contentShape(Rectangle())
            .padding(.vertical, -14)
            .accessibilityLabel(link.label)
    }

    // MARK: His words

    private var quote: some View {
        Text(entry.note)
            .font(PitchAtlasType.font(.hanken400, size: 15.5, relativeTo: .body))
            .foregroundStyle(PitchAtlasTheme.bone)
            .cssLineHeight(1.625, face: .hanken400, size: 15.5, relativeTo: .body)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            // pl-4 inside the 2pt cyan rule
            .padding(.leading, 18)
            .overlay(alignment: .leading) {
                Rectangle().fill(PitchAtlasTheme.cyan.opacity(0.4)).frame(width: 2).accessibilityHidden(true)
            }
    }

    private func movementBox(_ movement: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            MonoCaps(text: "How it moved", trackingEm: 0.12)
            Text(movement)
                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        // px-4 py-3.5 inside the 1pt border
        .padding(.horizontal, 17)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(PitchAtlasTheme.press.opacity(0.5)))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(PitchAtlasTheme.bone.opacity(0.12), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    // MARK: The theater

    /// One column on a phone: the film, capped at 360 and centered so it is never
    /// a full-width, very tall portrait, then each photograph.
    private var theater: some View {
        VStack(spacing: 20) {
            if let film = entry.film {
                GripMotionFigure(film: film, large: true)
                    .frame(maxWidth: 360)
                    .frame(maxWidth: .infinity)
            }
            ForEach(entry.photos, id: \.src) { GripPhotoFigure(photo: $0) }
        }
    }

    /// No film and no photograph: the labeled gap, never a borrowed picture
    /// implying Austin's hand.
    private func gapBox(_ gap: GripDistinction) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            MonoCaps(text: gap.marker, trackingEm: 0.14)
            Text(gap.reason)
                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        // px-5 py-6 inside the 1pt dashed border
        .padding(.horizontal, 21)
        .padding(.vertical, 25)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: 16)
            .strokeBorder(PitchAtlasTheme.bone.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
        .accessibilityElement(children: .combine)
    }
}

/// The grip's header line, as CSS lays `flex flex-wrap items-baseline
/// justify-between gap-x-4 gap-y-2`: items left to right at their own widths,
/// wrapping when the line runs out; a line's first and last at its two ends;
/// the items on a line sharing one baseline.
private struct GripHeaderRow: Layout {
    var columnGap: CGFloat
    var rowGap: CGFloat

    private struct Line { var items: [Int] = []; var width: CGFloat = 0 }

    /// An item at its own width, or wrapped to the line's when it runs wider.
    private static func size(of subview: LayoutSubview, within width: CGFloat) -> CGSize {
        let ideal = subview.sizeThatFits(.unspecified)
        guard width.isFinite, ideal.width > width else { return ideal }
        return subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
    }

    private static func baseline(of subview: LayoutSubview, size: CGSize) -> CGFloat {
        subview.dimensions(in: ProposedViewSize(size))[VerticalAlignment.firstTextBaseline]
    }

    private func lines(_ subviews: Subviews, width: CGFloat) -> [Line] {
        var lines: [Line] = []
        var line = Line()
        for index in subviews.indices {
            let w = Self.size(of: subviews[index], within: width).width
            if !line.items.isEmpty, line.width + columnGap + w > width {
                lines.append(line)
                line = Line()
            }
            line.width = line.items.isEmpty ? w : line.width + columnGap + w
            line.items.append(index)
        }
        if !line.items.isEmpty { lines.append(line) }
        return lines
    }

    /// A line's height above its shared baseline, and below it.
    private func extent(_ line: Line, _ subviews: Subviews, width: CGFloat) -> (above: CGFloat, below: CGFloat) {
        line.items.reduce((0, 0)) { acc, index in
            let size = Self.size(of: subviews[index], within: width)
            let base = Self.baseline(of: subviews[index], size: size)
            return (max(acc.0, base), max(acc.1, size.height - base))
        }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let all = lines(subviews, width: width)
        let height = all.reduce(0) { sum, line in
            let e = extent(line, subviews, width: width)
            return sum + e.above + e.below
        } + rowGap * CGFloat(max(0, all.count - 1))
        return CGSize(width: proposal.width ?? (all.map(\.width).max() ?? 0), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for line in lines(subviews, width: bounds.width) {
            let e = extent(line, subviews, width: bounds.width)
            let free = max(0, bounds.width - line.width)
            let between = line.items.count > 1 ? columnGap + free / CGFloat(line.items.count - 1) : 0
            var x = bounds.minX
            for index in line.items {
                let size = Self.size(of: subviews[index], within: bounds.width)
                let base = Self.baseline(of: subviews[index], size: size)
                subviews[index].place(at: CGPoint(x: x, y: y + e.above - base), proposal: ProposedViewSize(size))
                x += size.width + between
            }
            y += e.above + e.below + rowGap
        }
    }
}

// MARK: - How he attacked hitters

/// AttackPlan: the arsenal put to work as a sequenced at-bat, the putaway
/// marked; then command and the arm slot, in his words, never tracked data.
private struct AttackPlanSection: View {
    let file: GripsFile

    var body: some View {
        let plan = file.attackPlan
        VStack(alignment: .leading, spacing: 0) {
            KickerLabel(text: "How he attacked hitters")
            TightLines("The grips, put to work".uppercased(), face: .anton400, size: 26, lineHeight: 0.98,
                       relativeTo: .title2, balanced: true)
                .foregroundStyle(PitchAtlasTheme.bone)
                .padding(.top, 12)
                .accessibilityAddTraits(.isHeader)
            Text(plan.intro)
                .font(PitchAtlasType.font(.hanken400, size: 15.5, relativeTo: .body))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 15.5, relativeTo: .body)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)
            panel(plan).padding(.top, 36)
            VStack(alignment: .leading, spacing: 8) {
                MonoCaps(text: "On command and the arm slot", trackingEm: 0.12, ink: PitchAtlasTheme.cyan)
                Text(file.commandNote)
                    .font(PitchAtlasType.font(.hanken400, size: 15, relativeTo: .body))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .cssLineHeight(1.625, face: .hanken400, size: 15, relativeTo: .body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) {
                Rectangle().fill(PitchAtlasTheme.bone.opacity(0.10)).frame(height: 1).accessibilityHidden(true)
            }
            .padding(.top, 32)
            MonoCaps(text: "Austin H. · a pitcher’s own account, not tracked data")
                .padding(.top, 16)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 56)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) {
            Rectangle().fill(PitchAtlasTheme.bone.opacity(0.15)).frame(height: 1).accessibilityHidden(true)
        }
    }

    private func panel(_ plan: GripAttackPlan) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(plan.sequenceTitle.uppercased())
                .font(PitchAtlasType.font(.anton400, size: 24, relativeTo: .title2))
                .tracking(em: 0.01, size: 24)
                .foregroundStyle(PitchAtlasTheme.bone)
                .cssLineHeight(32.0 / 24.0, face: .anton400, size: 24, relativeTo: .title2)
                .fixedSize(horizontal: false, vertical: true)
                .modifier(CSSSkewX())
                .accessibilityLabel(plan.sequenceTitle)
                .accessibilityAddTraits(.isHeader)
            Text(plan.sequenceNote)
                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            VStack(spacing: 12) {
                ForEach(Array(plan.sequence.enumerated()), id: \.offset) { index, step in
                    stepRow(index, step, last: index == plan.sequence.count - 1)
                }
            }
            .padding(.top, 24)
        }
        // p-[clamp(20px,3vw,30px)] inside the 1pt border
        .padding(21)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(PitchAtlasTheme.press.opacity(0.6)))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(PitchAtlasTheme.bone.opacity(0.12), lineWidth: 1))
    }

    private func stepRow(_ index: Int, _ step: GripAttackStep, last: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(String(format: "%02d", index + 1))
                .font(PitchAtlasType.font(.anton400, size: 24, relativeTo: .title2))
                .tracking(em: 0.01, size: 24)
                .foregroundStyle(last ? PitchAtlasTheme.cyan : ArchiveInk.orange)
                .cssLineHeight(1, face: .anton400, size: 24, relativeTo: .title2)
                .modifier(CSSSkewX())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                (Text(step.label)
                    .font(PitchAtlasType.font(.hanken600, size: 15, relativeTo: .body))
                    .foregroundStyle(PitchAtlasTheme.bone)
                 + (last ? Text("\u{2002}PUTAWAY")
                    .font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2))
                    .tracking(0.12 * 9)
                    .foregroundStyle(PitchAtlasTheme.cyan) : Text("")))
                    .cssLineHeight(1.5, face: .hanken600, size: 15, relativeTo: .body)
                    .fixedSize(horizontal: false, vertical: true)
                Text(step.detail)
                    .font(PitchAtlasType.font(.hanken400, size: 13.5, relativeTo: .footnote))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .cssLineHeight(1.625, face: .hanken400, size: 13.5, relativeTo: .footnote)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // px-4 py-3.5 inside the 1pt border
        .padding(.horizontal, 17)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12).fill(PitchAtlasTheme.press)
                .overlay(RoundedRectangle(cornerRadius: 12).fill(PitchAtlasTheme.cyan.opacity(last ? 0.12 : 0)))
        }
        .overlay(RoundedRectangle(cornerRadius: 12)
            .strokeBorder(last ? PitchAtlasTheme.cyan.opacity(0.45) : PitchAtlasTheme.bone.opacity(0.10), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(index + 1)\(last ? ", the putaway" : ""). \(step.label). \(step.detail)")
    }
}

// MARK: - Same release, different grip

/// The comparison's doorway (GripsPage.tsx #grip-compare and GripCompare.tsx
/// with the workspace in reach): two grips under one arm slot, and the way in.
private struct GripCompareEntry: View {
    @Environment(\.compareSelection) private var comparison

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EggButton(note: .rubbingMud) { KickerLabel(text: "Same release, different grip") }
            TightLines("Two grips, one arm slot".uppercased(), face: .anton400, size: 26, lineHeight: 0.98,
                       relativeTo: .title2, balanced: true)
                .foregroundStyle(PitchAtlasTheme.bone)
                .padding(.top, 12)
                .accessibilityAddTraits(.isHeader)
            // Verbatim, GripsPage.tsx.
            Text("A hitter reads the delivery, not the hand. Put two grips side by side under one shared arm slot and the trick becomes obvious: the part they can see is identical, and the part that decides the pitch is the part they can’t. These balls are our own seam geometry, oriented to the grip (schematic, not a hand), and with no WebGL they fall back to the 2D seam diagram, so the grip still reads.")
                .font(PitchAtlasType.font(.hanken400, size: 15, relativeTo: .body))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 15, relativeTo: .body)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)
            // Verbatim, GripCompare.tsx.
            Text("Keep two pitches together as you move between grips, sourced cues, and schematic movement.")
                .font(PitchAtlasType.font(.hanken400, size: 16, relativeTo: .body))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 16, relativeTo: .body)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 36)
            Button("Open the comparison workspace") {
                comparison.presented = true
                Haptics.selection()
            }
            .buttonStyle(ArchiveActionStyle())
            .padding(.top, 20)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 56)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PitchAtlasTheme.press)
        .overlay(alignment: .top) {
            Rectangle().fill(PitchAtlasTheme.bone.opacity(0.15)).frame(height: 1).accessibilityHidden(true)
        }
    }
}
