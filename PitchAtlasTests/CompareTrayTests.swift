import XCTest
@testable import PitchAtlas

/// The compare tray, read the way compare/CompareTray.tsx, CompareButton.tsx and
/// CompareProvider.tsx read the selection (web 47e21e6).
final class CompareTrayTests: XCTestCase {
    /// CompareButton: a pitch already chosen leaves its place when tapped again
    /// and the other keeps its own; choosing never opens the table.
    func testTappingASelectedPitchRemovesIt() {
        let state = CompareSelection()
        state.toggle("four-seam"); state.toggle("slider")
        XCTAssertEqual(state.slugs, ["four-seam", "slider"])
        XCTAssertFalse(state.presented, "choosing a pitch never opens the table")
        state.toggle("four-seam")
        XCTAssertNil(state.slug(in: .a))
        XCTAssertEqual(state.slug(in: .b), "slider", "the other pitch keeps its place")
        state.toggle("cutter")
        XCTAssertEqual(state.slugs, ["cutter", "slider"], "the open place fills first")
        state.toggle("slider"); state.toggle("cutter")
        XCTAssertEqual(state.slugs, [])
        XCTAssertFalse(state.presented)
    }

    /// The tray's status line counts the chosen pitches.
    func testTrayStatusCountsTheChosen() {
        XCTAssertEqual(CompareTrayReads.status(chosen: 0), "0 of 2 pitches selected")
        XCTAssertEqual(CompareTrayReads.status(chosen: 1), "1 of 2 pitches selected")
        XCTAssertEqual(CompareTrayReads.status(chosen: 2), "2 of 2 pitches selected")
    }

    /// The tray's action names what it does, the button names its state, and
    /// the tray shows only while a pitch is chosen and the table is shut.
    func testTrayActionNamesWhatItDoes() {
        XCTAssertEqual(CompareTrayReads.action(chosen: 1), "Choose second pitch")
        XCTAssertEqual(CompareTrayReads.action(chosen: 2), "Compare pair")
        XCTAssertEqual(CompareTrayReads.emptySlot, "Choose another pitch")
        XCTAssertEqual(CompareTrayReads.name, "Selected pitches")
        XCTAssertEqual(CompareTrayReads.removeLabel("Slider"), "Remove Slider")
        XCTAssertEqual(CompareTrayReads.buttonLabel(selected: false), "Compare")
        XCTAssertEqual(CompareTrayReads.buttonLabel(selected: true), "Selected")
        XCTAssertEqual(CompareTrayReads.buttonAccessibility(selected: false, slug: "four-seam"), "Compare four seam")
        XCTAssertEqual(CompareTrayReads.buttonAccessibility(selected: true, slug: "circle-change"), "Selected circle change")
        XCTAssertFalse(CompareTrayReads.shows(chosen: 0, tableUp: false))
        XCTAssertTrue(CompareTrayReads.shows(chosen: 1, tableUp: false))
        XCTAssertFalse(CompareTrayReads.shows(chosen: 2, tableUp: true), "the table hides the tray")
    }

    /// A pitch is never in both places; a third waits for the reader to make room.
    func testSelectionNeverHoldsAPitchTwice() {
        let state = CompareSelection()
        state.toggle("four-seam"); state.toggle("slider"); state.toggle("cutter")
        XCTAssertEqual(state.slugs, ["four-seam", "slider"])
        XCTAssertEqual(state.pending, "cutter")
        state.replace(.a)
        XCTAssertEqual(state.slugs, ["cutter", "slider"])
        state.pending = "slider"
        state.replace(.a)
        XCTAssertEqual(state.slugs, ["cutter", "slider"])
        XCTAssertNil(state.pending)
        XCTAssertEqual(Set(state.slugs).count, state.slugs.count)
    }
}
