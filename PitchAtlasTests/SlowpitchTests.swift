import XCTest
@testable import PitchAtlas

// =============================================================================
// Slow-pitch Flight Lab — ported tests
// =============================================================================
// A line-for-line port of the web repo's tests (github.com/ahump20/Pitch-Atlas
// @ 47e21e6):
//   src/lib/slowpitch/zone.test.ts, batter.test.ts, flight.test.ts,
//   verdict.test.ts, and src/components/flightlab/model.test.ts.
// Each web `it(...)` is one test method. Expected values are the web tests'
// own; none were changed to make the port pass. `toBeCloseTo(x, n)` is
// |a − b| < 0.5·10^−n (strict), which `assertClose` reproduces.
//
// The verdict and model tests on the web import EXAMPLE_LOBS from
// src/data/softball/flightLab.ts. That content ships to the app as generated
// JSON (Resources/Content/flight-lab.json), never as Swift literals; until it
// lands, the six lob param sets are decoded here from a test fixture copied
// verbatim from that file, through the same `FlightLabLob` Decodable the app
// uses. `testFixtureLobsMatchBundledFlightLabJSON` pins the fixture to the
// bundle once the JSON is generated.
// =============================================================================

final class SlowpitchTests: XCTestCase {

    // MARK: - Helpers

    /// vitest `toBeCloseTo(expected, digits)`: |expected − received| < 10^−digits / 2.
    private func assertClose(
        _ received: Double, _ expected: Double, _ digits: Int = 2,
        _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line
    ) {
        let tolerance = pow(10, -Double(digits)) / 2
        XCTAssertTrue(
            abs(expected - received) < tolerance,
            "expected \(received) to be close to \(expected) (±\(tolerance)) \(message())",
            file: file, line: line
        )
    }

    /// JS `Math.round`: round half toward +∞.
    private func jsRound(_ x: Double) -> Double {
        let floor = x.rounded(.down)
        return x - floor >= 0.5 ? floor + 1 : floor
    }

    /// The six example lobs, verbatim from src/data/softball/flightLab.ts
    /// (EXAMPLE_LOBS) in the shape the content generator emits.
    static let lobFixtureJSON = """
    [
      { "key": "belt", "name": "Belt-high lob", "color": "#bf5700", "params": { "value": { "apex": 9, "land": 36, "side": 0, "rpm": 110, "push": 0 }, "confidence": "unverified", "note": "Example arc, set by hand." } },
      { "key": "low", "name": "Low strike", "color": "#cdba8e", "params": { "value": { "apex": 6.5, "land": 31, "side": 0, "rpm": 150, "push": 0 }, "confidence": "unverified", "note": "Example arc, set by hand." } },
      { "key": "deep", "name": "Deep strike", "color": "#7fc6ff", "params": { "value": { "apex": 9, "land": 85, "side": 0, "rpm": 110, "push": 0 }, "confidence": "unverified", "note": "Example arc, set by hand." } },
      { "key": "inside", "name": "Inside lob", "color": "#ff2d44", "params": { "value": { "apex": 9, "land": 36, "side": -8, "rpm": 110, "push": 0 }, "confidence": "unverified", "note": "Example arc, set by hand." } },
      { "key": "flat", "name": "Flat lob", "color": "#34e27e", "params": { "value": { "apex": 6.5, "land": 66, "side": 0, "rpm": 150, "push": 0 }, "confidence": "unverified", "note": "Example arc, set by hand." } },
      { "key": "rainbow", "name": "Rainbow", "color": "#6f8cb0", "params": { "value": { "apex": 11.6, "land": 26, "side": 0, "rpm": 80, "push": 0 }, "confidence": "unverified", "note": "Example arc, set by hand." } }
    ]
    """

    static let exampleLobs: [FlightLabLob] = {
        // A broken fixture is a test bug; fail loudly.
        // swiftlint:disable:next force_try
        try! JSONDecoder().decode([FlightLabLob].self, from: Data(lobFixtureJSON.utf8))
    }()

    private func lob(_ key: String) throws -> SlowpitchFlight {
        let found = try XCTUnwrap(Self.exampleLobs.first { $0.key == key }, "no lob \(key)")
        return Slowpitch.solveLob(found.params.value)
    }

    private static let belt = SlowpitchLobParams(apex: 9, land: 36, side: 0, rpm: 110, push: 0)

    private static var defaultStance: SlowpitchStance { Slowpitch.DEFAULT_STANCE }

    private static func stance(
        heightIn: Double? = nil, toesIn: Double? = nil, box: SlowpitchBoxPosition? = nil, batIn: Double? = nil
    ) -> SlowpitchStance {
        var s = Slowpitch.DEFAULT_STANCE
        if let heightIn { s.heightIn = heightIn }
        if let toesIn { s.toesIn = toesIn }
        if let box { s.box = box }
        if let batIn { s.batIn = batIn }
        return s
    }

    func testFixtureLobsMatchBundledFlightLabJSON() throws {
        guard let url = Bundle.main.url(forResource: "flight-lab", withExtension: "json") else {
            throw XCTSkip("flight-lab.json is not generated into the bundle yet")
        }
        let content = try JSONDecoder().decode(FlightLabContent.self, from: Data(contentsOf: url))
        XCTAssertEqual(content.lobs.map(\.key), Self.exampleLobs.map(\.key))
        XCTAssertEqual(content.lobs.map(\.params.value), Self.exampleLobs.map(\.params.value))
    }

    // MARK: - zone.test.ts

    // legal arc window
    func testLegalArcWindowUSSSAMeasuresItsThreeFootFloorFromTheHand() {
        let (min, max) = Slowpitch.legalArcWindow(.usssa)
        assertClose(min, 5.8215, 3)
        XCTAssertEqual(max, 10)
    }

    func testLegalArcWindowUSAAdultIsSixToTenAndSeniorSixToTwelve() {
        let usa = Slowpitch.legalArcWindow(.usa)
        XCTAssertEqual(usa.0, 6)
        XCTAssertEqual(usa.1, 10)
        let senior = Slowpitch.legalArcWindow(.senior)
        XCTAssertEqual(senior.0, 6)
        XCTAssertEqual(senior.1, 12)
    }

