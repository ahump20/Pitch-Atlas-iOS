import Foundation

// =============================================================================
// FlightLabReads — the Flight Lab's words
// =============================================================================
// Web: pages/SoftballFlightLabPage.tsx (the verdict, look-for, "This pitch", the
// status line, the rail's copy, the sources) and components/flightlab/
// FlightLabSchematic.tsx (the tags on the drawing). Every figure comes from the
// lab model, which reads the same solver as the drawing, so the words cannot
// disagree with it. No spin, speed or break figure is ever said.
// =============================================================================

enum FlightLabReads {
    /// A landmark tag on the schematic: its height (metres), words, and whether it
    /// is a barrel landmark (amber) or a zone edge (bone).
    struct LandmarkTag: Hashable {
        let y: Double
        let text: String
        let amber: Bool
    }

    /// One "This pitch" figure.
    struct Stat: Hashable {
        let label: String
        let value: String
        let unit: String
    }

    private static func inches(_ metres: Double) -> String { FlightLab.round(metres / Slowpitch.IN) }

    /// Shoulder, chest, belt, front knee; senior rules have no shoulder or knee.
    static func landmarkTags(_ m: FlightLabModel, narrow: Bool) -> [LandmarkTag] {
        let senior = m.rule == .senior
        func tag(_ y: Double, _ word: String, _ short: String, amber: Bool) -> LandmarkTag {
            LandmarkTag(y: y, text: narrow ? "\(short) \(inches(y))" : "\(word) · \(inches(y)) in", amber: amber)
        }
        var tags: [LandmarkTag] = []
        if !senior { tags.append(tag(m.zone.top, "Shoulder", "Shoulder", amber: false)) }
        tags.append(tag(m.marks.chest, "Chest", "Chest", amber: true))
        tags.append(tag(m.marks.belt, "Belt", "Belt", amber: true))
        if !senior { tags.append(tag(m.zone.bottom, "Front knee", "Knee", amber: false)) }
        return tags
    }

    /// Where it crosses the plate, when it reaches the plate at all.
    static func crossingText(_ m: FlightLabModel, narrow: Bool) -> String? {
        let flight = m.selected.flight
        guard flight.land.z > 0 else { return nil }
        let y = inches(flight.crossing.y)
        return narrow ? "Plate \(y)" : "Over the plate · \(y) in"
    }

    static func barrelText(_ m: FlightLabModel, narrow: Bool) -> String? {
        guard let barrel = m.selected.reading.barrel else { return nil }
        return narrow
            ? "Barrel \(FlightLab.round(barrel.heightIn)) in"
            : "Barrel · \(FlightLab.round(barrel.heightIn)) in high · \(FlightLab.round(barrel.outFrontIn)) in out front"
    }

    /// Under the ground line: the strike lane (zone rules only).
    static func strikeLine(_ m: FlightLabModel) -> String? {
        guard m.laneZ != nil else { return nil }
        let s = m.selected.reading.strikeWindowIn
        return "STRIKE · \(FlightLab.round(s.0))–\(FlightLab.round(s.1)) IN"
    }

    /// Under the ground line: the landing window that is your pitch.
    static func pitchLine(_ m: FlightLabModel) -> String? {
        guard let hot = m.selected.reading.lookFor.hot else { return nil }
        return "YOUR PITCH · \(FlightLab.round(hot.0))–\(FlightLab.round(hot.1)) IN"
    }

    /// The schematic's spoken label.
    static func stageLabel(_ m: FlightLabModel) -> String {
        let h = m.stance.heightIn
        var line = "Side view of the strike zone for a \(SlowpitchJS.string((h / 12).rounded(.down))) ft \(SlowpitchJS.string(h.truncatingRemainder(dividingBy: 12))) in batter: the \(m.selected.name.lowercased()) falls through it"
        if m.selected.flight.land.z > 0 { line += ", \(inches(m.selected.flight.crossing.y)) in high over the plate" }
        if let b = m.selected.reading.barrel {
            line += ", and the barrel meets it \(FlightLab.round(b.heightIn)) in high, \(FlightLab.round(b.outFrontIn)) in out front"
        }
        return line + "."
    }

    // MARK: The page

    static let whySentence = "Your eyes judge a lob over the plate. Your barrel meets it out front, where it hasn’t finished falling."

    private static func spoken(_ range: String) -> String { range.replacingOccurrences(of: "–", with: " to ") }

