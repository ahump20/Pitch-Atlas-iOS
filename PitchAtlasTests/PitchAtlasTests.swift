import XCTest
import UIKit
@testable import PitchAtlas

final class PitchAtlasTests: XCTestCase {

    /// The shell must expose exactly the five v1 tabs.
    func testFiveTabs() {
        XCTAssertEqual(AppTab.allCases.count, 5)
        XCTAssertEqual(AppTab.allCases.map(\.rawValue),
                       ["atlas", "index", "grips", "craftsmen", "sources"])
    }

    /// Provenance mapping must always resolve. An unknown tier falls back to the
    /// honest gray (unverified), never crashes and never silently upgrades.
    func testConfidenceColorFallback() {
        let known = PitchAtlasTheme.color(forConfidence: "official-data")
        let unknown = PitchAtlasTheme.color(forConfidence: "nonsense-tier")
        XCTAssertEqual(unknown, PitchAtlasTheme.ink3)
        XCTAssertNotEqual(known, PitchAtlasTheme.ink3)
    }

    /// Every bundled JSON decodes with zero failures across every record.
    /// If any file or any record fails, the store records it and this fails.
    func testBundleDecodesCleanly() {
        let store = PitchStore()
        if case .failed(let message) = store.status {
            XCTFail("Content failed to decode: \(message)")
        }
        XCTAssertFalse(store.pitches.isEmpty, "no pitches decoded")
        XCTAssertFalse(store.repertoire.entries.isEmpty, "no repertoire entries decoded")
        XCTAssertFalse(store.craftsmen.isEmpty, "no craftsmen decoded")
        XCTAssertFalse(store.lostPitches.entries.isEmpty, "no lost pitches decoded")
        XCTAssertFalse(store.knowledge.isEmpty, "no knowledge wings decoded")
        XCTAssertFalse(store.grips.entries.isEmpty, "no grips decoded")
        XCTAssertFalse(store.sources.isEmpty, "no sources decoded")
    }

    /// Drift guard: decoded record counts must match the build manifest. If the
    /// generator emits more records than the models can decode (a new field/shape),
    /// the array decode throws and counts diverge. This catches that in CI.
    func testDecodedCountsMatchManifest() {
        let store = PitchStore()
        XCTAssertEqual(store.pitches.count, store.manifest.counts["pitches.json"])
        XCTAssertEqual(store.repertoire.entries.count, store.manifest.counts["repertoire.json"])
        XCTAssertEqual(store.craftsmen.count, store.manifest.counts["craftsmen.json"])
        XCTAssertEqual(store.lostPitches.entries.count, store.manifest.counts["lost-pitches.json"])
        XCTAssertEqual(store.knowledge.count, store.manifest.counts["knowledge.json"])
        XCTAssertEqual(store.grips.entries.count, store.manifest.counts["grips.json"])
        XCTAssertEqual(store.sources.count, store.manifest.counts["sources.json"])
    }

    /// The owner's grip films: every film referenced by the content must resolve
    /// to a real bundled clip and poster, carry first-party/original rights, and
    /// cover exactly the four grips that were filmed — no fabricated films, no
    /// dead references.
    func testGripFilmsAreBundledAndRightsClean() throws {
        let store = PitchStore()

        let specimenFilms = store.pitches.compactMap { $0.canonical.gripFilm }
        let libraryFilms = store.grips.entries.compactMap(\.film)
        XCTAssertEqual(specimenFilms.count, 3, "four-seam, two-seam, twelve-six carry films")
        XCTAssertEqual(libraryFilms.count, 4, "the grip library carries all four films")

        for film in specimenFilms + libraryFilms {
            XCTAssertNotNil(GripFilmCard.bundledURL(for: film.clip.src),
                            "clip missing from bundle: \(film.clip.src)")
            XCTAssertNotNil(GripFilmCard.bundledURL(for: film.poster),
                            "poster missing from bundle: \(film.poster)")
            XCTAssertEqual(film.clip.kind, .firstParty)
            XCTAssertEqual(film.clip.rights, .original)
            XCTAssertNotNil(film.clip.attribution)
            XCTAssertFalse(film.clip.caption.isEmpty)
            XCTAssertFalse(film.clip.alt.isEmpty)
        }
    }

