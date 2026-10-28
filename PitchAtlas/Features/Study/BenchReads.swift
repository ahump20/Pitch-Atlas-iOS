import Foundation

// =============================================================================
// BenchReads — what the compare table says about a pair
// =============================================================================
// Web: pages/ComparePage.tsx (the aspect names, the empty table),
// inspector/BenchBody.tsx (the stage chip, the study links, the mark where two
// hands differ) and lib/specimenReads.ts (FINGER_NAME, fingerRows). Every read
// comes from the record; none of them is a number.
// =============================================================================

enum BenchReads {
    /// ComparePage's VIEW_LABEL. The link keeps grips, cues and movement; the
    /// tabs say what the reader is looking at.
    static func tabLabel(_ mode: CompareSelection.Mode) -> String {
        switch mode {
        case .grips: "Grip"
        case .cues: "Release"
        case .movement: "Flight"
        }
    }

    /// The empty table's heading: nothing chosen, or one of two.
    static func emptyTitle(chosen: Int) -> String {
        chosen > 0 ? "Bring another pitch to the table." : "Start with two pitches."
    }

    /// The study link under the rows: a pair names its pitch, one pitch the aspect.
    static func studyLabel(_ entry: PitchAtlasEntry, pair: Bool, mode: CompareSelection.Mode) -> String {
        if pair { return "Study \(entry.display.shortName)" }
        switch mode {
        case .grips: return "Study grip"
        case .cues: return "Study release"
        case .movement: return "Study movement"
        }
    }

    /// The chip on the ball. An unfiled grip says so; every hand drawn here is the
    /// seam-informed schematic.
    static func stageChip(_ entry: PitchAtlasEntry) -> String {
        entry.canonical.gripModel.status == .unfiled ? "No canonical grip on file" : "Seam-informed schematic"
    }

    /// FINGER_ORDER: the hand's own order, never the enum's.
    static let fingerOrder: [Finger] = [.index, .middle, .ring, .pinky, .thumb]

    /// FINGER_NAME.
    static func fingerName(_ finger: Finger) -> String {
        switch finger {
        case .index: "Index"
        case .middle: "Middle"
        case .ring: "Ring"
        case .pinky: "Pinky"
        case .thumb: "Thumb"
        }
    }

    struct FingerRow: Equatable {
        let finger: Finger
        /// One per pitch, in pair order; nil where that hand puts no such finger on the ball.
        let contacts: [GripContactModel?]
    }

    /// Every finger either hand puts on the ball, in hand order, each pitch's
    /// contact matched by finger, never by label.
    static func fingerRows(_ entries: [PitchAtlasEntry]) -> [FingerRow] {
        fingerOrder
            .filter { finger in entries.contains { $0.canonical.gripModel.contacts.contains { $0.finger == finger } } }
            .map { finger in
                FingerRow(finger: finger,
                          contacts: entries.map { $0.canonical.gripModel.contacts.first { $0.finger == finger } })
            }
    }

    /// The two hands differ where a finger meets the ball another way or works
    /// harder; a missing contact is never a difference.
    static func differs(_ a: GripContactModel?, _ b: GripContactModel?) -> Bool {
        guard let a, let b else { return false }
        return a.engagement != b.engagement || a.pressureTier != b.pressureTier
    }

    /// The ball's spoken name (BenchBody.tsx's SpecimenStage label).
    static func stageLabel(_ entry: PitchAtlasEntry, hand: Handedness, view: GripView) -> String {
        let name = entry.canonical.name
        if entry.canonical.gripModel.status == .unfiled {
            return "\(name): no canonical grip on file, the seam drawn alone."
        }
        return "\(name), \(hand.rawValue)-handed, \(view.rawValue) view, a seam-informed schematic."
    }

    /// The flight figure's spoken name (TunnelPlot.tsx's aria-label).
    static func flightLabel(_ entries: [PitchAtlasEntry], hand: Handedness) -> String {
        let names = entries.map(\.display.shortName).joined(separator: " and ")
        let shapes = entries.map { "\($0.display.shortName) \(FlightPath.shapeWords($0.motion))" }.joined(separator: "; ")
        return "Illustrative flight of the \(names), drawn from the mound for a \(hand.rawValue)-handed pitcher: \(shapes). Direction only, not a measured path."
    }
}
