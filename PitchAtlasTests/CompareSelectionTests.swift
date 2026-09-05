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
}
