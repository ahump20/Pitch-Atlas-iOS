import XCTest
@testable import PitchAtlas

/// The Flight Lab page and its flat schematic, pinned to web 47e21e6:
/// pages/SoftballFlightLabPage.tsx and components/flightlab/FlightLabSchematic.tsx.
/// The default batter (the measured swing) on the belt lob under USSSA reads
/// "Your pitch", look for 6–37, the barrel 44 in high and 31 in out front, and
/// the ball 20 in over the plate.
final class FlightLabPageTests: XCTestCase {
    private let store = PitchStore()

    private func model(_ rule: SlowpitchRuleKey = .usssa, lob: String = "belt") throws -> FlightLabModel {
        let content = try XCTUnwrap(store.flightLab)
        let s = FlightLab.DEFAULT_SETTINGS
        let stance = SlowpitchStance(heightIn: s.heightIn, toesIn: s.toesIn, box: s.box,
                                     batIn: content.measuredBatter.bat.value.lengthIn)
        return try XCTUnwrap(FlightLab.buildLabModel(rule: rule, stance: stance, compareIn: s.compareIn,
                                                     params: FlightLab.defaultLobParams(content.lobs), selected: lob,
                                                     lobs: content.lobs, rulebooks: content.rulebooks))
    }

    func testTheStoreCarriesTheFlightLab() throws {
        let content = try XCTUnwrap(store.flightLab)
        XCTAssertEqual(content.rulebooks.map(\.key), [.usssa, .usa, .senior])
        XCTAssertEqual(content.lobs.count, 6)
    }

    func testTheSchematicTagsReadTheDefaultBatter() throws {
        let m = try model()
        XCTAssertEqual(m.selected.reading.verdict.short, "Your pitch")
        XCTAssertEqual(FlightLabReads.barrelText(m, narrow: false), "Barrel · 44 in high · 31 in out front")
        XCTAssertEqual(FlightLabReads.barrelText(m, narrow: true), "Barrel 44 in")
        XCTAssertEqual(FlightLabReads.crossingText(m, narrow: false), "Over the plate · 20 in")
        XCTAssertEqual(FlightLabReads.crossingText(m, narrow: true), "Plate 20")
        XCTAssertEqual(FlightLabReads.pitchLine(m), "YOUR PITCH · 6–37 IN")
        let strike = m.selected.reading.strikeWindowIn
        XCTAssertEqual(FlightLabReads.strikeLine(m),
                       "STRIKE · \(FlightLab.round(strike.0))–\(FlightLab.round(strike.1)) IN")
    }

    func testTheLandmarksDropShoulderAndKneeUnderSeniorRules() throws {
        let m = try model()
        let tags = FlightLabReads.landmarkTags(m, narrow: false).map(\.text)
        XCTAssertEqual(tags.count, 4)
        XCTAssertEqual(tags.first, "Shoulder · \(FlightLab.round(m.zone.top / Slowpitch.IN)) in")
        XCTAssertEqual(tags.last, "Front knee · \(FlightLab.round(m.zone.bottom / Slowpitch.IN)) in")
        XCTAssertEqual(FlightLabReads.landmarkTags(m, narrow: true).map(\.text)[1],
                       "Chest \(FlightLab.round(m.marks.chest / Slowpitch.IN))")
        let senior = try model(.senior)
        XCTAssertEqual(FlightLabReads.landmarkTags(senior, narrow: false).map(\.text),
                       ["Chest · \(FlightLab.round(senior.marks.chest / Slowpitch.IN)) in",
                        "Belt · \(FlightLab.round(senior.marks.belt / Slowpitch.IN)) in"])
        XCTAssertNil(FlightLabReads.strikeLine(senior))
    }