    // zone bounds
    func testZoneBoundsRunKneeToShoulderForTheFiveFootTwoBatter() {
        let z = Slowpitch.zoneBounds(62)
        assertClose(z.bottom / Slowpitch.IN, 15.004, 2)
        assertClose(z.top / Slowpitch.IN, 48.98, 2)
    }

    // plate and mat
    func testPlateKnowsTheOutline() {
        let plate = Slowpitch.PLATE
        XCTAssertTrue(Slowpitch.insidePlate(0, 0))
        XCTAssertTrue(Slowpitch.insidePlate(0, plate.front + 0.01))
        XCTAssertFalse(Slowpitch.insidePlate(plate.halfWidth + 0.01, 0))
        // The back point is a triangle: a corner behind the sides is off the plate.
        XCTAssertFalse(Slowpitch.insidePlate(plate.halfWidth - 0.01, plate.back - 0.01))
    }

    func testPlateMeasuresDistanceToTheEdge() {
        XCTAssertEqual(Slowpitch.distanceToPlate(0, 0), 0)
        assertClose(Slowpitch.distanceToPlate(Slowpitch.PLATE.halfWidth + 1 * Slowpitch.IN, -0.05) / Slowpitch.IN, 1, 5)
    }

    func testSeniorMatRunsThirtyTwoAndAHalfInchesBackFromTheEndOfThePlateSides() {
        let IN = Slowpitch.IN
        XCTAssertTrue(Slowpitch.onPlateOrMat(0, 30 * IN))
        XCTAssertFalse(Slowpitch.onPlateOrMat(0, 33 * IN))
        XCTAssertFalse(Slowpitch.onPlateOrMat(9 * IN, 10 * IN))
        assertClose(Slowpitch.inchesPastFront(32.5 * IN), 41, 6)
    }

    // MARK: - batter.test.ts

    func testLandmarksScaleTheMeasuredRatiosToHeight() {
        let IN = Slowpitch.IN
        let l = Slowpitch.landmarks(62)
        assertClose(l.knee / IN, 15.004, 3)
        assertClose(l.belt / IN, 31.186, 3)
        assertClose(l.chest / IN, 40.982, 3)
        assertClose(l.shoulder / IN, 48.98, 3)
        XCTAssertEqual(jsRound(Slowpitch.landmarks(66).shoulder / IN), 52)
        XCTAssertEqual(jsRound(Slowpitch.landmarks(54).knee / IN), 13)
    }

    func testSweetSpotReachForAThirtyFourInchBat() {
        let IN = Slowpitch.IN
        assertClose(Slowpitch.sweetSpotReach(62, 34) / IN, 45.8986, 3)
        assertClose(Slowpitch.sweetSpotReach(66, 34) / IN, 47.2714, 3)
        assertClose(Slowpitch.sweetSpotReach(54, 34) / IN, 43.153, 3)
    }

    func testPivotSitsOffThePlateAndAStrideForwardAndTheBoxMovesItSixteenInches() {
        let IN = Slowpitch.IN
        let p = Slowpitch.contactPivot(Self.defaultStance)
        assertClose(p.x / IN, -36.018, 3)
        assertClose(p.z / IN, -9.92, 3)
        assertClose(Slowpitch.contactPivot(Self.stance(box: .front)).z / IN, -25.92, 3)
        assertClose(Slowpitch.contactPivot(Self.stance(box: .back)).z / IN, 6.08, 3)
        assertClose(Slowpitch.contactPivot(Self.stance(toesIn: 10)).x / IN, -24.018, 3)
    }

    func testBallDownTheMiddleMeetsTheBarrelTooCloseJamsTooFarIsOffTheEnd() {
        let IN = Slowpitch.IN
        XCTAssertEqual(Slowpitch.reachAt(Self.defaultStance, 0).side, .barrel)
        XCTAssertEqual(Slowpitch.reachAt(Self.stance(toesIn: 4), -8 * IN).side, .jam)
        XCTAssertEqual(Slowpitch.reachAt(Self.stance(toesIn: 36), 8 * IN).side, .end)
    }

    func testHeightComfortIsFullFromBeltToChestAndFadesPastKneeAndShoulder() {
        let l = Slowpitch.landmarks(62)
        XCTAssertEqual(Slowpitch.heightComfort(62, (l.belt + l.chest) / 2), 1)
        assertClose(Slowpitch.heightComfort(62, l.knee), 0.4, 6)
        assertClose(Slowpitch.heightComfort(62, l.shoulder), 0.45, 6)
        XCTAssertEqual(Slowpitch.heightComfort(62, l.shoulder + 7 * Slowpitch.IN), 0)
    }

    func testThirtyFourInchBatMatchesTheLiveAppAgainstAThirtyTwo() {
        let c = Slowpitch.compareBats(Self.defaultStance, 32)
        XCTAssertEqual(FlightLab.fixed(c.reachGapIn, 1), "2.0")
        XCTAssertEqual(FlightLab.fixed(c.matchShiftIn, 1), "2.4")
        assertClose(c.outFrontIn.0, 28.4497, 3)
        assertClose(c.outFrontIn.1, 25.1487, 3)
    }

    func testThirtyFourInchBatAgainstThirtyOneAndThirtyThreeAndOtherHeights() {
        assertClose(Slowpitch.compareBats(Self.defaultStance, 31).reachGapIn, 2.9544, 3)
        assertClose(Slowpitch.compareBats(Self.defaultStance, 31).matchShiftIn, 3.476, 3)
        assertClose(Slowpitch.compareBats(Self.defaultStance, 33).matchShiftIn, 1.2208, 3)
        assertClose(Slowpitch.compareBats(Self.stance(heightIn: 66), 32).matchShiftIn, 2.4255, 3)
        assertClose(Slowpitch.compareBats(Self.stance(heightIn: 54), 32).matchShiftIn, 2.2789, 3)
    }

