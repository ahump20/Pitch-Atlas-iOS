import Foundation

/// field-notes.json, generated from the web's data/field-notes.ts: the ranking
/// model the pitch page prints under "How notes rank" (each weight beside its
/// signal), the vocabulary, and the note form's context lists and limits. The
/// Swift option enums carry the same words; FieldNotesChapterTests holds them to
/// this bundle so a change on the site fails the build instead of drifting.
struct FieldNotesGuide: Decodable, Equatable {
    struct Signal: Decodable, Equatable, Identifiable {
        let key: String
        let label: String
        let blurb: String
        let weight: Double
        var id: String { key }
        /// `Math.round(weight * 100)`, as the site prints it.
        var percent: Int { Int((weight * 100).rounded()) }
    }

    struct Term: Decodable, Equatable, Identifiable {
        let term: String
        let gloss: String
        var id: String { term }
    }

    struct Option: Decodable, Equatable {
        let value: String
        let label: String
    }

    /// FIELD_NOTE_CONSTRAINTS, the hard limits the form and the server share.
    struct Limits: Decodable, Equatable {
        struct Bound: Decodable, Equatable {
            let min: Double?
            let max: Double?
        }
        let displayName: Bound
        let tweakDescription: Bound
        let cueNote: Bound
        let claimedResultNote: Bound
        let evidenceLabel: Bound
        let evidenceUrl: Bound
    }

    let rankSignals: [Signal]
    let vocabulary: [Term]
    let playerLevels: [Option]
    let armSlots: [Option]
    let velocityBands: [Option]
    let limits: Limits?

    static let empty = FieldNotesGuide(rankSignals: [], vocabulary: [], playerLevels: [], armSlots: [],
                                       velocityBands: [], limits: nil)
}
