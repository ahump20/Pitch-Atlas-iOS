import XCTest
@testable import PitchAtlas

final class CompareSelectionTests: XCTestCase {
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
}
