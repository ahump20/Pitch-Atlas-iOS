import XCTest
@testable import PitchAtlas

/// The Learn hub and a wing, read the way KnowledgeHub.tsx, KnowledgePage.tsx and
/// WingNav.tsx read the wings. The expected shelves and numbers are the ones
/// pitch-atlas.com printed on /learn (web 47e21e6).
final class LearnHubTests: XCTestCase {
    private let wings = PitchStore().knowledge

    private func wing(_ slug: String) throws -> KnowledgeWing {
        try XCTUnwrap(wings.first { $0.slug == slug }, "\(slug) is not in the bundle")
    }

    // MARK: - The shelves

    /// Two shelves: the craft, led by the delivery and closed by the canon at
    /// full width with the rest in the grid, then the scope boundaries.
    func testTheCraftShelfLeadsWithTheDeliveryAndClosesWithTheCanon() throws {
        let shelves = LearnHubReads.shelves(wings)
        XCTAssertEqual(shelves.map(\.label), ["The craft", "Scope boundaries"])
        let craft = shelves[0]
        XCTAssertFalse(craft.boundary)
        XCTAssertEqual(craft.lead?.slug, "mechanics")
        XCTAssertEqual(craft.middle.map(\.slug), ["pitch-design", "sequencing", "spin", "metrics", "trends", "handedness"])
        XCTAssertEqual(craft.closer?.slug, "canon")
        let edge = shelves[1]
        XCTAssertTrue(edge.boundary)
        XCTAssertNil(edge.lead)
        XCTAssertNil(edge.closer)
        XCTAssertEqual(edge.middle.map(\.slug), ["arm-health", "youth"])
    }

    /// The rule behind it: each shelf keeps the teaching order; a shelf of more
    /// than four leads and closes at full width; an empty shelf is left out.
    func testShelvesKeepTheTeachingOrderAndOnlyALongShelfStagesItsEnds() {
        let shelves = LearnHubReads.shelves(wings)
        XCTAssertEqual(shelves.flatMap(\.wings).map(\.slug).sorted(), wings.map(\.slug).sorted(), "every wing is shelved once")
        XCTAssertEqual(shelves[0].wings.map(\.slug), wings.filter { $0.boundaryOnly != true }.map(\.slug))
        XCTAssertEqual(shelves[1].wings.map(\.slug), wings.filter { $0.boundaryOnly == true }.map(\.slug))

        let four = Array(wings.filter { $0.boundaryOnly != true }.prefix(4))
        let short = LearnHubReads.shelves(four)
        XCTAssertEqual(short.map(\.label), ["The craft"], "a shelf with nothing on it is left out")
        XCTAssertNil(short[0].lead)
        XCTAssertNil(short[0].closer)
        XCTAssertEqual(short[0].middle.map(\.slug), four.map(\.slug))
        XCTAssertTrue(LearnHubReads.shelves([]).isEmpty)
    }

    /// A wing's number is its place in the whole teaching order, so the shelves
    /// read 01 … 05, 08, 09, 10 and the boundaries 06 and 07.
    func testReadingNumbersCountTheWholeOrder() throws {
        XCTAssertEqual(LearnHubReads.pad(LearnHubReads.readingNo(try wing("mechanics"), in: wings)), "01")
        XCTAssertEqual(LearnHubReads.pad(LearnHubReads.readingNo(try wing("arm-health"), in: wings)), "06")
        XCTAssertEqual(LearnHubReads.pad(LearnHubReads.readingNo(try wing("youth"), in: wings)), "07")
        XCTAssertEqual(LearnHubReads.pad(LearnHubReads.readingNo(try wing("canon"), in: wings)), "10")
        for (i, w) in wings.enumerated() { XCTAssertEqual(LearnHubReads.readingNo(w, in: wings), i + 1, w.slug) }
        XCTAssertEqual(LearnHubReads.pad(nil), "")
    }

    /// A card and a crumb carry the wing's short label; the hero carries the title.
    func testShortTitleIsTheNavLabel() throws {
        XCTAssertEqual(LearnHubReads.shortTitle(try wing("spin")), "Spin & Shape")
        XCTAssertEqual(LearnHubReads.shortTitle(try wing("arm-health")), "Health & Workload Boundary")
    }

    // MARK: - A wing

