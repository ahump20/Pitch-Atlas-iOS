import Foundation

// =============================================================================
// SpecimenReads — the plain reads a filed specimen gives up
// =============================================================================
// Web: lib/specimenReads.ts and pages/PitchChapter.tsx (the hero pills,
// collectSources, the gold 1/1's accent) and components/study/GripStudy.tsx
// (the four steps). The chapter and the bench say the same thing in the same
// words; every read comes from the record and none of them is a number.
// =============================================================================

enum SpecimenReads {
    /// The direction the pitch breaks, in words.
    static func shapeLabel(_ entry: PitchAtlasEntry) -> String {
        let motion = entry.motion
        if motion.indeterminateBreak == true { return "Erratic flutter" }
        let vertical = motion.verticalShape == .ride ? "Rides" : motion.verticalShape == .drop ? "Drops" : "Holds flat"
        let horizontal: String? = switch motion.horizontalDir {
        case .armSide: "arm-side run"
        case .gloveSide: "glove-side sweep"
        case .none: nil
        }
        return horizontal.map { "\(vertical) · \($0)" } ?? vertical
    }

    struct ReleaseCue: Hashable {
        let label: String
        let copy: String
    }

    /// Hold, pressure, leave: the reference hand's three release cues.
    static func releaseSequence(_ entry: PitchAtlasEntry) -> [ReleaseCue] {
        let model = entry.canonical.gripModel
        let pressure = model.contacts.first { $0.finger == model.primaryPressureFinger }?.pressureRole ?? model.thumbRole
        return [
            ReleaseCue(label: "Hold", copy: model.palmGapCue),
            ReleaseCue(label: "Pressure", copy: pressure),
            ReleaseCue(label: "Leave", copy: model.releaseCue),
        ]
    }

    /// The hero's pills: the family, the guide's family, the force — each once.
    static func pills(_ entry: PitchAtlasEntry) -> [String] {
        var pills: [String] = []
        for pill in [entry.canonical.family.label, entry.guide?.family, entry.motion.forceLabel] {
            if let pill, !pill.isEmpty, !pills.contains(pill) { pills.append(pill) }
        }
        return pills
    }

    /// The gold 1/1 (specimen 00) wears burnt orange; every other pitch its own c3.
    static func accentRGB(_ entry: PitchAtlasEntry) -> UInt32 {
        entry.display.specimenNo == "00" ? WebTokens.Accent.burnt : PitchAccents.triad(for: entry.slug).c3
    }

    /// Every distinct cited source on the page for the colophon, in render order.
    static func colophonSources(_ entry: PitchAtlasEntry) -> [Source] {
        let canonical = entry.canonical
        var claims: [Claim?] = [canonical.grip]
        claims += canonical.gripDetails
        claims += [canonical.mechanics, canonical.voice,
                   canonical.physics.spinAxis, canonical.physics.shape, canonical.physics.teaching]
        for variant in entry.masterVariants {
            claims.append(variant.distinction)
            claims += (variant.accolades ?? []).map(\.claim)
            claims.append(variant.quote)
        }
        claims += [entry.seam.stitchCount, entry.seam.accuracyNote]
        var seen = Set<String>()
        return claims.compactMap { $0?.source }.filter { seen.insert($0.id).inserted }
    }

    /// The grip bench's four steps and the line each one opens with.
    static let studySteps = ["Hold", "Fingers", "Seam", "Sourced cue"]
    static let studyTitles = [
        "Start with the whole hand.", "Read the finger placement.",
        "Find the seam relationship.", "Carry one cue with you.",
    ]
}
