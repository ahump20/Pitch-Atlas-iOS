import Foundation

// =============================================================================
// Pitch Atlas — Content models
// =============================================================================
// Swift Codable mirror of the web repo's data layer (src/data/types.ts and the
// generated Resources/Content/*.json). The web repo is the single source of
// truth; this file decodes the bundle it emits.
//
// Hard rules baked in from an all-records scan of every bundled JSON:
//  • Every numeric field is Double. The JSON mixes 0 and 0.5 for the same key;
//    an Int anywhere CRASHES the decode.
//  • The provenance `Claim` carries value + confidence always; source, note and
//    approximate are all optional (the TS union has a source-less weak branch).
//  • Every string-enum decodes leniently: an unrecognised value falls back to a
//    safe case instead of throwing, so a future content delta can't brick launch.
//  • No JSON key collides with a Swift keyword, so no CodingKeys are needed; the
//    only mapping is enum raw values (kebab-case, one with a space).
// =============================================================================

// MARK: - Provenance (the load-bearing types)

/// How sure the *source* is — never whether the value is "right". Sourced, not corrected.
enum ClaimConfidence: String, Codable, Hashable, CaseIterable {
    case officialData = "official-data"
    case pitcherOwnWords = "pitcher-own-words"
    case coachObserved = "coach-observed"
    case reputableAnalysis = "reputable-analysis"
    case secondhandAttributed = "secondhand-attributed"
    case communityFirsthand = "community-firsthand"
    case unverified

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ClaimConfidence(rawValue: raw) ?? .unverified
    }

    /// Short badge label.
    var label: String {
        switch self {
        case .officialData: return "Official data"
        case .pitcherOwnWords: return "Pitcher's own words"
        case .coachObserved: return "Coach-observed"
        case .reputableAnalysis: return "Reputable analysis"
        case .secondhandAttributed: return "Secondhand, attributed"
        case .communityFirsthand: return "Community, firsthand"
        case .unverified: return "Unverified"
        }
    }

    /// One-line meaning, shown when the tier is explained.
    var meaning: String {
        switch self {
        case .officialData: return "Measured and published by the source of record (Statcast / MLB)."
        case .pitcherOwnWords: return "Stated by the athlete directly."
        case .coachObserved: return "Reported firsthand by a coach."
        case .reputableAnalysis: return "A credible analyst, or our paraphrase of a cited reference."
        case .secondhandAttributed: return "A quote or figure relayed through a secondary source."
        case .communityFirsthand: return "A community member's own report. Launches with safeguards."
        case .unverified: return "No source corroborated this value. Shown so the gap is visible."
        }
    }
}

/// What we are allowed to do with an asset or claim.
enum RightsStatus: String, Codable, Hashable, CaseIterable {
    case original
    case licensed
    case publicDomain = "public-domain"
    case linkedOnly = "linked-only"
    case restricted

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = RightsStatus(rawValue: raw) ?? .restricted
    }
}

/// A cited source. `url`/`retrievedAt`/`season` stay String — the dates are bare
/// yyyy-MM-dd and the urls can carry parenthesised paths that trip Foundation.URL.
struct Source: Codable, Hashable, Identifiable {
    let id: String
    let label: String
    let url: String
    let retrievedAt: String
    let season: String?
}

/// A provenance-wrapped value. Every claim wears its source and tier. `value` is
/// always a String in the bundle (the web's `Claim<T>` is only ever `Claim<string>`).
struct Claim: Codable, Hashable {
    let value: String
    let confidence: ClaimConfidence
    let source: Source?
    let note: String?
    let approximate: Bool?
}

/// Shared `{ label, claim }` number — used by pitch master variants, craftsmen, and lost pitches.
struct LabeledClaim: Codable, Hashable {
    let label: String
    let claim: Claim
}

// MARK: - Geometry / grip enums

enum PitchFamily: String, Codable, Hashable, CaseIterable {
    case fastball, breaking, offspeed
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = PitchFamily(rawValue: raw) ?? .offspeed
    }
}

