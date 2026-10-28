import SwiftUI
import XCTest
@testable import PitchAtlas

/// The Craftsmen hall and a craftsman's file, read the way CraftsmenHall.tsx,
/// CraftsmanMedia.tsx and CraftsmanChapter.tsx read the record. The expected
/// words are the ones pitch-atlas.com printed on /craftsmen and
/// /craftsmen/greg-maddux (web 47e21e6).
final class CraftsmenHallTests: XCTestCase {
    private let store = PitchStore()

    private func craftsman(_ slug: String) throws -> Craftsman {
        try XCTUnwrap(store.craftsman(slug: slug), "\(slug) is not in the bundle")
    }

    // MARK: - The hall

    /// CRAFTSMEN_BY_ERA: the masters by the year their era began (file order
    /// breaking a tie, as the site's stable sort does), then the legend.
    func testTheHallFilesMastersByEraStartThenTheLegend() throws {
        let order = store.craftsmenByEra
        XCTAssertEqual(order.count, store.craftsmen.count, "every craftsman is filed once")
        XCTAssertEqual(Set(order.map(\.slug)).count, order.count)
        let masters = order.prefix { $0.kind == .craftsman }
        XCTAssertEqual(masters.count, store.craftsmen.filter { $0.kind == .craftsman }.count, "the legend comes after every master")
        let starts = masters.map { EraSpan.parse($0.era)?.start ?? Int.max }
        XCTAssertEqual(starts, starts.sorted())
        XCTAssertEqual(masters.first?.slug, "carl-hubbell")
        XCTAssertEqual(masters.last?.slug, "jurrangelo-cijntje")
        // Skenes and Cijntje both began in 2024; Skenes is filed first in the record
        let skenes = try XCTUnwrap(order.firstIndex { $0.slug == "paul-skenes" })
        let cijntje = try XCTUnwrap(order.firstIndex { $0.slug == "jurrangelo-cijntje" })
        XCTAssertLessThan(skenes, cijntje)
        XCTAssertEqual(order.last?.slug, "gyroball")
    }

    /// craftsmenForPitch reads the same chronology.
    func testThePitchsMastersAreTheHallsOrderFiltered() {
        for pitch in store.pitches {
            XCTAssertEqual(store.masters(forPitch: pitch.slug).map(\.slug),
                           store.craftsmenByEra.filter { $0.kind == .craftsman && $0.signaturePitchSlug == pitch.slug }.map(\.slug))
        }
    }

    /// The note under "C The masters" reads its bookends off the data.
    func testTheMastersNoteReadsTheChronologysRealBookends() throws {
        let masters = store.craftsmenByEra.filter { $0.kind == .craftsman }
        XCTAssertEqual(CraftsmenHallReads.mastersNote(masters),
                       "\(masters.count) arms, filed in the order their eras began: 1928 to Jurrangelo Cijntje. Each card's band is the career laid against the same century; the longer the bar, the longer the arm lasted.")
        XCTAssertNil(CraftsmenHallReads.mastersNote([]), "no bookends, no sentence")
    }

    /// featuredCraftsmanMedia: Ryan, Rivera, Skenes, the first filed clip each.
    func testTheFilmShelfFeaturesRyanRiveraSkenesFirstClipEach() {
        let featured = CraftsmenHallReads.featuredFilm(store.craftsmanMedia)
        XCTAssertEqual(featured.map(\.craftsmanSlug), ["nolan-ryan", "mariano-rivera", "paul-skenes"])
        XCTAssertEqual(featured.map(CraftsmenHallReads.frameLabel), ["TikTok embed", "X embed", "TikTok embed"])
        XCTAssertEqual(featured.map { MediaShelf.monthYear($0.retrievedAt) }, ["JUN 2026", "JUN 2026", "JUN 2026"])

        let ryan = featured[0]
        let second = CraftsmanMediaItem(kind: "tiktok", id: "second", title: ryan.title, lede: ryan.lede, author: ryan.author,
                                        authorUrl: ryan.authorUrl, url: ryan.url, retrievedAt: ryan.retrievedAt,
                                        craftsmanSlug: "nolan-ryan", craftsmanName: ryan.craftsmanName, clip: nil)
        let elsewhere = CraftsmanMediaItem(kind: "tiktok", id: "elsewhere", title: ryan.title, lede: ryan.lede, author: ryan.author,
                                           authorUrl: ryan.authorUrl, url: ryan.url, retrievedAt: ryan.retrievedAt,
                                           craftsmanSlug: "greg-maddux", craftsmanName: "Greg Maddux", clip: nil)
        XCTAssertEqual(CraftsmenHallReads.featuredFilm([second, elsewhere, ryan]).map(\.id), ["second"],
                       "one clip per featured arm, the first filed; an arm outside the three stays off the shelf")
        XCTAssertEqual(CraftsmenHallReads.featuredFilm([]), [])
    }

    // MARK: - A craftsman's file

    /// The stage kicker: kind, era, and the hand when the record has one.
    func testTheFileKickerNamesKindEraAndHand() throws {
        XCTAssertEqual(CraftsmanFileReads.kicker(try craftsman("greg-maddux")), "Master · 1986-2008 · right-handed")
        XCTAssertEqual(CraftsmanFileReads.kicker(try craftsman("johan-santana")), "Master · 2000-2012 · left-handed")
        XCTAssertEqual(CraftsmanFileReads.kicker(try craftsman("jurrangelo-cijntje")), "Master · 2024-present")
        XCTAssertEqual(CraftsmanFileReads.kicker(try craftsman("gyroball")), "Legend · Designed 2001")
    }

