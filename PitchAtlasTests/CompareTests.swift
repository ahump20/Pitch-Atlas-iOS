import XCTest
@testable import PitchAtlas

/// The compare table, read the way the site's compare/selection.ts, ComparePage.tsx,
/// inspector/BenchBody.tsx and lib/flightPath.ts read a pair (web 47e21e6). The
/// expected rows are the bundle's own contacts.
final class CompareTests: XCTestCase {
    private let store = PitchStore()

    private func pitch(_ slug: String) throws -> PitchAtlasEntry {
        try XCTUnwrap(store.pitch(slug: slug), "\(slug) is not in the bundle")
    }

    private func link(_ query: String) throws -> URL {
        try XCTUnwrap(URL(string: "pitchatlas://compare?\(query)"))
    }

    // MARK: - The pair

    /// Swap trades the two places; each pitch keeps the master variant picked for
    /// it. With a place empty there is nothing to swap.
    func testSwapExchangesAAndBAndKeepsBothVariants() throws {
        let state = CompareSelection()
        let four = try pitch("four-seam"), slider = try pitch("slider")
        state.add(four.slug)
        state.add(slider.slug)
        XCTAssertTrue(state.canSwap)
        state.selectVariant(0, for: four)
        state.selectVariant(slider.masterVariants.isEmpty ? -1 : slider.masterVariants.count - 1, for: slider)
        let sliderVariant = state.variantIndex(for: slider)
        state.swap()
        XCTAssertEqual(state.a, "slider")
        XCTAssertEqual(state.b, "four-seam")
        XCTAssertEqual(state.variantIndex(for: four), 0)
        XCTAssertEqual(state.variantIndex(for: slider), sliderVariant)

        state.set(.b, to: nil, store: store)
        XCTAssertFalse(state.canSwap)
        state.swap()
        XCTAssertEqual(state.a, "slider")
        XCTAssertNil(state.b)
    }

    /// The pickers' reset clears the table (the site's "Clear comparison") and
    /// keeps the aspect, the hand and the view the reader chose.
    func testResetClearsThePairAndKeepsTheView() throws {
        let state = CompareSelection()
        XCTAssertTrue(state.handle(try link("a=slider&b=sweeper&view=movement&hand=left&orientation=thumb"), store: store))
        state.clear()
        XCTAssertNil(state.a)
        XCTAssertNil(state.b)
        XCTAssertTrue(state.slugs.isEmpty)
        XCTAssertEqual(state.mode, .movement)
        XCTAssertEqual(state.hand, .left)
        XCTAssertEqual(state.orientation, .thumb)
    }

    /// A picker fills one place; a pitch already in the other place cannot be
    /// doubled, and a pitch the bundle lacks leaves the place open.
    func testPickersNeverDoubleAPitchOrInventOne() {
        let state = CompareSelection()
        state.set(.a, to: "slider", store: store)
        state.set(.b, to: "slider", store: store)
        XCTAssertEqual(state.a, "slider")
        XCTAssertNil(state.b)
        state.set(.b, to: "not-bundled", store: store)
        XCTAssertNil(state.b)
        state.set(.b, to: "sweeper", store: store)
        XCTAssertEqual(state.slugs, ["slider", "sweeper"])
    }

    /// Compare fills A, then B; a third pitch waits for the reader to choose which
    /// place it takes, and the other stays.
    func testAddFillsAThenBThenAsksWhichToReplace() {
        let state = CompareSelection()
        state.add("four-seam")
        state.add("slider")
        XCTAssertEqual(state.slugs, ["four-seam", "slider"])
        state.add("sweeper")
        XCTAssertEqual(state.pending, "sweeper")
        XCTAssertEqual(state.slugs, ["four-seam", "slider"])
        state.replace(.a)
        XCTAssertEqual(state.slugs, ["sweeper", "slider"])
        XCTAssertNil(state.pending)
        state.add("slider")
        XCTAssertNil(state.pending, "a pitch already at the table is not asked about again")
        XCTAssertEqual(state.slugs, ["sweeper", "slider"])
    }

