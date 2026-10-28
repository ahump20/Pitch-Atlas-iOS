import SwiftUI

// =============================================================================
// Pitch Atlas — a craftsman's file
// =============================================================================
// Web: pages/CraftsmanChapter.tsx, in its order. The stage (breadcrumb, kicker,
// the name, the tagline, the signature-pitch chip, the way to the grip), the
// chapter boxes, the arm on bound paper, the signature pitch with its specimen
// card, the mental edge beside the pitcher's own words (the legend swaps it for
// a myth-and-physics room), the film filed to the arm, the record on bound
// paper, the walk to the neighboring eras, and the site's footer. Every claim
// keeps its tier and source; the record is told in prose, its numbers left with
// the record-keepers.
// =============================================================================

struct CraftsmanDetailView: View {
    let craftsman: Craftsman

    @Environment(PitchStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage(MotionPreference.pausedKey) private var motionPaused = false
    @State private var currentChapter: String?
    @State private var pageWidth: CGFloat = 440

    private static let scrollSpace = "craftsman-scroll"

    private var isLegend: Bool { craftsman.kind == .legend }
    private var pitch: PitchAtlasEntry? { craftsman.signaturePitchSlug.flatMap(store.pitch(slug:)) }

    var body: some View {
        let neighbors = CraftsmanFileReads.neighbors(of: craftsman, in: store.craftsmenByEra)
        ZStack {
            FieldBackdrop()
            GeometryReader { viewport in
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            stage
                            ChapterBoxes(chapters: CraftsmanFileReads.chapters(craftsman), current: currentChapter,
                                         label: "In this craftsman file") { id in scroll(proxy, to: id) }
                                .padding(.horizontal, 24)
                            story.chapterAnchor("story", space: Self.scrollSpace)
                            signature.chapterAnchor("signature", space: Self.scrollSpace)
                            secondRoom
                            legendRoom
                            MediaRail(eyebrow: "The lesson, on film",
                                      title: CraftsmanFileReads.mediaTitle(craftsman),
                                      intro: "A route-aware shelf for credited interviews, demonstrations, and historical clips connected to this craftsman's file.",
                                      items: MediaShelf.query(store.externalMedia.items, craftsmanSlug: craftsman.slug, limit: 2))
                            if !craftsman.recordProse.isEmpty {
                                record.chapterAnchor("record", space: Self.scrollSpace)
                            }
                            ChapterWalk(name: "Craftsmen chapters", prevName: neighbors.prev?.name, nextName: neighbors.next?.name,
                                        hallLabel: "The Craftsmen", hallLine: "Back to the hall →", hallPath: "craftsmen") {
                                if let prev = neighbors.prev { CraftsmanDetailView(craftsman: prev) }
                            } nextDestination: {
                                if let next = neighbors.next { CraftsmanDetailView(craftsman: next) }
                            }
                            SiteFooter(path: "/craftsmen/\(craftsman.slug)")
                        }
                        .readsWidth(into: $pageWidth)
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
        .navigationTitle(craftsman.name)
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

    /// `.on-stage`: the breadcrumb (its last crumb the file's number), the kicker,
    /// the name in Newsreader, the tagline, the chip, and the way to the grip.
    private var stage: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Mono 11 on a 16.5 line, as the stage's crumbs and kicker set it.
            Breadcrumb(trail: [Crumb(label: "The Atlas", path: "home"),
                               Crumb(label: "The Craftsmen", path: "craftsmen"),
                               Crumb(label: craftsman.specimenNo)],
                       linkInk: PitchAtlasTheme.bone2.opacity(0.8), currentInk: PitchAtlasTheme.bone2)
                .padding(.vertical, 1.65)
            KickerLabel(text: CraftsmanFileReads.kicker(craftsman))
                .padding(.vertical, 1.65)
                .padding(.top, 31.8)
            Text(craftsman.name)
                .font(PitchAtlasType.font(.newsreader400, size: 43.2, relativeTo: .largeTitle))
                .tracking(em: -0.04, size: 43.2)
                .foregroundStyle(PitchAtlasTheme.bone)
                .cssLineHeight(0.98, face: .newsreader400, size: 43.2, relativeTo: .largeTitle)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 14 * 0.5665 * 43.2, alignment: .leading)
                .padding(.top, 16)
                .accessibilityAddTraits(.isHeader)
            Text(craftsman.tagline)
                .font(PitchAtlasType.font(.hanken400, size: 18, relativeTo: .title3))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 18, relativeTo: .title3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 54 * 0.56 * 18, alignment: .leading)
                .padding(.top, 20)
            signatureChip.padding(.top, 28)
            if let pitch {
                NavigationLink { PitchDetailView(entry: pitch, opensAt: .grip) } label: {
                    ArchiveLinkLabel(title: CraftsmanFileReads.inspectLink(pitch), arrow: "↗\u{FE0E}", ink: PitchAtlasTheme.bone)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the \(pitch.canonical.name.lowercased()) file at its grip bench")
                .padding(.top, 20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 64)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { ArchiveStageGround(light: ArchiveInk.craftsmanStageLight) }
    }

    /// "Signature pitch" and the pitch in powder, in a bone hairline box.
    private var signatureChip: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("Signature pitch".uppercased())
                .foregroundStyle(PitchAtlasTheme.bone)
            Text(craftsman.signaturePitch.uppercased())
                .foregroundStyle(Color(web: WebTokens.Palette.powder))
        }
        .font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .caption))
        .tracking(em: 0.12, size: 12)
        .cssLineHeight(16.0 / 12.0, face: .martian400, size: 12, relativeTo: .caption)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 17)
        .padding(.vertical, 9)
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(PitchAtlasTheme.bone.opacity(0.25), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    // MARK: - The arm (on paper)

    private var story: some View {
        Text(craftsman.intro)
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

    // MARK: - The signature pitch

    private var signature: some View {
        VStack(alignment: .leading, spacing: 0) {
            StageTierMarker(index: "01", label: "The signature pitch")
            ClaimProse(claim: craftsman.signature, size: 20, ink: PitchAtlasTheme.bone)
            if let pitch {
                NavigationLink { PitchDetailView(entry: pitch) } label: { studyLabel(pitch) }
                    .buttonStyle(.plain)
                    .padding(.top, 24)
                specimen(pitch).padding(.top, 40)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 64)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func studyLabel(_ pitch: PitchAtlasEntry) -> some View {
        HStack(spacing: 8) {
            Text(CraftsmanFileReads.studyLink(pitch).uppercased())
                .fixedSize(horizontal: false, vertical: true)
            Text("→").accessibilityHidden(true)
        }
        .font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .caption))
        .tracking(em: 0.12, size: 12)
        .foregroundStyle(PitchAtlasTheme.seamBright)
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 17)
        .padding(.vertical, 11)
        .frame(minHeight: 44)
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(PitchAtlasTheme.seamBright.opacity(0.6), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 6))
    }

    /// The arm's signature pitch, struck as the same specimen card it wears
    /// across the atlas; the card opens the pitch's file. The card is the page's
    /// one motion control, so its grip film plays and Pause sits beside Compare.
    private func specimen(_ pitch: PitchAtlasEntry) -> some View {
        let width = min(360, max(240, pageWidth - 40))
        return VStack(alignment: .leading, spacing: 10.4) {
            NavigationLink { PitchDetailView(entry: pitch) } label: {
                PitchSpecimenCard(entry: pitch, style: .wall(width: width), motionPaused: motionPaused, playsLoop: true)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Open the \(pitch.canonical.name.lowercased()) file")
            .accessibilityAddTraits(.isButton)
            HStack(spacing: 8) {
                CompareButton(slug: pitch.slug)
                if hasFilm(pitch) && !reduceMotion { PauseMotionButton() }
            }
        }
        .frame(width: width, alignment: .leading)
        .frame(maxWidth: .infinity)
    }

    private func hasFilm(_ pitch: PitchAtlasEntry) -> Bool {
        if case .film = SpecimenCardContent.make(entry: pitch, grip: store.gripEntry(forSpecimen: pitch.slug)).face { return true }
        return false
    }

    // MARK: - The mental edge, or their words

    @ViewBuilder
    private var secondRoom: some View {
        if let heading = CraftsmanFileReads.secondRoom(craftsman) {
            VStack(alignment: .leading, spacing: 0) {
                StageTierMarker(index: "02", label: heading)
                if let edge = craftsman.mentalEdge {
                    ClaimProse(claim: edge, size: 20, ink: PitchAtlasTheme.bone)
                    if let quote = craftsman.quote { ArchiveQuoteFigure(quote: quote).padding(.top, 40) }
                } else if let quote = craftsman.quote {
                    ArchiveQuoteFigure(quote: quote)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 64)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - The legend's myth, and the physics

    @ViewBuilder
    private var legendRoom: some View {
        if isLegend, let note = craftsman.legendNote {
            VStack(alignment: .leading, spacing: 0) {
                StageTierMarker(index: "03", label: "The myth, and the physics")
                ClaimProse(claim: note, size: 20, ink: PitchAtlasTheme.bone)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 64)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - The record (on paper)

    private var record: some View {
        VStack(alignment: .leading, spacing: 0) {
            StageTierMarker(index: CraftsmanFileReads.recordIndex(craftsman), label: "The record")
            VStack(alignment: .leading, spacing: 40) {
                ForEach(Array(craftsman.recordProse.enumerated()), id: \.offset) { index, claim in
                    ClaimProse(claim: claim, size: index == 0 ? 20 : 18, ink: ArchiveInk.paperInk)
                }
            }
            if let links = craftsman.recordLinks, !links.isEmpty {
                RecordLinksRow(links: links).padding(.top, 48)
            }
            // Verbatim, CraftsmanChapter.tsx.
            Text("The record is told here the way the rest of the atlas is told: in prose, each claim confidence-labeled and one click from its source. Where reputation and record disagree, the gap is shown, not smoothed over.")
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
}

// MARK: - The record's way out

/// RecordLinks: the record-keepers' line under an ivory hairline, then each
/// keeper as a source link.
private struct RecordLinksRow: View {
    let links: [RecordLink]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("The numbers live with the record-keepers.")
                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.text2)
                .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                .fixedSize(horizontal: false, vertical: true)
            FlowRow(spacing: 24, lineSpacing: 8) {
                ForEach(links) { link in
                    SourceBadge(source: Source(id: link.id, label: link.label, url: link.url,
                                               retrievedAt: link.retrievedAt ?? "", season: nil))
                }
            }
        }
        .padding(.top, 21)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) {
            Rectangle().fill(ArchiveInk.paperInk.opacity(0.15)).frame(height: 1).accessibilityHidden(true)
        }
    }
}