enum GripView: String, Codable, Hashable, CaseIterable {
    case top, side, thumb
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = GripView(rawValue: raw) ?? .top
    }
}

enum BallDepth: String, Codable, Hashable, CaseIterable {
    case outInFingers = "out-in-fingers"
    case neutral
    case deepInHand = "deep-in-hand"
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = BallDepth(rawValue: raw) ?? .neutral
    }
}

enum FingerSpacing: String, Codable, Hashable, CaseIterable {
    case touching
    case slightSpread = "slight-spread"
    case wide
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = FingerSpacing(rawValue: raw) ?? .touching
    }
}

enum Finger: String, Codable, Hashable, CaseIterable {
    case index, middle, thumb, ring, pinky
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = Finger(rawValue: raw) ?? .index
    }
}

enum Handedness: String, Codable, Hashable, CaseIterable {
    case right, left
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = Handedness(rawValue: raw) ?? .right
    }
}

enum HorizontalDir: String, Codable, Hashable, CaseIterable {
    case armSide = "arm-side"
    case gloveSide = "glove-side"
    case none
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = HorizontalDir(rawValue: raw) ?? .none
    }
}

enum BreakView: String, Codable, Hashable, CaseIterable {
    case carry, movement
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = BreakView(rawValue: raw) ?? .movement
    }
}

enum VerticalShape: String, Codable, Hashable, CaseIterable {
    case ride, flat, drop
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = VerticalShape(rawValue: raw) ?? .flat
    }

    var label: String {
        switch self {
        case .ride: return "ride"
        case .flat: return "flat"
        case .drop: return "drop"
        }
    }
}

enum SeamAccuracyLevel: String, Codable, Hashable, CaseIterable {
    case seamAccurate = "seam-accurate"
    case schematic = "seam-informed schematic"
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = SeamAccuracyLevel(rawValue: raw) ?? .schematic
    }
}

enum VisualReferenceKind: String, Codable, Hashable, CaseIterable {
    case firstParty = "first-party"
    case community
    case creativeCommons = "creative-commons"
    case publicDomain = "public-domain"
    case licensed
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = VisualReferenceKind(rawValue: raw) ?? .firstParty
    }
}

// MARK: - Shared visual reference

/// A rights-clean grip photo or render. Shared by filed pitches and the Grip Library.
struct VisualReference: Codable, Hashable {
    let caption: String
    let src: String
    let alt: String
    let kind: VisualReferenceKind
    let rights: RightsStatus
    let attribution: String?
    let source: Source?
    let capturedAt: String?
    let view: GripView?
}

/// A first-party grip film: a short looping clip of the owner's hand working the
/// grip, plus the still poster shown when motion is reduced or the clip is absent.
/// The clip reuses VisualReference so films carry the same rights/attribution
/// record photos do — nothing renders without that provenance.
struct GripFilm: Codable, Hashable {
    let clip: VisualReference
    /// Bundled still (`/grips/<stem>-poster.webp`).
    let poster: String
}

// MARK: - Pitch specimen (pitches.json → [PitchAtlasEntry])

struct Vec3: Codable, Hashable {
    let x: Double
    let y: Double
    let z: Double
}

struct SeamAnchoredPoint: Codable, Hashable {
    let seamT: Double
    let lift: Double
    let label: String
    let finger: Finger
    let note: String?
}

struct GripContactModel: Codable, Hashable {
    let finger: Finger
    let label: String
    let seamT: Double
    let lift: Double
    let seamRelation: String
    let pressureRole: String
    let cue: String
    let curl: Double
}

struct GripModel: Codable, Hashable {
    let defaultView: GripView
    let ballDepth: BallDepth
    let fingerSpacing: FingerSpacing
    let primaryPressureFinger: Finger
    let thumbRole: String
    let palmGapCue: String
    let releaseCue: String
    let visualCaveat: String
    let contacts: [GripContactModel]
}

struct BreakReading: Codable, Hashable {
    let label: String
    let claim: Claim
    let accent: Bool?
}