    /// The web's craft-over-numbers rename (`numbers` → `record`) must carry
    /// through decode. A key rename that Codable silently absorbs as nil would
    /// strip every craftsman and lost-pitch record section without failing a
    /// decode — this pins the records as present, not just decodable.
    func testRecordSectionsSurviveKeyRenames() {
        let store = PitchStore()
        // The gyroball legend is record-less by design (its content is the
        // myth-vs-physics note); every true craftsman carries a record.
        for craftsman in store.craftsmen where craftsman.kind == .craftsman {
            XCTAssertFalse(craftsman.recordProse.isEmpty && craftsman.recordNumbers.isEmpty,
                           "craftsman \(craftsman.slug) decoded with no record")
        }
        for pitch in store.lostPitches.entries {
            XCTAssertFalse(pitch.recordEntries.isEmpty,
                           "lost pitch \(pitch.slug) decoded with no record entries")
        }
    }

    /// The owner's grip photography: every photo referenced by the content must
    /// resolve to a real bundled image and carry first-party/original rights.
    /// Counts pin the 17 labeled stills (12 on specimens, 17 in the library) so
    /// a dropped bundle file or dead reference fails loudly.
    func testGripPhotographyIsBundledAndRightsClean() {
        let store = PitchStore()

        let specimenPhotos = store.pitches.flatMap { $0.canonical.gripImages ?? [] }
        let libraryPhotos = store.grips.entries.flatMap(\.photos)
        XCTAssertEqual(specimenPhotos.count, 12, "four-seam, two-seam, twelve-six, splitter carry 3 photos each")
        XCTAssertEqual(libraryPhotos.count, 17, "the grip library carries all 17 labeled stills")

        for photo in specimenPhotos + libraryPhotos {
            XCTAssertNotNil(BundledImage.load(photo.src),
                            "photo missing from bundle: \(photo.src)")
            XCTAssertEqual(photo.kind, .firstParty)
            XCTAssertEqual(photo.rights, .original)
            XCTAssertFalse(photo.alt.isEmpty)
        }

        // The real-still ladder: a film's poster fronts it, else the first
        // photo, and every still it returns resolves in the bundle.
        let stills = store.pitches.compactMap { $0.canonical.realStill }
        XCTAssertEqual(stills.count, 4, "four specimens carry a real still face")
        for still in stills {
            XCTAssertNotNil(BundledImage.load(still.src),
                            "real still missing from bundle: \(still.src)")
        }
    }

    func testSupabaseConfigUsesPitchAtlasProject() {
        XCTAssertEqual(SupabaseConfig.projectURL.absoluteString, "https://cloeoulvrrfcbitrjpso.supabase.co")
        XCTAssertEqual(SupabaseConfig.authRedirectURL.absoluteString, "pitchatlas://auth-callback")
        XCTAssertTrue(SupabaseConfig.publishableKey.hasPrefix("sb_publishable_"))
        XCTAssertFalse(SupabaseConfig.publishableKey.lowercased().contains("service_role"))
    }