    // MARK: - flight.test.ts

    // acceleration
    func testAccelerationIsPureGravityAtRest() {
        assertClose(Slowpitch.acceleration(SlowpitchVec3(0, 1e-9, 0), nil).y, -9.81, 3)
    }

    func testAccelerationDragsAgainstTheMotion() {
        let a = Slowpitch.acceleration(SlowpitchVec3(0, 0, 10), nil)
        XCTAssertLessThan(a.z, 0)
        // `toBe(-0)` is Object.is: negative zero, not just zero.
        XCTAssertEqual(a.x, 0)
        XCTAssertEqual(a.x.sign, .minus)
    }

    func testBackspinLiftsABallTravellingTowardThePlate() {
        let v = SlowpitchVec3(0, 0, 10)
        let lifted = Slowpitch.acceleration(v, Slowpitch.spinVector(v, rpm: 300, push: 0))
        XCTAssertGreaterThan(lifted.y, Slowpitch.acceleration(v, nil).y)
    }

    func testNoSpinNoSpinVector() {
        XCTAssertNil(Slowpitch.spinVector(SlowpitchVec3(0, 1, 1), rpm: 0, push: 0))
    }

    // solveLob, belt-high lob
    func testSolveLobBeltHighHitsTheTargetPeakAndLandingSpot() {
        let f = Slowpitch.solveLob(Self.belt)
        assertClose(f.apex.y / Slowpitch.FT, 9, 3)
        assertClose((f.land.z - Slowpitch.PLATE.front) / Slowpitch.IN, 36, 1)
        assertClose(f.land.x / Slowpitch.IN, 0, 1)
    }

    func testSolveLobBeltHighMatchesTheOriginalFlightTimeReleaseSpeedAndPlateCrossing() {
        let f = Slowpitch.solveLob(Self.belt)
        assertClose(f.duration, 1.3832, 3)
        assertClose(f.releaseMph, 29.334, 2)
        assertClose(f.crossing.y / Slowpitch.IN, 20.447, 2)
        assertClose(f.crossing.angle, 32.653, 2)
        assertClose(f.spinCarryIn, 12.467, 2)
    }

    func testSolveLobBeltHighStartsAtTheReleasePointAndIsSampledDensely() {
        let f = Slowpitch.solveLob(Self.belt)
        assertClose(Double(f.positions[0]), Slowpitch.RELEASE.x, 5)
        assertClose(Double(f.positions[1]), Slowpitch.RELEASE.y, 5)
        assertClose(Double(f.positions[2]), Slowpitch.RELEASE.z, 5)
        XCTAssertGreaterThan(f.count, 500)
    }

    // path lookups
    func testPositionAtClampsToTheEnds() {
        let f = Slowpitch.solveLob(Self.belt)
        assertClose(Slowpitch.positionAt(f, -1).z, Slowpitch.RELEASE.z, 5)
        assertClose(Slowpitch.positionAt(f, 99).z, f.land.z, 5)
        XCTAssertGreaterThan(Slowpitch.positionAt(f, f.duration / 2).y, Slowpitch.RELEASE.y)
    }

    func testProgressAtRunsZeroToOneAndNeverGoesBack() {
        let f = Slowpitch.solveLob(Self.belt)
        var last = -1.0
        var t = 0.0
        while t <= f.duration {
            let p = Slowpitch.progressAt(f, t)
            XCTAssertGreaterThanOrEqual(p, last)
            last = p
            t += 0.05
        }
        XCTAssertEqual(Slowpitch.progressAt(f, 0), 0)
        XCTAssertEqual(Slowpitch.progressAt(f, f.duration), 1)
    }

    func testDescentLookupsAgreeWithEachOther() throws {
        let f = Slowpitch.solveLob(Self.belt)
        let y = 0.8
        let z = try XCTUnwrap(Slowpitch.descentDepthAtHeight(f, y))
        assertClose(try XCTUnwrap(Slowpitch.descentAtDepth(f, z)).1, y, 3)
        assertClose(try XCTUnwrap(Slowpitch.descentAtDepth(f, 0)).1 / Slowpitch.IN, 20.447, 1)
        XCTAssertNil(Slowpitch.descentAtDepth(f, 10))
        XCTAssertNil(Slowpitch.descentDepthAtHeight(f, 99))
    }

    // solveLob, when it cannot find the throw
    func testSolveLobSaysTheBeltHighLobWasSolved() {
        XCTAssertTrue(Slowpitch.solveLob(Self.belt).converged)
    }

    func testSolveLobSaysSoWhenNoThrowPeaksAndLandsWhereAsked() {
        // Landing hundreds of feet to the side off a 4 ft peak: no lob does that.
        let f = Slowpitch.solveLob(SlowpitchLobParams(apex: 4.2, land: 36, side: 10000, rpm: 110, push: 0))
        XCTAssertFalse(f.converged)
    }

    // MARK: - verdict.test.ts — judgePitch, pinned to the original build

    struct Row {
        let batter: String
        let rule: SlowpitchRuleKey
        let lob: String
        let headline: String
        let call: SlowpitchPitchCall.Call
        let hot: (Double, Double)?
        let barrel: (Double, Double)?
        let window: (Double, Double)

        init(
            _ batter: String, _ rule: SlowpitchRuleKey, _ lob: String, _ headline: String,
            _ call: SlowpitchPitchCall.Call, _ hot: (Double, Double)?, _ barrel: (Double, Double)?,
            _ window: (Double, Double)
        ) {
            self.batter = batter
            self.rule = rule
            self.lob = lob
            self.headline = headline
            self.call = call
            self.hot = hot
            self.barrel = barrel
            self.window = window
        }
    }

    private static let batters: [String: SlowpitchStance] = [
        "default": Slowpitch.DEFAULT_STANCE,
        "h66": stance(heightIn: 66),
        "h54": stance(heightIn: 54),
        "front": stance(box: .front),
        "back": stance(box: .back),
        "toes10": stance(toesIn: 10),
        "toes34": stance(toesIn: 34),
    ]

