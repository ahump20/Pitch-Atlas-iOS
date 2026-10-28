import XCTest
@testable import PitchAtlas

/// The pitch page's tier-03 chapter (web sections/FieldNotes.tsx). Every expected
/// value is the site's: data/field-notes.ts for the ranking model, the
/// vocabulary and the context lists; lib/community.ts for the writable source
/// tiers and the pace mapping; FieldNotes.tsx for the form defaults, the
/// validity rule, the age line and the bullpen card's words.
final class FieldNotesChapterTests: XCTestCase {
    private let store = PitchStore()

    // MARK: How notes rank, and the vocabulary

    func testRankSignalsReadTheSitesWeightsInOrder() {
        let signals = store.fieldNotesGuide.rankSignals
        XCTAssertEqual(signals.map(\.label), ["Provenance", "Adoption", "Usefulness", "Context match", "Community confidence"])
        XCTAssertEqual(signals.map(\.percent), [35, 20, 20, 15, 10])
        XCTAssertEqual(signals.map(\.weight).reduce(0, +), 1.0, accuracy: 1e-9)
        XCTAssertEqual(signals.first?.blurb,
                       "Source tier and evidence. A coach-observed note with a link outranks an unverified hunch with none.")
    }

    func testVocabularyIsTheSitesEightTerms() {
        let terms = store.fieldNotesGuide.vocabulary
        XCTAssertEqual(terms.count, 8)
        XCTAssertEqual(terms.first?.term, "Field Note")
        XCTAssertEqual(terms.first?.gloss, "One pitcher's report on a grip variant.")
        XCTAssertEqual(terms.last?.term, "Needs Evidence")
    }

    func testFieldNoteCountsMatchTheManifest() {
        XCTAssertEqual(store.fieldNotesGuide.rankSignals.count, store.manifest.counts["field-notes.signals"])
        XCTAssertEqual(store.fieldNotesGuide.vocabulary.count, store.manifest.counts["field-notes.vocabulary"])
    }

    // MARK: The form's context lists follow the site's words

    func testContextLabelsMatchTheSite() {
        let guide = store.fieldNotesGuide
        XCTAssertEqual(guide.playerLevels.map(\.value), CommunityPlayerLevel.allCases.map(\.rawValue))
        for option in guide.playerLevels {
            XCTAssertEqual(CommunityPlayerLevel(rawValue: option.value)?.label, option.label)
        }
        XCTAssertEqual(guide.armSlots.map(\.value), CommunityArmSlot.allCases.map(\.rawValue))
        for option in guide.armSlots {
            XCTAssertEqual(CommunityArmSlot(rawValue: option.value)?.label, option.label)
        }
        XCTAssertEqual(guide.velocityBands.map(\.value), CommunityVelocityBand.allCases.map(\.formValue))
        for option in guide.velocityBands {
            XCTAssertEqual(CommunityVelocityBand(stored: option.value)?.label, option.label)
        }
        XCTAssertEqual(CommunityPlayerLevel.youth.label, "Developing competition")
    }

    func testFormLimitsMatchTheSite() throws {
        let limits = try XCTUnwrap(store.fieldNotesGuide.limits)
        XCTAssertEqual(limits.displayName.min, 2)
        XCTAssertEqual(limits.displayName.max.map(Int.init), CommunityFieldNoteLimits.displayName)
        XCTAssertEqual(limits.tweakDescription.max.map(Int.init), CommunityFieldNoteLimits.tweak)
        XCTAssertEqual(limits.cueNote.max.map(Int.init), CommunityFieldNoteLimits.note)
        XCTAssertEqual(limits.evidenceLabel.max.map(Int.init), CommunityFieldNoteLimits.evidenceLabel)
        XCTAssertEqual(limits.evidenceUrl.max.map(Int.init), CommunityFieldNoteLimits.evidenceURL)
    }

    func testOptionsFollowTheSitesOrderAndRetireTheMedicalCategories() {
        XCTAssertEqual(CommunityClaimedResultKind.allCases,
                       [.moreMovement, .betterCommand, .velocityGain, .workedInBullpen, .workedInGame, .inconsistent, .noNoticeableChange])
        XCTAssertEqual(CommunityClaimedResultKind.velocityGain.label, "Firmer feel")
        XCTAssertEqual(CommunityPitchIntent(rawValue: "reduce-stress")?.label, "Legacy category (closed)")
        XCTAssertEqual(CommunityClaimedResultKind(rawValue: "reduced-discomfort")?.label, "Legacy category (closed)")
    }

