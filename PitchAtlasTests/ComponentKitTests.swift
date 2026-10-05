import XCTest
import SwiftUI
@testable import PitchAtlas

@MainActor
final class ComponentKitTests: XCTestCase {
    func testKickerMetricsMatchTheWeb() {
        XCTAssertEqual(KickerLabel.ruleSize, CGSize(width: 22, height: 2))
        XCTAssertEqual(KickerLabel.gap, 9)
        XCTAssertEqual(KickerLabel.trackingEm, 0.2)
    }

    func testStampMetricsMatchTheWeb() {
        XCTAssertEqual(InkStamp.fontSize, 9)
        XCTAssertEqual(InkStamp.padding, EdgeInsets(top: 4, leading: 9, bottom: 4, trailing: 9))
        XCTAssertEqual(InkStamp.rotation, -1)
    }

    func testPanelCatchIsTheRenderedWhiteBand() {
        // :root .rfx-panel::before wins on the dark site (spec 10.1).
        XCTAssertEqual(PanelSurface.catchPeakOpacity, 0.4)
        XCTAssertEqual(PanelSurface.catchLayerOpacity, 0.55)
        XCTAssertEqual(PanelSurface.rimOpacity, 0.16)
    }

    func testSurfacesRender() {
        let views: [AnyView] = [
            AnyView(PanelSurface().frame(width: 200, height: 100)),
            AnyView(Text("x").panelFoil().frame(width: 200, height: 100)),
            AnyView(KickerLabel(text: "The filed set")),
            AnyView(InkStamp(text: "Filed")),
            AnyView(Hairline().frame(width: 200)),
        ]
        for view in views { XCTAssertNotNil(ImageRenderer(content: view).uiImage) }
    }

    func testEveryButtonKeepsA44ptHitArea() {
        for kind: PitchButtonKind in [.chrome, .ghost, .waxSeal, .chapter(fill: 0xB9D4E5), .link] {
            XCTAssertGreaterThanOrEqual(kind.minHitHeight, 44)
        }
    }

    func testChapterButtonInkComesFromAccentButton() {
        XCTAssertEqual(PitchButtonKind.chapter(fill: 0x5B7F96).colors.fill, 0x63859B, "forkball lifts one 5% step")
        XCTAssertEqual(PitchButtonKind.chapter(fill: 0xBF5700).colors.ink, 0xFFFFFF)
        XCTAssertEqual(PitchButtonKind.chapter(fill: 0xB9D4E5).colors.ink, 0x06121B)
    }

    func testRosinGrainsFallAndFade() throws {
        let early = try XCTUnwrap(RosinPuff.grain(3, at: 0.05))
        let late = RosinPuff.grain(3, at: 0.4)
        XCTAssertGreaterThan(early.alpha, late?.alpha ?? 0)
        XCTAssertNil(RosinPuff.grain(3, at: 0.9), "every grain is gone by 0.85s")
        XCTAssertEqual(RosinPuff.grainCount, 30)
        XCTAssertEqual(RosinPuff.duration, 0.8)
    }

    func testRosinPuffIsDeterministic() {
        XCTAssertEqual(RosinPuff.grain(7, at: 0.2), RosinPuff.grain(7, at: 0.2))
    }

    func testTagChipIsCyanWhenOnAndBoneWhenOff() {
        let on = ChipAppearance.of(.tag, selected: true), off = ChipAppearance.of(.tag, selected: false)
        XCTAssertEqual(on.fill, PitchAtlasTheme.cyan)
        XCTAssertEqual(on.ink, ComponentInk.onCyanInk)
        XCTAssertEqual(on.weight, .martian600)
        XCTAssertNil(off.fill)
        XCTAssertEqual(off.ink, PitchAtlasTheme.bone)
        XCTAssertEqual(off.border, PitchAtlasTheme.cyan.opacity(0.4))
    }

    func testFilterChipIsBurntWithWhiteInkWhenOn() {
        let on = ChipAppearance.of(.filter, selected: true)
        XCTAssertEqual(on.fill, Color(rgb: WebTokens.Accent.burnt))
        XCTAssertEqual(on.ink, Color(rgb: WebTokens.Palette.white.rgb))
    }

    func testControlsKeep44ptHitAreas() {
        XCTAssertGreaterThanOrEqual(PitchChip.hitHeight, 44)
        XCTAssertGreaterThanOrEqual(PillToggle<Int>.hitHeight, 44)
        XCTAssertGreaterThanOrEqual(SegmentToggle<Int>.hitHeight, 44)
        XCTAssertGreaterThanOrEqual(FilterSortPill.hitHeight, 44)
    }

    func testFilterPillCountsActiveFilters() {
        XCTAssertEqual(FilterSortPill.title(activeCount: 0), "Filter & sort")
        XCTAssertEqual(FilterSortPill.title(activeCount: 2), "Filter & sort (2)")
    }

    func testToastShowsThenClearsItself() async throws {
        let center = ToastCenter()
        center.show("Sent for review", duration: 0.05)
        XCTAssertEqual(center.current?.message, "Sent for review")
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertNil(center.current)
    }

    func testANewerToastIsNotClearedByAnOlderTimer() async throws {
        let center = ToastCenter()
        center.show("first", duration: 0.05)
        center.show("second", duration: 1)
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(center.current?.message, "second")
    }

    func testSearchFieldMetricsMatchTheWeb() {
        XCTAssertEqual(PitchSearchField.height, 44)
        XCTAssertEqual(PitchSearchField.radius, 14)
    }
}
