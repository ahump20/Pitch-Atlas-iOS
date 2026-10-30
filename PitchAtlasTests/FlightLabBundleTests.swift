import XCTest
@testable import PitchAtlas

/// The guard on the bundled Flight Lab data. It checks flight-lab.json against
/// literal lists copied from web main 47e21e6 — never against what a view renders,
/// which would pass forever. A merge of web PR #272 adds the knuckler note (and the
/// arsenal); this fails, and that means port the arsenal before archive.
final class FlightLabBundleTests: XCTestCase {
    func testFlightLabNotesAreOnlyWhatTheAppDraws() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "flight-lab", withExtension: "json"))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        XCTAssertEqual(Set(object.keys), ["rulebooks", "lobs", "measuredBatter", "notes"],
                       "flight-lab.json gained a key the app does not draw (the arsenal?)")
        let notes = try XCTUnwrap(object["notes"] as? [[String: Any]])
        XCTAssertEqual(notes.compactMap { $0["label"] as? String }, [
            "Bat: 34 in max",
            "Slow-pitch bats are made at 34 in",
            "Sweet spot: about 6 in from the end",
            "Lift and drag: baseball fits",
        ], "the Flight Lab's notes changed on the web; port what they describe before archive")
    }
}
