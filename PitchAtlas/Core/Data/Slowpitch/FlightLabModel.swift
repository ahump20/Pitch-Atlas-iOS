import Foundation

// =============================================================================
// Slow-pitch Flight Lab — content types, the lab model and the batter settings
// =============================================================================
// Ports of the web repo (@ 47e21e6):
//   • src/data/softball/types.ts — only the Flight Lab shapes, as Decodable
//     mirrors. The content itself (rulebooks, the six example lobs, the measured
//     batter, the notes) is never authored here: it ships as the generated
//     Resources/Content/flight-lab.json (keys `rulebooks`, `lobs`,
//     `measuredBatter`, `notes`) and is passed in.
//   • src/components/flightlab/model.ts — the lab's one model, line for line.
//     Where the web reads EXAMPLE_LOBS / FLIGHT_LAB_RULEBOOKS as module globals,
//     these functions take the decoded content as parameters.
//   • src/components/flightlab/labSettings.ts — parse, clamp and defaults, with
//     UserDefaults standing in for localStorage under the same key.
// =============================================================================

// MARK: - Content types (src/data/softball/types.ts)

/// A provenance-wrapped value of any shape. The app's `Claim` is string-only;
/// the Flight Lab's claims also wrap lob params, a stance, a swing and numbers.
/// Same fields and tiers as `Claim`.
struct SlowpitchClaim<Value: Codable & Hashable>: Codable, Hashable {
    let value: Value
    let confidence: ClaimConfidence
    let source: Source?
    let note: String?
    let approximate: Bool?
}

/// A slow-pitch rulebook as the Flight Lab reads it. The numbers are the model's
/// inputs; every line a visitor reads is a sourced Claim.
struct FlightLabRulebook: Codable, Hashable {
    let key: SlowpitchRuleKey
    let name: String
    let short: String
    /// The model's arc and strike-call inputs.
    let arc: SlowpitchArcRule
    /// The legal arc, in plain words.
    let arcText: Claim
    /// What a strike is under this book.
    let zoneText: Claim
    /// What happens on an illegal arc.
    let illegalText: Claim
}

/// One of the lab's example lobs. The arc is set by hand, so it is labelled so.
struct FlightLabLob: Codable, Hashable {
    /// 'belt' | 'low' | 'deep' | 'inside' | 'flat' | 'rainbow' on the web.
    let key: String
    let name: String
    /// Swatch colour for the path and its list row, as the content's hex string.
    let color: String
    /// Peak, landing, side and the internal spin inputs (rpm is never shown).
    let params: SlowpitchClaim<SlowpitchLobParams>
}

/// The proportions of the measured swing, as fractions of standing height
/// unless named in inches or degrees.
struct FlightLabMeasuredSwing: Codable, Hashable {
    let landmarks: SlowpitchLandmarks
    let stanceDepthPerHeight: Double
    let stridePerHeight: Double
    let armReachPerHeight: Double
    let handsFromKnobIn: Double
}

/// The measured batter's bat: length and barrel diameter, inches.
struct FlightLabBat: Codable, Hashable {
    let lengthIn: Double
    let diameterIn: Double
}

/// The lab's default batter: one batter's measured swing, never named.
struct FlightLabMeasuredBatter: Codable, Hashable {
    /// Height, toes to plate, box and bat, as measured.
    let stance: SlowpitchClaim<SlowpitchStance>
    /// Landmark ratios, stance depth, stride and reach.
    let swing: SlowpitchClaim<FlightLabMeasuredSwing>
    /// The bat they swing.
    let bat: SlowpitchClaim<FlightLabBat>
    /// Barrel angle below level at contact, degrees.
    let barrelAngleDeg: SlowpitchClaim<Double>
}

/// The generated flight-lab.json. A note is the web's `SlowpitchNote`
/// (`{ label, claim: Claim<string> }`), which is the app's `LabeledClaim`.
struct FlightLabContent: Codable, Hashable {
    let rulebooks: [FlightLabRulebook]
    let lobs: [FlightLabLob]
    let measuredBatter: FlightLabMeasuredBatter
    let notes: [LabeledClaim]
}

// MARK: - The lab model (src/components/flightlab/model.ts)

enum FlightLabCameraView: String, CaseIterable, Hashable {
    case zone
    case catcher
    case arc
    case reach
}

