import SwiftUI

// =============================================================================
// CompareView — the compare table
// =============================================================================
// Web: pages/ComparePage.tsx (the page, its pickers, its tabs),
// inspector/BenchBody.tsx (the stage and the rows), sections/TunnelPlot.tsx
// (the flight figure) and compare/CompareProvider.tsx (making room for a third
// pitch), dressed by styles/compare.css and bench.css at the site's phone width.
// The ball is the seam-informed schematic: the reader's view and hand turn it,
// and a finger row lights that finger's pad on the ball.
// =============================================================================

struct CompareView: View {
    @Environment(\.compareSelection) private var selection
    @Environment(PitchStore.self) private var store
    @Environment(DeepLinkRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    /// The lede's max-width, 35ch of Hanken 13.
    private static let ledeWidth: CGFloat = 35 * 0.56 * 13

    var body: some View {
        @Bindable var selection = selection
        NavigationStack {
            GeometryReader { geo in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        CompareControls()
                        if case .failed(let reason) = store.status {
                            ErrorStateView(reason: reason).padding(.top, 20)
                        } else if let a = selection.a.flatMap(store.pitch(slug:)),
                                  let b = selection.b.flatMap(store.pitch(slug:)) {
                            BenchBody(entries: [a, b], viewport: geo.size.width)
                                .padding(.top, 20)
                            next
                        } else {
                            empty
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 80)
                }
            }
            .background(PitchAtlasTheme.void)
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { BrandLockup(size: .sm) }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .toolbarBackground(PitchAtlasTheme.void, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $selection.inspection) { target in
                if let entry = store.pitch(slug: target.slug) {
                    PitchDetailView(entry: entry, opensAt: .grip)
                } else {
                    EmptyStateView(message: "This specimen is not in the bundle. Return to comparison to choose another.")
                }
            }
        }
        .tint(PitchAtlasTheme.kicker)
        .overlay {
            if let pending = selection.pending { MakeRoom(pending: pending) }
        }
    }

    /// Out of the table to a page of the site: the cover closes onto that page.
    private func leave(to route: String) {
        if let url = URL(string: "pitchatlas://\(route)") { router.handle(url, store: store) }
        selection.presented = false
    }

    // MARK: - The header (.archive-compare-header)

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { leave(to: "repertoire") } label: {
                Text("Back to the Pitch Index")
                    .font(PitchAtlasType.font(.hanken400, size: 13, relativeTo: .footnote))
                    .underline(true, color: CompareInk.back)
                    .foregroundStyle(CompareInk.back)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            (Text("Look at ") + Text("the difference.").foregroundStyle(CompareInk.titleAccent))
                .font(PitchAtlasType.font(.newsreader400, size: 36, relativeTo: .largeTitle))
                .tracking(em: -0.035, size: 36)
                .foregroundStyle(CompareInk.title)
                .cssLineHeight(1.02, face: .newsreader400, size: 36, relativeTo: .largeTitle)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 16)
            Text("Two grips on the same table. Turn them together. Follow what changes.")
                .font(PitchAtlasType.font(.hanken400, size: 13, relativeTo: .footnote))
                .foregroundStyle(CompareInk.lede)
                .cssLineHeight(1.6, face: .hanken400, size: 13, relativeTo: .footnote)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: Self.ledeWidth, alignment: .leading)
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
    }

    // MARK: - The empty table (.compare-empty)

    private var empty: some View {
        VStack(spacing: 0) {
            Text("A / B")
                .font(PitchAtlasType.font(.anton400, size: 70, relativeTo: .largeTitle))
                .foregroundStyle(CompareInk.emptyMark)
                .cssLineHeight(1, face: .anton400, size: 70, relativeTo: .largeTitle)
                .accessibilityHidden(true)
            Text(BenchReads.emptyTitle(chosen: selection.slugs.count))
                .font(PitchAtlasType.font(.newsreader400, size: 28, relativeTo: .title))
                .foregroundStyle(CompareInk.emptyTitle)
                .cssLineHeight(1.2, face: .newsreader400, size: 28, relativeTo: .title)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .padding(.vertical, 16)
            Text("Choose from the selectors above, or select Compare while exploring the Pitch Index. An unavailable pitch leaves its place open.")
                .font(PitchAtlasType.font(.hanken400, size: 15, relativeTo: .body))
                .foregroundStyle(CompareInk.emptyBody)
                .cssLineHeight(1.7, face: .hanken400, size: 15, relativeTo: .body)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 24)
            Button("Explore the index") { leave(to: "repertoire") }
                .buttonStyle(ArchiveActionStyle())
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: 500)
        .padding(.horizontal, 16)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - What comes next (.compare-next)

    private var next: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Put the difference in context")
                    .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                    .tracking(em: 0.13, size: 10)
                    .textCase(.uppercase)
                    .foregroundStyle(CompareInk.nextEyebrow)
                    .cssLineHeight(1.6, face: .martian400, size: 10, relativeTo: .caption2)
                Text("What does the next pitch change?")
                    .font(PitchAtlasType.font(.newsreader400, size: 32, relativeTo: .title))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .cssLineHeight(1.1, face: .newsreader400, size: 32, relativeTo: .title)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.vertical, 10)
                Text("Keep this pair at the table while you explore how pitches work together.")
                    .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                    .foregroundStyle(CompareInk.lede)
                    .cssLineHeight(1.6, face: .hanken400, size: 14, relativeTo: .subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 47 * 0.56 * 14, alignment: .leading)
            }
            Button { leave(to: "learn/sequencing") } label: {
                HStack(spacing: 18) {
                    Text("Read the sequencing lesson").underline(true, color: CompareInk.linkRule)
                    Text("→").underline(true, color: CompareInk.linkRule).accessibilityHidden(true)
                }
                .font(PitchAtlasType.font(.hanken600, size: 15, relativeTo: .body))
                .foregroundStyle(PitchAtlasTheme.bone)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // 28 inside each 1pt rule
        .padding(.vertical, 29)
        .overlay(alignment: .top) { CompareInk.rule.frame(height: 1) }
        .overlay(alignment: .bottom) { CompareInk.rule.frame(height: 1) }
        .padding(.top, 40)
    }
}

