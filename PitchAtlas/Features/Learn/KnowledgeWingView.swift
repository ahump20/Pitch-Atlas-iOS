import SwiftUI

// =============================================================================
// Pitch Atlas — one wing of the craft record
// =============================================================================
// Web: components/sections/KnowledgePage.tsx and knowledge/WingNav.tsx, in their
// order. The section header, the lessons as chapter boxes, the scope boundary
// on a wing that stops at education, each lesson under its marker (the odd ones
// on bound paper) with the sources behind it, the note on how it was sourced,
// the places to keep reading, the discussion (never on a boundary wing), the
// page-turn to the wings either side, and the site's footer.
// =============================================================================

struct KnowledgeWingView: View {
    let wing: KnowledgeWing

    @Environment(PitchStore.self) private var store
    @Environment(\.compareSelection) private var comparison
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var currentChapter: String?

    private static let scrollSpace = "learn-wing-scroll"

    var body: some View {
        let name = LearnHubReads.shortTitle(wing)
        ZStack {
            FieldBackdrop()
            GeometryReader { viewport in
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            SectionHero(eyebrow: wing.eyebrow,
                                        title: Text(wing.title),
                                        sub: Text(wing.sub),
                                        trail: [Crumb(label: "The Atlas", path: "home"),
                                                Crumb(label: "Learn", path: "learn"),
                                                Crumb(label: name)],
                                        accent: wing.accent == "seam" ? .seam : .powder)
                            // The site sets these boxes flush to the screen's edge (the
                            // nav sits outside the page's gutter); here they keep it.
                            ChapterBoxes(chapters: WingFileReads.chapters(wing), current: currentChapter,
                                         label: "In this lesson", inset: 20) { id in scroll(proxy, to: id) }
                            if wing.boundaryOnly == true {
                                scopeBoundary
                            }
                            ForEach(Array(wing.sections.enumerated()), id: \.offset) { index, section in
                                lesson(section, index: index)
                                    .chapterAnchor("lesson-\(index + 1)", space: Self.scrollSpace)
                            }
                            note
                            if let related = wing.related, !related.isEmpty {
                                keepReading(related)
                            }
                            if let topic = CommunityTopic.learnWing(wing) {
                                DiscussionDrawer(topic: topic, topicName: name)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 48)
                            }
                            walk
                            SiteFooter(path: "/learn/\(wing.slug)")
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
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { BrandLockup(markSize: 26, wordSize: 20) }
        }
    }

    private func scroll(_ proxy: ScrollViewProxy, to id: String) {
        withAnimation((reduceMotion || dynamicTypeSize.isAccessibilitySize) ? nil : .easeOut(duration: 0.25)) {
            proxy.scrollTo(id, anchor: .top)
        }
    }

    // MARK: - The scope boundary