struct PhysicsReference: Codable, Hashable {
    let spinAxis: Claim
    let spinRateRpm: Claim?
    let activeSpinPct: Claim?
    let primaryBreak: BreakReading?
    let secondaryBreak: BreakReading?
    let shape: Claim?
    let teaching: Claim
}

struct CanonicalPitchRecord: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let family: PitchFamily
    let grip: Claim
    let gripDetails: [Claim]
    let fingerPlacement: [SeamAnchoredPoint]
    let gripModel: GripModel
    let mechanics: Claim
    let physics: PhysicsReference
    let voice: Claim?
    let rights: RightsStatus
    let gripImages: [VisualReference]?
    let gripFilm: GripFilm?
}

extension CanonicalPitchRecord {
    /// The best real still on file: the film's poster frame (carrying the
    /// film's own rights record), else the first grip photo. Nil when only the
    /// drawn ball exists — surfaces fall back to the SeamBall, never a faked
    /// image.
    var realStill: VisualReference? {
        if let film = gripFilm {
            return VisualReference(caption: film.clip.caption, src: film.poster,
                                   alt: film.clip.alt, kind: film.clip.kind,
                                   rights: film.clip.rights,
                                   attribution: film.clip.attribution,
                                   source: film.clip.source,
                                   capturedAt: film.clip.capturedAt,
                                   view: film.clip.view)
        }
        return gripImages?.first
    }
}

struct PitchMotion: Codable, Hashable {
    let spinAxis: Vec3
    let forceLabel: String
    let gyro: Bool?
    let verticalShape: VerticalShape?
    let horizontalDir: HorizontalDir
    let breakView: BreakView
    let indeterminateBreak: Bool?
}

struct PitchDisplay: Codable, Hashable {
    let slug: String
    let shortName: String
    let specimenNo: String
    let heroSub: String
    let heroIntro: String
    let foundationCaption: String
    let mastersIntro: String
}

struct SafetyFlag: Codable, Hashable {
    let ageAware: Bool?
    let note: String?
}

struct MasterVariantRecord: Codable, Hashable {
    /// The only literal in the bundle is "verified-attributed"; kept as String to
    /// avoid a single-case enum.
    let tier: String
    let pitcher: String
    let context: String
    let verifiedPro: Bool
    let record: [LabeledClaim]?
    let numbers: [LabeledClaim]?
    let distinction: Claim?
    let accolades: [LabeledClaim]?
    let quote: Claim?
    let rights: RightsStatus
    let safety: SafetyFlag?

    var recordNumbers: [LabeledClaim] { record ?? numbers ?? accolades ?? [] }
}

struct CommunityVariantPreview: Codable, Hashable {
    let enabled: Bool
    let safetyNote: String
    let provenanceNote: String
    let columns: [String]
}

struct SeamGeometryReference: Codable, Hashable {
    let equationPlain: String
    let parameterization: String
    let stitchCount: Claim
    let accuracyLevel: SeamAccuracyLevel
    let accuracyNote: Claim
    let calibrationDoc: String
}

struct GripDoes: Codable, Hashable {
    let headline: String
    let plain: String
}

struct GripGuide: Codable, Hashable {
    let family: String
    let tagline: String
    let feel: String
    let steps: [String]
    let does: GripDoes
}

/// The honest specimen grade, baked by the content generator from the web's
/// specimenGradeFor. It is documentation depth — a first-party moving grip beats
/// a still beats a reference schematic — never a scarcity claim or a random draw.
/// The gold 1/1 is the four-seam struck at specimen 00; every other grade is
/// categorical. Unknown keys degrade to `.reference` so a future grade can never
/// crash an older build.
enum SpecimenGradeKey: String, Codable, Hashable {
    case gold
    case inMotion = "in-motion"
    case firstParty = "first-party"
    case reference
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = SpecimenGradeKey(rawValue: raw) ?? .reference
    }
}