    // MARK: - The link

    /// compare?a=slider&b=sweeper opens the pair under the site's defaults, and the
    /// table's own link reads back the same choices.
    func testTheCompareLinkRoundTrips() throws {
        let state = CompareSelection()
        XCTAssertTrue(state.handle(try link("a=slider&b=sweeper"), store: store))
        XCTAssertEqual(state.a, "slider")
        XCTAssertEqual(state.b, "sweeper")
        XCTAssertEqual(state.mode, .grips)
        XCTAssertEqual(state.hand, .right)
        XCTAssertEqual(state.orientation, .top)
        XCTAssertTrue(state.presented)

        let full = CompareSelection()
        XCTAssertTrue(full.handle(try link("a=four-seam&b=slider&view=movement&hand=left&orientation=thumb"), store: store))
        let again = CompareSelection()
        XCTAssertTrue(again.handle(full.link, store: store))
        XCTAssertEqual(again.a, "four-seam")
        XCTAssertEqual(again.b, "slider")
        XCTAssertEqual(again.mode, .movement)
        XCTAssertEqual(again.hand, .left)
        XCTAssertEqual(again.orientation, .thumb)
        XCTAssertEqual(again.link, full.link)
    }

    /// A link is read the site's way: a pitch it cannot find leaves its place open,
    /// a doubled pitch keeps only A, and a bad view or hand falls back to the
    /// defaults — never a guessed pitch.
    func testLinksNormalizeWithoutInventingDefaults() throws {
        let state = CompareSelection()
        XCTAssertTrue(state.handle(try link("a=bogus&b=four-seam&hand=bad&view=bad"), store: store))
        XCTAssertNil(state.a)
        XCTAssertEqual(state.b, "four-seam")
        XCTAssertEqual(state.mode, .grips)
        XCTAssertEqual(state.hand, .right)
        XCTAssertTrue(state.handle(try link("a=slider&b=slider"), store: store))
        XCTAssertEqual(state.a, "slider")
        XCTAssertNil(state.b)
        XCTAssertFalse(state.handle(try XCTUnwrap(URL(string: "pitchatlas://grips")), store: store))
    }

    // MARK: - The bench

    /// The site's words: the aspects, the empty table, the study links.
    func testTheTableSpeaksTheSitesWords() throws {
        XCTAssertEqual(CompareSelection.Mode.allCases.map(BenchReads.tabLabel), ["Grip", "Release", "Flight"])
        XCTAssertEqual(BenchReads.emptyTitle(chosen: 0), "Start with two pitches.")
        XCTAssertEqual(BenchReads.emptyTitle(chosen: 1), "Bring another pitch to the table.")
        let slider = try pitch("slider")
        XCTAssertEqual(BenchReads.studyLabel(slider, pair: true, mode: .grips), "Study Slider")
        XCTAssertEqual(BenchReads.studyLabel(slider, pair: false, mode: .cues), "Study release")
        XCTAssertEqual(BenchReads.studyLabel(slider, pair: false, mode: .movement), "Study movement")
        XCTAssertEqual(BenchReads.stageChip(slider), "Seam-informed schematic")
        XCTAssertEqual(BenchReads.stageChip(try pitch("eephus")), "No canonical grip on file")
    }

    /// The fingers either hand puts on the ball, in hand order, matched by finger
    /// (never by label); the circle change's fourth finger gets its own row.
    func testFingerRowsMatchByFingerInHandOrder() throws {
        let pair = [try pitch("slider"), try pitch("sweeper")]
        let rows = BenchReads.fingerRows(pair)
        XCTAssertEqual(rows.map(\.finger), [.index, .middle, .thumb])
        XCTAssertEqual(rows.map { $0.contacts.map { $0?.label } },
                       [["Index off-center", "Index around the side"], ["Middle seam", "Middle seam"], ["Thumb", "Thumb"]])

        let circle = BenchReads.fingerRows([try pitch("four-seam"), try pitch("circle-change")])
        XCTAssertEqual(circle.map(\.finger), [.index, .middle, .ring, .thumb])
        XCTAssertNil(circle[2].contacts[0], "the four-seam puts no ring finger on the ball")
        XCTAssertEqual(circle[2].contacts[1]?.label, "Ring pad")
        XCTAssertEqual(BenchReads.fingerName(.pinky), "Pinky")
    }

