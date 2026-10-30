import XCTest
import UIKit
@testable import PitchAtlas

final class FontTests: XCTestCase {
    /// Every face the web loads (design-tokens.json `fonts`) is bundled and
    /// resolves by PostScript name — a silent system fallback would fail here.
    func testEveryWebFontFaceResolves() {
        XCTAssertEqual(WebTokens.Fonts.faces.count, PitchAtlasType.Face.allCases.count)
        for face in PitchAtlasType.Face.allCases {
            XCTAssertNotNil(UIFont(name: face.postScriptName, size: 12), face.postScriptName)
            XCTAssertTrue(WebTokens.Fonts.faces.contains { $0.family == face.family && $0.weight == face.weight && $0.italic == face.italic },
                          "\(face) is not a web face")
        }
    }

    func testCustomFontsScaleWithDynamicType() {
        let base = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont(name: PitchAtlasType.Face.hanken400.postScriptName, size: 17)!,
                                                              compatibleWith: UITraitCollection(preferredContentSizeCategory: .large))
        let ax5 = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont(name: PitchAtlasType.Face.hanken400.postScriptName, size: 17)!,
                                                             compatibleWith: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge))
        XCTAssertGreaterThan(ax5.pointSize, base.pointSize * 2)
    }
}
