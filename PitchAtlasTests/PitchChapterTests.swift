import XCTest
@testable import PitchAtlas

/// The specimen page reads its record the way PitchChapter.tsx and
/// lib/specimenReads.ts do. The expected words are the ones pitch-atlas.com
/// printed on /pitch/four-seam and /pitch/two-seam (web 47e21e6).
final class PitchChapterTests: XCTestCase {
    private let store = PitchStore()

    private func entry(_ slug: String) throws -> PitchAtlasEntry {
        try XCTUnwrap(store.pitch(slug: slug), "\(slug) is not in the bundle")
    }

    func testTheChapterIndexIsTheSitesFiveInOrder() {
        XCTAssertEqual(SpecimenChapter.allCases.map(\.rawValue), ["Grip", "Variants", "Lessons", "Discussion", "Sources"])
    }

    func testTheStudyStepsAreHoldFingersSeamSourcedCue() {
        XCTAssertEqual(SpecimenReads.studySteps, ["Hold", "Fingers", "Seam", "Sourced cue"])
        XCTAssertEqual(SpecimenReads.studyTitles, [
            "Start with the whole hand.", "Read the finger placement.",
            "Find the seam relationship.", "Carry one cue with you.",
        ])
    }

    func testTheShapeReadIsWordsFromTheMotionRecord() throws {
        XCTAssertEqual(SpecimenReads.shapeLabel(try entry("four-seam")), "Rides")
        XCTAssertEqual(SpecimenReads.shapeLabel(try entry("two-seam")), "Holds flat · arm-side run")
        XCTAssertEqual(SpecimenReads.shapeLabel(try entry("knuckleball")), "Erratic flutter")
    }

    func testTheHeroPillsAreTheFamilyTheGuideAndTheForceEachOnce() throws {
        XCTAssertEqual(SpecimenReads.pills(try entry("four-seam")), ["Fastball", "The straight one", "Magnus"])
        XCTAssertEqual(SpecimenReads.pills(try entry("two-seam")), ["Fastball", "The runner", "Magnus, tilted"])
    }

    func testTheReleaseRoomReadsHoldPressureLeave() throws {
        let sequence = SpecimenReads.releaseSequence(try entry("two-seam"))
        XCTAssertEqual(sequence.map(\.label), ["Hold", "Pressure", "Leave"])
        XCTAssertEqual(sequence.map(\.copy), [
            "Held like a fastball: out in the fingers, not choked into the palm.",
            "Starts the arm-side bias",
            "Throw fastball effort and let the along-seam contact tilt the axis.",
        ])
    }

    func testTheGoldOneOfOneWearsBurntOrangeAndTheRestTheirOwnAccent() throws {
        XCTAssertEqual(SpecimenReads.accentRGB(try entry("four-seam")), WebTokens.Accent.burnt)
        XCTAssertEqual(SpecimenReads.accentRGB(try entry("two-seam")), 0x1F97A2)
    }

    func testTheColophonListsEverySourceOnTheFileOnceInPageOrder() throws {
        for pitch in store.pitches {
            let sources = SpecimenReads.colophonSources(pitch)
            XCTAssertEqual(Set(sources.map(\.id)).count, sources.count, "\(pitch.slug) repeats a source")
            XCTAssertEqual(sources.first?.id, pitch.canonical.grip.source?.id ?? sources.first?.id)
            var claims = [pitch.canonical.grip, pitch.canonical.mechanics, pitch.canonical.physics.spinAxis,
                          pitch.canonical.physics.teaching, pitch.seam.stitchCount, pitch.seam.accuracyNote]
            claims += pitch.canonical.gripDetails
            claims += [pitch.canonical.voice, pitch.canonical.physics.shape].compactMap { $0 }
            for variant in pitch.masterVariants {
                claims += [variant.distinction, variant.quote].compactMap { $0 }
                claims += (variant.accolades ?? []).map(\.claim)
            }
            let listed = Set(sources.map(\.id))
            for source in claims.compactMap(\.source) {
                XCTAssertTrue(listed.contains(source.id), "\(pitch.slug): \(source.label) is cited but not in the colophon")
            }
        }
    }

    func testTheSiblingsAreTheOtherFiledPitchesOfTheFamilyInFiledOrder() throws {
        let four = try entry("four-seam")
        let expected = store.pitches.filter { $0.canonical.family == four.canonical.family && $0.slug != four.slug }
        XCTAssertEqual(store.siblings(of: four).map(\.slug), expected.map(\.slug))
        XCTAssertFalse(store.siblings(of: four).contains { $0.slug == "four-seam" })
    }
}
