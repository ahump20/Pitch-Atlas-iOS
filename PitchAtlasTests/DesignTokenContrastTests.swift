import XCTest
import SwiftUI
@testable import PitchAtlas

/// Every text/background pairing the app uses, at WCAG thresholds: 4.5:1 for
/// body text, 3:1 for large text and graphics (tier dots, rules).
final class DesignTokenContrastTests: XCTestCase {
    private let field = WebTokens.Palette.void.rgb
    private let press = WebTokens.Palette.press.rgb

    func testBodyTextRoles() {
        let pairs: [(String, UInt32, UInt32)] = [
            ("bone on void", WebTokens.Palette.bone.rgb, field),
            ("ink-2 on void", WebTokens.Palette.ink2.rgb, field),
            ("ink-3 on void", WebTokens.Palette.ink3.rgb, field),
            ("bone on press", WebTokens.Palette.bone.rgb, press),
            ("bone-2 on press", InkContext.object.text2RGB, press),
            ("bone-3 on press", InkContext.object.text3RGB, press),
            ("cyan on void", WebTokens.Palette.cyan.rgb, field),
            ("on-accent on cyan", WebTokens.Palette.ctlOnAccent.rgb, WebTokens.Palette.cyan.rgb),
            ("white on burnt", WebTokens.Palette.white.rgb, WebTokens.Accent.burnt),
            ("placeholder on control", WebTokens.Palette.ctlPlaceholder.rgb, WebTokens.Palette.ctlBg.rgb),
        ]
        for (name, fg, bg) in pairs { XCTAssertGreaterThanOrEqual(PitchAccents.contrast(fg, bg), 4.5, name) }
    }

    func testTierDotsAreVisibleGraphics() {
        for (raw, dot) in WebTokens.Tier.dot {
            XCTAssertGreaterThanOrEqual(PitchAccents.contrast(dot.rgb, field), 3, "\(raw) dot on void")
            XCTAssertGreaterThanOrEqual(PitchAccents.contrast(dot.rgb, press), 3, "\(raw) dot on press")
        }
    }

    func testSmallBurntTextIsNeverUsedOnTheVoid() {
        XCTAssertLessThan(PitchAccents.contrast(WebTokens.Accent.burnt, field), 4.5, "if this ever passes, the bone rule can relax")
        XCTAssertEqual(PitchAccents.accentInk(WebTokens.Accent.burnt), Color(web: WebTokens.Palette.bone))
    }
}
