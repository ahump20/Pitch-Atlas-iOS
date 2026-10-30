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

    func testThePagerReadsTheFiledOrderWithNoWrap() throws {
        let pitches = store.pitches
        XCTAssertGreaterThan(pitches.count, 2)
        let first = try XCTUnwrap(pitches.first), last = try XCTUnwrap(pitches.last)
        XCTAssertNil(SpecimenReads.neighbors(of: first, in: pitches).previous)
        XCTAssertEqual(SpecimenReads.neighbors(of: first, in: pitches).next?.slug, pitches[1].slug)
        XCTAssertEqual(SpecimenReads.neighbors(of: last, in: pitches).previous?.slug, pitches[pitches.count - 2].slug)
        XCTAssertNil(SpecimenReads.neighbors(of: last, in: pitches).next)
    }

    /// craftsmenForPitch: the masters (never a legend) who sign the pitch, oldest
    /// first; a master file names its arm only when the hall has that person.
    func testTheMastersBehindAPitchAreItsSignatureCraftsmenOldestFirst() throws {
        for pitch in store.pitches {
            let masters = store.masters(forPitch: pitch.slug)
            XCTAssertTrue(masters.allSatisfy { $0.kind == .craftsman && $0.signaturePitchSlug == pitch.slug })
            XCTAssertEqual(masters.count, store.craftsmen.filter { $0.kind == .craftsman && $0.signaturePitchSlug == pitch.slug }.count)
            let starts = masters.map { EraSpan.parse($0.era)?.start ?? Int.max }
            XCTAssertEqual(starts, starts.sorted(), "\(pitch.slug) masters are out of era order")
        }
        XCTAssertEqual(store.masters(forPitch: "four-seam").map(\.slug), ["nolan-ryan"])
        XCTAssertEqual(store.master(named: "  NOLAN RYAN ", forPitch: "four-seam")?.slug, "nolan-ryan")
        XCTAssertNil(store.master(named: "Nolan Ryan", forPitch: "two-seam"))
    }

    func testTheSourcedCueIsThePitchersOwnWordsElseTheMechanics() {
        for pitch in store.pitches {
            XCTAssertEqual(SpecimenReads.sourcedCue(pitch), pitch.canonical.voice ?? pitch.canonical.mechanics)
        }
    }

    func testTheSeamStepSaysWhatIsFiled() throws {
        let four = try entry("four-seam")
        XCTAssertEqual(SpecimenReads.seamStepLine(four),
                       "Use \u{201C}Lift the hand\u{201D} on the reference model to see the seam beneath the hold.")
        XCTAssertEqual(SpecimenReads.seamAccuracyLine(four),
                       "\(four.seam.accuracyLevel.rawValue). No additional contact positions are inferred.")
        for pitch in store.pitches where pitch.canonical.gripModel.status == .unfiled {
            XCTAssertEqual(SpecimenReads.seamStepLine(pitch), "A canonical seam relationship has not been filed for this pitch.")
        }
    }

    func testTheColophonLegendIsTheSitesFiveTiersInOrder() {
        XCTAssertEqual(SpecimenReads.colophonTiers,
                       [.officialData, .pitcherOwnWords, .coachObserved, .reputableAnalysis, .secondhandAttributed])
    }

    func testTheHeroChipSaysWhatTheFilmIsDoing() {
        XCTAssertEqual(SpecimenReads.heroChip(hasClip: true, reduced: false, held: false), "Austin\u{2019}s grip · in motion")
        XCTAssertEqual(SpecimenReads.heroChip(hasClip: true, reduced: false, held: true), "Austin\u{2019}s grip · held")
        XCTAssertEqual(SpecimenReads.heroChip(hasClip: true, reduced: true, held: false), "Austin\u{2019}s grip")
        XCTAssertEqual(SpecimenReads.heroChip(hasClip: false, reduced: false, held: false), "Austin\u{2019}s grip")
    }

    /// ChapterSections.tsx observes with rootMargin -15% 0 -55% 0: a section counts
    /// while it crosses the band from 15% to 45% of the screen, and the highest one
    /// is the place. Nothing in the band keeps the last mark (nil here).
    func testTheChapterBoxMarksTheHighestSectionInTheReadingBand() {
        let frames: [String: CGRect] = [
            "specimen-grip": CGRect(x: 0, y: -900, width: 10, height: 1000),
            "specimen-variants": CGRect(x: 0, y: 200, width: 10, height: 700),
            "specimen-lessons": CGRect(x: 0, y: 400, width: 10, height: 200),
            "specimen-sources": CGRect(x: 0, y: 1200, width: 10, height: 300),
        ]
        XCTAssertEqual(ChapterBoxes.activeChapter(frames: frames, viewportHeight: 1000), "specimen-variants")
        var spanning = frames
        spanning["specimen-grip"] = CGRect(x: 0, y: -500, width: 10, height: 800)
        XCTAssertEqual(ChapterBoxes.activeChapter(frames: spanning, viewportHeight: 1000), "specimen-grip")
        let between: [String: CGRect] = ["specimen-grip": CGRect(x: 0, y: -900, width: 10, height: 1000),
                                         "specimen-sources": CGRect(x: 0, y: 460, width: 10, height: 300)]
        XCTAssertNil(ChapterBoxes.activeChapter(frames: between, viewportHeight: 1000))
    }

    func testTheSiblingsAreTheOtherFiledPitchesOfTheFamilyInFiledOrder() throws {
        let four = try entry("four-seam")
        let expected = store.pitches.filter { $0.canonical.family == four.canonical.family && $0.slug != four.slug }
        XCTAssertEqual(store.siblings(of: four).map(\.slug), expected.map(\.slug))
        XCTAssertFalse(store.siblings(of: four).contains { $0.slug == "four-seam" })
    }
}
