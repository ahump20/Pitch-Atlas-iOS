import XCTest
@testable import PitchAtlas

/// pitchatlas:// links land where the same path lands on pitch-atlas.com.
final class DeepLinkRouterTests: XCTestCase {
    private let store = PitchStore()

    private func destination(_ link: String) -> DeepLinkDestination? {
        DeepLinkRouter.destination(for: URL(string: link)!, store: store)
    }

    func testWebPathsOpenTheSameScreens() throws {
        let fourSeam = try XCTUnwrap(store.pitch(slug: "four-seam"))
        let twoSeam = try XCTUnwrap(store.pitch(slug: "two-seam"))
        let splitFinger = try XCTUnwrap(store.repertoireEntry(id: "split-finger-fastball"))
        let maddux = try XCTUnwrap(store.craftsman(slug: "greg-maddux"))
        let spin = try XCTUnwrap(store.wing(slug: "spin"))
        let fadeaway = try XCTUnwrap(store.lostPitch(slug: "rube-foster-fadeaway"))

        XCTAssertEqual(destination("pitchatlas://pitch/four-seam"), DeepLinkDestination(tab: .atlas, stack: [.pitch(fourSeam)]))
        XCTAssertEqual(destination("pitchatlas://repertoire/sinker"), DeepLinkDestination(tab: .atlas, stack: [.pitch(twoSeam)]))
        XCTAssertEqual(destination("pitchatlas://repertoire/split-finger-fastball"), DeepLinkDestination(tab: .index, stack: [.basicFile(splitFinger)]))
        XCTAssertEqual(destination("pitchatlas://home"), DeepLinkDestination(tab: .atlas, stack: []))
        XCTAssertEqual(destination("pitchatlas://repertoire"), DeepLinkDestination(tab: .index, stack: []))
        XCTAssertEqual(destination("pitchatlas://craftsmen/greg-maddux"), DeepLinkDestination(tab: .craftsmen, stack: [.craftsman(maddux)]))
        XCTAssertEqual(destination("pitchatlas://craftsman/greg-maddux"), DeepLinkDestination(tab: .craftsmen, stack: [.craftsman(maddux)]))
        XCTAssertEqual(destination("pitchatlas://learn/spin"), DeepLinkDestination(tab: .atlas, stack: [.atlas(.learn), .wing(spin)]))
        XCTAssertEqual(destination("pitchatlas://learn"), DeepLinkDestination(tab: .atlas, stack: [.atlas(.learn)]))
        XCTAssertEqual(destination("pitchatlas://lost-pitches/rube-foster-fadeaway"),
                       DeepLinkDestination(tab: .atlas, stack: [.atlas(.lostPitches), .lostPitch(fadeaway)]))
        XCTAssertEqual(destination("pitchatlas://about"), DeepLinkDestination(tab: .atlas, stack: [.atlas(.about)]))
        XCTAssertEqual(destination("pitchatlas://account"), DeepLinkDestination(tab: .atlas, stack: [.atlas(.account)]))
        XCTAssertEqual(destination("pitchatlas://grips"), DeepLinkDestination(tab: .grips, stack: []))
        XCTAssertEqual(destination("pitchatlas://sources"), DeepLinkDestination(tab: .sources, stack: []))
        XCTAssertEqual(destination("pitchatlas://tab/index"), DeepLinkDestination(tab: .index, stack: []))
    }

    func testAMissedSlugOpensTheListItWouldHaveLivedIn() {
        XCTAssertEqual(destination("pitchatlas://pitch/no-such-pitch"), DeepLinkDestination(tab: .index, stack: []))
        XCTAssertEqual(destination("pitchatlas://repertoire/no-such-file"), DeepLinkDestination(tab: .index, stack: []))
        XCTAssertEqual(destination("pitchatlas://craftsmen/no-such-hand"), DeepLinkDestination(tab: .craftsmen, stack: []))
        XCTAssertEqual(destination("pitchatlas://learn/no-such-wing"), DeepLinkDestination(tab: .atlas, stack: [.atlas(.learn)]))
        XCTAssertEqual(destination("pitchatlas://lost-pitches/no-such-pitch"), DeepLinkDestination(tab: .atlas, stack: [.atlas(.lostPitches)]))
    }

    /// The site sends /repertoire/<id> to /pitch/<filedSlug> when the entry has a
    /// filed specimen; every other entry keeps its basic file.
    func testAFiledBasicFileOpensItsSpecimen() throws {
        XCTAssertFalse(store.repertoire.entries.isEmpty)
        for entry in store.repertoire.entries {
            let landed = destination("pitchatlas://repertoire/\(entry.id)")
            if let slug = entry.filedSlug {
                let pitch = try XCTUnwrap(store.pitch(slug: slug), "\(entry.id) names \(slug), which is not bundled")
                XCTAssertEqual(landed, DeepLinkDestination(tab: .atlas, stack: [.pitch(pitch)]), entry.id)
            } else {
                XCTAssertEqual(landed, DeepLinkDestination(tab: .index, stack: [.basicFile(entry)]), entry.id)
            }
        }
    }

    func testForeignAndUnknownLinksAreIgnored() {
        XCTAssertNil(destination("https://pitch-atlas.com/learn/spin"))
        XCTAssertNil(destination("pitchatlas://nowhere"))
        XCTAssertNil(destination("pitchatlas://tab/bogus"))
        // CompareSelection owns compare links.
        XCTAssertNil(destination("pitchatlas://compare?a=slider&b=sweeper"))
    }

    func testALinkReplacesTheStackOnItsTab() {
        let router = DeepLinkRouter()
        router.handle(URL(string: "pitchatlas://learn/spin")!, store: store)
        XCTAssertEqual(router.selection, .atlas)
        XCTAssertEqual(router.atlasPath.count, 2)

        router.handle(URL(string: "pitchatlas://about")!, store: store)
        XCTAssertEqual(router.atlasPath.count, 1, "a second link lands in place instead of stacking on the first")

        router.handle(URL(string: "pitchatlas://repertoire/split-finger-fastball")!, store: store)
        XCTAssertEqual(router.selection, .index)
        XCTAssertEqual(router.indexPath.count, 1)
        XCTAssertEqual(router.atlasPath.count, 1, "another tab's stack is left alone")

        router.handle(URL(string: "pitchatlas://nowhere")!, store: store)
        XCTAssertEqual(router.selection, .index, "an unknown link changes nothing")
    }
}