struct SpecimenGrade: Codable, Hashable {
    let key: SpecimenGradeKey
    /// The visible stamp wording. Categorical; the only digits are the real 1/1 gold.
    let label: String
}

/// One filed specimen — the canonical record plus its render spec, display copy,
/// master variants, community preview, seam geometry, and optional coaching guide.
struct PitchAtlasEntry: Codable, Hashable, Identifiable {
    let canonical: CanonicalPitchRecord
    let motion: PitchMotion
    let display: PitchDisplay
    let masterVariants: [MasterVariantRecord]
    let community: CommunityVariantPreview
    let seam: SeamGeometryReference
    let guide: GripGuide?
    /// How richly THIS atlas has preserved the specimen — read by the detail
    /// badge and the index documentation sort, baked from the web at generate time.
    let specimenGrade: SpecimenGrade

    var id: String { canonical.id }
    var slug: String { display.slug }
}

// MARK: - Repertoire (repertoire.json → RepertoireRoot)

enum RepertoireFamily: String, Codable, Hashable, CaseIterable {
    case fastball, breaking, offspeed, specialty, banned
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = RepertoireFamily(rawValue: raw) ?? .specialty
    }
}

enum RepertoireStatus: String, Codable, Hashable, CaseIterable {
    case standard, niche, rare
    case nearExtinct = "near-extinct"
    case banned
    case alias, illusion
    case notAPitch = "not-a-pitch"
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = RepertoireStatus(rawValue: raw) ?? .niche
    }
}

struct RepertoireFamilyInfo: Codable, Hashable, Identifiable {
    let family: RepertoireFamily
    let label: String
    let blurb: String
    var id: RepertoireFamily { family }
}

struct RepertoireEntry: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let family: RepertoireFamily
    let status: RepertoireStatus
    let aka: [String]?
    let grip: Claim
    let movement: Claim
    /// A sourced velocity, never a bare number. Velocity is the single figure the
    /// doctrine most forbids fabricating, so it rides the Claim contract (tier +
    /// source) like every other reading — the type makes an unsourced number
    /// impossible to render. Optional: most index rows carry none.
    let velocity: Claim?
    let relationship: Claim?
    let notableThrowers: String?
    let filedSlug: String?
    let plain: String?
}

struct RepertoireRoot: Codable, Hashable {
    let families: [RepertoireFamilyInfo]
    let entries: [RepertoireEntry]
}

// MARK: - Craftsmen (craftsmen.json → [Craftsman])

enum CraftsmanKind: String, Codable, Hashable, CaseIterable {
    case craftsman, legend
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = CraftsmanKind(rawValue: raw) ?? .craftsman
    }
}

/// An external "full record" pointer — the craft-over-numbers redesign sends
/// readers to the source of record instead of restating a stat grid.
struct RecordLink: Codable, Hashable, Identifiable {
    let id: String
    let label: String
    let url: String
    let retrievedAt: String?
}

struct Craftsman: Codable, Hashable, Identifiable {
    let slug: String
    let name: String
    let kind: CraftsmanKind
    let era: String
    let hand: Handedness?
    let signaturePitch: String
    let signaturePitchSlug: String?
    let specimenNo: String
    let tagline: String
    let intro: String
    let signature: Claim
    let mentalEdge: Claim?
    /// The record as sourced prose (current web shape).
    let record: [Claim]?
    /// Legacy labeled stat lines (pre craft-over-numbers bundles).
    let numbers: [LabeledClaim]?
    let biography: [LabeledClaim]?
    let recordLinks: [RecordLink]?
    let quote: Claim?
    let legendNote: Claim?
    let rights: RightsStatus
    var id: String { slug }
    var recordProse: [Claim] { record ?? [] }
    var recordNumbers: [LabeledClaim] { numbers ?? biography ?? [] }
}

// MARK: - Lost Pitches (lost-pitches.json → LostPitchesRoot)

enum LostPitchKind: String, Codable, Hashable, CaseIterable {
    case pitch, pitcher, doctored
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = LostPitchKind(rawValue: raw) ?? .pitch
    }
}