    func testThePageWordsReadTheSelectedLob() throws {
        let m = try model()
        let sel = m.selected
        XCTAssertEqual(FlightLabReads.statusText(m),
                       "\(sel.name): \(sel.reading.verdict.word). Look for 6 to 37 inches past the front of the plate.")
        XCTAssertEqual(FlightLabReads.lookForBody(m),
                       "Look for it to land 6 to 37 in past the front of the plate. " + FlightLabReads.whySentence)
        let stats = FlightLabReads.thisPitchStats(m)
        XCTAssertEqual(stats.map(\.label), ["Arc peak", "Over the plate", "At your barrel", "Falling at", "Strike window"])
        XCTAssertEqual(stats[2].value, "44")
        XCTAssertEqual(stats[2].unit, "in, 31 in out")
        XCTAssertTrue(try FlightLabReads.thisPitchStats(model(.senior)).last!.value.hasPrefix("0–"))
    }

    /// Review Focus 4: every lob at every slider extreme, under every rulebook,
    /// either converges or carries the unsolved flag the page shows; no NaN or
    /// infinity reaches the drawing or the words.
    func testTheSliderExtremesNeverDrawANaN() throws {
        let content = try XCTUnwrap(store.flightLab)
        let base = FlightLab.defaultLobParams(content.lobs)
        let s = FlightLab.DEFAULT_SETTINGS
        for heightIn in [FlightLab.HEIGHT_RANGE.min, FlightLab.HEIGHT_RANGE.max] {
            for rule in SlowpitchRuleKey.allCases {
                for lob in content.lobs {
                    for (apex, land, side) in [(4.2, -30.0, -24.0), (13.0, 150.0, 24.0), (4.2, 150.0, 0.0), (13.0, -30.0, 0.0)] {
                        var p = try XCTUnwrap(base[lob.key])
                        p.apex = apex; p.land = land; p.side = side
                        let stance = SlowpitchStance(heightIn: heightIn, toesIn: s.toesIn, box: s.box, batIn: 34)
                        let m = try XCTUnwrap(FlightLab.buildLabModel(rule: rule, stance: stance, compareIn: 32, params: [lob.key: p],
                                                                      selected: lob.key, lobs: content.lobs, rulebooks: content.rulebooks))
                        let f = m.selected.flight
                        let tag = "\(rule) \(lob.key) h\(heightIn) apex \(apex) land \(land) side \(side)"
                        XCTAssertTrue(f.positions.allSatisfy(\.isFinite), "positions: \(tag)")
                        XCTAssertTrue(f.crossing.y.isFinite && f.land.z.isFinite && f.duration.isFinite, "flight: \(tag)")
                        let r = m.selected.reading
                        XCTAssertTrue(r.apexFt.isFinite && r.overPlateIn.isFinite && r.fallingAngleDeg.isFinite, "reading: \(tag)")
                        if let b = r.barrel { XCTAssertTrue(b.heightIn.isFinite && b.outFrontIn.isFinite, "barrel: \(tag)") }
                        let words = [FlightLabReads.statusText(m), FlightLabReads.stageLabel(m)]
                            + FlightLabReads.thisPitchStats(m).map { $0.value + $0.unit }
                        XCTAssertFalse(words.contains { $0.contains("NaN") || $0.contains("inf") }, "words: \(tag)")
                    }
                }
            }
        }
    }

    func testTheLobLineSpeaksNoSpinOrSpeed() {
        let p = SlowpitchLobParams(apex: 10, land: 6, side: -3, rpm: 900, push: 0)
        XCTAssertEqual(FlightLabReads.lobLine(p), "Peaks at 10.0 ft, lands 6 in past the front of the plate, 3 in inside.")
    }

    func testTheFlightLabRoutesWithItsRulebook() throws {
        func dest(_ path: String) throws -> DeepLinkDestination? {
            DeepLinkRouter.destination(for: try XCTUnwrap(URL(string: "pitchatlas://\(path)")), store: store)
        }
        func lab(_ rule: SlowpitchRuleKey) -> DeepLinkDestination {
            DeepLinkDestination(tab: .atlas, stack: [.atlas(.softball), .atlas(.flightLab(rule: rule))])
        }
        XCTAssertEqual(try dest("softball/flight-lab"), lab(.usssa))
        XCTAssertEqual(try dest("softball/flight-lab?rule=senior"), lab(.senior))
        XCTAssertEqual(try dest("softball/flight-lab?rule=usa"), lab(.usa))
        XCTAssertEqual(try dest("softball/flight-lab?rule=bogus"), lab(.usssa))
    }
}
