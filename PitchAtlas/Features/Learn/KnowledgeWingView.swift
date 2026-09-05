import SwiftUI

// =============================================================================
// KnowledgeWingView — one wing of the field manual (a sourced essay)
// =============================================================================
// The teaching layer rendered long-form: an eyebrow + Anton title + editorial
// sub, then each section as prose with its pull-stat gauge and the sources
// standing behind it. Closes with how the wing was sourced and any related
// reading. Provenance is the point — every measured value rides ClaimText,
// GaugeView, or SourceClaimLabel, never a bare string.
// =============================================================================

struct KnowledgeWingView: View {
    @Environment(PitchStore.self) private var store
    @Environment(\.compareSelection) private var comparison
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let wing: KnowledgeWing

    private var chapters: [ArchiveChapter] {
        [ArchiveChapter(id: "lesson-overview", title: "Overview")]
        + wing.sections.enumerated().map { ArchiveChapter(id: "lesson-section-\($0.offset)", title: $0.element.heading) }
        + [ArchiveChapter(id: "lesson-sources", title: "Sources and related reading")]
    }

    var body: some View {
        ZStack {
            FieldBackdrop()

            ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xl) {
                    header.id("lesson-overview")

                    if wing.educational == true {
                        educationalBanner
                    }

                    sections

                    footer.id("lesson-sources")
                }
                .padding(.horizontal, PitchAtlasSpacing.md)
                .padding(.top, PitchAtlasSpacing.md)
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                ArchiveChapterNavigation(chapters: chapters, compact: true) { id in
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { proxy.scrollTo(id, anchor: .top) }
                }
            }
            }
        }
        .navigationTitle(wing.navLabel.isEmpty ? wing.title : wing.navLabel)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: wing.eyebrow)
            Text(wing.title)
                .font(PitchAtlasTheme.anton(wing.title.count > 18 ? 30 : 40))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
                .fixedSize(horizontal: false, vertical: true)
            Text(wing.sub)
                .font(PitchAtlasTheme.newsreaderItalic(17))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(wing.eyebrow). \(wing.title). \(wing.sub)")
    }

    // MARK: - Educational banner

    private var educationalBanner: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            SectionLabel(text: "EDUCATIONAL USE", color: PitchAtlasTheme.amberBright)
            Text("This wing is teaching, not medical care.")
                .font(PitchAtlasTheme.hanken(13))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .leatherPress(padding: PitchAtlasSpacing.sm, radius: PitchAtlasRadius.panel)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Educational use — not medical care. This wing is teaching, not medical care.")
    }

    // MARK: - Sections

    private var sections: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xl) {
            ForEach(Array(wing.sections.enumerated()), id: \.offset) { index, section in
                WingSectionView(section: section).id("lesson-section-\(index)")
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.lg) {
            HairlineDivider()

            VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
                SectionLabel(text: "HOW THIS WING WAS SOURCED")
                Text(wing.confidenceNote)
                    .font(PitchAtlasTheme.hanken(13))
                    .foregroundStyle(PitchAtlasTheme.ink3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("How this wing was sourced. \(wing.confidenceNote)")

            if let related = wing.related, !related.isEmpty {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
                    SectionLabel(text: "RELATED")
                    ForEach(Array(related.enumerated()), id: \.offset) { _, link in
                        VStack(alignment: .leading, spacing: 4) {
                            relatedLink(link)
                            if let reason = link.reason, !reason.isEmpty {
                                Text(reason).font(.subheadline)
                                    .foregroundStyle(PitchAtlasTheme.bone2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

            }
        }
    }
    @ViewBuilder private func relatedLink(_ link: KnowledgeRelatedLink) -> some View {
        let parts = link.to.split(separator: "/").map(String.init)
        if parts.count == 2, parts[0] == "learn", let destination = store.wing(slug: parts[1]) {
            NavigationLink { KnowledgeWingView(wing: destination) } label: { Label(link.label, systemImage: "book") }.frame(minHeight: 44)
        } else if parts.count == 2, parts[0] == "pitch", let entry = store.pitch(slug: parts[1]) {
            NavigationLink { PitchDetailView(entry: entry) } label: { Label(link.label, systemImage: "baseball") }.frame(minHeight: 44)
        } else if link.to == "/repertoire" {
            NavigationLink { IndexView() } label: { Label(link.label, systemImage: "square.grid.2x2") }.frame(minHeight: 44)
        } else if link.to == "/compare" {
            Button { comparison.presented = true } label: { Label(link.label, systemImage: "square.split.2x1") }.frame(minHeight: 44)
        } else if let url = URL(string: "https://pitch-atlas.com" + link.to), link.to.hasPrefix("/") {
            Link(destination: url) { Label(link.label + " · web", systemImage: "arrow.up.right.square") }.frame(minHeight: 44)
        }
    }

}

// MARK: - One section

private struct WingSectionView: View {
    let section: KnowledgeSection

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            Text(section.heading)
                .font(PitchAtlasTheme.newsreader(18))
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                    .font(PitchAtlasTheme.hanken(15))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let pull = section.pullStat {
                GaugeView(label: pull.label, claim: pull.claim, accent: true)
            }

            if let claims = section.claims, !claims.isEmpty {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                    SectionLabel(text: "SOURCES BEHIND THIS SECTION", size: 9)
                    ForEach(Array(claims.enumerated()), id: \.offset) { _, claim in
                        SourceClaimLabel(claim: claim)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .leatherPress(padding: PitchAtlasSpacing.sm, radius: PitchAtlasRadius.panel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
