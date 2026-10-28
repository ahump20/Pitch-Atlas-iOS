import SwiftUI
import XCTest
@testable import PitchAtlas

/// TightLines sets a title at the site's CSS line-height when that is tighter
/// than the face's own line box (Anton's box is about 1.5 of its size; the site
/// sets its athletic titles near 1.0), which SwiftUI's Text cannot do.
final class TightLinesTests: XCTestCase {
    func testWordsBreakWhereTheNextWouldOverflow() {
        let lines = TightLinesLayout.lines(widths: [50, 60, 40], spaceAfter: [true, true, false], space: 10, maxWidth: 125)
        XCTAssertEqual(lines, [0..<2, 2..<3])
    }

    func testALineHoldsExactlyTheWidthItIsGiven() {
        let lines = TightLinesLayout.lines(widths: [50, 60], spaceAfter: [true, false], space: 10, maxWidth: 120)
        XCTAssertEqual(lines, [0..<2])
    }

    func testAWordWiderThanTheLineTakesALineOfItsOwn() {
        let lines = TightLinesLayout.lines(widths: [30, 200, 30], spaceAfter: [true, true, false], space: 10, maxWidth: 100)
        XCTAssertEqual(lines, [0..<1, 1..<2, 2..<3])
    }

    /// CSS breaks after a hyphen with no space: "THE FOUR- / SEAM FASTBALL".
    func testAHyphenOffersABreakWithoutASpace() {
        let tokens = TightLines.tokens("FIELD NOTES FOR THE FOUR-SEAM FASTBALL")
        XCTAssertEqual(tokens.map(\.text), ["FIELD", "NOTES", "FOR", "THE", "FOUR-", "SEAM", "FASTBALL"])
        XCTAssertEqual(tokens.map(\.spaceAfter), [true, true, true, true, false, true, false])
        XCTAssertEqual(TightLines.tokens("  A  B ").map(\.text), ["A", "B"], "runs of spaces collapse, as in CSS")
        XCTAssertEqual(TightLines.tokens("OFF-").map(\.text), ["OFF-"], "a trailing hyphen stays on its word")
    }

    /// text-wrap: balance — the narrowest width that keeps the same number of lines.
    func testABalancedTitleNarrowsToItsEvenestBreak() {
        let widths: [CGFloat] = [80, 80, 80, 80]
        let spaces = [true, true, true, false]
        XCTAssertEqual(TightLinesLayout.lines(widths: widths, spaceAfter: spaces, space: 10, maxWidth: 300).count, 2)
        let balanced = TightLinesLayout.balancedWidth(widths: widths, spaceAfter: spaces, space: 10, maxWidth: 300)
        XCTAssertEqual(balanced, 170, accuracy: 0.5)
        XCTAssertEqual(TightLinesLayout.lines(widths: widths, spaceAfter: spaces, space: 10, maxWidth: balanced), [0..<2, 2..<4])
    }

    /// Each line box is the CSS pitch tall; the face's own box sits centered in
    /// it, overhanging above and below when the pitch is tighter.
    func testLinesStackAtTheCSSPitch() {
        XCTAssertEqual(TightLinesLayout.height(lineCount: 2, pitch: 38.4 * 1.02), 78.336, accuracy: 0.001)
        XCTAssertEqual(TightLinesLayout.lineTop(index: 0, pitch: 39.168, natural: 57.792), -9.312, accuracy: 0.001)
        XCTAssertEqual(TightLinesLayout.lineTop(index: 1, pitch: 39.168, natural: 57.792), 29.856, accuracy: 0.001)
    }

    /// End to end with the real face: FieldNotes.tsx's band title, two lines at
    /// leading 1.02 in its 16ch box, is 2 × 39.168 tall, not Anton's own 2 × 57.8.
    @MainActor
    func testTheBandTitleSetsTwoLinesAtTheSitesPitch() throws {
        let title = TightLines("FIELD NOTES FROM THE BULLPEN.", face: .anton400, size: 38.4, lineHeight: 1.02, trackingEm: 0.01)
            .frame(width: 303.6)
        let image = try XCTUnwrap(ImageRenderer(content: title).uiImage)
        XCTAssertEqual(image.size.height, 2 * 38.4 * 1.02, accuracy: 1)
    }
}
