import SwiftUI

// =============================================================================
// ChapterBoxes — the page's chapters as numbered boxes
// =============================================================================
// Web: components/study/ChapterSections.tsx with study.css .study-chapter-nav and
// archive.css a[aria-current]. A row of bordered boxes ("01 Grip" … "05
// Sources") between two rules; tapping one scrolls to its section, and the box
// for the section in view is marked as the reader's place. It scrolls with the
// page; nothing pins.
// =============================================================================

struct ChapterBoxes: View {
    let chapters: [ArchiveChapter]
    /// The chapter whose section is in the reading band, if any yet.
    let current: String?
    /// ChapterSections' `label`: what VoiceOver calls the row.
    var label = "In this pitch"
    let go: (String) -> Void

    /// The site observes each section with rootMargin -15% 0 -55% 0: a section
    /// counts while it crosses the band from 15% to 45% of the screen, and the
    /// highest such section is the place. Nil when none is in the band — the
    /// caller keeps the mark it had, as the site does.
    static func activeChapter(frames: [String: CGRect], viewportHeight: CGFloat) -> String? {
        let top = viewportHeight * 0.15, bottom = viewportHeight * 0.45
        return frames
            .filter { $0.value.maxY > top && $0.value.minY < bottom }
            .min { $0.value.minY < $1.value.minY }?
            .key
    }

    var body: some View {
        FlowRow(spacing: 6, lineSpacing: 6) {
            ForEach(Array(chapters.enumerated()), id: \.element.id) { index, chapter in
                box(chapter, number: index + 1)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { Rectangle().fill(ChapterInk.chapterRule).frame(height: 1) }
        .overlay(alignment: .bottom) { Rectangle().fill(ChapterInk.chapterRule).frame(height: 1) }
        .padding(.bottom, 14)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }

    private func box(_ chapter: ArchiveChapter, number: Int) -> some View {
        let on = current == chapter.id
        let ink = on ? ChapterInk.chapterCurrentInk : PitchAtlasTheme.bone
        return Button { go(chapter.id); Haptics.selection() } label: {
            HStack(spacing: 8) {
                Text(String(format: "%02d", number))
                    .font(PitchAtlasType.font(.martian500, size: 9, relativeTo: .caption2))
                    .opacity(0.55)
                    .accessibilityHidden(true)
                Text(chapter.title)
                    .font(PitchAtlasType.font(.martian500, size: 12, relativeTo: .caption))
            }
            .foregroundStyle(ink)
            .padding(10)
            .frame(minHeight: 44)
            .background { if on { RoundedRectangle(cornerRadius: 4).fill(ChapterInk.chapterCurrentFill) } }
            .overlay { RoundedRectangle(cornerRadius: 4).strokeBorder(ink, lineWidth: 1) }
            .overlay(alignment: .bottom) {
                if on { Rectangle().fill(ChapterInk.chapterCurrentRule).frame(height: 1).padding(.horizontal, 3) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(chapter.title)
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }
}

/// Reports a chapter section's frame in the page's scroll space, for the boxes
/// to find the reader's place.
struct ChapterFramesKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, next in next })
    }
}

extension View {
    /// A chapter's scroll target and its frame in the page's scroll space.
    func chapterAnchor(_ id: String, space: String) -> some View {
        self.id(id)
            .background {
                GeometryReader { geometry in
                    Color.clear.preference(key: ChapterFramesKey.self, value: [id: geometry.frame(in: .named(space))])
                }
            }
    }
}

/// PitchChapter.tsx SectionHead: the kicker in the pitch's ink behind a 22×2
/// accent rule (.rfx-skick), the upright athletic title (.rfx-stitle at its
/// 26pt phone floor), and the section's lede.
struct ChapterSectionHead: View {
    let kicker: String
    let title: String
    let accent: UInt32
    var lede: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                Rectangle().fill(Color(rgb: accent)).frame(width: 22, height: 2)
                Text(kicker.uppercased())
                    .font(PitchAtlasType.font(.martian500, size: 11, relativeTo: .caption))
                    .tracking(em: 0.2, size: 11)
                    .foregroundStyle(PitchAccents.accentInk(accent))
            }
            .accessibilityElement(children: .combine)
            TightLines(title.uppercased(), face: .anton400, size: 26, lineHeight: 0.98,
                       relativeTo: .title2, balanced: true)
                .foregroundStyle(PitchAtlasTheme.bone)
                .padding(.top, 12)
            .accessibilityAddTraits(.isHeader)
            if let lede {
                Text(lede)
                    .font(PitchAtlasType.font(.hanken400, size: 15, relativeTo: .body))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .cssLineHeight(1.625, face: .hanken400, size: 15, relativeTo: .body)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