    // MARK: Source tiers and the context they require

    func testWritableSourceTiersAreTheSitesFour() {
        XCTAssertEqual(CommunityWritableTier.allCases.map(\.tier),
                       [.communityFirsthand, .coachObserved, .secondhandAttributed, .unverified])
        XCTAssertEqual(CommunityWritableTier.allCases.map(\.label),
                       ["My own report", "A coach I work with reported it", "Relayed from someone else", "A hunch - untested"])
        XCTAssertEqual(CommunityWritableTier.allCases.map(\.requiresNote), [false, false, true, true])
    }

    func testAWeakTierWithoutContextIsRefused() throws {
        var draft = FieldNoteDraft()
        draft.displayName = "RHP_threequarter"
        draft.tweak = "Thumb tucked deeper under the leather."
        draft.sourceTier = .hunch
        XCTAssertTrue(draft.showsContext)
        XCTAssertFalse(draft.isValid)
        XCTAssertThrowsError(try draft.newFieldNote(pitchSlug: "four-seam")) { error in
            XCTAssertEqual(error as? CommunityValidationError, .missingContext)
        }
        draft.note = "Saw it in a bullpen clip."
        XCTAssertTrue(draft.isValid)
        let note = try draft.newFieldNote(pitchSlug: "four-seam")
        XCTAssertEqual(note.sourceTier, .unverified)
        XCTAssertEqual(note.note, "Saw it in a bullpen clip.")
    }

    func testTheEmptyFormStartsWhereTheSitesDoes() {
        let draft = FieldNoteDraft()
        XCTAssertEqual(draft.playerLevel, .highSchool)
        XCTAssertEqual(draft.armSlot, .threeQuarter)
        XCTAssertNil(draft.velocityBand)
        XCTAssertEqual(draft.intent, .moreMovement)
        XCTAssertEqual(draft.claimedResultKind, .workedInBullpen)
        XCTAssertEqual(draft.sourceTier, .ownReport)
        XCTAssertFalse(draft.showsContext)
        XCTAssertFalse(draft.isValid, "a handle and a tweak are required")
    }

    func testFilingClearsTheFormButKeepsTheHandle() {
        var draft = FieldNoteDraft()
        draft.displayName = "RHP_threequarter"
        draft.tweak = "Ring finger off the seam."
        draft.velocityBand = .prepArm
        draft.clearAfterFiling()
        XCTAssertEqual(draft, FieldNoteDraft(displayName: "RHP_threequarter"))
    }

    // MARK: Pace context between the form and the database

    func testPaceMapsBetweenTheFormAndTheDatabase() {
        XCTAssertEqual(CommunityVelocityBand.allCases.map(\.rawValue), ["under-60", "60-69", "70-79", "80-89", "90-plus"])
        XCTAssertEqual(CommunityVelocityBand(stored: "90-plus"), .powerArm)
        XCTAssertEqual(CommunityVelocityBand(stored: "power-arm"), .powerArm)
        XCTAssertNil(CommunityVelocityBand(stored: "warp-speed"))
        XCTAssertEqual(CommunityVelocityBand.lowEffort.label, "Low-effort context")
    }

