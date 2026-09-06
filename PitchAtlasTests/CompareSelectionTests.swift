import XCTest
import simd
@testable import PitchAtlas

final class CompareSelectionTests: XCTestCase {
    func testGripSearchAndNavigationUseBundledRecordTextAndExplicitLinks() throws {
        let store = PitchStore()
        let four = try XCTUnwrap(store.gripEntry(id: "four-seam"))
        XCTAssertTrue(four.matchesStudySearch("  FOUR  seam \n"))
        XCTAssertTrue(four.matchesStudySearch("fastball"))
        XCTAssertTrue(four.matchesStudySearch("  \n"))
        XCTAssertFalse(four.matchesStudySearch("no-such-grip"))
        XCTAssertEqual(four.filedSpecimen(in: store)?.slug, "four-seam")
        let basic = try XCTUnwrap(store.gripEntry(id: "split-finger"))
        XCTAssertNil(basic.filedSpecimen(in: store), "A similar name must not invent a specimen link")
        XCTAssertNotNil(basic.repertoireId.flatMap { store.repertoireEntry(id: $0) })
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(four)) as? [String: Any])
        object["specimenSlug"] = "not-bundled"
        let missing = try JSONDecoder().decode(GripEntry.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(missing.filedSpecimen(in: store), "Missing references must not fall back to a guessed id")
    }

    func testSpecimenInspectionPreservesComparisonAndReturnsToWorkspace() throws {
        let store = PitchStore()
        let state = CompareSelection()
        let four = try XCTUnwrap(store.pitch(slug: "four-seam"))
        state.add(four.slug)
        state.inspect("slider", store: store)
        XCTAssertNil(state.inspection)
        state.add("slider")
        state.mode = .cues; state.hand = .left; state.orientation = .thumb
        state.selectVariant(0, for: four)
        state.inspect("slider", store: store)
        XCTAssertEqual(state.inspection?.slug, "slider")
        state.inspection = nil // Native Back dismisses only this destination.
        XCTAssertEqual(state.slugs, ["four-seam", "slider"])
        XCTAssertEqual(state.mode, .cues)
        XCTAssertEqual(state.hand, .left)
        XCTAssertEqual(state.orientation, .thumb)
        XCTAssertEqual(state.variantIndex(for: four), 0)
        state.inspect("four-seam", store: store)
        state.add("four-seam") // Compare inside inspection returns to the existing workspace.
        XCTAssertNil(state.inspection)
        XCTAssertEqual(state.slugs, ["four-seam", "slider"])
        XCTAssertEqual(state.mode, .cues)
    }

    func testVariantCuesKeepCanonicalClaimsAndNeverFillMissingVariantEvidence() throws {
        let store = PitchStore()
        let state = CompareSelection()
        let four = try XCTUnwrap(store.pitch(slug: "four-seam"))
        XCTAssertFalse(four.masterVariants.isEmpty)
        state.selectVariant(0, for: four)
        state.selectVariant(99_999, for: four)
        XCTAssertEqual(state.variantIndex(for: four), 0)
        for entry in store.pitches {
            for (index, variant) in entry.masterVariants.enumerated() {
                XCTAssertEqual(CueComparisonField.grip.claims(in: entry, variantIndex: index), [entry.canonical.grip])
                XCTAssertEqual(CueComparisonField.cue.claims(in: entry, variantIndex: index), [entry.canonical.mechanics])
                XCTAssertEqual(CueComparisonField.distinction.claims(in: entry, variantIndex: index), variant.distinction.map { [$0] } ?? [])
                XCTAssertEqual(CueComparisonField.voice.claims(in: entry, variantIndex: index), variant.quote.map { [$0] } ?? [])
            }
        }
        state.selectVariant(-1, for: four)
        XCTAssertEqual(state.variantIndex(for: four), -1)
        XCTAssertTrue(CueComparisonField.distinction.claims(in: four, variantIndex: -1).isEmpty)
    }

    func testSpecimenSourceLedgerIncludesCanonicalAndVariantSourcesWithoutDuplicates() throws {
        let store = PitchStore()
        let four = try XCTUnwrap(store.pitch(slug: "four-seam"))
        let ids = four.studySources.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
        XCTAssertTrue(ids.contains(try XCTUnwrap(four.canonical.grip.source).id))
        for variant in four.masterVariants {
            for source in [variant.distinction?.source, variant.quote?.source].compactMap({ $0 }) {
                XCTAssertTrue(ids.contains(source.id))
            }
        }
    }

    func testThirdPitchRequiresExplicitReplacementAndDuplicateKeepsPair() {
        let state = CompareSelection()
        state.add("four-seam"); state.add("slider"); state.add("four-seam")
        XCTAssertEqual(state.slugs, ["four-seam", "slider"])
        state.add("changeup")
        XCTAssertEqual(state.slugs, ["four-seam", "slider"])
        XCTAssertEqual(state.pending, "changeup")
        state.replace(1)
        XCTAssertEqual(state.slugs, ["four-seam", "changeup"])
        XCTAssertNil(state.pending)
        state.remove("four-seam")
        XCTAssertEqual(state.slugs, ["changeup"])
    }
    func testDeepLinksResolveBundleAndRejectInvalidValuesWithoutDestroyingPair() {
        let store = PitchStore()
        let state = CompareSelection()
        let pitches = Array(store.pitches.prefix(2))
        XCTAssertEqual(pitches.count, 2)
        guard pitches.count == 2 else { return }
        let base = "pitchatlas://compare?a=\(pitches[0].slug)&b=\(pitches[1].slug)"
        XCTAssertTrue(state.handle(URL(string: base + "&view=cues&hand=left&orientation=thumb")!, store: store))
        XCTAssertEqual(state.slugs, pitches.map(\.slug))
        XCTAssertEqual(state.mode, .cues)
        XCTAssertEqual(state.hand, .left)
        XCTAssertEqual(state.orientation, .thumb)
        for suffix in ["&view=bogus", "&hand=bogus", "&orientation=bogus", "&a=missing"] {
            state.handle(URL(string: base + suffix)!, store: store)
            XCTAssertNotNil(state.error)
            XCTAssertEqual(state.slugs, pitches.map(\.slug))
        }
        state.handle(URL(string: "pitchatlas://compare?a=missing&b=missing")!, store: store)
        XCTAssertNotNil(state.error)
        XCTAssertEqual(state.slugs, pitches.map(\.slug))
    }
    func testArchiveConnectionsResolveExplicitBundledRelationships() throws {
        let store = PitchStore()
        let fourSeam = try XCTUnwrap(store.pitch(slug: "four-seam"))
        XCTAssertTrue(store.practitioners(for: fourSeam).contains { $0.slug == "nolan-ryan" })
        XCTAssertFalse(store.practitioners(for: fourSeam).contains { $0.slug == "bob-gibson" })
        XCTAssertTrue(store.lessons(for: fourSeam).contains { $0.slug == "sequencing" })
        for pitch in store.pitches {
            XCTAssertTrue(store.practitioners(for: pitch).allSatisfy { $0.signaturePitchSlug == pitch.slug })
            XCTAssertTrue(store.lessons(for: pitch).allSatisfy { $0.related?.contains { $0.to == "/pitch/" + pitch.slug } == true })
        }
    }
    func testRelatedLinkSupportsOptionalNavigationContext() throws {
        let decoder = JSONDecoder()
        let legacy = try decoder.decode(KnowledgeRelatedLink.self, from: Data(#"{"label":"Pitch","to":"/pitch/four-seam"}"#.utf8))
        XCTAssertNil(legacy.reason)
        let contextual = try decoder.decode(KnowledgeRelatedLink.self, from: Data(#"{"label":"Pitch","to":"/pitch/four-seam","reason":"Navigation context"}"#.utf8))
        XCTAssertEqual(contextual.reason, "Navigation context")
    }
    func testSharedGripCameraFacesLeadContactsAndPreservesGeometry() throws {
        let store = PitchStore()
        let first = try XCTUnwrap(store.pitch(slug: "four-seam"))
        let second = try XCTUnwrap(store.pitch(slug: "slider"))
        let camera = GripStudyOrientation.quaternion(reference: first.canonical.fingerPlacement, view: .top)
        let lead = first.canonical.fingerPlacement.filter { $0.finger != .thumb }
        XCTAssertFalse(lead.isEmpty)
        for contact in lead {
            XCTAssertGreaterThan(camera.act(SeamMath.seamPoint(contact.seamT * 2 * .pi)).z, 0)
        }
        for pitch in [first, second] {
            for contact in pitch.canonical.fingerPlacement {
                let point = SeamMath.seamPoint(contact.seamT * 2 * .pi)
                XCTAssertEqual(simd_length(camera.act(point)), simd_length(point), accuracy: 0.0000001)
                XCTAssertLessThan(simd_distance(camera.inverse.act(camera.act(point)), point), 0.0000001)
            }
        }
    }

}
