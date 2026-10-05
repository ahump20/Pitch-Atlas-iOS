import XCTest
@testable import PitchAtlas

/// The wing bundles generated from web src/data: softball, hidden notes,
/// quotes, credited media and the Muybridge plate.
final class WingBundleTests: XCTestCase {
    func testWingBundlesDecodeAndMatchManifest() {
        let store = PitchStore()
        if case .failed(let message) = store.status { XCTFail("decode failed: \(message)") }
        let counts = store.manifest.counts
        XCTAssertEqual(store.softball.pitches.count, counts["softball.pitches"])
        XCTAssertEqual(store.softball.craftsmen.count, counts["softball.craftsmen"])
        XCTAssertEqual(store.tidbits.count, counts["tidbits.json"])
        XCTAssertEqual(store.quotes.count, counts["quotes.json"])
        XCTAssertEqual(store.externalMedia.items.count, counts["external-media.items"])
        XCTAssertEqual(store.craftsmanMedia.count, counts["craftsman-media.json"])
        XCTAssertEqual(store.plate273?.frames.count, counts["plate-273.frames"])
        XCTAssertFalse(store.softball.pitches.isEmpty)
        XCTAssertFalse(store.tidbits.isEmpty)
        XCTAssertNotNil(store.manifest.contentHash)
    }

    func testEveryWingClaimCarriesASource() {
        let store = PitchStore()
        let claims = store.softball.pitches.flatMap { [$0.grip, $0.spin, $0.movement] }
            + store.softball.windmillPhases.map(\.what)
            + store.tidbits.map(\.claim)
            + store.quotes.map(\.claim)
        XCTAssertFalse(claims.isEmpty)
        for claim in claims { XCTAssertNotNil(claim.source, "unsourced claim: \(claim.value.prefix(60))") }
    }

    func testPlateFramesAreClosedStraightLineOutlines() throws {
        let plate = try XCTUnwrap(PitchStore().plate273)
        XCTAssertEqual(plate.rights, "public-domain")
        XCTAssertEqual(plate.frames.count, plate.frameCount)
        for frame in plate.frames {
            XCTAssertEqual(frame.viewBox.count, 4)
            XCTAssertFalse(frame.subpaths.isEmpty)
            for sub in frame.subpaths {
                XCTAssertGreaterThanOrEqual(sub.count, 3)
                sub.forEach { XCTAssertEqual($0.count, 2) }
            }
        }
    }

    func testOutboundOnlyMediaIsNeverEmbedded() {
        for item in PitchStore().externalMedia.items where item.platform == "x" {
            XCTAssertNotNil(URL(string: item.canonicalUrl), "\(item.id) has no outbound URL")
        }
    }

    func testStoreToleratesAMissingOptionalBundle() throws {
        // A bundle with only the core files: the wing collections fall back empty
        // and status names the missing file; the core collections still load.
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }
        for name in ["manifest", "pitches", "repertoire", "craftsmen", "lost-pitches", "knowledge", "grips",
                     "sources", "archive-images", "teaching-clips"] {
            let url = try XCTUnwrap(Bundle.main.url(forResource: name, withExtension: "json"))
            try FileManager.default.copyItem(at: url, to: temp.appendingPathComponent("\(name).json"))
        }
        let bundle = try XCTUnwrap(Bundle(path: temp.path))
        let store = PitchStore(bundle: bundle)
        XCTAssertFalse(store.pitches.isEmpty)
        XCTAssertTrue(store.softball.pitches.isEmpty)
        guard case .failed(let message) = store.status else {
            return XCTFail("a missing softball.json should be reported")
        }
        XCTAssertTrue(message.contains("softball.json"))
    }
}
