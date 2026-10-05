import XCTest
import SwiftUI
@testable import PitchAtlas

final class ThemeRoleTests: XCTestCase {
    func testAccentButtonMatchesTheWebAlgorithm() {
        // Vectors from web src/components/refractor/accents.ts accentButton().
        let cases: [(UInt32, UInt32, UInt32)] = [
            (0xBF5700, 0xBF5700, 0xFFFFFF), (0x5FE0EA, 0x5FE0EA, 0x06121B), (0x5B7F96, 0x63859B, 0x06121B),
            (0x6E757B, 0x6E757B, 0xFFFFFF), (0xB9D4E5, 0xB9D4E5, 0x06121B), (0xFF4D46, 0xFF4D46, 0x06121B),
            (0x3F5768, 0x3F5768, 0xFFFFFF), (0x7F97A8, 0x7F97A8, 0x06121B),
        ]
        for (fill, background, foreground) in cases {
            let result = PitchAccents.accentButton(fill: fill)
            XCTAssertEqual(result.background, background, String(fill, radix: 16))
            XCTAssertEqual(result.foreground, foreground, String(fill, radix: 16))
        }
    }

    func testContrastMatchesTheWebFormula() {
        XCTAssertEqual(PitchAccents.contrast(0x070509, 0xBF5700), 4.425, accuracy: 0.001)
        XCTAssertEqual(PitchAccents.contrast(0x221E18, 0x7C8294), 4.324, accuracy: 0.001)
    }

    func testCssAngleEndpointsOnASquare() {
        let p = PitchAtlasMaterials.cssEndpoints(angle: 112, aspect: 1)
        XCTAssertEqual(p.start.x, -0.1035, accuracy: 0.001)
        XCTAssertEqual(p.start.y, 0.2559, accuracy: 0.001)
        XCTAssertEqual(p.end.x, 1.1035, accuracy: 0.001)
        XCTAssertEqual(p.end.y, 0.7441, accuracy: 0.001)
        let down = PitchAtlasMaterials.cssEndpoints(angle: 180, aspect: 5.0 / 7.0)
        XCTAssertEqual(down.start.x, 0.5, accuracy: 0.0001); XCTAssertEqual(down.start.y, 0, accuracy: 0.0001)
        XCTAssertEqual(down.end.y, 1, accuracy: 0.0001)
    }

    func testFamilyColorsAreTheWebInkwells() {
        XCTAssertEqual(PitchAccents.familyRGB(RepertoireFamily.fastball), 0xBF5700)
        XCTAssertEqual(PitchAccents.familyRGB(RepertoireFamily.offspeed), 0xD8CFBB)
        XCTAssertEqual(PitchAccents.familyRGB(RepertoireFamily.breaking), 0x5FE0EA)
        XCTAssertEqual(PitchAccents.familyRGB(RepertoireFamily.specialty), 0xB9D4E5)
        XCTAssertEqual(PitchAccents.familyRGB(RepertoireFamily.banned), 0xFF4D46)
        for family in PitchFamily.allCases {
            XCTAssertEqual(PitchAccents.familyRGB(family), WebTokens.Family.accent[family.rawValue], family.rawValue)
        }
    }

    func testUnknownSlugFallsBackToTheNeutralTriad() {
        XCTAssertEqual(PitchAccents.triad(for: "not-a-slug"), WebTokens.Accent.fallback)
    }

    func testReduceMotionDropsAnimation() {
        XCTAssertNil(PitchAtlasMotion.animation(PitchAtlasMotion.medium, reduceMotion: true))
        XCTAssertNotNil(PitchAtlasMotion.animation(PitchAtlasMotion.medium, reduceMotion: false))
    }

    func testStatusAndTierTonesFollowTheWebMaps() {
        for status in RepertoireStatus.allCases {
            XCTAssertEqual(status.toneRGB, WebTokens.Status.indexColor[status.rawValue]?.rgb, status.rawValue)
        }
        XCTAssertEqual(RepertoireStatus.alias.badgeToneRGB, WebTokens.Palette.seam.rgb)
        XCTAssertEqual(RepertoireStatus.rare.badgeToneRGB, WebTokens.Palette.bone2.rgb)
        XCTAssertEqual(DocumentationTier.documented.toneRGB, WebTokens.Tier.dot["official-data"]?.rgb)
        XCTAssertEqual(DocumentationTier.partial.toneRGB, WebTokens.Tier.dot["reputable-analysis"]?.rgb)
        XCTAssertEqual(DocumentationTier.legend.toneRGB, WebTokens.Tier.dot["unverified"]?.rgb)
    }

    func testFamilyAccentsReadTheWebInkwells() {
        XCTAssertEqual(RepertoireFamily.fastball.accentRGB, 0xBF5700)
        XCTAssertEqual(PitchFamily.breaking.accentRGB, 0x5FE0EA)
    }
}