    private func checkPinned(_ row: Row, file: StaticString = #filePath, line: UInt = #line) throws {
        let batter = try XCTUnwrap(Self.batters[row.batter])
        let r = Slowpitch.judgePitch(try lob(row.lob), row.rule, batter)
        let label = "\(row.batter) · \(row.rule.rawValue) · \(row.lob)"
        XCTAssertEqual(r.verdict.word, row.headline, label, file: file, line: line)
        XCTAssertEqual(r.call.call, row.call, label, file: file, line: line)
        if let hot = row.hot {
            let got = try XCTUnwrap(r.lookFor.hot, label, file: file, line: line)
            assertClose(got.0, hot.0, 1, label, file: file, line: line)
            assertClose(got.1, hot.1, 1, label, file: file, line: line)
        } else {
            XCTAssertNil(r.lookFor.hot.map { [$0.0, $0.1] }, label, file: file, line: line)
        }
        if let barrel = row.barrel {
            let got = try XCTUnwrap(r.barrel, label, file: file, line: line)
            assertClose(got.heightIn, barrel.0, 1, label, file: file, line: line)
            assertClose(got.outFrontIn, barrel.1, 1, label, file: file, line: line)
        } else {
            XCTAssertNil(r.barrel.map { [$0.heightIn, $0.outFrontIn] }, label, file: file, line: line)
        }
        assertClose(r.strikeWindowIn.0, row.window.0, 1, label, file: file, line: line)
        assertClose(r.strikeWindowIn.1, row.window.1, 1, label, file: file, line: line)
    }

    /// default · usssa · belt: Your pitch
    func testPinned_default_usssa_belt() throws {
        try checkPinned(Row("default", .usssa, "belt", "Your pitch", .strike, (6.47, 37.18), (43.83, 30.99), (14.85, 99.2)))
    }

    /// default · usssa · low: Your pitch
    func testPinned_default_usssa_low() throws {
        try checkPinned(Row("default", .usssa, "low", "Your pitch", .strike, (23.52, 73.13), (29.17, 30.91), (22.04, 144.18)))
    }

    /// default · usssa · deep: Strike · over your shoulders
    func testPinned_default_usssa_deep() throws {
        try checkPinned(Row("default", .usssa, "deep", "Strike · over your shoulders", .strike, (9.02, 42.48), (64.13, 31.63), (16.2, 105.45)))
    }

    /// default · usssa · inside: Strike · up at your shoulders
    func testPinned_default_usssa_inside() throws {
        try checkPinned(Row("default", .usssa, "inside", "Strike · up at your shoulders", .strike, (6.47, 37.18), (47.47, 37.76), (14.85, 99.2)))
    }

    /// default · usssa · flat: Your pitch
    func testPinned_default_usssa_flat() throws {
        try checkPinned(Row("default", .usssa, "flat", "Your pitch", .strike, (26.63, 78.99), (40.19, 31.4), (23.4, 152.17)))
    }

    /// default · usssa · rainbow: Illegal arc · too high
    func testPinned_default_usssa_rainbow() throws {
        try checkPinned(Row("default", .usssa, "rainbow", "Illegal arc · too high", .illegal, (-3.53, 18.13), (50.5, 30.84), (10.19, 76.14)))
    }

    /// default · usa · belt: Your pitch
    func testPinned_default_usa_belt() throws {
        try checkPinned(Row("default", .usa, "belt", "Your pitch", .strike, (6.47, 37.18), (43.83, 30.99), (14.85, 99.2)))
    }

    /// default · usa · low: Your pitch
    func testPinned_default_usa_low() throws {
        try checkPinned(Row("default", .usa, "low", "Your pitch", .strike, (23.52, 73.13), (29.17, 30.91), (22.04, 144.18)))
    }

    /// default · usa · deep: Strike · over your shoulders
    func testPinned_default_usa_deep() throws {
        try checkPinned(Row("default", .usa, "deep", "Strike · over your shoulders", .strike, (9.02, 42.48), (64.13, 31.63), (16.2, 105.45)))
    }

    /// default · usa · inside: Strike · up at your shoulders
    func testPinned_default_usa_inside() throws {
        try checkPinned(Row("default", .usa, "inside", "Strike · up at your shoulders", .strike, (6.47, 37.18), (47.47, 37.76), (14.85, 99.2)))
    }

    /// default · usa · flat: Your pitch
    func testPinned_default_usa_flat() throws {
        try checkPinned(Row("default", .usa, "flat", "Your pitch", .strike, (26.63, 78.99), (40.19, 31.4), (23.4, 152.17)))
    }

    /// default · usa · rainbow: Illegal arc · too high
    func testPinned_default_usa_rainbow() throws {
        try checkPinned(Row("default", .usa, "rainbow", "Illegal arc · too high", .illegal, (-3.53, 18.13), (50.5, 30.84), (10.19, 76.14)))
    }

    /// default · senior · belt: Your pitch
    func testPinned_default_senior_belt() throws {
        try checkPinned(Row("default", .senior, "belt", "Your pitch", .strike, (6.47, 37.18), (43.83, 30.99), (0, 41)))
    }

    /// default · senior · low: Your pitch
    func testPinned_default_senior_low() throws {
        try checkPinned(Row("default", .senior, "low", "Your pitch", .strike, (23.52, 73.13), (29.17, 30.91), (0, 41)))
    }

    /// default · senior · deep: Ball · past the mat
    func testPinned_default_senior_deep() throws {
        try checkPinned(Row("default", .senior, "deep", "Ball · past the mat", .ball, (9.02, 42.48), (64.13, 31.63), (0, 41)))
    }

    /// default · senior · inside: Strike · up at your shoulders
    func testPinned_default_senior_inside() throws {
        try checkPinned(Row("default", .senior, "inside", "Strike · up at your shoulders", .strike, (6.47, 37.18), (47.47, 37.76), (0, 41)))
    }