/// A request to throw: a new `id` starts it; `indices` are the lobs to throw.
struct FlightLabThrowRequest: Hashable {
    let id: Int
    let indices: [Int]
}

/// One example lob, solved and read for the current batter and rulebook (the web's `LabLob`).
struct FlightLabSolvedLob {
    let key: String
    let name: String
    let color: String
    let params: SlowpitchLobParams
    let flight: SlowpitchFlight
    let reading: SlowpitchPitchReading
}

struct FlightLabModel {
    let rule: SlowpitchRuleKey
    /// The rulebook for `rule`, else the first one passed (as on the web); nil
    /// only when no rulebooks were passed.
    let rulebook: FlightLabRulebook?
    let stance: SlowpitchStance
    /// The bat being compared against, inches; 0 when the compare is off.
    let compareIn: Double
    let lobs: [FlightLabSolvedLob]
    let selectedIndex: Int
    let selected: FlightLabSolvedLob
    let marks: SlowpitchLandmarks
    let zone: (bottom: Double, top: Double)
    /// Where the swing turns at contact, (x, z) metres.
    let pivot: (x: Double, z: Double)
    /// Hands to sweet spot at contact, metres: this bat and the compared one (0 when off).
    let reach: Double
    let reachOld: Double
    /// The look-for landing window along z, metres, or nil when nothing reaches the barrel.
    let hotZ: (Double, Double)?
    /// The strike lane along z, metres (zone rules only).
    let laneZ: (Double, Double)?
    let heat: SlowpitchReachHeatMap
    let comparison: SlowpitchBatComparison?
    /// Where the compared bat would meet the selected lob.
    let compareContact: SlowpitchBatterContact?
}

/// Solved flights kept by their params. Solving a lob is the expensive step
/// (Newton on a full integration), and only the params decide it.
private final class FlightLabFlightCache {
    static let shared = FlightLabFlightCache()
    private let lock = NSLock()
    private var flights: [SlowpitchLobParams: SlowpitchFlight] = [:]

    func flight(for params: SlowpitchLobParams) -> SlowpitchFlight {
        lock.lock()
        if let cached = flights[params] {
            lock.unlock()
            return cached
        }
        lock.unlock()
        let solved = Slowpitch.solveLob(params)
        lock.lock()
        if flights.count > 120 { flights.removeAll() }
        flights[params] = solved
        lock.unlock()
        return solved
    }
}

/// The Flight Lab's namespace: constants and functions keep their web names.
enum FlightLab {
    static let CAMERA_VIEWS: [(value: FlightLabCameraView, label: String)] = [
        (value: .zone, label: "Zone"),
        (value: .catcher, label: "Catcher"),
        (value: .arc, label: "Arc"),
        (value: .reach, label: "Reach"),
    ]

    /// How fast the clock runs near the plate, 0.22..1: the throw slows as the ball
    /// comes into the zone so the eye can follow the last few feet. `z` is the
    /// ball's depth in metres.
    static func nearPlateTimeScale(_ z: Double) -> Double {
        let k = SlowpitchJS.min(1, SlowpitchJS.max(0, (abs(z) - 1) / 1.6))
        return 0.22 + 0.78 * (k * k * (3 - 2 * k))
    }

    /// Slow motion's clock rate.
    static let SLOW_RATE = 0.35

    /// Bat lengths the compare switch offers; 0 is off.
    static let COMPARE_OPTIONS: [Double] = [0, 31, 32, 33]

    static let HEIGHT_RANGE = (min: 50.0, max: 80.0)
    static let TOES_RANGE = (min: 4.0, max: 36.0)

    /// The example lobs' hand-set params, keyed for state.
    static func defaultLobParams(_ lobs: [FlightLabLob]) -> [String: SlowpitchLobParams] {
        var params: [String: SlowpitchLobParams] = [:]
        for l in lobs { params[l.key] = l.params.value }
        return params
    }

    static func flightFor(_ params: SlowpitchLobParams) -> SlowpitchFlight {
        FlightLabFlightCache.shared.flight(for: params)
    }

    static func rulebookFor(_ rule: SlowpitchRuleKey, in rulebooks: [FlightLabRulebook]) -> FlightLabRulebook? {
        rulebooks.first { $0.key == rule } ?? rulebooks.first
    }

    static func isRuleKey(_ value: String?) -> Bool {
        value == "usssa" || value == "usa" || value == "senior"
    }

