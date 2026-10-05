import XCTest
import SwiftUI
@testable import PitchAtlas

/// The generated Swift tokens and the generated JSON come from one object in the
/// generator; this pins that both committed files still agree (a hand edit to
/// either fails here), and that the alpha/reference resolution is right.
final class DesignTokenParityTests: XCTestCase {
    private func tokens() throws -> [String: Any] {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "design-tokens", withExtension: "json"))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }
    private func color(_ any: Any?) -> WebColor? {
        guard let d = any as? [String: Any], let hex = d["hex"] as? String, let alpha = d["alpha"] as? Double,
              let rgb = UInt32(hex.dropFirst(), radix: 16) else { return nil }
        return WebColor(rgb: rgb, alpha: alpha)
    }

    func testEveryPaletteTokenMatchesTheGeneratedSwift() throws {
        let palette = try XCTUnwrap(try tokens()["palette"] as? [String: Any])
        XCTAssertEqual(palette.count, WebTokens.Palette.all.count)
        for (name, value) in palette { XCTAssertEqual(WebTokens.Palette.all[name], color(value), name) }
    }

    func testPaletteResolvesReferencesAndAlpha() {
        XCTAssertEqual(WebTokens.Palette.all["color-void"], WebColor(rgb: 0x070509, alpha: 1))
        XCTAssertEqual(WebTokens.Palette.all["color-dim"], WebTokens.Palette.all["color-ink-2"], "{color-ink-2} reference")
        XCTAssertEqual(WebTokens.Palette.all["color-white"], WebColor(rgb: 0xFFFFFF, alpha: 1), "#fff short hex")
        let navyLine = WebTokens.Palette.all["color-navy-line"]
        XCTAssertEqual(navyLine?.rgb, 0xD8D1C0)
        XCTAssertEqual(navyLine?.alpha ?? 0, Double(0x29) / 255, accuracy: 0.0001)
    }

    func testTiersAreThreeColorsAcrossSevenLabels() throws {
        XCTAssertEqual(WebTokens.Tier.label.count, 7)
        XCTAssertEqual(Set(WebTokens.Tier.dot.values).count, 3)
        for raw in ClaimConfidence.allCases.map(\.rawValue) {
            XCTAssertNotNil(WebTokens.Tier.dot[raw], raw)
            XCTAssertNotNil(WebTokens.Tier.ink[raw], raw)
            XCTAssertFalse(WebTokens.Tier.glyph[raw, default: ""].isEmpty, raw)
            XCTAssertFalse(WebTokens.Tier.label[raw, default: ""].isEmpty, raw)
        }
        XCTAssertEqual(WebTokens.Tier.dot["official-data"]?.rgb, 0xBF5700)
        XCTAssertEqual(WebTokens.Tier.dot["community-firsthand"]?.rgb, 0x8FBAD6)
        XCTAssertEqual(WebTokens.Tier.dot["unverified"]?.rgb, 0xFF2D44)
        XCTAssertEqual(WebTokens.Tier.ink["reputable-analysis"]?.rgb, 0x3D6A8A)
    }

    func testGradientsMatchTheJSONAndTheCSSOrder() throws {
        let gradients = try XCTUnwrap(try tokens()["gradients"] as? [String: [String: Any]])
        let swift: [String: WebGradient] = ["foil": WebTokens.Gradient.foil, "foilType": WebTokens.Gradient.foilType,
                                            "ember": WebTokens.Gradient.ember]
        for (name, gradient) in swift {
            let json = try XCTUnwrap(gradients[name])
            XCTAssertEqual(json["angle"] as? Double, gradient.angle, name)
            let stops = try XCTUnwrap(json["stops"] as? [[String: Any]])
            XCTAssertEqual(stops.count, gradient.stops.count, name)
            XCTAssertEqual(gradient.stops.map(\.location), gradient.stops.map(\.location).sorted(), "\(name) out of order")
        }
        XCTAssertEqual(WebTokens.Gradient.foil.angle, 112)
        XCTAssertEqual(WebTokens.Gradient.foil.stops.count, 21)
        XCTAssertEqual(WebTokens.Gradient.ember.angle, 150)
        XCTAssertEqual(WebTokens.Gradient.ember.stops.first?.color.rgb, 0x2A1208)
    }

    func testThrowbackFoilStopsParseFractionalLocations() {
        let powder = WebTokens.CardFinish.powder
        XCTAssertTrue(powder.foil.stops.contains { abs($0.location - 0.245) < 0.0001 && $0.color.rgb == 0xFFF6F7 })
        XCTAssertEqual(powder.ring.rgb, 0xC41E3A)
        XCTAssertEqual(powder.ringIn.alpha, 0.34, accuracy: 0.0001)
        XCTAssertEqual(WebTokens.CardFinish.teal.ring.rgb, 0x00B2A9)
    }

    func testAccentTriadsCoverEverySpecimenAndSoftballPitch() {
        let store = PitchStore()
        for pitch in store.pitches { XCTAssertNotNil(WebTokens.Accent.byPitch[pitch.slug], pitch.slug) }
        for pitch in store.softball.pitches { XCTAssertNotNil(WebTokens.Accent.byPitch[pitch.slug], pitch.slug) }
        XCTAssertEqual(WebTokens.Accent.byPitch["twelve-six"]?.finish, "powder")
        XCTAssertEqual(WebTokens.Accent.byPitch["circle-change"]?.finish, "teal")
        XCTAssertEqual(WebTokens.Accent.burnt, 0xBF5700)
        XCTAssertEqual(WebTokens.Family.accent["breaking"], 0x5FE0EA)
    }

    func testMotionAndRadiusTokens() {
        XCTAssertEqual(WebTokens.Motion.settle, [0.22, 1, 0.36, 1])
        XCTAssertEqual([WebTokens.Motion.tinyMs, WebTokens.Motion.shortMs, WebTokens.Motion.mediumMs,
                        WebTokens.Motion.slowMs, WebTokens.Motion.sweepMs], [120, 190, 400, 700, 900])
        XCTAssertEqual(WebTokens.Radius.sm, 6)
        XCTAssertEqual(WebTokens.Radius.lg, 10)
    }

    func testColorSetsAreGeneratedFromTheTokens() throws {
        let accent = try XCTUnwrap(UIColor(named: "AccentColor"))
        let launch = try XCTUnwrap(UIColor(named: "LaunchBackground"))
        XCTAssertEqual(rgb(accent), WebTokens.Palette.all["color-cyan"]?.rgb)
        XCTAssertEqual(rgb(launch), WebTokens.Palette.all["color-void"]?.rgb)
    }

    private func rgb(_ color: UIColor) -> UInt32 {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (UInt32((r * 255).rounded()) << 16) | (UInt32((g * 255).rounded()) << 8) | UInt32((b * 255).rounded())
    }
}