    func testAppInfoPlistUsesReleaseBuildSettings() {
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String, "1.0.1")
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String, "6")
    }

    func testCommunityImagePreparationRejectsNonImages() {
        XCTAssertThrowsError(try CommunityService.prepareImage(data: Data("not an image".utf8))) { error in
            XCTAssertEqual(error as? CommunityServiceError, .unsupportedMedia)
        }
    }

    func testCommunityImagePreparationProducesStillJpeg() throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 12))
        let source = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 24, height: 12))
        }
        let png = try XCTUnwrap(source.pngData())

        let prepared = try CommunityService.prepareImage(data: png)

        XCTAssertEqual(prepared.mimeType, "image/jpeg")
        XCTAssertEqual(prepared.fileExtension, "jpg")
        XCTAssertGreaterThan(prepared.width, 0)
        XCTAssertGreaterThan(prepared.height, 0)
        XCTAssertLessThanOrEqual(max(prepared.width, prepared.height), 2048)
        XCTAssertEqual(Double(prepared.width) / Double(prepared.height), 2.0, accuracy: 0.01)
        XCTAssertLessThan(prepared.data.count, 8 * 1024 * 1024)
    }

    func testNewFieldNoteEncodesLiveSupabaseValues() throws {
        let note = NewFieldNote(
            pitchSlug: "four-seam",
            displayName: "Austin",
            tweak: "Index finger rides the inside seam.",
            playerLevel: .collegePlus,
            armSlot: .threeQuarter,
            intent: .addedVelocity,
            claimedResultKind: .velocityGain,
            claimedResultNote: "Firmer feel in catch play.",
            sampleSize: 12,
            evidenceURL: "https://example.com/session",
            evidenceLabel: "Bullpen notes",
            sourceTier: .communityFirsthand,
            note: "Firsthand field note."
        )

        let data = try JSONEncoder().encode(note)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertEqual(object["player_level"] as? String, "college-plus")
        XCTAssertEqual(object["arm_slot"] as? String, "three-quarter")
        XCTAssertEqual(object["intent"] as? String, "added-velocity")
        XCTAssertEqual(object["claimed_result_kind"] as? String, "velocity-gain")
        XCTAssertEqual(object["sample_size"] as? Int, 12)
        XCTAssertEqual(object["evidence_label"] as? String, "Bullpen notes")
        XCTAssertFalse(json.contains("adult"))
        XCTAssertFalse(json.contains("not specified"))
        XCTAssertFalse(json.contains("firsthand note"))
        XCTAssertFalse(json.contains("self-reported"))
    }

    func testFieldNoteValidationMatchesLiveSupabaseConstraints() throws {
        let note = try NewFieldNote.validated(
            pitchSlug: "four-seam",
            displayName: "  Austin  ",
            tweak: "  Index finger rides the inside seam.  ",
            playerLevel: .collegePlus,
            armSlot: .threeQuarter,
            intent: .addedVelocity,
            claimedResultKind: .velocityGain,
            claimedResultNote: "  Firmer feel.  ",
            sampleSizeText: "12",
            evidenceURL: " https://example.com/session ",
            evidenceLabel: " Bullpen notes ",
            sourceTier: .communityFirsthand,
            note: " Firsthand field note. "
        )

        XCTAssertEqual(note.displayName, "Austin")
        XCTAssertEqual(note.tweak, "Index finger rides the inside seam.")
        XCTAssertEqual(note.claimedResultNote, "Firmer feel.")
        XCTAssertEqual(note.sampleSize, 12)
        XCTAssertEqual(note.evidenceURL, "https://example.com/session")
        XCTAssertEqual(note.evidenceLabel, "Bullpen notes")
        XCTAssertEqual(note.note, "Firsthand field note.")

        XCTAssertThrowsError(try NewFieldNote.parsedSampleSize("100001")) { error in
            XCTAssertEqual(error as? CommunityValidationError, .invalidSampleSize)
        }
        XCTAssertThrowsError(try NewFieldNote.validatedEvidenceURL("ftp://example.com/session")) { error in
            XCTAssertEqual(error as? CommunityValidationError, .invalidEvidenceURL)
        }
        XCTAssertThrowsError(try NewFieldNote.validated(
            pitchSlug: "four-seam",
            displayName: "Austin",
            tweak: String(repeating: "x", count: 161),
            playerLevel: .collegePlus,
            armSlot: .threeQuarter,
            intent: .addedVelocity,
            claimedResultKind: .velocityGain,
            claimedResultNote: "",
            sampleSizeText: "",
            evidenceURL: "",
            evidenceLabel: "",
            sourceTier: .communityFirsthand,
            note: ""
        )) { error in
            XCTAssertEqual(error as? CommunityValidationError, .valueTooLong(field: "Grip change or cue", max: 160))
        }
    }

    func testDiscussionPostValidationTrimsAndRejectsBadBodies() throws {
        let post = try NewDiscussionPost.validated(
            id: "post-1",
            topicKey: "pitch:four-seam",
            displayName: "Austin",
            body: "  This grip finally held through catch play.  ",
            parentID: nil
        )

        XCTAssertEqual(post.body, "This grip finally held through catch play.")

        XCTAssertThrowsError(try NewDiscussionPost.validated(
            id: "post-2",
            topicKey: "pitch:four-seam",
            displayName: "Austin",
            body: "   ",
            parentID: nil
        )) { error in
            XCTAssertEqual(error as? CommunityServiceError, .invalidDiscussionPost("Add a post before submitting."))
        }
        XCTAssertThrowsError(try NewDiscussionPost.validated(
            id: "post-3",
            topicKey: "pitch:four-seam",
            displayName: "Austin",
            body: String(repeating: "x", count: 4001),
            parentID: nil
        )) { error in
            XCTAssertEqual(error as? CommunityServiceError, .invalidDiscussionPost("Discussion posts must be 4000 characters or fewer."))
        }
    }

    func testCommunityErrorMapperHidesRawDatabaseErrors() {
        let duplicateBlock = NSError(
            domain: "PostgREST",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "duplicate key value violates unique constraint \"blocked_users_pkey\""]
        )
        XCTAssertEqual(CommunityService.userMessage(for: duplicateBlock), "That contributor is already blocked.")

        let constraint = NSError(
            domain: "PostgREST",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "new row violates check constraint \"field_notes_player_level_check\""]
        )
        XCTAssertEqual(
            CommunityService.userMessage(for: constraint),
            "One field does not match the allowed choices. Review the form and try again."
        )

        let rateLimit = NSError(
            domain: "PostgREST",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "rate_limit: too many posts in a short time"]
        )
        XCTAssertEqual(
            CommunityService.userMessage(for: rateLimit),
            "Too many community actions in a short time. Wait a bit and try again."
        )
    }

    func testPrivacyManifestDeclaresCommunityDataWithoutTracking() throws {
        let manifestURL = try XCTUnwrap(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let manifest = try XCTUnwrap(NSDictionary(contentsOf: manifestURL) as? [String: Any])

        XCTAssertEqual(manifest["NSPrivacyTracking"] as? Bool, false)

        let collectedTypes = try XCTUnwrap(manifest["NSPrivacyCollectedDataTypes"] as? [[String: Any]])
            .compactMap { $0["NSPrivacyCollectedDataType"] as? String }

        XCTAssertTrue(collectedTypes.contains("NSPrivacyCollectedDataTypeEmailAddress"))
        XCTAssertTrue(collectedTypes.contains("NSPrivacyCollectedDataTypeUserID"))
        XCTAssertTrue(collectedTypes.contains("NSPrivacyCollectedDataTypeOtherUserContent"))
        XCTAssertTrue(collectedTypes.contains("NSPrivacyCollectedDataTypePhotosorVideos"))
    }

    /// Provenance integrity: a confident claim carries a source; a weak claim
    /// (unverified / secondhand) carries an explanatory note. This is the data
    /// contract the whole "Sourced, not corrected" promise rests on.
    func testProvenanceContractHolds() {
        let store = PitchStore()
        var checked = 0
        for entry in store.pitches {
            for claim in claims(in: entry) {
                checked += 1
                switch claim.confidence {
                case .unverified, .secondhandAttributed:
                    XCTAssertNotNil(claim.note,
                                    "weak claim must carry a note: \(claim.value.prefix(40))")
                default:
                    XCTAssertNotNil(claim.source,
                                    "confident claim must carry a source: \(claim.value.prefix(40))")
                }
            }
        }
        XCTAssertGreaterThan(checked, 0, "expected claims to verify")
    }

    /// Gather the headline claims on a pitch for the provenance check.
    private func claims(in entry: PitchAtlasEntry) -> [Claim] {
        var out: [Claim] = [entry.canonical.grip, entry.canonical.mechanics,
                            entry.physics.teaching, entry.physics.spinAxis]
        out.append(contentsOf: entry.canonical.gripDetails)
        if let shape = entry.physics.shape { out.append(shape) }
        if let spinRate = entry.physics.spinRateRpm { out.append(spinRate) }
        if let primaryBreak = entry.physics.primaryBreak { out.append(primaryBreak.claim) }
        if let secondaryBreak = entry.physics.secondaryBreak { out.append(secondaryBreak.claim) }
        if let activeSpin = entry.physics.activeSpinPct { out.append(activeSpin) }
        if let voice = entry.canonical.voice { out.append(voice) }
        for variant in entry.masterVariants {
            if let distinction = variant.distinction { out.append(distinction) }
            out.append(contentsOf: variant.recordNumbers.map(\.claim))
            if let quote = variant.quote { out.append(quote) }
        }
        return out
    }
}

private extension PitchAtlasEntry {
    var physics: PhysicsReference { canonical.physics }
}
