import SwiftUI
import XCTest
@testable import PitchAtlas

/// The accessibility floor: 44pt taps, hairlines that lift under Increase
/// Contrast, and copy that tells VoiceOver what the screen says.
final class AccessibilityFloorTests: XCTestCase {

    func testHairlinesLiftUnderIncreaseContrast() {
        for (name, color, webAlpha) in [
            ("machined", PitchAtlasTheme.machinedUIColor, WebTokens.Palette.machined.alpha),
            ("navyLine", PitchAtlasTheme.navyLineUIColor, WebTokens.Palette.navyLine.alpha),
        ] {
            let normal = color.resolvedColor(with: UITraitCollection(accessibilityContrast: .normal))
            let high = color.resolvedColor(with: UITraitCollection(accessibilityContrast: .high))
            var normalAlpha: CGFloat = 0, highAlpha: CGFloat = 0
            normal.getRed(nil, green: nil, blue: nil, alpha: &normalAlpha)
            high.getRed(nil, green: nil, blue: nil, alpha: &highAlpha)
            XCTAssertEqual(Double(normalAlpha), webAlpha, accuracy: 0.002, "\(name) keeps the web's alpha by default")
            XCTAssertGreaterThanOrEqual(Double(highAlpha), 0.45, "\(name) lifts under Increase Contrast")
        }
    }

    func testContrastLiftFloorsAndCaps() {
        XCTAssertEqual(PitchAtlasTheme.contrastLifted(WebColor(rgb: 0xD8D1C0, alpha: 0.2)).alpha, 0.5, accuracy: 0.0001)
        XCTAssertEqual(PitchAtlasTheme.contrastLifted(WebColor(rgb: 0xD8D1C0, alpha: 0.1)).alpha, 0.45, accuracy: 0.0001)
        XCTAssertEqual(PitchAtlasTheme.contrastLifted(WebColor(rgb: 0xD8D1C0, alpha: 0.6)).alpha, 1, accuracy: 0.0001)
        XCTAssertEqual(PitchAtlasTheme.contrastLifted(WebColor(rgb: 0xD8D1C0, alpha: 0.6)).rgb, 0xD8D1C0)
    }

    /// The app gives every system bordered button the large control size; this
    /// pins the assumption that large clears the 44pt floor at the default size.
    @MainActor
    func testLargeBorderedButtonsClearTheTapFloor() throws {
        for prominent in [false, true] {
            let button = Group {
                if prominent {
                    Button("Reply") {}.buttonStyle(.borderedProminent)
                } else {
                    Button("Try again") {}.buttonStyle(.bordered)
                }
            }
            .controlSize(.large)
            .font(PitchAtlasTheme.hankenMedium(13))
            .environment(\.dynamicTypeSize, .large)
            let renderer = ImageRenderer(content: button)
            renderer.scale = 1
            let height = try XCTUnwrap(renderer.uiImage?.size.height)
            XCTAssertGreaterThanOrEqual(height, 44, prominent ? "prominent" : "bordered")
        }
    }

    func testEveryPitchButtonKindKeepsA44ptHit() {
        for kind: PitchButtonKind in [.chrome, .ghost, .waxSeal, .chapter(fill: 0xBF5700), .link] {
            XCTAssertEqual(kind.minHitHeight, 44)
        }
    }

    func testAboutSpeaksTheSentenceItShows() {
        XCTAssertTrue(AboutView.honestyLine.contains("work anonymously"))
        XCTAssertFalse(AboutView.honestyLine.contains("require sign-in"))
    }

    func testMotionPermissionNamesTheCardTilt() throws {
        let usage = try XCTUnwrap(Bundle.main.object(forInfoDictionaryKey: "NSMotionUsageDescription") as? String)
        XCTAssertTrue(usage.contains("tilt"))
        XCTAssertFalse(usage.lowercased().contains("foil"))
        XCTAssertTrue(usage.contains("Reduce Motion"))
    }
}