    /// EducationalDisclaimer: the one caution on an otherwise calm page, on a
    /// press panel ruled in the seam.
    private var scopeBoundary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scope boundary".uppercased())
                .font(MonoLabel.font)
                .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                .foregroundStyle(PitchAtlasTheme.seamBright)
                .cssLineHeight(1, face: .martian400, size: MonoLabel.size, relativeTo: .caption2)
                .accessibilityAddTraits(.isHeader)
            Text(WingFileReads.scopeBoundary)
                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.text2)
                .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 72 * 0.56 * 14, alignment: .leading)
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 21)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { PanelSurface(radius: 6) }
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(PitchAtlasTheme.seamBright.opacity(0.3), lineWidth: 1)
                .accessibilityHidden(true)
        }
        .inkContext(.object)
        .accessibilityElement(children: .combine)
        .padding(.horizontal, 20)
        .padding(.top, 48)
    }

    // MARK: - A lesson

    /// The marker, the paragraphs, and the sources behind them. The odd lessons
    /// (the first, the third…) sit on the bound paper and take its inks.
    @ViewBuilder
    private func lesson(_ section: KnowledgeSection, index: Int) -> some View {
        let paper = WingFileReads.onPaper(index)
        let body = lessonBody(section, index: index, paper: paper)
            .padding(.horizontal, 20)
            .padding(.vertical, 56)
            .frame(maxWidth: .infinity, alignment: .leading)
        if paper { body.archivePaper() } else { body }
    }

    private func lessonBody(_ section: KnowledgeSection, index: Int, paper: Bool) -> some View {
        let claims = WingFileReads.claims(section)
        let ink = paper ? ArchiveInk.paperInk : PitchAtlasTheme.bone
        return VStack(alignment: .leading, spacing: 0) {
            StageTierMarker(index: LearnHubReads.pad(index + 1), label: section.heading)
            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph)
                        .font(PitchAtlasType.font(.hanken400, size: 18, relativeTo: .title3))
                        .foregroundStyle(ink)
                        .cssLineHeight(1.625, face: .hanken400, size: 18, relativeTo: .title3)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 64 * 0.56 * 18, alignment: .leading)
                }
            }
            if !claims.isEmpty {
                VStack(alignment: .leading, spacing: 20) {
                    Text("The sources behind it".uppercased())
                        .font(MonoLabel.font)
                        .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                        .foregroundStyle(PitchAtlasTheme.text3)
                        .cssLineHeight(1, face: .martian400, size: MonoLabel.size, relativeTo: .caption2)
                        .accessibilityAddTraits(.isHeader)
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(Array(claims.enumerated()), id: \.offset) { _, claim in
                            // On the paper the prose takes its ivory in full; on the
                            // void, bone at 90%.
                            ClaimProse(claim: claim, size: 15.2, leading: 1.625,
                                       ink: paper ? ArchiveInk.paperInk : PitchAtlasTheme.bone.opacity(0.9))
                                .padding(.leading, 17)
                                .overlay(alignment: .leading) {
                                    Rectangle().fill(ink.opacity(0.15)).frame(width: 1).accessibilityHidden(true)
                                }
                        }
                    }
                }
                .padding(.top, 40)
            }
        }
    }

    // MARK: - How it was sourced

    /// The mono label runs into the note on one line, as the site's inline span does.
    private var note: some View {
        (Text(WingFileReads.noteLabel(wing).uppercased())
            .font(MonoLabel.font)
            .tracking(MonoLabel.trackingEm * MonoLabel.size)
            .foregroundStyle(PitchAtlasTheme.ink3)
            + Text("\u{2002}")
            + Text(wing.confidenceNote)
            .foregroundStyle(PitchAtlasTheme.ink2))
            .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
            .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 72 * 0.56 * 14, alignment: .leading)
            .padding(.top, 25)
            .overlay(alignment: .top) {
                Rectangle().fill(PitchAtlasTheme.bone.opacity(0.15)).frame(height: 1).accessibilityHidden(true)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Keep reading

    private func keepReading(_ related: [KnowledgeRelatedLink]) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Keep reading".uppercased())
                .font(MonoLabel.font)
                .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                .foregroundStyle(PitchAtlasTheme.text2)
                .cssLineHeight(1, face: .martian400, size: MonoLabel.size, relativeTo: .caption2)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 16) {
                ForEach(Array(related.enumerated()), id: \.offset) { _, link in
                    relatedLink(link)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 48)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Where the site's link goes, opened in this stack; a page the app does not
    /// file yet (or a slug the bundle lacks) opens on pitch-atlas.com.
    @ViewBuilder
    private func relatedLink(_ link: KnowledgeRelatedLink) -> some View {
        switch WingFileReads.route(link.to) {
        case .wing(let slug):
            if let other = store.wing(slug: slug) {
                NavigationLink { KnowledgeWingView(wing: other) } label: { relatedPlate(link, web: false) }
                    .buttonStyle(.plain)
            } else {
                webLink(link)
            }
        case .pitch(let slug):
            if let entry = store.pitch(slug: slug) {
                NavigationLink { PitchDetailView(entry: entry) } label: { relatedPlate(link, web: false) }
                    .buttonStyle(.plain)
            } else {
                webLink(link)
            }
        case .index:
            NavigationLink { IndexView() } label: { relatedPlate(link, web: false) }
                .buttonStyle(.plain)
        case .compare:
            Button { comparison.presented = true } label: { relatedPlate(link, web: false) }
                .buttonStyle(.plain)
        case .web:
            webLink(link)
        }
    }

    @ViewBuilder
    private func webLink(_ link: KnowledgeRelatedLink) -> some View {
        if link.to.hasPrefix("/"), let url = URL(string: "https://pitch-atlas.com" + link.to) {
            Link(destination: url) { relatedPlate(link, web: true) }
                .buttonStyle(.plain)
                .accessibilityHint("Opens on pitch-atlas.com")
        }
    }

    /// A rfx-plate on the pale steel, its corner cut to 6 and its ticks off: the
    /// label (and why, when the wing says) centered over the seam's arrow.
    private func relatedPlate(_ link: KnowledgeRelatedLink, web: Bool) -> some View {
        Plate(accent: ArchiveInk.keepReadingPlate, radius: 6, ticks: false,
              insets: EdgeInsets(top: 17, leading: 21, bottom: 17, trailing: 21),
              alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(link.label.uppercased())
                    .font(PitchAtlasType.font(.anton400, size: 18, relativeTo: .headline))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .cssLineHeight(28.0 / 18.0, face: .anton400, size: 18, relativeTo: .headline)
                    .fixedSize(horizontal: false, vertical: true)
                if let reason = link.reason, !reason.isEmpty {
                    Text(reason)
                        .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                        .foregroundStyle(PitchAtlasTheme.text2)
                        .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            // A link the app sends to the web says so with its arrow.
            Text(web ? "↗\u{FE0E}" : "→")
                .font(MonoLabel.font)
                .foregroundStyle(PitchAtlasTheme.seamBright)
                .cssLineHeight(1, face: .martian400, size: MonoLabel.size, relativeTo: .caption2)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    // MARK: - The page-turn

    @ViewBuilder
    private var walk: some View {
        if let walk = WingFileReads.walk(wing, in: store.knowledge) {
            ChapterWalk(name: "Learn wings",
                        prevName: walk.prev.map(LearnHubReads.shortTitle),
                        nextName: walk.next.map(LearnHubReads.shortTitle),
                        hallLabel: walk.hallLabel, hallLine: "Back to the craft record →", hallPath: "learn",
                        style: .rule, prevLabel: walk.prevLabel, nextLabel: walk.nextLabel) {
                if let prev = walk.prev { KnowledgeWingView(wing: prev) }
            } nextDestination: {
                if let next = walk.next { KnowledgeWingView(wing: next) }
            }
        }
    }
}
