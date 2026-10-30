import XCTest
@testable import PitchAtlas

/// The softball wing, pinned to the site (web 47e21e6): SoftballStudy.test.tsx,
/// softball-provenance-row.test.tsx, and the wing's routes.
final class SoftballWingTests: XCTestCase {
    private let store = PitchStore()

    private func pitch(_ slug: String) throws -> SoftballPitch {
        try XCTUnwrap(store.softball.pitches.first { $0.slug == slug })
    }

    func testTheWingDecodesFromTheBundle() {
        XCTAssertFalse(store.softball.pitches.isEmpty)
        XCTAssertFalse(store.softball.craftsmen.isEmpty)
        XCTAssertEqual(store.softball.windmillPhases.map(\.num), ["01", "02", "03", "04"])
        XCTAssertFalse(store.softball.fundamentalBlocks.isEmpty)
        XCTAssertFalse(store.softball.hubFastpitchBlurb.isEmpty)
    }

    // MARK: softball-provenance-row.test.tsx

    /// The four fields from the riseball record: the date is the source's own
    /// retrievedAt, never typed in here.
    func testTheProvenanceRowReadsTheRiseballRecord() throws {
        let riseball = try pitch("riseball")
        let source = try XCTUnwrap(riseball.movement.source)
        let question = try XCTUnwrap(riseball.openQuestion)
        XCTAssertEqual(SoftballReads.provenance("Movement", claim: riseball.movement, openQuestion: question),
                       "Movement · \(riseball.movement.confidence.label) · Last checked \(AsOf.format(source.retrievedAt)) · Open question: \(question)")
    }

    func testNoOpenQuestionReadsNoneOnFile() throws {
        let fastball = try pitch("fastball")
        XCTAssertNil(fastball.openQuestion)
        XCTAssertTrue(SoftballReads.provenance("Movement", claim: fastball.movement, openQuestion: nil)
            .hasSuffix("Open question: none on file"))
    }

    func testNoCheckedDateReadsNotRecorded() {
        let weak = Claim(value: "a relayed description with no registered source", confidence: .unverified,
                         source: nil, note: "no source corroborates this value", approximate: nil)
        XCTAssertTrue(SoftballReads.provenance("Movement", claim: weak, openQuestion: nil)
            .contains("Last checked not recorded"))
    }

    // MARK: SoftballStudy.test.tsx

    /// An unknown step opens at the hold; Previous stops at the hold, Next at the movement.
    func testTheStudyStepsStopAtTheirEnds() {
        XCTAssertEqual(SoftballStudy.Step(raw: "spin"), .spin)
        XCTAssertEqual(SoftballStudy.Step(raw: "no-such"), .hold)
        XCTAssertEqual(SoftballStudy.Step(raw: nil), .hold)
        XCTAssertNil(SoftballStudy.Step.hold.previous)
        XCTAssertEqual(SoftballStudy.Step.hold.next, .spin)
        XCTAssertNil(SoftballStudy.Step.movement.next)
        XCTAssertEqual(SoftballStudy.Step.allCases.map(\.buttonLabel), ["01 The hold", "02 The spin", "03 The movement"])
    }

    /// The hold stays the written grip; the spin and movement steps read their own claims.
    func testTheStudyReadsEachAccount() throws {
        let riseball = try pitch("riseball")
        XCTAssertNil(SoftballStudy.Step.hold.claim(riseball))
        XCTAssertEqual(SoftballStudy.Step.spin.claim(riseball), riseball.spin)
        XCTAssertEqual(SoftballStudy.Step.movement.claim(riseball), riseball.movement)
    }

    // MARK: Routes and the thread

    func testEveryPitchAndCraftsmanRoutes() throws {
        for p in store.softball.pitches {
            let url = try XCTUnwrap(URL(string: "pitchatlas://softball/pitch/\(p.slug)"))
            XCTAssertEqual(DeepLinkRouter.destination(for: url, store: store),
                           DeepLinkDestination(tab: .atlas, stack: [.atlas(.softball), .atlas(.softballPitch(slug: p.slug))]))
        }
        for c in store.softball.craftsmen {
            let url = try XCTUnwrap(URL(string: "pitchatlas://softball/craftsmen/\(c.slug)"))
            XCTAssertEqual(DeepLinkRouter.destination(for: url, store: store),
                           DeepLinkDestination(tab: .atlas, stack: [.atlas(.softball), .atlas(.softballCraftsman(slug: c.slug))]))
        }
    }

    func testTheWingsPagesRouteAndAMissLandsOnTheHub() throws {
        let hub = DeepLinkDestination(tab: .atlas, stack: [.atlas(.softball)])
        func dest(_ path: String) throws -> DeepLinkDestination? {
            DeepLinkRouter.destination(for: try XCTUnwrap(URL(string: "pitchatlas://\(path)")), store: store)
        }
        XCTAssertEqual(try dest("softball"), hub)
        XCTAssertEqual(try dest("softball/fastpitch"),
                       DeepLinkDestination(tab: .atlas, stack: [.atlas(.softball), .atlas(.fastpitch)]))
        XCTAssertEqual(try dest("softball/slowpitch"),
                       DeepLinkDestination(tab: .atlas, stack: [.atlas(.softball), .atlas(.slowpitch)]))
        XCTAssertEqual(try dest("softball/pitch/no-such"), hub)
        XCTAssertEqual(try dest("softball/craftsmen/no-such"), hub)
        XCTAssertEqual(try dest("softball/no-such"), hub)
    }

    func testTheDiscussionTopicIsSoftballSlug() {
        XCTAssertEqual(CommunityTopic.softball(slug: "riseball").key, "softball:riseball")
    }
}
