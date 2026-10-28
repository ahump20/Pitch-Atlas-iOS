import SwiftUI

// =============================================================================
// Pitch Atlas — a lost pitch's file
// =============================================================================
// Web: pages/LostPitchChapter.tsx, in its order. The stage (breadcrumb, the era,
// the name, the tagline, and the documentation tier riding in the hero so the
// reader knows how solid the ground is before the first sentence), the chapter
// boxes, the pitch on bound paper, the filed plate, what it was, why it is lost
// (with the one real quote when it exists), the surviving record on bound paper,
// the fadeaway's way into the screwball file, the discussion, the walk to the
// neighboring files, and the site's footer. No specimen and no seam schematic:
// these pitches were never filed, and that absence is the point.
// =============================================================================

struct LostPitchDetailView: View {
    let pitch: LostPitch

    @Environment(PitchStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var currentChapter: String?

    private static let scrollSpace = "lost-pitch-scroll"

    var body: some View {
        let neighbors = LostPitchFileReads.neighbors(of: pitch, in: store.lostPitches.entries)
        ZStack {
            FieldBackdrop()
            GeometryReader { viewport in
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            stage
                            ChapterBoxes(chapters: LostPitchFileReads.chapters(pitch), current: currentChapter,
                                         label: "In this archive file") { id in scroll(proxy, to: id) }
                                .padding(.horizontal, 24)
                            story.chapterAnchor("story", space: Self.scrollSpace)
                            if let image = store.archiveImage(forLostPitch: pitch.slug) {
                                ArchiveImageCard(image: image, variant: .detail)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 40)
                            }
                            account.chapterAnchor("account", space: Self.scrollSpace)
                            absence.chapterAnchor("absence", space: Self.scrollSpace)
                            if !pitch.recordEntries.isEmpty {
                                record.chapterAnchor("record", space: Self.scrollSpace)
                            }
                            if let followOn = LostPitchFileReads.followOn(pitch) {
                                followOnRoom(followOn)
                            }
                            DiscussionDrawer(topic: LostPitchFileReads.topic(pitch), topicName: pitch.name, compact: true)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 48)
                            ChapterWalk(name: "Lost pitch chapters", prevName: neighbors.prev?.name, nextName: neighbors.next?.name,
                                        hallLabel: "Lost Pitches", hallLine: "Back to the archive →", hallPath: "lost-pitches") {
                                if let prev = neighbors.prev { LostPitchDetailView(pitch: prev) }
                            } nextDestination: {
                                if let next = neighbors.next { LostPitchDetailView(pitch: next) }
                            }
                            SiteFooter(path: "/lost-pitches/\(pitch.slug)")
                        }
                        .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                    }
                    .coordinateSpace(.named(Self.scrollSpace))
                    .onPreferenceChange(ChapterFramesKey.self) { frames in
                        if let place = ChapterBoxes.activeChapter(frames: frames, viewportHeight: viewport.size.height),
                           place != currentChapter {
                            currentChapter = place
                        }
                    }
                }
            }
        }
        // The site's header carries the brand on every page; the title still names
        // the back button on the pages this one opens.
        .navigationTitle(pitch.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { BrandLockup(size: .sm) }
        }
    }

    private func scroll(_ proxy: ScrollViewProxy, to id: String) {
        withAnimation((reduceMotion || dynamicTypeSize.isAccessibilitySize) ? nil : .easeOut(duration: 0.25)) {
            proxy.scrollTo(id, anchor: .top)
        }
    }

    // MARK: - The stage

    /// `.on-stage` under the seam's faint light: the breadcrumb (its last crumb the
    /// file's number), the era, the name in Newsreader, the tagline, and the tier.
    private var stage: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Mono 11 on a 16.5 line, as the stage's crumbs and kicker set it. The
            // number is a hidden-note button on the site; here it is the plain crumb.
            Breadcrumb(trail: [Crumb(label: "The Atlas", path: "home"),
                               Crumb(label: "Lost Pitches", path: "lost-pitches"),
                               Crumb(label: pitch.specimenNo)],
                       linkInk: PitchAtlasTheme.bone2.opacity(0.8), currentInk: PitchAtlasTheme.bone2)
                .padding(.vertical, 1.65)
            KickerLabel(text: pitch.era)
                .padding(.vertical, 1.65)
                .padding(.top, 31.8)
            Text(pitch.name)
                .font(PitchAtlasType.font(.newsreader400, size: 43.2, relativeTo: .largeTitle))
                .tracking(em: -0.04, size: 43.2)
                .foregroundStyle(PitchAtlasTheme.bone)
                .cssLineHeight(0.98, face: .newsreader400, size: 43.2, relativeTo: .largeTitle)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 16 * 0.5665 * 43.2, alignment: .leading)
                .padding(.top, 16)
                .accessibilityAddTraits(.isHeader)
            Text(pitch.tagline)
                .font(PitchAtlasType.font(.hanken400, size: 18, relativeTo: .title3))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 18, relativeTo: .title3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 56 * 0.56 * 18, alignment: .leading)
                .padding(.top, 20)
            tierBadge.padding(.top, 28)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 64)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { ArchiveStageGround(light: ArchiveInk.lostStageLight) }
    }

    /// The documentation tier in a hairline box: bone for a paper trail or a thin
    /// record, the seam for a legend. Its meaning is the site's hover title.
    private var tierBadge: some View {
        let legend = pitch.tier == .legend
        return Text(pitch.tier.label.uppercased())
            .font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .caption))
            .tracking(em: 0.12, size: 12)
            .foregroundStyle(legend ? PitchAtlasTheme.seamBright : PitchAtlasTheme.bone)
            .cssLineHeight(16.0 / 12.0, face: .martian400, size: 12, relativeTo: .caption)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 17)
            .padding(.vertical, 9)
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(legend ? PitchAtlasTheme.seamBright.opacity(0.5) : PitchAtlasTheme.bone.opacity(0.25), lineWidth: 1)
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Documentation, \(pitch.tier.label)")
            .accessibilityHint(pitch.tier.meaning)
    }

    // MARK: - The pitch (on paper)

    private var story: some View {
        Text(pitch.intro)
            .font(PitchAtlasType.font(.newsreader400, size: 24, relativeTo: .title2))
            .tracking(em: -0.012, size: 24)
            .foregroundStyle(ArchiveInk.paperInk)
            .cssLineHeight(1.375, face: .newsreader400, size: 24, relativeTo: .title2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 58 * 0.5665 * 24, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 64)
            .archivePaper()
    }

    // MARK: - What it was, and why it is lost

    private var account: some View {
        VStack(alignment: .leading, spacing: 0) {
            StageTierMarker(index: "01", label: "What it was")
            ClaimProse(claim: pitch.what, size: 20, ink: PitchAtlasTheme.bone)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 64)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Why it is lost, and beside it the one real quote when the record holds one.
    private var absence: some View {
        VStack(alignment: .leading, spacing: 0) {
            StageTierMarker(index: "02", label: "Why it is lost")
            VStack(alignment: .leading, spacing: 40) {
                ClaimProse(claim: pitch.whyLost, size: 20, ink: PitchAtlasTheme.bone)
                if let quote = pitch.quote { ArchiveQuoteFigure(quote: quote) }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 64)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - The surviving record (on paper)

    private var record: some View {
        VStack(alignment: .leading, spacing: 0) {
            StageTierMarker(index: "03", label: "The surviving record")
            VStack(alignment: .leading, spacing: 40) {
                ForEach(Array(pitch.recordEntries.enumerated()), id: \.offset) { _, entry in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(entry.label.uppercased())
                            .font(MonoLabel.font)
                            .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                            .foregroundStyle(PitchAtlasTheme.text2)
                            .cssLineHeight(1, face: .martian400, size: MonoLabel.size, relativeTo: .caption2)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        ClaimProse(claim: entry.claim, size: 18, ink: ArchiveInk.paperInk)
                    }
                }
            }
            // Verbatim, LostPitchChapter.tsx.
            Text("Every line here is what the recovered record can actually support, labeled by its source and its confidence. Where the legend says more than the record can prove, the gap is shown, not filled.")
                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.text2)
                .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 78 * 0.56 * 14, alignment: .leading)
                .padding(.top, 25)
                .overlay(alignment: .top) {
                    Rectangle().fill(ArchiveInk.paperInk.opacity(0.15)).frame(height: 1).accessibilityHidden(true)
                }
                .padding(.top, 40)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 64)
        .archivePaper()
    }

    // MARK: - Follow the name into the pitch

    /// `.archive-history-next`: the eyebrow, the title, the account, and the way
    /// into the basic file the surviving account names, between gold hairlines.
    private func followOnRoom(_ followOn: LostPitchFileReads.FollowOn) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // `.archive-history-next > p` outranks `.archive-eyebrow`'s size: mono 15 on a 1.7 line.
            Text(followOn.eyebrow.uppercased())
                .font(PitchAtlasType.font(.martian400, size: 15, relativeTo: .subheadline))
                .tracking(em: 0.13, size: 15)
                .foregroundStyle(ArchiveInk.discoveryEyebrow)
                .cssLineHeight(1.7, face: .martian400, size: 15, relativeTo: .subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Text(followOn.title)
                .font(PitchAtlasType.font(.newsreader400, size: 32, relativeTo: .title))
                .tracking(em: -0.025, size: 32)
                .foregroundStyle(PitchAtlasTheme.bone)
                .cssLineHeight(1.06, face: .newsreader400, size: 32, relativeTo: .title)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
                .accessibilityAddTraits(.isHeader)
            Text(followOn.body)
                .font(PitchAtlasType.font(.hanken400, size: 15, relativeTo: .subheadline))
                .foregroundStyle(ArchiveInk.discoveryLede)
                .cssLineHeight(1.7, face: .hanken400, size: 15, relativeTo: .subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 66 * 0.56 * 15, alignment: .leading)
                .padding(.top, 12)
            if let id = followOn.repertoireId, let entry = store.repertoireEntry(id: id) {
                NavigationLink { followOnFile(entry) } label: {
                    ArchiveLinkLabel(title: followOn.link, ink: ArchiveInk.discoveryAccent)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the \(entry.name.lowercased()) file")
                .padding(.top, 16)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 49)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { Rectangle().fill(ArchiveInk.historyNextRule).frame(height: 1).accessibilityHidden(true) }
        .overlay(alignment: .bottom) { Rectangle().fill(ArchiveInk.historyNextRule).frame(height: 1).accessibilityHidden(true) }
    }

    /// The site sends /repertoire/<id> to the filed specimen when there is one,
    /// else to the basic file; either way it opens in this reading stack.
    @ViewBuilder
    private func followOnFile(_ entry: RepertoireEntry) -> some View {
        if let filed = entry.filedSlug.flatMap(store.pitch(slug:)) {
            PitchDetailView(entry: filed)
        } else {
            RepertoireDetailView(entry: entry)
        }
    }
}
