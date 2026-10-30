import SwiftUI
import XCTest
@testable import PitchAtlas

/// The page kit draws the site's own geometry. The expected points were printed
/// by running SeamGuide.tsx's formulas (web 47e21e6) in node.
final class ArchivePageTests: XCTestCase {
    private func assertPoint(_ p: CGPoint, _ x: CGFloat, _ y: CGFloat, accuracy: CGFloat = 0.06,
                             file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(p.x, x, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(p.y, y, accuracy: accuracy, file: file, line: line)
    }

    func testUnderlineStitchesAlternateLikeTheSite() {
        let row = StitchGeometry.row(width: 150, count: 9)
        XCTAssertEqual(row.count, 9)
        assertPoint(row[0].from, 4.8333, 3); assertPoint(row[0].to, 11.8333, 13)
        assertPoint(row[1].from, 28.5, 3); assertPoint(row[1].to, 21.5, 13)
        assertPoint(row[8].from, 138.1667, 3); assertPoint(row[8].to, 145.1667, 13)
    }

    func testTearRowSpacesSixtyEightStitchesAcrossTwelveHundred() {
        let row = StitchGeometry.row(width: 1200, count: 68)
        XCTAssertEqual(row.count, 68)
        assertPoint(row[0].from, 5.3235, 3); assertPoint(row[0].to, 12.3235, 13)
        assertPoint(row[1].from, 29.9706, 3); assertPoint(row[1].to, 22.9706, 13)
        XCTAssertTrue(StitchGeometry.row(width: 150, count: 0).isEmpty)
    }

    func testOrbitArcHasThirteenTicksAcrossTheHorseshoe() {
        let arc = StitchGeometry.arc()
        XCTAssertEqual(arc.count, 13)
        assertPoint(arc[0].from, 18.6592, 65.8323); assertPoint(arc[0].to, 13.4818, 75.7410)
        assertPoint(arc[1].from, 16.5782, 56.2883); assertPoint(arc[1].to, 7.7460, 49.4341)
        assertPoint(arc[6].from, 50.5360, 20.5043); assertPoint(arc[6].to, 43.2290, 12.0428)
        assertPoint(arc[12].from, 80.9462, 66.8289); assertPoint(arc[12].to, 91.5034, 63.1499)
    }

    /// text-wrap: balance — keep the line count, take the narrowest width that does.
    func testBalanceFindsTheNarrowestWidthThatKeepsTheLineCount() {
        // 300pt of words, set in 40pt lines.
        let height: (CGFloat) -> CGFloat = { width in 40 * (300 / width).rounded(.up) }
        // Two lines at 200: the narrowest width that still sets two is 150 — even halves.
        XCTAssertEqual(BalancedLines.balancedWidth(full: 200, height: height), 150, accuracy: 0.5)
        // One line at 400 or 380: it stays one line, at the 300 the line needs —
        // rounded up to the next whole point, so a fractional measure never adds a line.
        XCTAssertEqual(BalancedLines.balancedWidth(full: 400, height: height), 300, accuracy: 0.5)
        let narrowest = BalancedLines.balancedWidth(full: 380, height: height)
        XCTAssertEqual(narrowest, 300, accuracy: 1)
        XCTAssertEqual(narrowest, narrowest.rounded(.up))
        XCTAssertEqual(height(narrowest), height(380), "the balanced width keeps the line count")
        XCTAssertEqual(BalancedLines.balancedWidth(full: .infinity, height: height), .infinity)
    }

    func testHeroTitleScalesWithThePageLikeTheClamp() {
        XCTAssertEqual(SectionHero<EmptyView, EmptyView>.titleSize(width: 440), 37.4, accuracy: 0.01)
        XCTAssertEqual(SectionHero<EmptyView, EmptyView>.titleSize(width: 320), 35.2, accuracy: 0.01)
        XCTAssertEqual(SectionHero<EmptyView, EmptyView>.titleSize(width: 1400), 76.8, accuracy: 0.01)
    }
}