    func testANoteSendsItsPaceAsTheDatabaseBand() throws {
        var draft = FieldNoteDraft(displayName: "RHP_threequarter")
        draft.tweak = "Ring finger off the seam."
        draft.velocityBand = .collegeArm
        let data = try JSONEncoder().encode(try draft.newFieldNote(pitchSlug: "four-seam"))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["velocity_band"] as? String, "80-89")
        XCTAssertNil(object["claimed_result_note"], "the site's form never sends a result note")
    }

    func testANoteReadsItsPaceLeniently() throws {
        func decode(_ band: String) throws -> CommunityFieldNote {
            let json = """
            {"id":"n1","pitch_slug":"four-seam","author_id":"a1","display_name":"RHP","tweak":"Thumb under.","player_level":"high-school","arm_slot":"three-quarter","velocity_band":\(band),"intent":"more-movement","claimed_result_kind":"worked-in-bullpen","source_tier":"community-firsthand","created_at":"2026-10-27T12:00:00Z"}
            """
            return try JSONDecoder().decode(CommunityFieldNote.self, from: Data(json.utf8))
        }
        XCTAssertEqual(try decode("\"70-79\"").velocityBand, .prepArm)
        XCTAssertEqual(try decode("\"prep-arm\"").velocityBand, .prepArm)
        XCTAssertNil(try decode("\"warp\"").velocityBand, "an unknown band reads as none, never a failed note")
        XCTAssertNil(try decode("null").velocityBand)
    }

    // MARK: The age line and the bullpen card

    func testTheAgeLineMatchesTheSite() {
        XCTAssertEqual(FieldNoteAge.label(seconds: -30), "just now")
        XCTAssertEqual(FieldNoteAge.label(seconds: 59), "just now")
        XCTAssertEqual(FieldNoteAge.label(seconds: 60), "1 min ago")
        XCTAssertEqual(FieldNoteAge.label(seconds: 3_599), "59 min ago")
        XCTAssertEqual(FieldNoteAge.label(seconds: 3_600), "1 hr ago")
        XCTAssertEqual(FieldNoteAge.label(seconds: 86_399), "23 hr ago")
        XCTAssertEqual(FieldNoteAge.label(seconds: 86_400), "1 d ago")
        XCTAssertEqual(FieldNoteAge.label(seconds: 29 * 86_400), "29 d ago")
        XCTAssertEqual(FieldNoteAge.label(seconds: 30 * 86_400), "1 mo ago")
        XCTAssertEqual(FieldNoteAge.label(seconds: 359 * 86_400), "11 mo ago")
        XCTAssertEqual(FieldNoteAge.label(seconds: 360 * 86_400), "1 yr ago")
        let now = ISO8601DateFormatter().date(from: "2026-10-28T12:00:00Z")!
        XCTAssertEqual(FieldNoteAge.label(createdAt: "2026-10-28T09:00:00Z", now: now), "3 hr ago")
        XCTAssertEqual(FieldNoteAge.label(createdAt: "2026-10-28T11:59:30.123456+00:00", now: now), "just now")
        XCTAssertNil(FieldNoteAge.label(createdAt: "not a date", now: now))
    }

    func testTheBullpenCardNeverInventsPoints() {
        let identity = ContributorIdentity(displayName: "RHP_threequarter", isClaimed: false, contributionScore: 12, notesCount: 2)
        XCTAssertEqual(BullpenCard.points(.signedOut), "0 pts")
        XCTAssertNil(BullpenCard.points(.loading), "a signed-in reader's score is unknown until it loads")
        XCTAssertNil(BullpenCard.points(.failed), "a failed read shows no score, never a zero")
        XCTAssertEqual(BullpenCard.points(.loaded(identity)), "12 pts")

        XCTAssertEqual(BullpenCard.filingLine(.signedOut, accountClaimed: false), "Filing as an unclaimed contributor · anonymous.")
        XCTAssertEqual(BullpenCard.filingLine(.loaded(identity), accountClaimed: false), "Filing as RHP_threequarter · anonymous.")
        let claimed = ContributorIdentity(displayName: nil, isClaimed: true, contributionScore: 0, notesCount: 0)
        XCTAssertEqual(BullpenCard.filingLine(.loaded(claimed), accountClaimed: false), "Filing as an unclaimed contributor · claimed ✓.")

        XCTAssertEqual(BullpenCard.claimPrompt(.signedOut),
                       "You can take part with no account. Add an email to keep your points and notes if you switch devices, never required.")
        XCTAssertEqual(BullpenCard.claimPrompt(.loaded(identity)),
                       "You can take part with no account. Add an email to keep your 12 points and notes if you switch devices, never required.")
    }

    func testIdentityReadsTheProfileRow() throws {
        let json = #"[{"display_name":null,"is_claimed":true,"contribution_score":7,"notes_count":1}]"#
        let rows = try JSONDecoder().decode([ContributorIdentity].self, from: Data(json.utf8))
        XCTAssertEqual(rows.first, ContributorIdentity(displayName: nil, isClaimed: true, contributionScore: 7, notesCount: 1))
        let sparse = try JSONDecoder().decode(ContributorIdentity.self, from: Data(#"{"display_name":"RHP"}"#.utf8))
        XCTAssertEqual(sparse.contributionScore, 0)
        XCTAssertNil(sparse.isClaimed)
    }
}
