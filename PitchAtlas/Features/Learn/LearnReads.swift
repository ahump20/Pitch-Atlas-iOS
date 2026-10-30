import Foundation

// =============================================================================
// Pitch Atlas — what the Learn pages read off the wings
// =============================================================================
// Web: pages/KnowledgeHub.tsx (the shelves and the reading numbers),
// components/sections/KnowledgePage.tsx and knowledge/WingNav.tsx (a wing's
// lessons, its sources, its closing note, the page-turn, where its links go).
// Pure reads, so the order and the numbering are pinned by tests.
// =============================================================================

enum LearnHubReads {
    /// One shelf of the contents page. A long shelf stages its first and last
    /// wings full width (`lead`, `closer`); the rest hold the grid.
    struct Shelf: Identifiable {
        let label: String
        let boundary: Bool
        let lead: KnowledgeWing?
        let middle: [KnowledgeWing]
        let closer: KnowledgeWing?
        var id: String { label }
        var wings: [KnowledgeWing] { [lead].compactMap { $0 } + middle + [closer].compactMap { $0 } }
    }

    /// Verbatim, KNOWLEDGE_HUB_COPY.heroSub in data/knowledge/index.ts.
    static let heroSub = "The specimens say what each pitch is. These wings explain the craft underneath it and mark the subjects Pitch Atlas does not cover. Every teaching claim is sourced and labeled by confidence."

    /// The craft, then the scope boundaries, each in teaching order. A shelf of
    /// more than four wings leads with its first and closes with its last; a
    /// shelf with nothing on it is left out.
    static func shelves(_ wings: [KnowledgeWing]) -> [Shelf] {
        [("The craft", false), ("Scope boundaries", true)].compactMap { label, boundary in
            let filed = wings.filter { ($0.boundaryOnly == true) == boundary }
            guard !filed.isEmpty else { return nil }
            guard filed.count > 4 else {
                return Shelf(label: label, boundary: boundary, lead: nil, middle: filed, closer: nil)
            }
            return Shelf(label: label, boundary: boundary, lead: filed.first,
                         middle: Array(filed.dropFirst().dropLast()), closer: filed.last)
        }
    }

    /// The wing's place in the whole teaching order, from 1: chapter N of the
    /// archive, so a shelf's numbers can skip.
    static func readingNo(_ wing: KnowledgeWing, in wings: [KnowledgeWing]) -> Int? {
        wings.firstIndex { $0.slug == wing.slug }.map { $0 + 1 }
    }

    /// Two digits, or nothing for a wing outside the order.
    static func pad(_ n: Int?) -> String {
        guard let n, n > 0 else { return "" }
        return String(format: "%02d", n)
    }

    /// The name a card, a crumb and the page-turn carry.
    static func shortTitle(_ wing: KnowledgeWing) -> String {
        wing.navLabel.isEmpty ? wing.title : wing.navLabel
    }

    /// What VoiceOver reads for a wing's card: its name, its place, its line.
    static func accessibilityLabel(_ wing: KnowledgeWing, in wings: [KnowledgeWing]) -> String {
        let no = pad(readingNo(wing, in: wings))
        let kind = wing.boundaryOnly == true ? "Scope boundary" : "The craft"
        return [shortTitle(wing), no.isEmpty ? nil : "Wing \(no)", wing.eyebrow, kind, wing.summary]
            .compactMap { $0 }.joined(separator: ". ")
    }
}

enum WingFileReads {
    /// Where a "Keep reading" link goes in the app.
    enum RelatedRoute: Equatable {
        case wing(slug: String), pitch(slug: String), index, compare, shapeMap
        /// A page the app does not file yet: it opens on pitch-atlas.com.
        case web(path: String)
    }

    /// The page-turn: the wing before, the wing after, and this one's place.
    struct Walk {
        let prev: KnowledgeWing?
        let next: KnowledgeWing?
        let position: Int
        let total: Int
        var hallLabel: String { "Wing \(LearnHubReads.pad(position)) of \(LearnHubReads.pad(total))" }
        var prevLabel: String { "← Wing \(LearnHubReads.pad(position - 1))" }
        var nextLabel: String { "Wing \(LearnHubReads.pad(position + 1)) →" }
    }

    /// Verbatim, EDUCATIONAL_DISCLAIMER in data/knowledge/claim.ts.
    static let scopeBoundary = "Pitch Atlas does not publish medical, injury, pain, rehabilitation, recovery, workload, durability, health-outcome, or youth-training claims. This route remains as a clear scope boundary and intentionally contains no teaching claims."

    /// ChapterSections: each lesson, numbered from 1, under its heading.
    static func chapters(_ wing: KnowledgeWing) -> [ArchiveChapter] {
        wing.sections.enumerated().map { ArchiveChapter(id: "lesson-\($0.offset + 1)", title: $0.element.heading) }
    }

    /// The sources behind a lesson: its claims, then its pull-stat's claim.
    static func claims(_ section: KnowledgeSection) -> [Claim] {
        (section.claims ?? []) + [section.pullStat?.claim].compactMap { $0 }
    }

    /// The lessons alternate on bound paper, the first one on it.
    static func onPaper(_ index: Int) -> Bool { index % 2 == 0 }

    /// The closing note's label.
    static func noteLabel(_ wing: KnowledgeWing) -> String {
        wing.boundaryOnly == true ? "Why this page stops here" : "How this was sourced"
    }

    static func walk(_ wing: KnowledgeWing, in wings: [KnowledgeWing]) -> Walk? {
        guard let i = wings.firstIndex(where: { $0.slug == wing.slug }) else { return nil }
        return Walk(prev: i > 0 ? wings[i - 1] : nil,
                    next: i < wings.count - 1 ? wings[i + 1] : nil,
                    position: i + 1, total: wings.count)
    }

    static func route(_ to: String) -> RelatedRoute {
        let parts = to.split(separator: "/").map(String.init)
        if parts.count == 2, parts[0] == "learn" { return .wing(slug: parts[1]) }
        if parts.count == 2, parts[0] == "pitch" { return .pitch(slug: parts[1]) }
        if to == "/repertoire" { return .index }
        if to == "/compare" { return .compare }
        if to == "/movement-map" { return .shapeMap }
        return .web(path: to)
    }
}
