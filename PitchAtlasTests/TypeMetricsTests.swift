import UIKit
import XCTest
@testable import PitchAtlas

/// CSS line-height is a multiple of the font size; SwiftUI starts from the face's
/// own line box. The table the helper converts with is read here from the bundled
/// files themselves, so a swapped font file fails this instead of every page.
final class TypeMetricsTests: XCTestCase {
    func testEachFacesNaturalLineHeightIsTheBundledFilesOwn() throws {
        for face in PitchAtlasType.Face.allCases {
            let font = try XCTUnwrap(UIFont(name: face.postScriptName, size: 100), face.postScriptName)
            XCTAssertEqual(face.naturalLineHeight, font.lineHeight / 100, accuracy: 0.01, face.postScriptName)
        }
    }

    func testExtraLeadingIsTheWebLineBoxLessTheFacesOwn() {
        // the Index row's name: Hanken 700, 15pt, line-height 1.5
        XCTAssertEqual(PitchAtlasType.extraLeading(1.5, face: .hanken700, size: 15), 2.955, accuracy: 0.01)
        // .rfx-athletic at 40: Anton set at .9, far tighter than its file's 1.505
        XCTAssertEqual(PitchAtlasType.extraLeading(0.9, face: .anton400, size: 40), -24.2, accuracy: 0.01)
        // a face set at exactly its own box adds nothing
        XCTAssertEqual(PitchAtlasType.extraLeading(1.0, face: .newsreader400, size: 30), 0, accuracy: 0.001)
    }
}