    /// default · senior · flat: Ball · past the mat
    func testPinned_default_senior_flat() throws {
        try checkPinned(Row("default", .senior, "flat", "Ball · past the mat", .ball, (26.63, 78.99), (40.19, 31.4), (0, 41)))
    }

    /// default · senior · rainbow: Strike · over your shoulders
    func testPinned_default_senior_rainbow() throws {
        try checkPinned(Row("default", .senior, "rainbow", "Strike · over your shoulders", .strike, (-3.53, 18.13), (50.5, 30.84), (0, 41)))
    }

    /// h66 · usssa · belt: Your pitch
    func testPinned_h66_usssa_belt() throws {
        try checkPinned(Row("h66", .usssa, "belt", "Your pitch", .strike, (6.47, 39.94), (45.12, 33.35), (16.41, 104.74)))
    }

    /// h66 · usssa · low: Your pitch
    func testPinned_h66_usssa_low() throws {
        try checkPinned(Row("h66", .usssa, "low", "Your pitch", .strike, (25.49, 79.82), (30.09, 33.28), (24.87, 155.82)))
    }

    /// h66 · usssa · inside: Strike · up at your shoulders
    func testPinned_h66_usssa_inside() throws {
        try checkPinned(Row("h66", .usssa, "inside", "Strike · up at your shoulders", .strike, (6.47, 39.94), (48.57, 39.86), (16.41, 104.74)))
    }

    /// h66 · usa · belt: Your pitch
    func testPinned_h66_usa_belt() throws {
        try checkPinned(Row("h66", .usa, "belt", "Your pitch", .strike, (6.47, 39.94), (45.12, 33.35), (16.41, 104.74)))
    }

    /// h66 · usa · low: Your pitch
    func testPinned_h66_usa_low() throws {
        try checkPinned(Row("h66", .usa, "low", "Your pitch", .strike, (25.49, 79.82), (30.09, 33.28), (24.87, 155.82)))
    }

    /// h66 · usa · inside: Strike · up at your shoulders
    func testPinned_h66_usa_inside() throws {
        try checkPinned(Row("h66", .usa, "inside", "Strike · up at your shoulders", .strike, (6.47, 39.94), (48.57, 39.86), (16.41, 104.74)))
    }

    /// h66 · senior · belt: Your pitch
    func testPinned_h66_senior_belt() throws {
        try checkPinned(Row("h66", .senior, "belt", "Your pitch", .strike, (6.47, 39.94), (45.12, 33.35), (0, 41)))
    }

    /// h66 · senior · low: Your pitch
    func testPinned_h66_senior_low() throws {
        try checkPinned(Row("h66", .senior, "low", "Your pitch", .strike, (25.49, 79.82), (30.09, 33.28), (0, 41)))
    }

    /// h66 · senior · inside: Strike · up at your shoulders
    func testPinned_h66_senior_inside() throws {
        try checkPinned(Row("h66", .senior, "inside", "Strike · up at your shoulders", .strike, (6.47, 39.94), (48.57, 39.86), (0, 41)))
    }

    /// h54 · usssa · belt: Strike · up at your shoulders
    func testPinned_h54_usssa_belt() throws {
        try checkPinned(Row("h54", .usssa, "belt", "Strike · up at your shoulders", .strike, (6.08, 31.67), (41.15, 26.11), (11.75, 86.56)))
    }

    /// h54 · usssa · low: Your pitch
    func testPinned_h54_usssa_low() throws {
        try checkPinned(Row("h54", .usssa, "low", "Your pitch", .strike, (20.37, 61.32), (27.25, 26.03), (18.27, 123.89)))
    }

    /// h54 · usssa · inside: Strike · over your shoulders
    func testPinned_h54_usssa_inside() throws {
        try checkPinned(Row("h54", .usssa, "inside", "Strike · over your shoulders", .strike, (6.08, 31.67), (45.22, 33.54), (11.74, 86.56)))
    }

    /// h54 · usa · belt: Strike · up at your shoulders
    func testPinned_h54_usa_belt() throws {
        try checkPinned(Row("h54", .usa, "belt", "Strike · up at your shoulders", .strike, (6.08, 31.67), (41.15, 26.11), (11.75, 86.56)))
    }

    /// h54 · usa · low: Your pitch
    func testPinned_h54_usa_low() throws {
        try checkPinned(Row("h54", .usa, "low", "Your pitch", .strike, (20.37, 61.32), (27.25, 26.03), (18.27, 123.89)))
    }

    /// h54 · usa · inside: Strike · over your shoulders
    func testPinned_h54_usa_inside() throws {
        try checkPinned(Row("h54", .usa, "inside", "Strike · over your shoulders", .strike, (6.08, 31.67), (45.22, 33.54), (11.74, 86.56)))
    }

    /// h54 · senior · belt: Strike · up at your shoulders
    func testPinned_h54_senior_belt() throws {
        try checkPinned(Row("h54", .senior, "belt", "Strike · up at your shoulders", .strike, (6.08, 31.67), (41.15, 26.11), (0, 41)))
    }

    /// h54 · senior · low: Your pitch
    func testPinned_h54_senior_low() throws {
        try checkPinned(Row("h54", .senior, "low", "Your pitch", .strike, (20.37, 61.32), (27.25, 26.03), (0, 41)))
    }

    /// h54 · senior · inside: Strike · over your shoulders
    func testPinned_h54_senior_inside() throws {
        try checkPinned(Row("h54", .senior, "inside", "Strike · over your shoulders", .strike, (6.08, 31.67), (45.22, 33.54), (0, 41)))
    }

    /// front · usssa · belt: Strike · over your shoulders
    func testPinned_front_usssa_belt() throws {
        try checkPinned(Row("front", .usssa, "belt", "Strike · over your shoulders", .strike, (-9.67, 21.04), (52.37, 47.25), (14.85, 99.2)))
    }

    /// front · usssa · low: Your pitch
    func testPinned_front_usssa_low() throws {
        try checkPinned(Row("front", .usssa, "low", "Your pitch", .strike, (7.77, 56.98), (35.3, 47.18), (22.04, 144.18)))
    }