    /// Inches past the plate's front edge, as a depth z in metres.
    static func zFromInchesPastFront(_ inches: Double) -> Double {
        Slowpitch.PLATE.front + inches * Slowpitch.IN
    }

    /// The lab's one model. `lobs` and `rulebooks` are the decoded flight-lab.json;
    /// nil only when `lobs` is empty (the web's list never is).
    static func buildLabModel(
        rule: SlowpitchRuleKey,
        stance: SlowpitchStance,
        compareIn: Double,
        params: [String: SlowpitchLobParams],
        selected: String,
        lobs exampleLobs: [FlightLabLob],
        rulebooks: [FlightLabRulebook]
    ) -> FlightLabModel? {
        let lobs: [FlightLabSolvedLob] = exampleLobs.map { l in
            let p = params[l.key] ?? l.params.value
            let flight = flightFor(p)
            return FlightLabSolvedLob(
                key: l.key, name: l.name, color: l.color, params: p, flight: flight,
                reading: Slowpitch.judgePitch(flight, rule, stance)
            )
        }
        guard !lobs.isEmpty else { return nil }
        let selectedIndex = Swift.max(0, lobs.firstIndex { $0.key == selected } ?? -1)
        let selectedLob = lobs[selectedIndex]
        let hot = selectedLob.reading.lookFor.hot
        let senior = rule == .senior
        let compareOn = compareIn > 0 && compareIn != stance.batIn
        var compareStance = stance
        compareStance.batIn = compareIn
        return FlightLabModel(
            rule: rule,
            rulebook: rulebookFor(rule, in: rulebooks),
            stance: stance,
            compareIn: compareOn ? compareIn : 0,
            lobs: lobs,
            selectedIndex: selectedIndex,
            selected: selectedLob,
            marks: Slowpitch.landmarks(stance.heightIn),
            zone: Slowpitch.zoneBounds(stance.heightIn),
            pivot: Slowpitch.contactPivot(stance),
            reach: Slowpitch.sweetSpotReach(stance.heightIn, stance.batIn),
            reachOld: compareOn ? Slowpitch.sweetSpotReach(stance.heightIn, compareIn) : 0,
            hotZ: hot.map { (zFromInchesPastFront($0.0), zFromInchesPastFront($0.1)) },
            laneZ: senior ? nil : (selectedLob.reading.call.lane.min, selectedLob.reading.call.lane.max),
            heat: Slowpitch.reachHeatMap(selectedLob.flight, stance),
            comparison: compareOn ? Slowpitch.compareBats(stance, compareIn) : nil,
            compareContact: compareOn ? Slowpitch.meetBall(selectedLob.flight, compareStance) : nil
        )
    }

    // MARK: Words

    /// `String(Math.round(n))`.
    static func round(_ n: Double) -> String {
        SlowpitchJS.string(SlowpitchJS.round(n))
    }

    /// `n.toFixed(digits)`.
    static func fixed(_ n: Double, _ digits: Int = 1) -> String {
        SlowpitchJS.toFixed(n, digits)
    }

    static func heightLabel(_ heightIn: Double) -> String {
        "\(SlowpitchJS.string((heightIn / 12).rounded(.down))) ft \(SlowpitchJS.string(heightIn.truncatingRemainder(dividingBy: 12))) in"
    }

    static func sideLabel(_ sideIn: Double) -> String {
        if sideIn == 0 { return "middle" }
        return "\(SlowpitchJS.string(abs(sideIn))) in \(sideIn < 0 ? "inside" : "outside")"
    }

    /// A signed one-decimal figure: "+2.0", "-0.4".
    static func signed(_ n: Double) -> String {
        let v = abs(n) < 0.05 ? 0 : n
        return "\(v >= 0 ? "+" : "-")\(SlowpitchJS.toFixed(abs(v), 1))"
    }

    /// The release height in feet, for the "Release" stat and tag.
    static let RELEASE_FT = Slowpitch.RELEASE.y / Slowpitch.FT

    /// "6–37", or nil when nothing at this arc reaches the barrel.
    static func lookForRange(_ model: FlightLabModel) -> String? {
        guard let hot = model.selected.reading.lookFor.hot else { return nil }
        return "\(round(hot.0))–\(round(hot.1))"
    }
}

// MARK: - The batter settings (src/components/flightlab/labSettings.ts)

/// The visitor's own batter: height, toes to plate, box and the compare bat.
struct FlightLabSettings: Hashable {
    var heightIn: Double
    var toesIn: Double
    var box: SlowpitchBoxPosition
    var compareIn: Double
}

