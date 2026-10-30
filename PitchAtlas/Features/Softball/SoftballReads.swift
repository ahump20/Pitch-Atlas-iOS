import SwiftUI

// =============================================================================
// SoftballReads — the softball wing's words and small rules
// =============================================================================
// Web: pages/SoftballHub.tsx and SoftballPitchChapter.tsx (FAMILY_LABEL, the
// accents), components/provenance/SoftballProvenanceRow.tsx (the four-field row),
// components/study/SoftballStudy.tsx (the three written steps). Every field comes
// from the record; a missing date reads "not recorded", a missing question "none
// on file". Nothing invented to fill a slot.
// =============================================================================

enum SoftballReads {
    /// FAMILY_LABEL.
    static func familyLabel(_ family: String) -> String {
        switch family {
        case "rise": "Rise"
        case "drop": "Drop"
        case "fastball": "Fastball"
        case "breaking": "Breaking"
        case "offspeed": "Off-speed"
        default: family.capitalized
        }
    }

    /// accentForSlug(slug).c3: a pitch's own accent, or the atlas fallback.
    static func accent(_ slug: String?) -> Color { Color(rgb: PitchAccents.triad(for: slug ?? "").c3) }

    /// SoftballProvenanceRow: "{type} · {tier} · Last checked {date} · Open question: {q}".
    static func provenance(_ claimType: String, claim: Claim, openQuestion: String?) -> String {
        let checked = claim.source.map { AsOf.format($0.retrievedAt) } ?? "not recorded"
        return "\(claimType) · \(claim.confidence.label) · Last checked \(checked) · Open question: \(openQuestion ?? "none on file")"
    }

    /// The pitch's sources, once each, in the order the file cites them.
    static func sources(_ pitch: SoftballPitch) -> [Source] {
        var seen = Set<String>()
        return [pitch.grip, pitch.spin, pitch.movement, pitch.physicsNote].compactMap { $0?.source }
            .filter { seen.insert($0.id).inserted }
    }

    /// The Atlas / Softball / here.
    static func trail(_ here: String) -> [Crumb] {
        [Crumb(label: "The Atlas", path: "home"), Crumb(label: "Softball", path: "softball"), Crumb(label: here)]
    }

    static func neighbors<T>(_ items: [T], at index: Int?) -> (previous: T?, next: T?) {
        guard let index else { return (nil, nil) }
        return (index > 0 ? items[index - 1] : nil, index < items.count - 1 ? items[index + 1] : nil)
    }

    // The site's words, verbatim.
    static let hubSub = "A different craft from the baseball game: the underhand windmill, a kinetic chain driven from the ground up, and pitches with no baseball cousin: the rise, the drop, the screw. We are building fastpitch first and deepest, with the riseball’s honest physics at the center, and Cat Osterman as the anchor. Slowpitch is filed honestly and lighter. Early innings."
    static let arsenalLede = "The pitches of the circle, filed light for the launch. The riseball leads, carrying the atlas’s honest answer to whether it actually rises."
    static let craftsmenLede = "The arms that defined fastpitch from inside the circle. Cat Osterman opens the wing — the softball case that command and spin beat raw power — with the legends behind her (Fernandez, Finch, Abbott) and the new wave already here (Canady, Kavan)."
    static let slowpitchBlurb = "No windmill and no riseball shape, but a real craft of arc height, deadening spin, and placement to the mat. Filed honestly and lighter."
    static let flightLabBlurb = "For the batter: drop a lob through a strike zone set to your height and stance, see where your barrel meets it, and learn which landing spots are your pitch."
    static let slowpitchSub = "Slowpitch strips the pitch down: no windmill and no riseball shape. What is left is a real, narrow craft: arc height, the backspin that deadens a ball on the plate, and placement to the corners of the mat. It is the opposite end of the craft from the riseball, filed here for exactly that contrast. Early innings, lighter than the fastpitch wing on purpose."
    static let slowpitchHonest = "Filed lighter than the fastpitch wing on purpose. The honest read: slowpitch pitching is a craft of touch and rules, not power. And the rules themselves vary by league, so the arc number is named, not smoothed."
    static let slowpitchZone = "Your eyes judge a lob where it crosses the plate. Your barrel meets it out front, where a falling lob is still higher. The flight lab drops each lob through a strike zone set to your height and stance, under your league’s rule book, and names the landing spots that are your pitch."
    static let slowpitchLabBlurb = "Set your height and where you stand. See where each lob crosses, where your barrel meets it, and what to look for, under USSSA, USA Softball or Senior rules."
    static let fastpitchNext = "Next: the arsenal that lives on this delivery. The rise, the drop, and the rest."
    static let stillToCome = "Every line above is one click from its source. Still to come for the circle: the full grip geometry and a 12″ seam, the way the baseball wing files a pitch."
    static let recordNote = "The record is told in prose, each claim confidence-labeled and one click from its source. Where a line is a teammate’s words rather than the pitcher’s own, it is labeled as such, not put in her mouth."

    /// The Flight Lab on the site: the way on when the bundled lab data cannot load.
    static let flightLabURL = URL(string: "https://pitch-atlas.com/softball/flight-lab")
}

/// SoftballStudy: the written grip stays in view while the steps read the spin and
/// the movement. No drawing: no baseball model stands in for a softball.
enum SoftballStudy {
    enum Step: Int, CaseIterable, Hashable {
        case hold, spin, movement

        /// `?study=`: a known step, or the hold.
        init(raw: String?) {
            self = Step.allCases.first { $0.key == raw } ?? .hold
        }

        var key: String { ["hold", "spin", "movement"][rawValue] }
        var label: String { ["The hold", "The spin", "The movement"][rawValue] }
        var buttonLabel: String { "0\(rawValue + 1) \(label)" }
        var heading: String {
            ["Begin with the written account.", "Follow the recorded spin.", "Read the movement account."][rawValue]
        }
        var previous: Step? { Step(rawValue: rawValue - 1) }
        var next: Step? { Step(rawValue: rawValue + 1) }

        /// The account this step reads; the hold reads the grip beside it.
        func claim(_ pitch: SoftballPitch) -> Claim? {
            switch self {
            case .hold: nil
            case .spin: pitch.spin
            case .movement: pitch.movement
            }
        }
    }

    static let eyebrow = "01 / From the circle"
    static let title = "Start with the hold."
    static let lede = "Keep the written grip in view. Follow its sourced spin and movement, one account at a time."
    static let holdOnFile = "The hold on file"
    static let noGeometry = "Grip photograph and finger-contact geometry: not documented in this file."
    static let holdNote = "The grip beside these steps is the sourced reference. A separate fingertip map, seam model and master-variant record are not documented here."
    static let readSources = "Read the sources in this file"
    static let fullRecord = "The complete written record"
}