    /// front · usssa · inside: Strike · over your shoulders
    func testPinned_front_usssa_inside() throws {
        try checkPinned(Row("front", .usssa, "inside", "Strike · over your shoulders", .strike, (-9.67, 21.04), (55.62, 53.76), (14.85, 99.2)))
    }

    /// front · usa · belt: Strike · over your shoulders
    func testPinned_front_usa_belt() throws {
        try checkPinned(Row("front", .usa, "belt", "Strike · over your shoulders", .strike, (-9.67, 21.04), (52.37, 47.25), (14.85, 99.2)))
    }

    /// front · usa · low: Your pitch
    func testPinned_front_usa_low() throws {
        try checkPinned(Row("front", .usa, "low", "Your pitch", .strike, (7.77, 56.98), (35.3, 47.18), (22.04, 144.18)))
    }

    /// front · usa · inside: Strike · over your shoulders
    func testPinned_front_usa_inside() throws {
        try checkPinned(Row("front", .usa, "inside", "Strike · over your shoulders", .strike, (-9.67, 21.04), (55.62, 53.76), (14.85, 99.2)))
    }

    /// front · senior · belt: Strike · over your shoulders
    func testPinned_front_senior_belt() throws {
        try checkPinned(Row("front", .senior, "belt", "Strike · over your shoulders", .strike, (-9.67, 21.04), (52.37, 47.25), (0, 41)))
    }

    /// front · senior · low: Your pitch
    func testPinned_front_senior_low() throws {
        try checkPinned(Row("front", .senior, "low", "Your pitch", .strike, (7.77, 56.98), (35.3, 47.18), (0, 41)))
    }

    /// front · senior · inside: Strike · over your shoulders
    func testPinned_front_senior_inside() throws {
        try checkPinned(Row("front", .senior, "inside", "Strike · over your shoulders", .strike, (-9.67, 21.04), (55.62, 53.76), (0, 41)))
    }

    /// back · usssa · belt: Your pitch
    func testPinned_back_usssa_belt() throws {
        try checkPinned(Row("back", .usssa, "belt", "Your pitch", .strike, (22.22, 52.93), (34.66, 14.72), (14.85, 99.2)))
    }

    /// back · usssa · low: Strike · at your knees
    func testPinned_back_usssa_low() throws {
        try checkPinned(Row("back", .usssa, "low", "Strike · at your knees", .strike, (39.66, 89.27), (22.62, 14.65), (22.04, 144.18)))
    }

    /// back · usssa · inside: Your pitch
    func testPinned_back_usssa_inside() throws {
        try checkPinned(Row("back", .usssa, "inside", "Your pitch", .strike, (22.22, 52.93), (38.71, 21.77), (14.85, 99.2)))
    }

    /// back · usa · belt: Your pitch
    func testPinned_back_usa_belt() throws {
        try checkPinned(Row("back", .usa, "belt", "Your pitch", .strike, (22.22, 52.93), (34.66, 14.72), (14.85, 99.2)))
    }

    /// back · usa · low: Strike · at your knees
    func testPinned_back_usa_low() throws {
        try checkPinned(Row("back", .usa, "low", "Strike · at your knees", .strike, (39.66, 89.27), (22.62, 14.65), (22.04, 144.18)))
    }

    /// back · usa · inside: Your pitch
    func testPinned_back_usa_inside() throws {
        try checkPinned(Row("back", .usa, "inside", "Your pitch", .strike, (22.22, 52.93), (38.71, 21.77), (14.85, 99.2)))
    }

    /// back · senior · belt: Your pitch
    func testPinned_back_senior_belt() throws {
        try checkPinned(Row("back", .senior, "belt", "Your pitch", .strike, (22.22, 52.93), (34.66, 14.72), (0, 41)))
    }

    /// back · senior · low: Strike · at your knees
    func testPinned_back_senior_low() throws {
        try checkPinned(Row("back", .senior, "low", "Strike · at your knees", .strike, (39.66, 89.27), (22.62, 14.65), (0, 41)))
    }

    /// back · senior · inside: Your pitch
    func testPinned_back_senior_inside() throws {
        try checkPinned(Row("back", .senior, "inside", "Your pitch", .strike, (22.22, 52.93), (38.71, 21.77), (0, 41)))
    }

    /// toes10 · usssa · belt: Strike · over your shoulders
    func testPinned_toes10_usssa_belt() throws {
        try checkPinned(Row("toes10", .usssa, "belt", "Strike · over your shoulders", .strike, nil, (49.25, 41.16), (14.85, 99.2)))
    }

    /// toes10 · usssa · low: Your pitch
    func testPinned_toes10_usssa_low() throws {
        try checkPinned(Row("toes10", .usssa, "low", "Your pitch", .strike, nil, (33.07, 41.12), (22.04, 144.18)))
    }

    /// toes10 · usssa · inside: Strike · jams you
    func testPinned_toes10_usssa_inside() throws {
        try checkPinned(Row("toes10", .usssa, "inside", "Strike · jams you", .strike, nil, (50.94, 44.43), (14.85, 99.2)))
    }

    /// toes10 · usa · belt: Strike · over your shoulders
    func testPinned_toes10_usa_belt() throws {
        try checkPinned(Row("toes10", .usa, "belt", "Strike · over your shoulders", .strike, nil, (49.25, 41.16), (14.85, 99.2)))
    }

    /// toes10 · usa · low: Your pitch
    func testPinned_toes10_usa_low() throws {
        try checkPinned(Row("toes10", .usa, "low", "Your pitch", .strike, nil, (33.07, 41.12), (22.04, 144.18)))
    }

    /// toes10 · usa · inside: Strike · jams you
    func testPinned_toes10_usa_inside() throws {
        try checkPinned(Row("toes10", .usa, "inside", "Strike · jams you", .strike, nil, (50.94, 44.43), (14.85, 99.2)))
    }

    /// toes10 · senior · belt: Strike · over your shoulders
    func testPinned_toes10_senior_belt() throws {
        try checkPinned(Row("toes10", .senior, "belt", "Strike · over your shoulders", .strike, nil, (49.25, 41.16), (0, 41)))
    }