    /// The lessons are the chapters, numbered from 1, under the section headings.
    func testAWingFilesItsLessonsAsItsChapters() throws {
        let spin = try wing("spin")
        let chapters = WingFileReads.chapters(spin)
        XCTAssertEqual(chapters.map(\.id), spin.sections.indices.map { "lesson-\($0 + 1)" })
        XCTAssertEqual(chapters.map(\.title), spin.sections.map(\.heading))
        XCTAssertEqual(chapters.first?.title, "Axis Is Direction")
    }

    /// The sources behind a lesson are its claims, then its pull-stat's claim.
    func testTheSourcesBehindALessonIncludeItsPullStat() {
        let a = Claim(value: "a", confidence: .reputableAnalysis, source: nil, note: nil, approximate: nil)
        let b = Claim(value: "b", confidence: .officialData, source: nil, note: nil, approximate: nil)
        let both = KnowledgeSection(heading: "h", paragraphs: [], claims: [a], pullStat: KnowledgePullStat(label: "l", claim: b))
        XCTAssertEqual(WingFileReads.claims(both).map(\.value), ["a", "b"])
        let plain = KnowledgeSection(heading: "h", paragraphs: [], claims: [a], pullStat: nil)
        XCTAssertEqual(WingFileReads.claims(plain).map(\.value), ["a"])
        let none = KnowledgeSection(heading: "h", paragraphs: [], claims: nil, pullStat: nil)
        XCTAssertTrue(WingFileReads.claims(none).isEmpty)
    }

    /// The lessons alternate on bound paper, starting with the first.
    func testLessonsAlternateOnPaperFromTheFirst() {
        XCTAssertEqual((0..<5).map(WingFileReads.onPaper), [true, false, true, false, true])
    }

    /// A boundary wing says why it stops; a teaching wing says how it was sourced.
    func testTheClosingNoteNamesWhyABoundaryStops() throws {
        XCTAssertEqual(WingFileReads.noteLabel(try wing("arm-health")), "Why this page stops here")
        XCTAssertEqual(WingFileReads.noteLabel(try wing("spin")), "How this was sourced")
    }

    /// The boundary wings teach nothing: no claims, and no discussion thread.
    /// A teaching wing opens its thread under learn:<slug>.
    func testBoundaryWingsCarryNoClaimsAndOpenNoThread() throws {
        for w in wings where w.boundaryOnly == true {
            XCTAssertNil(CommunityTopic.learnWing(w), w.slug)
            XCTAssertTrue(w.sections.flatMap(WingFileReads.claims).isEmpty, "\(w.slug) carries a teaching claim")
        }
        XCTAssertEqual(CommunityTopic.learnWing(try wing("spin"))?.key, "learn:spin")
    }

    /// The page-turn: the wing before, the wing after, and where this one sits in
    /// the ten, in the site's words.
    func testTheWalkTurnsToTheNeighborsInTheTeachingOrder() throws {
        let walk = try XCTUnwrap(WingFileReads.walk(try wing("spin"), in: wings))
        XCTAssertEqual(walk.prev?.slug, "sequencing")
        XCTAssertEqual(walk.next?.slug, "metrics")
        XCTAssertEqual(walk.position, 4)
        XCTAssertEqual(walk.total, wings.count)
        XCTAssertEqual(walk.hallLabel, "Wing 04 of \(LearnHubReads.pad(wings.count))")
        XCTAssertEqual(walk.prevLabel, "← Wing 03")
        XCTAssertEqual(walk.nextLabel, "Wing 05 →")

        let first = try XCTUnwrap(WingFileReads.walk(try XCTUnwrap(wings.first), in: wings))
        XCTAssertNil(first.prev)
        let last = try XCTUnwrap(WingFileReads.walk(try XCTUnwrap(wings.last), in: wings))
        XCTAssertNil(last.next)
    }

    /// "Keep reading" goes where the site's links go; the movement map opens on
    /// the web until the app files its own.
    func testKeepReadingRoutesWhereTheSiteGoes() {
        XCTAssertEqual(WingFileReads.route("/learn/spin"), .wing(slug: "spin"))
        XCTAssertEqual(WingFileReads.route("/pitch/four-seam"), .pitch(slug: "four-seam"))
        XCTAssertEqual(WingFileReads.route("/repertoire"), .index)
        XCTAssertEqual(WingFileReads.route("/compare"), .compare)
        XCTAssertEqual(WingFileReads.route("/movement-map"), .web(path: "/movement-map"))
    }
}
