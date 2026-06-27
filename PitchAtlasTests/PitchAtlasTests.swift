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
        XCTAssertFalse(store.archiveImages.isEmpty, "no archive images decoded")
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
        XCTAssertEqual(store.archiveImages.count, store.manifest.counts["archive-images.json"])
    }

    /// Every lost pitch carries exactly one rights-labeled plate, the plate points
    /// back at a real lost pitch, every public-domain photo names a source, and
    /// every first-party study carries none. Mirrors the web archive-plate test so
    /// the two surfaces hold the same provenance contract.
    func testEveryLostPitchHasARightsLabeledPlate() {
        let store = PitchStore()
        XCTAssertEqual(store.archiveImages.count, store.lostPitches.entries.count)
        for pitch in store.lostPitches.entries {
            guard let image = store.archiveImage(forLostPitch: pitch.slug) else {
                XCTFail("\(pitch.slug) has no archive plate")
                continue
            }
            XCTAssertEqual(image.relatedSlug, pitch.slug)
            XCTAssertTrue(image.imageSrc.hasPrefix("/archive/lost-pitches/"),
                          "\(image.id) imageSrc escaped the archive folder: \(image.imageSrc)")
            XCTAssertGreaterThan(image.alt.count, 20, "\(image.id) alt text is too thin")
            switch image.rights {
            case .publicDomain:
                XCTAssertNotNil(image.source, "\(image.id) is public-domain but names no source")
            case .original:
                XCTAssertNil(image.source, "\(image.id) is an original study but carries a source")
            default:
                XCTFail("\(image.id) shipped with unexpected rights \(image.rights.rawValue)")
            }
        }
    }

    func testIndexSortOrdersRowsWithinAFamilyByName() {
        let store = PitchStore()
        let fastballs = store.repertoire.entries.filter { $0.family == .fastball }
        let sorted = IndexSort.az.ordered(fastballs, store: store)

        XCTAssertEqual(sorted.map(\.name), fastballs.map(\.name).sorted())
        XCTAssertEqual(Set(sorted.map(\.family)), [.fastball])
    }

    func testIndexSortPutsFiledSpecimensBeforeBasicFiles() {
        let store = PitchStore()
        let offspeed = store.repertoire.entries.filter { $0.family == .offspeed }
        let sorted = IndexSort.filed.ordered(offspeed, store: store)
        let firstBasic = sorted.firstIndex { $0.filedSlug == nil } ?? sorted.endIndex

        XCTAssertTrue(sorted[..<firstBasic].allSatisfy { $0.filedSlug != nil })
        XCTAssertTrue(sorted[firstBasic...].allSatisfy { $0.filedSlug == nil })
    }

    func testIndexSortRanksDocumentationDepthWithoutInventedGrades() {
        let store = PitchStore()
        let offspeed = store.repertoire.entries.filter { $0.family == .offspeed }
        let sorted = IndexSort.documentation.ordered(offspeed, store: store)
        let ranks = sorted.map { IndexSort.documentation.documentationRank($0, store: store) }

        XCTAssertEqual(ranks, ranks.sorted())
    }

    /// The specimen grade travels web → bundle → app on every filed pitch, and the
    /// gold 1/1 stays the singular chase: only the specimen-00 record may be gold,
    /// and that record must be gold. Guards the cross-platform parity contract.
    func testSpecimenGradeTravelsAndOnlyTheChaseIsGold() {
        let store = PitchStore()
        XCTAssertFalse(store.pitches.isEmpty, "no pitches decoded")
        for pitch in store.pitches {
            XCTAssertFalse(pitch.specimenGrade.label.isEmpty, "\(pitch.slug) has no grade label")
            if pitch.display.specimenNo == "00" {
                XCTAssertEqual(pitch.specimenGrade.key, .gold, "the specimen-00 chase must be gold")
            } else {
                XCTAssertNotEqual(pitch.specimenGrade.key, .gold, "\(pitch.slug) is gold but is not specimen 00")
            }
        }
    }

    /// The same-family rail reads off the filed family: every sibling shares the
    /// subject's family, the subject never lists itself, and the relationship is
    /// symmetric (if A lists B, B lists A). No baked relatedSlugs, no fabricated link.
    func testSameFamilyRailListsOtherFiledPitchesInTheFamily() {
        let store = PitchStore()
        XCTAssertFalse(store.pitches.isEmpty, "no pitches decoded")

        // At least one family must have more than one filed member for the rail to exist.
        guard let subject = store.pitches.first(where: { !store.siblings(of: $0).isEmpty }) else {
            return XCTFail("expected at least one family with multiple filed pitches")
        }

        let kin = store.siblings(of: subject)
        for s in kin {
            XCTAssertEqual(s.canonical.family, subject.canonical.family, "\(s.slug) is not in \(subject.slug)'s family")
            XCTAssertNotEqual(s.slug, subject.slug, "a pitch must not be its own sibling")
            // symmetric: the sibling's rail includes the subject
            XCTAssertTrue(store.siblings(of: s).contains { $0.slug == subject.slug },
                          "\(subject.slug) missing from \(s.slug)'s family rail")
        }
    }

    /// The status facet (native mate to the web one): the repertoire must span more
    /// than one status tier for the facet to earn its place, and filtering by any
    /// present tier must narrow to a real, smaller, homogeneous subset.
    func testRepertoireStatusFacetNarrowsToAPresentTier() {
        let store = PitchStore()
        let entries = store.repertoire.entries
        XCTAssertFalse(entries.isEmpty, "no repertoire entries decoded")

        let present = Set(entries.map(\.status))
        XCTAssertGreaterThan(present.count, 1, "status facet needs multiple tiers to be useful")

        for tier in present {
            let narrowed = entries.filter { $0.status == tier }
            XCTAssertFalse(narrowed.isEmpty, "\(tier) is present but filtered to nothing")
            XCTAssertLessThan(narrowed.count, entries.count, "a single status must narrow the list")
            XCTAssertTrue(narrowed.allSatisfy { $0.status == tier }, "\(tier) filter leaked another tier")
        }
    }

    /// Feature #11 — study hooks decode and bridge to real filed specimens. Every
    /// study-first slug must resolve to a bundled filed pitch (never a typo), the
    /// banned doctored pitches stay hook-free (no legal pitch to study first), and
    /// every context note is a real sourced claim. The native mate of the web guard.
    func testStudyHooksBridgeToFiledSpecimens() {
        let store = PitchStore()
        let entries = store.repertoire.entries
        XCTAssertFalse(entries.isEmpty, "no repertoire entries decoded")

        let filed = Set(store.pitches.map(\.slug))
        var hooked = 0
        for e in entries {
            if let slug = e.studyFirstSlug {
                XCTAssertTrue(filed.contains(slug), "\(e.id) -> \(slug) is not a filed specimen")
                XCTAssertNotNil(store.pitch(slug: slug), "\(e.id) -> \(slug) did not resolve")
                hooked += 1
            }
            // banned doctored pitches carry no legal "study this" cousin
            if e.family == .banned {
                XCTAssertNil(e.studyFirstSlug, "\(e.id) is banned but carries a study hook")
                XCTAssertNil(e.contextNote, "\(e.id) is banned but carries a context note")
            }
            // a context note, when present, is a real sourced claim with a tier
            if let note = e.contextNote {
                XCTAssertFalse(note.value.isEmpty, "\(e.id) context note is empty")
                let weak = note.confidence == .unverified || note.confidence == .secondhandAttributed
                if !weak { XCTAssertNotNil(note.source, "\(e.id) confident note needs a source") }
            }
        }
        // the feature actually shipped hooks, not an empty contract
        XCTAssertGreaterThan(hooked, 10, "expected many basic files to carry a study hook")
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
    /// Counts pin the labeled stills (9 on specimens, 17 in the library) so
    /// a dropped bundle file or dead reference fails loudly.
    func testGripPhotographyIsBundledAndRightsClean() {
        let store = PitchStore()

        let specimenPhotos = store.pitches.flatMap { $0.canonical.gripImages ?? [] }
        let libraryPhotos = store.grips.entries.flatMap(\.photos)
        XCTAssertEqual(specimenPhotos.count, 9, "four-seam, two-seam, twelve-six carry 3 photos each; the league-taxonomy splitter specimen carries none (the owner's split-finger lives in the library)")
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
        XCTAssertEqual(stills.count, 3, "four-seam, two-seam, twelve-six carry a real still face")
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
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String, "10")
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

    func testFieldNoteMenusAvoidMedicalReviewLanguageButDecodeLiveValues() throws {
        XCTAssertFalse(CommunityPitchIntent.allCases.contains(.reduceStress))
        XCTAssertFalse(CommunityClaimedResultKind.allCases.contains(.reducedDiscomfort))

        XCTAssertEqual(CommunityPitchIntent(rawValue: "reduce-stress")?.label, "Easier feel")
        XCTAssertEqual(CommunityClaimedResultKind(rawValue: "reduced-discomfort")?.label, "Easier feel")
    }

    func testDiscussionMediaDecodesPublicReadGrantShape() throws {
        let json = Data(
            """
            {
              "id": "media-1",
              "post_id": "post-1",
              "storage_path": "user-1/media-1.jpg",
              "kind": "image",
              "width": 1200,
              "height": 900
            }
            """.utf8
        )

        let media = try JSONDecoder().decode(DiscussionMedia.self, from: json)

        XCTAssertEqual(media.id, "media-1")
        XCTAssertEqual(media.postID, "post-1")
        XCTAssertEqual(media.storagePath, "user-1/media-1.jpg")
        XCTAssertEqual(media.kind, "image")
        XCTAssertEqual(media.width, 1200)
        XCTAssertEqual(media.height, 900)
        XCTAssertNil(media.signedURL)
        XCTAssertNil(media.signingError)
    }

    func testBlockedContributorVisibilityFiltersCommunityRowsLocally() {
        let hidden = CommunityVisibility.hiddenAuthorIDs(from: [
            BlockedContributor(blockedID: "author-blocked", displayName: "Blocked", createdAt: "2026-06-25T12:00:00Z")
        ])

        let notes = [
            communityFieldNote(id: "note-1", authorID: "author-visible"),
            communityFieldNote(id: "note-2", authorID: "author-blocked"),
        ]
        let posts = [
            DiscussionPost(
                id: "post-1",
                topicKey: "pitch:four-seam",
                authorID: "author-visible",
                displayName: "Visible",
                parentID: nil,
                body: "Visible post.",
                createdAt: "2026-06-25T12:00:00Z"
            ),
            DiscussionPost(
                id: "post-2",
                topicKey: "pitch:four-seam",
                authorID: "author-blocked",
                displayName: "Blocked",
                parentID: nil,
                body: "Hidden post.",
                createdAt: "2026-06-25T12:00:00Z"
            ),
        ]

        XCTAssertEqual(CommunityVisibility.visibleFieldNotes(notes, hiddenAuthorIDs: hidden).map(\.id), ["note-1"])
        XCTAssertEqual(CommunityVisibility.visibleDiscussionPosts(posts, hiddenAuthorIDs: hidden).map(\.id), ["post-1"])
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

        let permanentAccount = NSError(
            domain: "PostgREST",
            code: 42501,
            userInfo: [NSLocalizedDescriptionKey: "Permanent account required"]
        )
        XCTAssertEqual(
            CommunityService.userMessage(for: permanentAccount),
            "Use a permanent signed-in account before uploading images."
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

private func communityFieldNote(id: String, authorID: String) -> CommunityFieldNote {
    CommunityFieldNote(
        id: id,
        pitchSlug: "four-seam",
        authorID: authorID,
        displayName: authorID,
        tweak: "Index finger rides the inside seam.",
        playerLevel: .collegePlus,
        armSlot: .threeQuarter,
        intent: .addedVelocity,
        claimedResultKind: .velocityGain,
        claimedResultNote: nil,
        sampleSize: nil,
        evidenceURL: nil,
        evidenceLabel: nil,
        note: nil,
        sourceTier: .communityFirsthand,
        createdAt: "2026-06-25T12:00:00Z"
    )
}

private extension PitchAtlasEntry {
    var physics: PhysicsReference { canonical.physics }
}