    /// toes10 · senior · low: Your pitch
    func testPinned_toes10_senior_low() throws {
        try checkPinned(Row("toes10", .senior, "low", "Your pitch", .strike, nil, (33.07, 41.12), (0, 41)))
    }

    /// toes10 · senior · inside: Strike · jams you
    func testPinned_toes10_senior_inside() throws {
        try checkPinned(Row("toes10", .senior, "inside", "Strike · jams you", .strike, nil, (50.94, 44.43), (0, 41)))
    }

    /// toes34 · usssa · belt: Strike · off the end
    func testPinned_toes34_usssa_belt() throws {
        try checkPinned(Row("toes34", .usssa, "belt", "Strike · off the end", .strike, nil, (26.68, 1.42), (14.85, 99.2)))
    }

    /// toes34 · usssa · low: Strike · off the end
    func testPinned_toes34_usssa_low() throws {
        try checkPinned(Row("toes34", .usssa, "low", "Strike · off the end", .strike, nil, (16.97, 1.42), (22.04, 144.18)))
    }

    /// toes34 · usssa · inside: Your pitch
    func testPinned_toes34_usssa_inside() throws {
        try checkPinned(Row("toes34", .usssa, "inside", "Your pitch", .strike, nil, (39.9, 23.87), (14.85, 99.2)))
    }

    /// toes34 · usa · belt: Strike · off the end
    func testPinned_toes34_usa_belt() throws {
        try checkPinned(Row("toes34", .usa, "belt", "Strike · off the end", .strike, nil, (26.68, 1.42), (14.85, 99.2)))
    }

    /// toes34 · usa · low: Strike · off the end
    func testPinned_toes34_usa_low() throws {
        try checkPinned(Row("toes34", .usa, "low", "Strike · off the end", .strike, nil, (16.97, 1.42), (22.04, 144.18)))
    }

    /// toes34 · usa · inside: Your pitch
    func testPinned_toes34_usa_inside() throws {
        try checkPinned(Row("toes34", .usa, "inside", "Your pitch", .strike, nil, (39.9, 23.87), (14.85, 99.2)))
    }

    /// toes34 · senior · belt: Strike · off the end
    func testPinned_toes34_senior_belt() throws {
        try checkPinned(Row("toes34", .senior, "belt", "Strike · off the end", .strike, nil, (26.68, 1.42), (0, 41)))
    }

    /// toes34 · senior · low: Strike · off the end
    func testPinned_toes34_senior_low() throws {
        try checkPinned(Row("toes34", .senior, "low", "Strike · off the end", .strike, nil, (16.97, 1.42), (0, 41)))
    }

    /// toes34 · senior · inside: Your pitch
    func testPinned_toes34_senior_inside() throws {
        try checkPinned(Row("toes34", .senior, "inside", "Your pitch", .strike, nil, (39.9, 23.87), (0, 41)))
    }
    // MARK: - verdict.test.ts — the live app at its defaults (USSSA, belt-high lob)

    private func defaultsReading() throws -> SlowpitchPitchReading {
        Slowpitch.judgePitch(try lob("belt"), .usssa, Slowpitch.DEFAULT_STANCE)
    }

    func testDefaultsHeadlineYourPitch() throws {
        let r = try defaultsReading()
        XCTAssertEqual(r.verdict.word, "Your pitch")
        XCTAssertEqual(r.verdict.short, "Your pitch")
    }

    func testDefaultsSayLookForSixToThirtySevenInchesPastTheFrontOfThePlate() throws {
        let hot = try XCTUnwrap(try defaultsReading().lookFor.hot)
        XCTAssertEqual([jsRound(hot.0), jsRound(hot.1)], [6, 37])
    }

    func testDefaultsMeetItFortyFourHighThirtyOneOutFrontAndCrossThePlateTwentyHigh() throws {
        let r = try defaultsReading()
        let barrel = try XCTUnwrap(r.barrel)
        XCTAssertEqual(jsRound(barrel.heightIn), 44)
        XCTAssertEqual(jsRound(barrel.outFrontIn), 31)
        XCTAssertEqual(jsRound(r.overPlateIn), 20)
    }

    func testDefaultsCarryTheCallDetailsThePageReads() throws {
        let r = try defaultsReading()
        XCTAssertTrue(r.call.arcLegal)
        assertClose(r.apexFt, 9, 3)
        assertClose(r.call.depthMarginIn, 21.146, 2)
        assertClose(r.call.sideMarginIn, 10.41, 2)
        let warm = try XCTUnwrap(r.lookFor.warm)
        assertClose(warm.0, -6.52, 2)
        assertClose(warm.1, 45.055, 2)
        assertClose(r.fallingAngleDeg, 32.653, 2)
    }

    // MARK: - verdict.test.ts — verdict words

    private func contact(_ kind: SlowpitchBatterContact.Kind, y: Double = 1) -> SlowpitchBatterContact {
        SlowpitchBatterContact(
            contact: .init(x: 0, y: y, z: 0, forward: 0, angleDeg: 0),
            lateral: 1, vertical: 1, score: 1, kind: kind
        )
    }

    private func call(
        call: SlowpitchPitchCall.Call = .strike, arcWhy: SlowpitchPitchCall.ArcWhy = .ok,
        miss: SlowpitchPitchCall.Miss = .none
    ) -> SlowpitchPitchCall {
        SlowpitchPitchCall(
            arcLegal: true, arcWhy: arcWhy, strike: true, call: call, miss: miss,
            lane: .init(min: 0, max: 0), depthMarginIn: 0, sideMarginIn: 0
        )
    }

    func testVerdictNamesAnIllegalArcBeforeAnythingElse() {
        XCTAssertEqual(
            Slowpitch.verdictFor(call(call: .illegal, arcWhy: .flat), contact(.pitch), 1, .usssa).word,
            "Illegal arc · too flat"
        )
        XCTAssertEqual(
            Slowpitch.verdictFor(call(call: .illegal, arcWhy: .high), contact(.pitch), 1, .usssa).short,
            "Illegal"
        )
    }

