import XCTest
@testable import PitchAtlas

final class IndexScrollRestorationTests: XCTestCase {
    private let top: [String: CGRect] = [
        "four-seam": CGRect(x: 0, y: 420, width: 320, height: 100),
        "two-seam": CGRect(x: 0, y: 520, width: 320, height: 100),
        "sinker": CGRect(x: 0, y: 720, width: 320, height: 100),
    ]
    private let deep: [String: CGRect] = [
        "four-seam": CGRect(x: 0, y: -140, width: 320, height: 100),
        "two-seam": CGRect(x: 0, y: -40, width: 320, height: 100),
        "sinker": CGRect(x: 0, y: 160, width: 320, height: 100),
    ]

    func testInitialTopNeverManufacturesFirstResultAnchor() {
        var state = IndexScrollRestoration()
        XCTAssertNil(state.indexDidAppear())
        state.observe(frames: top)
        state.beginNavigation()
        state.indexDidDisappear()
        state.navigationDidEnd()
        XCTAssertEqual(state.indexDidAppear(), .top)
    }

    func testReverseScrollToControlsClearsOldDeepRow() {
        var state = visibleDeepState()
        state.observe(frames: top)
        state.beginNavigation()
        XCTAssertEqual(state.indexDidAppear(), .top)
    }

    func testFamilyGapAndEmptyPreferenceKeepGenuinelyCrossedRow() {
        var state = visibleDeepState()
        state.observe(frames: [
            "two-seam": CGRect(x: 0, y: -110, width: 320, height: 100),
            "sinker": CGRect(x: 0, y: 70, width: 320, height: 100),
        ])
        state.observe(frames: [:])
        XCTAssertEqual(state.position, .row("two-seam"))
    }

    func testActivationFreezesBeforePushRelayoutAndDisappear() {
        var state = visibleDeepState()
        state.beginNavigation() // The tapped Sinker does not choose the anchor.
        state.observe(frames: top) // Push relayout can arrive before onDisappear.
        state.observe(frames: ["four-seam": CGRect(x: 0, y: 0, width: 320, height: 100)])
        state.indexDidDisappear()
        state.observe(frames: top)
        state.navigationDidEnd() // Back commits before Index onAppear.
        state.observe(frames: top)
        XCTAssertEqual(state.indexDidAppear(), .row("two-seam"))
        state.observe(frames: top) // Real reverse-scroll is accepted after return.
        XCTAssertEqual(state.position, .top)
    }

    func testEarlyAppearanceAndCancelledSwipeKeepFrozenSnapshot() {
        var state = visibleDeepState()
        state.beginNavigation()
        state.indexDidDisappear()
        XCTAssertEqual(state.indexDidAppear(), .row("two-seam"))
        state.observe(frames: top) // Interactive pop has not committed.
        state.indexDidDisappear() // User cancels the swipe.
        state.observe(frames: top)
        XCTAssertEqual(state.indexDidAppear(), .row("two-seam"))
        state.navigationDidEnd() // This pop commits after onAppear.
        state.observe(frames: top)
        XCTAssertEqual(state.position, .top)
    }

    func testEachResultMutationInvalidatesVisibleAndFrozenAnchors() {
        for mutation in ["query", "family", "status", "sort"] {
            var state = visibleDeepState()
            state.beginNavigation()
            state.indexDidDisappear()
            state.invalidate()
            state.navigationDidEnd()
            XCTAssertEqual(state.indexDidAppear(), .top, mutation)
            state.observe(frames: top)
            XCTAssertEqual(state.position, .top, mutation)
        }
    }

    func testTabDepartureKeepsRowAndIgnoresOffscreenLayout() {
        var state = visibleDeepState()
        state.indexDidDisappear()
        state.observe(frames: top)
        XCTAssertEqual(state.indexDidAppear(), .row("two-seam"))
    }

    func testNextTripCapturesNewlyViewedRowInsteadOfPreviousTrip() {
        var state = visibleDeepState()
        state.beginNavigation()
        state.indexDidDisappear()
        state.navigationDidEnd()
        _ = state.indexDidAppear()
        state.observe(frames: ["sinker": CGRect(x: 0, y: -20, width: 320, height: 220)])
        state.beginNavigation()
        state.indexDidDisappear()
        state.navigationDidEnd()
        XCTAssertEqual(state.indexDidAppear(), .row("sinker"))
    }

    private func visibleDeepState() -> IndexScrollRestoration {
        var state = IndexScrollRestoration()
        _ = state.indexDidAppear()
        state.observe(frames: deep)
        XCTAssertEqual(state.position, .row("two-seam"))
        return state
    }
}