    /// "In this craftsman file": the arm, the signature pitch, and the record
    /// only when one is filed.
    func testTheFileChaptersAreTheArmTheSignatureAndAFiledRecord() throws {
        let maddux = CraftsmanFileReads.chapters(try craftsman("greg-maddux"))
        XCTAssertEqual(maddux.map(\.title), ["The arm", "Signature pitch", "The record"])
        XCTAssertEqual(maddux.map(\.id), ["story", "signature", "record"])
        XCTAssertEqual(CraftsmanFileReads.chapters(try craftsman("gyroball")).map(\.title), ["The arm", "Signature pitch"])
    }

    /// The second room is the mental edge, else the pitcher's own words; the
    /// legend's record would follow its myth-and-physics room.
    func testTheRoomsFollowWhatTheFileHolds() throws {
        XCTAssertEqual(CraftsmanFileReads.secondRoom(try craftsman("greg-maddux")), "The mental edge")
        XCTAssertEqual(CraftsmanFileReads.secondRoom(try craftsman("gyroball")), "In their words")
        XCTAssertNil(CraftsmanFileReads.secondRoom(try stripped(try craftsman("gyroball"), ["quote"])))
        XCTAssertEqual(CraftsmanFileReads.recordIndex(try craftsman("greg-maddux")), "03")
        XCTAssertEqual(CraftsmanFileReads.recordIndex(try craftsman("gyroball")), "04")
    }

    /// Chapter to chapter in the hall's chronology: the next era.
    func testTheFileWalksTheHallInEraOrder() throws {
        let order = store.craftsmenByEra
        let maddux = CraftsmanFileReads.neighbors(of: try craftsman("greg-maddux"), in: order)
        XCTAssertEqual(maddux.prev?.slug, "roger-clemens")
        XCTAssertEqual(maddux.next?.slug, "mariano-rivera")
        let first = CraftsmanFileReads.neighbors(of: try craftsman("carl-hubbell"), in: order)
        XCTAssertNil(first.prev)
        XCTAssertEqual(first.next?.slug, "bob-gibson")
        let last = CraftsmanFileReads.neighbors(of: try craftsman("gyroball"), in: order)
        XCTAssertEqual(last.prev?.slug, "jurrangelo-cijntje")
        XCTAssertNil(last.next)
        let missing = CraftsmanFileReads.neighbors(of: try craftsman("greg-maddux"), in: [])
        XCTAssertNil(missing.prev)
        XCTAssertNil(missing.next)
    }

    /// The signature pitch's two ways on, named in lower case as the site sets them.
    func testTheSignatureLinksNameThePitch() throws {
        let pitch = try XCTUnwrap(store.pitch(slug: "two-seam"))
        XCTAssertEqual(CraftsmanFileReads.studyLink(pitch), "Study the two-seam fastball")
        XCTAssertEqual(CraftsmanFileReads.inspectLink(pitch), "Inspect the two-seam grip")
        XCTAssertEqual(CraftsmanFileReads.mediaTitle(try craftsman("greg-maddux")), "Greg Maddux, still teaching.")
    }

    // MARK: - The bound paper

    /// `.archive-paper` re-inks the claim kit: mono labels read its ink-2, the
    /// ink-2/ink-3 classes its muted tone, links its warm gold.
    func testThePaperReinksTheClaimKit() {
        XCTAssertEqual(InkContext.paper.labelRGB, 0xCEC4B8)
        XCTAssertEqual(InkContext.paper.text2RGB, 0xC8BBAE)
        XCTAssertEqual(InkContext.paper.text3RGB, 0xC8BBAE)
        XCTAssertEqual(InkContext.paper.inkRGB, 0xEEE9DF)
        XCTAssertEqual(InkContext.paper.linkRGB, 0xE4B182)
        XCTAssertEqual(InkContext.void.labelRGB, WebTokens.Palette.ink2.rgb, "the void keeps the site's ink-2")
        XCTAssertEqual(InkContext.void.inkRGB, WebTokens.Palette.bone.rgb)
        XCTAssertEqual(InkContext.void.linkRGB, WebTokens.Palette.ink2.rgb)
    }

    /// The paper's 120° stock is laid the CSS way: 90° runs left to right, 180°
    /// top to bottom, and 45° on a square runs corner to corner.
    func testACSSGradientLineRunsThroughTheBoxAtItsAngle() {
        let flat = CSSGradientLine.points(degrees: 90, size: CGSize(width: 200, height: 100))
        XCTAssertEqual(flat.start.x, 0, accuracy: 1e-9)
        XCTAssertEqual(flat.start.y, 0.5, accuracy: 1e-9)
        XCTAssertEqual(flat.end.x, 1, accuracy: 1e-9)
        XCTAssertEqual(flat.end.y, 0.5, accuracy: 1e-9)
        let down = CSSGradientLine.points(degrees: 180, size: CGSize(width: 200, height: 100))
        XCTAssertEqual(down.start.y, 0, accuracy: 1e-9)
        XCTAssertEqual(down.end.y, 1, accuracy: 1e-9)
        let diagonal = CSSGradientLine.points(degrees: 45, size: CGSize(width: 100, height: 100))
        XCTAssertEqual(diagonal.start.x, 0, accuracy: 1e-9)
        XCTAssertEqual(diagonal.start.y, 1, accuracy: 1e-9)
        XCTAssertEqual(diagonal.end.x, 1, accuracy: 1e-9)
        XCTAssertEqual(diagonal.end.y, 0, accuracy: 1e-9)
    }

    // MARK: - Helpers

    /// The craftsman with some fields removed, through the bundle's own coding.
    private func stripped(_ c: Craftsman, _ keys: [String]) throws -> Craftsman {
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(c)) as? [String: Any])
        keys.forEach { object.removeValue(forKey: $0) }
        return try JSONDecoder().decode(Craftsman.self, from: JSONSerialization.data(withJSONObject: object))
    }
}
