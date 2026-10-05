import Foundation

// =============================================================================
// Wing bundles — softball, hidden notes, quotes, credited media, plate 273
// =============================================================================
// Generated from web src/data by tools/generate-content. Enum-like strings stay
// String so a new web value can never brick the decode; every figure is a Claim
// that carries its source and tier, exactly like the baseball wing.
// =============================================================================

struct SoftballCopy: Codable, Hashable {
    let description: String
    let heroSub: String
    let phaseLede: String
}

/// A fastpitch pitch, filed light (the web's SoftballPitch).
struct SoftballPitch: Codable, Hashable, Identifiable {
    let slug: String
    let name: String
    /// fastball | rise | drop | breaking | offspeed
    let family: String
    let specimenNo: String
    /// standard | advanced | developing
    let status: String
    let tagline: String
    let intro: String
    let grip: Claim
    let spin: Claim
    let movement: Claim
    let role: String
    let physicsNote: Claim?
    /// The honest open question on file, when the sources record one.
    let openQuestion: String?
    let notableThrowers: String?
    let flagship: Bool?
    var id: String { slug }
}

/// One phase of the windmill delivery, sourced.
struct WindmillPhase: Codable, Hashable, Identifiable {
    let num: String
    let name: String
    let what: Claim
    var id: String { num }
}

/// A sourced teaching block on the fundamentals page.
struct FundamentalBlock: Codable, Hashable, Identifiable {
    let id: String
    let index: String
    let label: String
    let lede: String
    let claims: [Claim]
    let educational: Bool?
}

struct SlowpitchNote: Codable, Hashable {
    let label: String
    let claim: Claim
}

struct SoftballBundle: Codable, Hashable {
    let fastpitchCopy: SoftballCopy
    let hubFastpitchBlurb: String
    let pitches: [SoftballPitch]
    let craftsmen: [Craftsman]
    let windmillPhases: [WindmillPhase]
    let fundamentalBlocks: [FundamentalBlock]
    let slowpitchNotes: [SlowpitchNote]
    let slowpitchCraft: [String]
    let slowpitchFormats: [String]

    static let empty = SoftballBundle(
        fastpitchCopy: SoftballCopy(description: "", heroSub: "", phaseLede: ""), hubFastpitchBlurb: "",
        pitches: [], craftsmen: [], windmillPhases: [], fundamentalBlocks: [], slowpitchNotes: [],
        slowpitchCraft: [], slowpitchFormats: [])
}

/// A hidden note: one real, sourced fact filed at a named place in the archive.
struct Tidbit: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let claim: Claim
    /// Where the note is filed, in the web's own words ("The Shape Lab").
    let eggLocation: String
}

/// One line in the rotating quote pool (curated lines plus craftsman quotes).
struct AtlasQuote: Codable, Hashable, Identifiable {
    let id: String
    let attribution: String
    let context: String?
    let claim: Claim
}

struct ExternalSource: Codable, Hashable, Identifiable {
    let id: String
    let platform: String
    let name: String
    let handle: String
    let canonicalUrl: String
    let trustLane: String
    let ingestMethod: String
    let autoPublish: Bool
    let active: Bool
}

struct ExternalContentTags: Codable, Hashable {
    let pitchSlugs: [String]
    let craftsmanSlugs: [String]
    let families: [String]
    let topics: [String]
}

/// A credited post filed beside the archive. TikTok rows play in the official
/// player; X rows are credited outbound links. No media file is bundled.
struct ExternalContentItem: Codable, Hashable, Identifiable {
    let id: String
    let platform: String
    let externalId: String
    let canonicalUrl: String
    let sourceId: String
    let sourceName: String
    let sourceHandle: String
    let sourceUrl: String
    let title: String
    let lede: String
    let sourceCaption: String?
    let publishedAt: String
    let retrievedAt: String
    let tags: ExternalContentTags
    let trustLane: String
    let moderationState: String
    let availability: String
    let embedMode: String
    let featured: Bool?
    /// Published and not removed — the same gate as the web's externalContentFor.
    var isShowable: Bool { moderationState == "published" && availability != "removed" }
}

struct ExternalMediaBundle: Codable, Hashable {
    let sources: [ExternalSource]
    let items: [ExternalContentItem]
    static let empty = ExternalMediaBundle(sources: [], items: [])
}

/// Media filed to a craftsman: a TikTok row (with its clip) or a credited X post.
struct CraftsmanMediaItem: Codable, Hashable, Identifiable {
    /// "tiktok" | "x-rivera"
    let kind: String
    let id: String
    let title: String
    let lede: String
    let author: String
    let authorUrl: String
    let url: String
    let retrievedAt: String
    let craftsmanSlug: String
    let craftsmanName: String
    let clip: TeachingClip?
}

/// One traced frame of Muybridge plate 273.
struct Plate273Frame: Codable, Hashable, Identifiable {
    let id: String
    /// [minX, minY, width, height] of the frame's own box.
    let viewBox: [Double]
    /// Closed straight-line outlines, each an array of [x, y] points (even-odd fill).
    let subpaths: [[[Double]]]
}

/// Eadweard Muybridge, Animal Locomotion (1887), plate 273 "Baseball, pitching":
/// ten silhouettes traced from the public-domain scan. Only the outline ships.
struct Plate273: Codable, Hashable {
    let viewBox: String
    let frameCount: Int
    let plate: Int
    let title: String
    let maker: String
    let work: String
    let year: Int
    let rights: String
    let source: Source
    let frames: [Plate273Frame]
}
