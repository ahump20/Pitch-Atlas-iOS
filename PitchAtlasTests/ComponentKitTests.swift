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
}