extension FlightLab {
    /// The key the site keeps these settings under in localStorage; the app uses
    /// the same key in UserDefaults.
    static let SETTINGS_STORAGE_KEY = "pa-flight-lab:batter:v1"

    static let DEFAULT_SETTINGS = FlightLabSettings(
        heightIn: Slowpitch.DEFAULT_STANCE.heightIn,
        toesIn: Slowpitch.DEFAULT_STANCE.toesIn,
        box: Slowpitch.DEFAULT_STANCE.box,
        compareIn: 32
    )

    /// `typeof value === 'number'`, read off a JSONSerialization value. A JSON
    /// `true` also arrives as an NSNumber, so booleans are refused explicitly.
    private static func jsNumber(_ value: Any?) -> Double? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        return number.doubleValue
    }

    private static func intIn(_ value: Any?, _ min: Double, _ max: Double, _ fallback: Double) -> Double {
        if let n = jsNumber(value), n.isFinite, n >= min, n <= max { return SlowpitchJS.round(n) }
        return fallback
    }

    /// Parse whatever was stored, keeping only values the controls can show.
    static func parseSettings(_ raw: String?) -> FlightLabSettings {
        guard let raw, !raw.isEmpty else { return DEFAULT_SETTINGS }
        guard let parsed = try? JSONSerialization.jsonObject(with: Data(raw.utf8), options: [.fragmentsAllowed]) else {
            return DEFAULT_SETTINGS
        }
        // `JSON.parse` of a non-object leaves every field undefined (or throws on
        // null); either way each field falls back, which is DEFAULT_SETTINGS.
        let v = parsed as? [String: Any] ?? [:]
        let box = v["box"] as? String
        let compare = jsNumber(v["compareIn"])
        return FlightLabSettings(
            heightIn: intIn(v["heightIn"], HEIGHT_RANGE.min, HEIGHT_RANGE.max, DEFAULT_SETTINGS.heightIn),
            toesIn: intIn(v["toesIn"], TOES_RANGE.min, TOES_RANGE.max, DEFAULT_SETTINGS.toesIn),
            box: box == "front" || box == "back" || box == "middle" ? SlowpitchBoxPosition(rawValue: box!)! : DEFAULT_SETTINGS.box,
            compareIn: compare.map { COMPARE_OPTIONS.contains($0) } == true ? compare! : DEFAULT_SETTINGS.compareIn
        )
    }

    /// `JSON.stringify(settings)`, in the web's key order.
    static func serializeSettings(_ s: FlightLabSettings) -> String {
        "{\"heightIn\":\(SlowpitchJS.string(s.heightIn)),\"toesIn\":\(SlowpitchJS.string(s.toesIn)),\"box\":\"\(s.box.rawValue)\",\"compareIn\":\(SlowpitchJS.string(s.compareIn))}"
    }
}

/// The settings kept on this device. Mirrors the web's store: an in-memory copy
/// read once from storage, every write going back to storage, and storage only a
/// convenience — the lab keeps working on the in-memory copy if a write is lost.
/// The UI layer owns observation; this type holds no SwiftUI state.
final class FlightLabSettingsStore {
    private let defaults: UserDefaults
    private var cache: FlightLabSettings?

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func read() -> FlightLabSettings {
        if let cache { return cache }
        let parsed = FlightLab.parseSettings(defaults.string(forKey: FlightLab.SETTINGS_STORAGE_KEY))
        cache = parsed
        return parsed
    }

    func write(_ next: FlightLabSettings) {
        cache = next
        defaults.set(FlightLab.serializeSettings(next), forKey: FlightLab.SETTINGS_STORAGE_KEY)
    }

    /// The web's `update(patch)`: merge the given fields over the current settings.
    func update(heightIn: Double? = nil, toesIn: Double? = nil, box: SlowpitchBoxPosition? = nil, compareIn: Double? = nil) {
        var next = read()
        if let heightIn { next.heightIn = heightIn }
        if let toesIn { next.toesIn = toesIn }
        if let box { next.box = box }
        if let compareIn { next.compareIn = compareIn }
        write(next)
    }

    func reset() {
        write(FlightLab.DEFAULT_SETTINGS)
    }

    /// Test seam: forget the in-memory copy so the next read goes back to storage.
    func resetCache() {
        cache = nil
    }
}