enum DocumentationTier: String, Codable, Hashable, CaseIterable {
    case documented, partial, legend
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = DocumentationTier(rawValue: raw) ?? .legend
    }

    var label: String {
        switch self {
        case .documented: return "Documented"
        case .partial: return "Partially documented"
        case .legend: return "Legend"
        }
    }

    var meaning: String {
        switch self {
        case .documented:
            return "A hard paper trail: a rule change, league records, or a named eyewitness on the record."
        case .partial:
            return "Attested but thin. A name and a description survive; the grip does not."
        case .legend:
            return "A showman label or oral tradition. Shipped flagged, shown to mark the gap, never as fact."
        }
    }
}

struct LostPitchTierInfo: Codable, Hashable, Identifiable {
    let tier: DocumentationTier
    let index: String
    let label: String
    let note: String
    var id: DocumentationTier { tier }
}

struct LostPitch: Codable, Hashable, Identifiable {
    let slug: String
    let name: String
    let kind: LostPitchKind
    let era: String
    let tier: DocumentationTier
    let specimenNo: String
    let tagline: String
    let intro: String
    let what: Claim
    let whyLost: Claim
    /// "record" is the current web key; "numbers" the legacy one.
    let record: [LabeledClaim]?
    let numbers: [LabeledClaim]?
    let quote: Claim?
    let rights: RightsStatus
    var id: String { slug }
    var recordEntries: [LabeledClaim] { record ?? numbers ?? [] }
}

struct LostPitchesRoot: Codable, Hashable {
    let tiers: [LostPitchTierInfo]
    let entries: [LostPitch]
}

// MARK: - Knowledge wings (knowledge.json → [KnowledgeWing])

struct KnowledgeRelatedLink: Codable, Hashable {
    let label: String
    let to: String
}

struct KnowledgePullStat: Codable, Hashable {
    let label: String
    let claim: Claim
}

struct KnowledgeSection: Codable, Hashable {
    let heading: String
    let paragraphs: [String]
    let claims: [Claim]?
    let pullStat: KnowledgePullStat?
}

struct KnowledgeWing: Codable, Hashable, Identifiable {
    let slug: String
    let navLabel: String
    let eyebrow: String
    let title: String
    let summary: String
    let sub: String
    /// "powder" | "seam" in the bundle — kept String for forward-safety.
    let accent: String?
    let sections: [KnowledgeSection]
    let confidenceNote: String
    let educational: Bool?
    let related: [KnowledgeRelatedLink]?
    var id: String { slug }
}

// MARK: - Grip Library (grips.json → GripsFile)

struct GripAttackStep: Codable, Hashable {
    let label: String
    let detail: String
}

struct GripAttackPlan: Codable, Hashable {
    let intro: String
    let sequenceTitle: String
    let sequenceNote: String
    let sequence: [GripAttackStep]
}

struct GripEntry: Codable, Hashable, Identifiable {
    let id: String
    let label: String
    /// breaking/fastball/offspeed in the bundle.
    let family: PitchFamily
    let specimenSlug: String?
    let shortCue: String
    let visibleCue: String
    /// The flat confidence tier for this grip ("pitcher-own-words").
    let claimTier: ClaimConfidence
    let proofLimit: String
    let note: String
    let movement: String?
    let photos: [VisualReference]
    let film: GripFilm?
    let repertoireId: String?
    /// e.g. "note-only" — free text, kept String.
    let photoStatus: String?
}

struct GripsFile: Codable, Hashable {
    let intro: String
    let arsenal: String
    let commandNote: String
    let attackPlan: GripAttackPlan
    let proofLimit: String
    let entries: [GripEntry]
}

// MARK: - Manifest (manifest.json)

/// The build index. `counts` keys carry dots/hyphens (filenames), so it must be a
/// dictionary, not a struct. `sourcesLastChecked` is real freshness, never hardcoded.
struct ContentManifest: Codable, Hashable {
    let counts: [String: Int]
    let sourcesLastChecked: String
}
