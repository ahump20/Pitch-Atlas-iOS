import SwiftUI

// =============================================================================
// PitchDetailView — one pitch, one file
// =============================================================================
// Web: pages/PitchChapter.tsx, in its order. The breadcrumb, the card opened
// (ChapterHero), the five chapter boxes, Compare, the grip bench, the grip
// evidence, the release room, the movement read, the lessons filed from the
// conversation, the master files, the colophon, the connections, the field notes
// and discussion, the pager, and the site's footer. Every claim keeps its tier
// and source; the page holds no number the record doesn't.
// =============================================================================

struct PitchDetailView: View {
    let entry: PitchAtlasEntry
    /// A link into the file's chapter (the site's `/pitch/<slug>#grip-lab`)
    /// opens it there, once; coming back to the page keeps the reader's place.
    var opensAt: SpecimenChapter? = nil

    @Environment(PitchStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var currentChapter: String?
    @State private var openedAtChapter = false

    private static let scrollSpace = "specimen-scroll"

    var body: some View {
        let grip = store.gripEntry(forSpecimen: entry.slug)
        let accentRGB = SpecimenReads.accentRGB(entry)
        ZStack {
            FieldBackdrop()
            GeometryReader { viewport in
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            VStack(alignment: .leading, spacing: 0) {
                                Breadcrumb(trail: [Crumb(label: "Pitch Atlas", path: "home"),
                                                   Crumb(label: "Pitch Index", path: "repertoire"),
                                                   Crumb(label: entry.canonical.name)])
                                    .padding(.top, 24)
                                ChapterHero(entry: entry, grip: grip) { scroll(proxy, to: SpecimenChapter.grip) }
                                ChapterBoxes(chapters: SpecimenChapter.allCases.map(\.chapter), current: currentChapter) { id in
                                    scroll(proxy, toID: id)
                                }
                                CompareButton(slug: entry.slug)
                                    .padding(.top, 8)
                                    .padding(.bottom, 20)
                                GripBench(entry: entry, grip: grip, accentRGB: accentRGB)
                                    .chapterAnchor(SpecimenChapter.grip.chapter.id, space: Self.scrollSpace)
                                if let grip {
                                    SpecimenGripEvidence(grip: grip, accentRGB: accentRGB,
                                                         showBench: { scroll(proxy, to: SpecimenChapter.grip) })
                                }
                                ReleaseRoom(entry: entry, accentRGB: accentRGB)
                                MovementRead(entry: entry, accentRGB: accentRGB)
                            }
                            .padding(.horizontal, 20)
                            lessons
                                .chapterAnchor(SpecimenChapter.lessons.chapter.id, space: Self.scrollSpace)
                            VStack(alignment: .leading, spacing: 0) {
                                MasterFiles(entry: entry, accentRGB: accentRGB)
                                    .chapterAnchor(SpecimenChapter.variants.chapter.id, space: Self.scrollSpace)
                                Colophon(entry: entry, accentRGB: accentRGB)
                                    .chapterAnchor(SpecimenChapter.sources.chapter.id, space: Self.scrollSpace)
                                PitchConnections(entry: entry, accentRGB: accentRGB)
                                community
                                SpecimenPager(entry: entry)
                            }
                            .padding(.horizontal, 20)
                            SiteFooter(path: "/pitch/\(entry.slug)")
                        }
                        .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                    }
                    .coordinateSpace(.named(Self.scrollSpace))
                    .onAppear {
                        guard let opensAt, !openedAtChapter else { return }
                        openedAtChapter = true
                        // after the first layout, so the chapter's anchor exists
                        DispatchQueue.main.async { proxy.scrollTo(opensAt.chapter.id, anchor: .top) }
                    }
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
        .navigationTitle(entry.display.shortName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { BrandLockup(size: .sm) }
        }
    }

    /// The lessons filed from the conversation: two credited posts tagged to the
    /// pitch, full bleed. The chapter keeps its place even when none are filed.
    private var lessons: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 1)
            MediaRail(eyebrow: "Filed from the conversation",
                      title: "See the \(entry.canonical.name.lowercased()) taught.",
                      intro: "Credited posts that add a useful grip, release, history, or craft perspective to this specimen. The original provider serves every clip.",
                      items: MediaShelf.query(store.externalMedia.items, pitchSlug: entry.slug, limit: 2),
                      allowsSuggestion: true, pitchSlug: entry.slug)
        }
    }

    /// The field notes and the discussion on this pitch (FieldNotes and
    /// DiscussionPanel on the site), under a bone hairline. The Discussion box
    /// lands on the drawer, as the site's #discussion does, and leaves it shut.
    private var community: some View {
        VStack(alignment: .leading, spacing: 0) {
            FieldNotesChapter(entry: entry)
            DiscussionDrawer(topic: .specimen(slug: entry.slug), topicName: entry.canonical.name)
                .padding(.horizontal, 20)
                .padding(.vertical, 48)
                .chapterAnchor(SpecimenChapter.discussion.chapter.id, space: Self.scrollSpace)
        }
        .padding(.top, 32)
        .overlay(alignment: .top) { Rectangle().fill(PitchAtlasTheme.bone.opacity(0.08)).frame(height: 1) }
    }

    private func scroll(_ proxy: ScrollViewProxy, to chapter: SpecimenChapter) {
        scroll(proxy, toID: chapter.chapter.id)
    }

    private func scroll(_ proxy: ScrollViewProxy, toID id: String) {
        withAnimation((reduceMotion || dynamicTypeSize.isAccessibilitySize) ? nil : .easeOut(duration: 0.25)) {
            proxy.scrollTo(id, anchor: .top)
        }
    }
}

extension PitchAtlasEntry {
    /// Navigation ledger only: original Claim values, tiers and notes remain at their reading sites.
    var studySources: [Source] {
        var claims = [canonical.grip, canonical.mechanics, canonical.physics.teaching,
                      canonical.physics.spinAxis, seam.stitchCount, seam.accuracyNote]
        claims += canonical.gripDetails
        claims += [canonical.voice, canonical.gripModel.provenance, canonical.physics.shape,
                   canonical.physics.spinRateRpm, canonical.physics.activeSpinPct,
                   canonical.physics.primaryBreak?.claim, canonical.physics.secondaryBreak?.claim].compactMap { $0 }
        for variant in masterVariants {
            claims += [variant.distinction, variant.quote].compactMap { $0 }
            claims += variant.recordNumbers.map(\.claim)
        }
        var seen = Set<String>()
        return claims.compactMap(\.source).filter { seen.insert($0.id).inserted }
    }
}