    /// A finger is marked where the two hands differ in how it meets the ball or
    /// how hard it works; a missing contact is never a difference.
    func testDiffersMarksOnlyAChangedHold() throws {
        let circle = BenchReads.fingerRows([try pitch("four-seam"), try pitch("circle-change")])
        XCTAssertEqual(circle.map { BenchReads.differs($0.contacts[0], $0.contacts[1]) }, [true, false, false, false])
        let sweep = BenchReads.fingerRows([try pitch("slider"), try pitch("sweeper")])
        XCTAssertFalse(sweep.contains { BenchReads.differs($0.contacts[0], $0.contacts[1]) })
    }

    // MARK: - The flight figure

    /// A point on a pitch's path a fraction t of the way down (the cubic from the
    /// release), as TunnelPlot.test.ts reads it.
    private func at(_ s: FlightPath.Spot, _ t: Double) -> (x: Double, y: Double) {
        let u = 1 - t
        return (u * u * u * FlightPath.cx + 3 * u * u * t * s.c1x + 3 * u * t * t * s.c2x + t * t * t * s.x,
                u * u * u * FlightPath.releaseY + 3 * u * u * t * s.c1y + 3 * u * t * t * s.c2y + t * t * t * s.y)
    }

    private func sign(_ n: Double) -> Int { abs(n) < 1e-9 ? 0 : (n > 0 ? 1 : -1) }

    /// Ported from the site: every path bends toward the side its own shape words
    /// name, rides above or drops below the spinless line as they say, and falls
    /// the whole way from the mound — for either hand, every filed pitch.
    func testEveryPathBendsTowardItsStatedSideAndFalls() {
        for hand in [1.0, -1.0] {
            for entry in store.pitches {
                let m = entry.motion
                let s = FlightPath.plot(m, handFactor: hand)
                let side = m.horizontalDir == .armSide ? Int(hand) : m.horizontalDir == .gloveSide ? -Int(hand) : 0
                let down = m.verticalShape == .drop ? 1 : m.verticalShape == .ride ? -1 : 0
                for t in [0.25, 0.5, 0.75, 1] {
                    let p = at(s, t)
                    let spinless = FlightPath.releaseY + t * (FlightPath.cy - FlightPath.releaseY)
                    XCTAssertEqual(sign(p.x - FlightPath.cx), side, "\(entry.slug) at \(t), hand \(hand)")
                    XCTAssertEqual(sign(p.y - spinless), down, "\(entry.slug) at \(t), hand \(hand)")
                }
                for i in 1...40 {
                    XCTAssertGreaterThan(at(s, Double(i) / 40).y, at(s, Double(i - 1) / 40).y, "\(entry.slug) climbs")
                }
            }
        }
    }

    /// Two pitches that break the same way are nudged apart so both read; the
    /// Magnus share is the spin axis's part across the line of flight.
    func testAPairBreakingTheSameWayIsNudgedApart() throws {
        let slider = try pitch("slider").motion, sweeper = try pitch("sweeper").motion
        XCTAssertFalse(FlightPath.sameCell(slider, sweeper))
        XCTAssertTrue(FlightPath.sameCell(slider, slider))
        XCTAssertEqual(FlightPath.magnusStrength(Vec3(x: 0, y: 0, z: 2)), 0, accuracy: 1e-9)
        XCTAssertEqual(FlightPath.magnusStrength(Vec3(x: 3, y: 4, z: 0)), 1, accuracy: 1e-9)
        XCTAssertEqual(FlightPath.magnusStrength(Vec3(x: 0, y: 0, z: 0)), 0)
        let apart = FlightPath.plot(slider, handFactor: 1, nudge: -26)
        XCTAssertEqual(apart.x, FlightPath.plot(slider, handFactor: 1).x - 26, accuracy: 1e-9)
    }
}