// MARK: - The pickers and the tabs (.compare-controls)

/// The two pickers with Swap and Clear, then the aspect tabs, between two rules.
private struct CompareControls: View {
    @Environment(\.compareSelection) private var selection
    @Environment(PitchStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            pickers
            tabs
        }
        // 16 inside the top rule; the tabs sit on the bottom rule
        .padding(.top, 17)
        .padding(.bottom, 1)
        .overlay(alignment: .top) { CompareInk.rule.frame(height: 1) }
        .overlay(alignment: .bottom) { CompareInk.rule.frame(height: 1) }
    }

    /// `grid-template-columns: 1fr 1fr 44px 44px` at the phone width; at the
    /// largest text sizes the pickers stack.
    private var pickers: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .bottom, spacing: 6))
        return layout {
            picker(.a, label: "First pitch")
            picker(.b, label: "Second pitch")
            HStack(spacing: 6) {
                iconButton("arrow.left.arrow.right", size: 17, label: "Swap pitches", enabled: selection.canSwap) {
                    selection.swap()
                }
                iconButton("arrow.counterclockwise", size: 15, label: "Clear comparison") {
                    selection.clear()
                }
            }
        }
    }

    private func picker(_ slot: CompareSelection.Slot, label: String) -> some View {
        let current = selection.slug(in: slot).flatMap(store.pitch(slug:))
        let other = selection.slug(in: slot == .a ? .b : .a)
        return VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(PitchAtlasType.font(.hanken400, size: 10, relativeTo: .caption2))
                .foregroundStyle(CompareInk.pickerLabel)
                .accessibilityHidden(true)
            Menu {
                Button("Choose…") { choose(nil, for: slot) }
                ForEach(store.pitches) { entry in
                    Button { choose(entry.slug, for: slot) } label: {
                        if entry.slug == current?.slug {
                            Label(entry.display.shortName, systemImage: "checkmark")
                        } else {
                            Text(entry.display.shortName)
                        }
                    }
                    // the other place's pitch cannot be doubled
                    .disabled(entry.slug == other)
                }
            } label: {
                Text(current?.display.shortName ?? "Choose…")
                    .font(PitchAtlasType.font(.martian400, size: 13, relativeTo: .footnote))
                    .foregroundStyle(CompareInk.pickerInk)
                    .lineLimit(1)
                    .padding(8)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(CompareInk.pickerWell))
                    // the raking light along the top lip
                    .overlay(alignment: .top) { CompareInk.pickerLip.frame(height: 1).padding(.horizontal, 7).padding(.top, 1) }
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(CompareInk.pickerRim, lineWidth: 1))
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(label)
            .accessibilityValue(current?.display.shortName ?? "None chosen")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func choose(_ slug: String?, for slot: CompareSelection.Slot) {
        selection.set(slot, to: slug, store: store)
        Haptics.selection()
    }

    /// `.archive-icon-action`: a 44pt square, a faint rim, faded while it cannot act.
    private func iconButton(_ symbol: String, size: CGFloat, label: String, enabled: Bool = true,
                            action: @escaping () -> Void) -> some View {
        Button { action(); Haptics.selection() } label: {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .regular))
                .foregroundStyle(PitchAtlasTheme.bone)
                .frame(width: 44, height: 44)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(CompareInk.iconRim, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
        .accessibilityLabel(label)
    }

    /// `.compare-tabs`: Grip, Release, Flight; the pressed one wears the gold rule.
    private var tabs: some View {
        HStack(spacing: 20) {
            ForEach(CompareSelection.Mode.allCases, id: \.self) { mode in
                let on = selection.mode == mode
                Button { selection.mode = mode; Haptics.selection() } label: {
                    Text(BenchReads.tabLabel(mode))
                        .font(PitchAtlasType.font(.hanken400, size: 15, relativeTo: .subheadline))
                        .foregroundStyle(on ? CompareInk.tabOn : CompareInk.tab)
                        .padding(.vertical, 10)
                        .frame(minWidth: 44, minHeight: 48)
                        .overlay(alignment: .bottom) { (on ? CompareInk.tabRule : .clear).frame(height: 2) }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Aspect")
    }
}

// MARK: - The bench (BenchBody.tsx, .bench--page)

/// The stage (the ball in the hand, or the flight figure) with its controls, then
/// the rows that say what the stage shows.
private struct BenchBody: View {
    let entries: [PitchAtlasEntry]
    /// The screen's width: the ball's well is 76% of it, never past 380.
    let viewport: CGFloat
    @Environment(\.compareSelection) private var selection
    @Environment(PitchStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// What the reader picked belongs to the pair it was picked on; a new pair
    /// starts from A with no finger picked out.
    @State private var picked = Picked()

    private struct Picked: Equatable {
        var keys = ""
        var shown = 0
        var finger: Finger?
    }

    /// SeamSchematic's ball (r 86 in its 240 frame) inside the well's square.
    private static let ballShare: CGFloat = 172 / 240

    private var keys: String { entries.map(\.slug).joined(separator: "|") }
    private var shown: Int { picked.keys == keys ? min(picked.shown, entries.count - 1) : 0 }
    private var finger: Finger? { picked.keys == keys ? picked.finger : nil }
    private var pair: Bool { entries.count > 1 }
    private var anyFiled: Bool { entries.contains { $0.canonical.gripModel.status != .unfiled } }
    private var stacked: Bool { dynamicTypeSize.isAccessibilitySize }

    private func show(_ index: Int) { picked = Picked(keys: keys, shown: index, finger: finger) }
    private func pick(_ next: Finger?) { picked = Picked(keys: keys, shown: shown, finger: next) }
    private func slot(_ index: Int) -> String { index == 0 ? "A" : "B" }
    private func edge(_ entry: PitchAtlasEntry) -> Color { Color(rgb: PitchAccents.triad(for: entry.slug).c3) }
    private func unfiled(_ entry: PitchAtlasEntry) -> Bool { entry.canonical.gripModel.status == .unfiled }
    /// The sr-only name a pair's cell speaks before its words.
    private func who(_ index: Int) -> String? { pair ? entries[index].display.shortName : nil }

    var body: some View {
        VStack(spacing: 0) {
            stage
            rail
        }
        .padding(1)
        .background(CompareInk.benchGround)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(CompareInk.benchRim, lineWidth: 1))
    }

    // MARK: The stage

    private var stage: some View {
        VStack(alignment: .leading, spacing: 14) {
            if selection.mode == .movement {
                flight
            } else {
                // a phone has room for one ball, so A and B take turns in it
                if pair {
                    BenchSeg(label: "Pitch on the stage",
                             options: entries.indices.map { ($0, "\(slot($0)) · \(entries[$0].display.shortName)") },
                             selected: shown) { show($0) }
                }
                specimen(entries[shown], slot: pair ? slot(shown) : nil)
            }
            toolbar
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { StageGround() }
        .overlay(alignment: .bottom) { CompareInk.stageRule.frame(height: 1).padding(.horizontal, 12) }
    }

    private func specimen(_ entry: PitchAtlasEntry, slot: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let slot {
                HStack(alignment: .firstTextBaseline, spacing: 9.6) {
                    Text(slot)
                        .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                        .tracking(em: 0.12, size: 10)
                        .foregroundStyle(CompareInk.key)
                        .accessibilityHidden(true)
                    Text(entry.display.shortName)
                        .font(PitchAtlasType.font(.hanken600, size: 14, relativeTo: .subheadline))
                        .foregroundStyle(CompareInk.specimenName)
                }
                .padding(.leading, 10)
                .overlay(alignment: .leading) { edge(entry).frame(width: 2) }
            }
            ball(entry)
        }
    }

    private func ball(_ entry: PitchAtlasEntry) -> some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) * Self.ballShare / 0.92
            Group {
                if unfiled(entry) {
                    // no canonical grip on file: the seam drawn alone
                    SeamBall(motion: .schematicReference, size: side, showMovement: false)
                } else {
                    SeamBall(motion: entry.motion, size: side,
                             contacts: entry.canonical.fingerPlacement,
                             orientation: selection.orientation, hand: selection.hand,
                             showMovement: false,
                             referenceContacts: entry.canonical.fingerPlacement,
                             highlightedFinger: finger)
                }
            }
            .dynamicTypeSize(.large)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(height: min(viewport * 0.76, 380))
        .overlay(alignment: .bottomLeading) { BenchChip(text: BenchReads.stageChip(entry)).padding(10) }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(CompareInk.ballRing, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(BenchReads.stageLabel(entry, hand: selection.hand, view: selection.orientation))
    }

    /// `.bench-flight`: the Illustrative chip and its line, then the figure.
    private var flight: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                BenchChip(text: "Illustrative")
                Text("Drawn from the mound. A grip does not guarantee this shape.")
                    .font(PitchAtlasType.font(.hanken400, size: 13, relativeTo: .footnote))
                    .foregroundStyle(CompareInk.flightHead)
                    .cssLineHeight(1.4, face: .hanken400, size: 13, relativeTo: .footnote)
                    .fixedSize(horizontal: false, vertical: true)
            }
            FlightFigure(a: entries[0], b: pair ? entries[1] : nil, hand: selection.hand)
                .aspectRatio(FlightPath.w / FlightPath.h, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: 460)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(BenchReads.flightLabel(entries, hand: selection.hand))
                .accessibilityAddTraits(.isImage)
        }
    }

    /// `.bench-toolbar`: the view (not in Flight) and the hand, while a grip is filed.
    @ViewBuilder private var toolbar: some View {
        let views = selection.mode != .movement && anyFiled
        let hands = selection.mode == .movement || anyFiled
        let viewSeg = BenchSeg(label: pair ? "View both" : "View",
                               options: [(GripView.top, "Top"), (.side, "Side"), (.thumb, "Thumb")],
                               selected: selection.orientation) { selection.orientation = $0 }
        let handSeg = BenchSeg(label: "Pitching hand",
                               options: [(Handedness.right, "Right"), (.left, "Left")],
                               selected: selection.hand) { selection.hand = $0 }
        if stacked {
            VStack(spacing: 8) {
                if views { viewSeg }
                if hands { handSeg }
            }
        } else if views || hands {
            HStack(spacing: 8) {
                if views { viewSeg.frame(width: 186) }
                if hands { handSeg }
            }
        }
    }

    // MARK: The rows

    private var rail: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 0) {
                if pair && !stacked { heads }
                rows
            }
            study
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CompareInk.rail)
    }

    /// The column heads, drawn for the eye; each cell names its pitch to VoiceOver.
    private var heads: some View {
        HStack(alignment: .top, spacing: 16) {
            ForEach(entries.indices, id: \.self) { index in
                head(index)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .padding(.horizontal, 4)
        .accessibilityHidden(true)
    }

    private func head(_ index: Int) -> some View {
        HStack(spacing: 8) {
            Text("\(slot(index)) · \(entries[index].display.shortName)")
                .font(PitchAtlasType.font(.hanken600, size: 12, relativeTo: .caption))
                .foregroundStyle(CompareInk.specimenName)
                .cssLineHeight(1.3, face: .hanken600, size: 12, relativeTo: .caption)
            // in Flight the heads carry the line each path is drawn with
            if selection.mode == .movement {
                LineSample(color: edge(entries[index]), dashed: index == 1)
                    .frame(width: 22, height: 2)
            }
        }
        .padding(.leading, 8)
        .overlay(alignment: .leading) { edge(entries[index]).frame(width: 2) }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var rows: some View {
        switch selection.mode {
        case .grips:
            claimRow("The hold", dim: finger != nil) { $0.canonical.grip }
            handRow
            ForEach(BenchReads.fingerRows(entries), id: \.finger) { fingerRow($0) }
        case .cues:
            handRow
            ForEach(Array(["Hold", "Pressure", "Leave"].enumerated()), id: \.offset) { step, name in
                row(name) {
                    ForEach(entries.indices, id: \.self) { index in
                        let filed = !unfiled(entries[index])
                        let words = filed ? SpecimenReads.releaseSequence(entries[index])[step].copy : "Not filed"
                        VStack(alignment: .leading, spacing: 4) {
                            if pair && stacked { stackedHead(index) }
                            if filed { plain(words) } else { quiet(words) }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(who(index).map { "\($0): \(words)" } ?? words)
                    }
                }
            }
            claimRow("Mechanics") { $0.canonical.mechanics }
            claimRow("In their words") { $0.canonical.voice }
        case .movement:
            row("Shape") {
                ForEach(entries.indices, id: \.self) { index in
                    let entry = entries[index]
                    VStack(alignment: .leading, spacing: 4) {
                        if pair && stacked { stackedHead(index) }
                        strong(SpecimenReads.shapeLabel(entry))
                            .accessibilityLabel(who(index).map { "\($0): \(SpecimenReads.shapeLabel(entry))" } ?? SpecimenReads.shapeLabel(entry))
                        if let shape = entry.canonical.physics.shape {
                            RefractorClaimView(claim: shape, size: 14, ink: PitchAtlasTheme.bone)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            claimRow("Spin") { $0.canonical.physics.spinAxis }
            claimRow("The one sentence") { $0.canonical.physics.teaching }
        }
    }

    /// `.bench-row` at the phone width: the name across the top, then a cell per pitch.
    private func row<Cells: View>(_ name: String, dim: Bool = false, @ViewBuilder cells: () -> Cells) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            RowName(text: name)
            cellsLayout { cells() }
        }
        // 12 inside the top rule
        .padding(.top, 13)
        .padding(.bottom, 12)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { CompareInk.ballRing.frame(height: 1) }
        .opacity(dim ? 0.38 : 1)
    }

    /// Two equal columns, 16 apart; one column at the largest text sizes.
    private var cellsLayout: AnyLayout {
        stacked ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
    }

    /// At the largest text sizes the cells stack, so each wears its own head.
    private func stackedHead(_ index: Int) -> some View {
        Text("\(slot(index)) · \(entries[index].display.shortName)")
            .font(PitchAtlasType.font(.hanken600, size: 12, relativeTo: .caption))
            .foregroundStyle(CompareInk.specimenName)
            .padding(.leading, 8)
            .overlay(alignment: .leading) { edge(entries[index]).frame(width: 2) }
            .accessibilityHidden(true)
    }

    /// A claim per pitch, or "None on file"; the row shows only while one pitch has it.
    @ViewBuilder
    private func claimRow(_ name: String, dim: Bool = false, _ claimFor: @escaping (PitchAtlasEntry) -> Claim?) -> some View {
        if entries.contains(where: { claimFor($0) != nil }) {
            row(name, dim: dim) {
                ForEach(entries.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 4) {
                        if pair && stacked { stackedHead(index) }
                        if let claim = claimFor(entries[index]) {
                            RefractorClaimView(claim: claim, size: 14, ink: PitchAtlasTheme.bone, spokenPrefix: who(index))
                        } else {
                            quiet("None on file")
                                .accessibilityLabel(who(index).map { "\($0): None on file" } ?? "None on file")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    /// The reference hand's one badge, at the head of everything it wrote.
    private var handRow: some View {
        row("Reference hand") {
            ForEach(entries.indices, id: \.self) { index in
                let model = entries[index].canonical.gripModel
                let words = unfiled(entries[index]) ? (model.provenance?.value ?? "") : model.visualCaveat
                VStack(alignment: .leading, spacing: 4) {
                    if pair && stacked { stackedHead(index) }
                    if let provenance = model.provenance { GripSourceBadge(provenance: provenance) }
                    if !words.isEmpty {
                        quiet(words)
                            .accessibilityLabel(who(index).map { "\($0): \(words)" } ?? words)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// A finger row is a button: it lights that finger on the ball and dims the rest.
    private func fingerRow(_ row: BenchReads.FingerRow) -> some View {
        let on = finger == row.finger
        let differs = pair && row.contacts.count > 1 && BenchReads.differs(row.contacts[0], row.contacts[1])
        return Button { pick(on ? nil : row.finger); Haptics.selection() } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    RowName(text: BenchReads.fingerName(row.finger), header: false)
                    if differs {
                        Circle().fill(CompareInk.differs).frame(width: 6, height: 6)
                    }
                }
                cellsLayout {
                    ForEach(entries.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 4) {
                            if pair && stacked { stackedHead(index) }
                            contact(row.contacts[index], unfiled: unfiled(entries[index]))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.top, 13)
            .padding(.bottom, 12)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { if on { CompareInk.fingerWash } }
            .overlay(alignment: .leading) { if on { PitchAtlasTheme.cyan.frame(width: 2) } }
            .overlay(alignment: .top) { CompareInk.ballRing.frame(height: 1) }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(finger != nil && !on ? 0.38 : 1)
        // the button speaks the whole row; its own label stays the action
        .accessibilityLabel(spoken(row, differs: differs))
        .accessibilityAddTraits(on ? .isSelected : [])
        .accessibilityHint(on ? "Shows every finger again." : "Lights this finger on the ball.")
    }

    @ViewBuilder
    private func contact(_ contact: GripContactModel?, unfiled: Bool) -> some View {
        if unfiled {
            quiet("Not filed")
        } else if let contact {
            strong(contact.label)
            plain(contact.seamRelation)
            quiet(contact.pressureRole)
        } else {
            quiet("No contact")
        }
    }

    /// The finger row read aloud: the finger, whether the hands differ, then each hand's hold.
    private func spoken(_ row: BenchReads.FingerRow, differs: Bool) -> String {
        var parts = [BenchReads.fingerName(row.finger) + (differs ? ", the two hands differ here" : "")]
        for (index, entry) in entries.enumerated() {
            let words: String
            if unfiled(entry) {
                words = "Not filed"
            } else if let contact = row.contacts[index] {
                words = "\(contact.label), \(contact.seamRelation), \(contact.pressureRole)"
            } else {
                words = "No contact"
            }
            parts.append(pair ? "\(entry.display.shortName): \(words)" : words)
        }
        return parts.joined(separator: ". ")
    }

    // MARK: The cell's three inks

    private func strong(_ text: String) -> some View {
        Text(text)
            .font(PitchAtlasType.font(.hanken600, size: 14, relativeTo: .subheadline))
            .foregroundStyle(CompareInk.cellStrong)
            .cssLineHeight(1.5, face: .hanken600, size: 14, relativeTo: .subheadline)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func plain(_ text: String) -> some View {
        Text(text)
            .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
            .foregroundStyle(CompareInk.cell)
            .cssLineHeight(1.5, face: .hanken400, size: 14, relativeTo: .subheadline)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func quiet(_ text: String) -> some View {
        Text(text)
            .font(PitchAtlasType.font(.hanken400, size: 13, relativeTo: .footnote))
            .foregroundStyle(CompareInk.cellQuiet)
            .cssLineHeight(1.5, face: .hanken400, size: 13, relativeTo: .footnote)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Study further (.bench-study)

    private var study: some View {
        FlowRow(spacing: 20, lineSpacing: 0) {
            ForEach(entries, id: \.slug) { entry in
                Button { selection.inspect(entry.slug, store: store); Haptics.selection() } label: {
                    HStack(spacing: 6) {
                        Text(BenchReads.studyLabel(entry, pair: pair, mode: selection.mode))
                            .underline(true, color: CompareInk.linkRule)
                        Text("→").underline(true, color: CompareInk.linkRule).accessibilityHidden(true)
                    }
                    .font(PitchAtlasType.font(.hanken600, size: 14, relativeTo: .subheadline))
                    .foregroundStyle(CompareInk.study)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Study further")
    }
}

// MARK: - Bench parts

/// `.bench-row-name`: mono capitals in the gold key.
private struct RowName: View {
    let text: String
    /// A finger row is a button, and a button is never a heading.
    var header = true

    var body: some View {
        Text(text)
            .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
            .tracking(em: 0.13, size: 10)
            .textCase(.uppercase)
            .foregroundStyle(CompareInk.key)
            .cssLineHeight(1.6, face: .martian400, size: 10, relativeTo: .caption2)
            .padding(.top, 2)
            .accessibilityAddTraits(header ? .isHeader : [])
    }
}

/// `.bench-chip`: mono capitals on a dark pill.
private struct BenchChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2))
            .tracking(em: 0.14, size: 9)
            .textCase(.uppercase)
            .foregroundStyle(CompareInk.chipInk)
            .cssLineHeight(1.4, face: .martian400, size: 9, relativeTo: .caption2)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule().fill(CompareInk.chipGround))
            .overlay(Capsule().strokeBorder(CompareInk.chipRim, lineWidth: 1))
            .accessibilityHidden(true)
    }
}

/// `.specimen-seg`: one 44pt rail of equal choices, the pressed one lit in gold.
private struct BenchSeg<Value: Hashable>: View {
    let label: String
    let options: [(value: Value, title: String)]
    let selected: Value
    let choose: (Value) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                let on = option.value == selected
                Button { choose(option.value); Haptics.selection() } label: {
                    Text(option.title)
                        .font(PitchAtlasType.font(.hanken600, size: 12, relativeTo: .caption))
                        .foregroundStyle(on ? CompareInk.segOnInk : CompareInk.segInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 14)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(RoundedRectangle(cornerRadius: 5).fill(on ? CompareInk.segOnFill : CompareInk.segWash))
                        .overlay { if on { RoundedRectangle(cornerRadius: 5).strokeBorder(CompareInk.segOnRing, lineWidth: 1) } }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        // the switch inside its 1pt rim holds the 44pt line as a whole
        .padding(1)
        .frame(minHeight: 44)
        .background(RoundedRectangle(cornerRadius: 7).fill(CompareInk.benchGround))
        .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(CompareInk.segRim, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }
}

/// `.bench-stage`'s ground: radial-gradient(ellipse at 50% 38%, #1c1814 0%, #0b0a09 72%)
/// over the bench's own #0b0a09. The ellipse reaches the far corner at the box's
/// own proportions.
private struct StageGround: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                CompareInk.benchGround
                CSSEllipseWash(color: CompareInk.stageGlow, center: CGPoint(x: w * 0.5, y: h * 0.38),
                               radii: CGSize(width: w * 0.5 * 2.0.squareRoot(), height: h * 0.62 * 2.0.squareRoot()),
                               fade: 0.72)
            }
        }
        .accessibilityHidden(true)
    }
}

/// The 22pt sample of a path's line beside a Flight column head; B's is dashed.
private struct LineSample: View {
    let color: Color
    let dashed: Bool

    var body: some View {
        Canvas { context, size in
            var line = Path()
            line.move(to: CGPoint(x: 0, y: size.height / 2))
            line.addLine(to: CGPoint(x: size.width, y: size.height / 2))
            context.stroke(line, with: .color(color),
                           style: StrokeStyle(lineWidth: size.height, dash: dashed ? [6, 2] : []))
        }
        .accessibilityHidden(true)
    }
}

// MARK: - The flight figure (TunnelPlot.tsx)

/// The flight drawn from the mound: the release at the top, the plate below, a
/// right-hander's arm side on the right. One pitch draws its own path; two share
/// one release and one early leg (the tunnel) before each splits toward its own
/// side. Each endpoint sits in the direction the pitch breaks, from the shape
/// words on its record, never a magnitude; handedness is a mirror, not new data.
struct FlightFigure: View {
    let a: PitchAtlasEntry
    var b: PitchAtlasEntry? = nil
    let hand: Handedness

    var body: some View {
        Canvas { context, size in
            let k = size.width / FlightPath.w
            let ink = PitchAtlasTheme.bone2
            let rule = PitchAtlasTheme.bone3
            func at(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x * k, y: y * k) }
            func ring(_ x: Double, _ y: Double, _ r: Double) -> Path {
                Path(ellipseIn: CGRect(x: (x - r) * k, y: (y - r) * k, width: 2 * r * k, height: 2 * r * k))
            }
            let cx = FlightPath.cx, cy = FlightPath.cy

            // the axis guides; every name sits under its endpoint, the sides in the bottom corners
            var axes = Path()
            axes.move(to: at(cx, cy - FlightPath.axis))
            axes.addLine(to: at(cx, cy + FlightPath.axis))
            axes.move(to: at(cx - FlightPath.clamp - 16, cy))
            axes.addLine(to: at(cx + FlightPath.clamp + 16, cy))
            context.stroke(axes, with: .color(rule.opacity(0.5)), lineWidth: k)
            label(context, "RIDE", at: at(cx + 8, cy - FlightPath.axis + 9), k: k, color: ink)
            label(context, "DROP", at: at(cx + 8, cy + FlightPath.axis - 2), k: k, color: ink)
            label(context, hand == .right ? "← GLOVE SIDE" : "← ARM SIDE", at: at(6, FlightPath.h - 8), k: k, color: ink)
            label(context, hand == .right ? "ARM SIDE →" : "GLOVE SIDE →", at: at(FlightPath.w - 6, FlightPath.h - 8),
                  k: k, color: ink, anchor: 1)

            // a spinless ball's path ends here
            context.stroke(ring(cx, cy, 6), with: .color(ink.opacity(0.6)),
                           style: StrokeStyle(lineWidth: k, dash: [3 * k, 3 * k]))

            // the early leg: one line for one pitch, the shared tunnel for two
            var leg = Path()
            leg.move(to: at(cx, FlightPath.releaseY))
            leg.addLine(to: at(cx, FlightPath.tunnelY))
            context.stroke(leg, with: .color(ink.opacity(0.35)),
                           style: StrokeStyle(lineWidth: (b == nil ? 3 : 9) * k, lineCap: .round))
            context.fill(ring(cx, FlightPath.releaseY, 5.5), with: .color(ink))
            label(context, "RELEASE · MOUND", at: at(cx + 12, FlightPath.releaseY + 4), k: k, color: ink, size: 10, tracking: 1.2)
            if b != nil {
                context.stroke(ring(cx, FlightPath.tunnelY, 12), with: .color(ink),
                               style: StrokeStyle(lineWidth: 1.2 * k, dash: [3 * k, 3 * k]))
                label(context, "TUNNEL", at: at(cx + 18, FlightPath.tunnelY + 4), k: k, color: ink, size: 10, tracking: 1.2)
            }

            // a pair that breaks the same way is nudged apart so both read
            let handFactor: Double = hand == .right ? 1 : -1
            let entries = [a] + (b.map { [$0] } ?? [])
            let same = b.map { FlightPath.sameCell(a.motion, $0.motion) } ?? false
            for (index, entry) in entries.enumerated() {
                let nudge = same ? (index == 0 ? -FlightPath.nudge : FlightPath.nudge) : 0
                let spot = FlightPath.plot(entry.motion, handFactor: handFactor, nudge: nudge)
                let color = Color(rgb: PitchAccents.triad(for: entry.slug).c3)
                var path = Path()
                path.move(to: at(cx, FlightPath.releaseY))
                path.addCurve(to: at(spot.x, spot.y), control1: at(spot.c1x, spot.c1y), control2: at(spot.c2x, spot.c2y))
                // B is dashed, so the pair still reads apart where two accents run close
                context.stroke(path, with: .color(color),
                               style: StrokeStyle(lineWidth: 2.5 * k, lineCap: .round, dash: index == 1 ? [7 * k, 5 * k] : []))
                context.fill(ring(spot.x, spot.y, 8), with: .color(color))
                context.stroke(ring(spot.x, spot.y, 8), with: .color(CompareInk.halo), lineWidth: 1.2 * k)
                let name = (b == nil ? "" : (index == 0 ? "A · " : "B · ")) + entry.display.shortName
                // a pair sharing one endpoint stacks its names instead of overlapping them
                label(context, name, at: at(spot.x, spot.y + 23 + (index == 1 && same ? 16 : 0)), k: k,
                      color: PitchAtlasTheme.bone, size: 12, tracking: 0, anchor: 0.5, halo: CompareInk.halo)
            }
        }
        .dynamicTypeSize(.large)
    }

    /// A mono label on its baseline, the way SVG text sits; `anchor` 0 starts at
    /// the point, 0.5 centers on it, 1 ends at it. A halo is the text's dark
    /// stroke, painted beneath it.
    private func label(_ context: GraphicsContext, _ string: String, at point: CGPoint, k: Double, color: Color,
                       size: Double = 11, tracking: Double = 1.5, anchor: Double = 0, halo: Color? = nil) {
        func resolve(_ ink: Color) -> GraphicsContext.ResolvedText {
            context.resolve(Text(string)
                .font(PitchAtlasType.font(.martian400, size: size * k, relativeTo: .caption2))
                .tracking(tracking * k)
                .foregroundStyle(ink))
        }
        let text = resolve(color)
        let measured = text.measure(in: CGSize(width: 10_000, height: 10_000))
        let origin = CGPoint(x: point.x - anchor * measured.width, y: point.y - text.firstBaseline(in: measured))
        if let halo {
            let under = resolve(halo)
            let r = 2.5 * k
            for step in 0..<16 {
                let angle = Double(step) / 16 * 2 * .pi
                context.draw(under, in: CGRect(origin: CGPoint(x: origin.x + r * cos(angle), y: origin.y + r * sin(angle)),
                                               size: measured))
            }
        }
        context.draw(text, in: CGRect(origin: origin, size: measured))
    }
}

// MARK: - Making room (CompareProvider.tsx)

/// A third pitch asks which place it takes; the other pitch stays.
private struct MakeRoom: View {
    let pending: String
    @Environment(\.compareSelection) private var selection
    @Environment(PitchStore.self) private var store

    private func name(_ slug: String?) -> String {
        slug.flatMap(store.pitch(slug:))?.display.shortName ?? "a pitch"
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.1)
                .ignoresSafeArea()
                .onTapGesture { selection.pending = nil }
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 16) {
                Text("Make room for \(name(pending))")
                    .font(PitchAtlasType.font(.anton400, size: 16, relativeTo: .headline))
                    .foregroundStyle(CompareInk.dialogInk)
                    .padding(.trailing, 40)
                    .accessibilityAddTraits(.isHeader)
                Text("Choose which pitch to replace. Your other selection stays in place.")
                    .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                    .foregroundStyle(PitchAtlasTheme.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach([CompareSelection.Slot.a, .b], id: \.self) { slot in
                    Button { selection.replace(slot); Haptics.selection() } label: {
                        Text("Replace \(name(selection.slug(in: slot)))").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ArchiveActionStyle())
                }
                Button { selection.pending = nil } label: {
                    Text("Keep current pair").frame(maxWidth: .infinity)
                }
                .buttonStyle(QuietActionStyle())
            }
            .padding(28)
            .frame(maxWidth: 420)
            .background(RoundedRectangle(cornerRadius: 12).fill(CompareInk.dialogFill))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(PitchAtlasTheme.bone.opacity(0.1), lineWidth: 1))
            .overlay(alignment: .topTrailing) {
                Button { selection.pending = nil } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(CompareInk.dialogInk)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
                .padding(8)
            }
            .padding(.horizontal, 16)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
    }
}

/// `.archive-action--quiet`: the cream action's shape with no fill, bone words, a
/// brass rim.
private struct QuietActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PitchAtlasType.font(.hanken600, size: 13, relativeTo: .subheadline))
            .foregroundStyle(PitchAtlasTheme.bone)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 17)
            .padding(.vertical, 11.4)
            .frame(minHeight: 44)
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(CompareInk.quietRim, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .contentShape(Rectangle())
    }
}