    /// The one quiet announcement once the controls settle.
    static func statusText(_ m: FlightLabModel) -> String {
        let sel = m.selected
        let tail = FlightLab.lookForRange(m).map { "Look for \(spoken($0)) inches past the front of the plate." }
            ?? "No landing spot reaches your barrel."
        return "\(sel.name): \(sel.reading.verdict.word). \(tail)"
    }

    static func lookForBody(_ m: FlightLabModel) -> String {
        guard let range = FlightLab.lookForRange(m) else { return "No landing spot puts this arc on your barrel. \(whySentence)" }
        return "Look for it to land \(spoken(range)) in past the front of the plate. \(whySentence)"
    }

    /// "This pitch": the figures the site shows, in its order, the hidden ones dropped.
    static func thisPitchStats(_ m: FlightLabModel) -> [Stat] {
        let r = m.selected.reading
        let crossing = m.selected.flight.land.z > 0
        var stats = [Stat(label: "Arc peak", value: FlightLab.fixed(r.apexFt), unit: "ft")]
        if crossing {
            stats.append(Stat(label: "Over the plate", value: FlightLab.round(r.overPlateIn), unit: "in high"))
        } else {
            stats.append(Stat(label: "Over the plate", value: "Short", unit: "lands in front"))
        }
        if let b = r.barrel {
            stats.append(Stat(label: "At your barrel", value: FlightLab.round(b.heightIn),
                              unit: "in, \(FlightLab.round(b.outFrontIn)) in out"))
        }
        if crossing { stats.append(Stat(label: "Falling at", value: "\(FlightLab.fixed(r.fallingAngleDeg, 0))°", unit: "")) }
        let w = r.strikeWindowIn
        stats.append(Stat(label: "Strike window",
                          value: m.rule == .senior ? "0–\(FlightLab.round(w.1))" : "\(FlightLab.round(w.0))–\(FlightLab.round(w.1))",
                          unit: "in"))
        return stats
    }

    /// A lob as the sources list says it.
    static func lobLine(_ p: SlowpitchLobParams) -> String {
        "Peaks at \(FlightLab.fixed(p.apex)) ft, lands \(FlightLab.round(p.land)) in past the front of the plate, \(FlightLab.sideLabel(p.side))."
    }

    /// The list row's figure line: "9.5 ft · lands 18 in".
    static func lobRow(_ p: SlowpitchLobParams) -> String {
        "\(FlightLab.fixed(p.apex)) ft · lands \(FlightLab.round(p.land)) in"
    }

    // The site's words, verbatim.
    static let eyebrow = "Slowpitch · flight lab"
    static let title = "Your zone, at your height."
    static let heroSub = "Set your height and where you stand. Every lob drops through your zone, and the lab shows where your barrel meets it and which landing spots are your pitch. The swing is one batter’s, measured off their own video and scaled to your height. It doesn’t know yours."
    static let youMeasured = "Starting on one batter’s measured swing. Set your own height and stance."
    static let youTuned = "Your settings stay on this device. Reset goes back to the measured batter."
    static let examplesNote = "Example arcs, set by hand to teach, not measured from a pitcher."
    static let windowNote = "Strike window and look-for are landing spots, in inches past the front of the plate."
    static let unreachedNote = " At this arc no landing spot reaches your barrel."
    static let unsolved = "No throw in this model peaks and lands exactly there. The path shown is the closest it gets."
    static let sourcesLabel = "Every figure, and where it comes from"
    static let sourcesLede = "Rule lines come from the rule books, each cited to its rule or definition. The batter, the swing model and the example lobs are the lab’s own inputs, tagged that way, so a modelled number never passes for a measured one."
    static let modelTitle = "Modelled by the lab, not measured for you."
    static let exampleTitle = "An example arc, set by hand."

    /// The notes the site marks as the lab's own model.
    static func noteIsModel(_ label: String) -> Bool {
        let l = label.lowercased()
        return l.contains("lift and drag") || l.contains("sweet spot")
    }

    /// "34 × 2¼ in".
    static func batLine(_ bat: FlightLabBat) -> String {
        let across = bat.diameterIn == 2.25 ? "2¼" : SlowpitchJS.string(bat.diameterIn)
        return "\(SlowpitchJS.string(bat.lengthIn)) × \(across) in"
    }
}