    func testVerdictReadsABallAgainstTheZoneOrAgainstTheMatForSenior() {
        XCTAssertEqual(
            Slowpitch.verdictFor(call(call: .ball, miss: .short), contact(.pitch), 1, .usssa).word,
            "Ball · under your knees"
        )
        XCTAssertEqual(
            Slowpitch.verdictFor(call(call: .ball, miss: .long), contact(.pitch), 1, .senior).word,
            "Ball · past the mat"
        )
        XCTAssertEqual(
            Slowpitch.verdictFor(call(call: .ball, miss: .inside), contact(.pitch), 1, .senior).word,
            "Ball · off the mat"
        )
    }

    func testVerdictSplitsTooHighAtTheShoulder() {
        XCTAssertEqual(
            Slowpitch.verdictFor(call(), contact(.high, y: 2), 1, .usa).word, "Strike · over your shoulders"
        )
        XCTAssertEqual(
            Slowpitch.verdictFor(call(), contact(.high, y: 0.5), 1, .usa).word, "Strike · up at your shoulders"
        )
    }

    // MARK: - model.test.ts — flight lab model

    private func baseModel() throws -> FlightLabModel {
        try XCTUnwrap(FlightLab.buildLabModel(
            rule: .usssa, stance: Slowpitch.DEFAULT_STANCE, compareIn: 32,
            params: FlightLab.defaultLobParams(Self.exampleLobs), selected: "belt",
            lobs: Self.exampleLobs, rulebooks: []
        ))
    }

    func testLabModelReadsTheMeasuredBatterTheWayTheOriginalDid() throws {
        let m = try baseModel()
        let IN = Slowpitch.IN
        XCTAssertEqual(m.selected.reading.verdict.word, "Your pitch")
        XCTAssertEqual(FlightLab.lookForRange(m), "6–37")
        let barrel = try XCTUnwrap(m.selected.reading.barrel)
        XCTAssertEqual(jsRound(barrel.heightIn), 44)
        XCTAssertEqual(jsRound(barrel.outFrontIn), 31)
        XCTAssertEqual(jsRound(m.selected.reading.overPlateIn), 20)
        XCTAssertEqual(
            [m.zone.top, m.marks.chest, m.marks.belt, m.zone.bottom].map { jsRound($0 / IN) }, [49, 41, 31, 15]
        )
        let comparison = try XCTUnwrap(m.comparison)
        XCTAssertEqual(FlightLab.signed(comparison.reachGapIn), "+2.0")
        XCTAssertEqual(FlightLab.signed(comparison.matchShiftIn), "+2.4")
    }

    func testLabModelGivesEveryExampleLobTheShortVerdictTheOriginalListed() throws {
        let shorts = try baseModel().lobs.map(\.reading.verdict.short)
        XCTAssertEqual(shorts, ["Your pitch", "Your pitch", "Too high", "Too high", "Your pitch", "Illegal"])
    }

    func testLabModelDropsTheStrikeLaneUnderSeniorRulesAndKeepsTheLookForWindow() throws {
        let m = try XCTUnwrap(FlightLab.buildLabModel(
            rule: .senior, stance: Slowpitch.DEFAULT_STANCE, compareIn: 0,
            params: FlightLab.defaultLobParams(Self.exampleLobs), selected: "belt",
            lobs: Self.exampleLobs, rulebooks: []
        ))
        XCTAssertNil(m.laneZ.map { [$0.0, $0.1] })
        XCTAssertNil(m.comparison)
        XCTAssertEqual(m.reachOld, 0)
        XCTAssertNotNil(m.hotZ.map { [$0.0, $0.1] })
    }

    func testLabModelFormatsHeightsAndSignedReadoutsWithoutStraySymbols() {
        XCTAssertEqual(FlightLab.heightLabel(62), "5 ft 2 in")
        XCTAssertEqual(FlightLab.signed(-0.4), "-0.4")
        XCTAssertEqual(FlightLab.signed(0.01), "+0.0")
    }

    // MARK: - model.test.ts — flight lab settings

    func testLabSettingsFallBackToTheMeasuredBatterOnMissingOrBrokenStorage() {
        XCTAssertEqual(FlightLab.parseSettings(nil), FlightLab.DEFAULT_SETTINGS)
        XCTAssertEqual(FlightLab.parseSettings("{not json"), FlightLab.DEFAULT_SETTINGS)
    }

    func testLabSettingsKeepOnlyValuesTheControlsCanShow() throws {
        let raw = String(
            data: try JSONSerialization.data(withJSONObject: ["heightIn": 70, "toesIn": 99, "box": "side", "compareIn": 31]),
            encoding: .utf8
        )
        XCTAssertEqual(
            FlightLab.parseSettings(raw),
            FlightLabSettings(
                heightIn: 70,
                toesIn: FlightLab.DEFAULT_SETTINGS.toesIn,
                box: FlightLab.DEFAULT_SETTINGS.box,
                compareIn: 31
            )
        )
    }

    // Not a web `it`: the iOS persistence seam replaces localStorage, so pin that
    // it writes the same JSON under the same key the site uses.
    func testLabSettingsStorePersistsUnderTheSiteStorageKey() throws {
        let suite = "SlowpitchTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = FlightLabSettingsStore(defaults: defaults)
        XCTAssertEqual(store.read(), FlightLab.DEFAULT_SETTINGS)
        store.update(heightIn: 70, box: .back)
        XCTAssertEqual(
            defaults.string(forKey: "pa-flight-lab:batter:v1"),
            #"{"heightIn":70,"toesIn":22,"box":"back","compareIn":32}"#
        )
        XCTAssertEqual(FlightLabSettingsStore(defaults: defaults).read().heightIn, 70)
        store.reset()
        XCTAssertEqual(FlightLabSettingsStore(defaults: defaults).read(), FlightLab.DEFAULT_SETTINGS)
    }
}
