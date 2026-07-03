import Foundation

enum CommunityLoadState<Value> {
    case idle
    case loading
    case empty
    case loaded(Value)
    case failed(String)
}

enum CommunityPlayerLevel: String, Codable, CaseIterable, Identifiable, Hashable {
    case youth
    case highSchool = "high-school"
    case collegePlus = "college-plus"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .youth: return "Youth"
        case .highSchool: return "High school"
        case .collegePlus: return "College and up"
        }
    }
}

enum CommunityArmSlot: String, Codable, CaseIterable, Identifiable, Hashable {
    case overTheTop = "over-the-top"
    case threeQuarter = "three-quarter"
    case sidearm
    case submarine

    var id: String { rawValue }

    var label: String {
        switch self {
        case .overTheTop: return "Over the top"
        case .threeQuarter: return "Three-quarter"
        case .sidearm: return "Sidearm"
        case .submarine: return "Submarine"
        }
    }
}

enum CommunityPitchIntent: String, Codable, CaseIterable, Identifiable, Hashable {
    case moreMovement = "more-movement"
    case lessMovement = "less-movement"
    case addedVelocity = "added-velocity"
    case reducedVelocity = "reduced-velocity"
    case betterCommand = "better-command"
    case deception
    case reduceStress = "reduce-stress"
    case other

    static var allCases: [CommunityPitchIntent] {
        [
            .moreMovement,
            .lessMovement,
            .addedVelocity,
            .reducedVelocity,
            .betterCommand,
            .deception,
            .other,
        ]
    }

    var id: String { rawValue }

    var label: String {
        switch self {
        case .moreMovement: return "More movement"
        case .lessMovement: return "Less movement"
        case .addedVelocity: return "Firmer feel"
        case .reducedVelocity: return "Softer feel"
        case .betterCommand: return "Better command"
        case .deception: return "More deception"
        case .reduceStress: return "Easier feel"
        case .other: return "Something else"
        }
    }
}

enum CommunityClaimedResultKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case moreMovement = "more-movement"
    case betterCommand = "better-command"
    case velocityGain = "velocity-gain"
    case reducedDiscomfort = "reduced-discomfort"
    case inconsistent
    case workedInBullpen = "worked-in-bullpen"
    case workedInGame = "worked-in-game"
    case noNoticeableChange = "no-noticeable-change"

    static var allCases: [CommunityClaimedResultKind] {
        [
            .moreMovement,
            .betterCommand,
            .velocityGain,
            .inconsistent,
            .workedInBullpen,
            .workedInGame,
            .noNoticeableChange,
        ]
    }

    var id: String { rawValue }

    var label: String {
        switch self {
        case .moreMovement: return "More movement"
        case .betterCommand: return "Better command"
        case .velocityGain: return "Firmer result"
        case .reducedDiscomfort: return "Easier feel"
        case .inconsistent: return "Inconsistent so far"
        case .workedInBullpen: return "Worked in the bullpen"
        case .workedInGame: return "Worked in a game"
        case .noNoticeableChange: return "No noticeable change"
        }
    }
}

enum CommunitySourceTier: String, Codable, CaseIterable, Identifiable, Hashable {
    case communityFirsthand = "community-firsthand"
    case coachObserved = "coach-observed"
    case reputableAnalysis = "reputable-analysis"
    case secondhandAttributed = "secondhand-attributed"
    case unverified

    var id: String { rawValue }

    var label: String {
        switch self {
        case .communityFirsthand: return "Community firsthand"
        case .coachObserved: return "Coach observed"
        case .reputableAnalysis: return "Reputable analysis"
        case .secondhandAttributed: return "Secondhand attributed"
        case .unverified: return "Unverified"
        }
    }
}

struct CommunityFieldNote: Decodable, Identifiable, Hashable {
    let id: String
    let pitchSlug: String
    let authorID: String
    let displayName: String
    let tweak: String
    let playerLevel: CommunityPlayerLevel
    let armSlot: CommunityArmSlot
    let intent: CommunityPitchIntent
    let claimedResultKind: CommunityClaimedResultKind
    let claimedResultNote: String?
    let sampleSize: Int?
    let evidenceURL: String?
    let evidenceLabel: String?
    let note: String?
    let sourceTier: CommunitySourceTier
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case pitchSlug = "pitch_slug"
        case authorID = "author_id"
        case displayName = "display_name"
        case tweak
        case playerLevel = "player_level"
        case armSlot = "arm_slot"
        case intent
        case claimedResultKind = "claimed_result_kind"
        case claimedResultNote = "claimed_result_note"
        case sampleSize = "sample_size"
        case evidenceURL = "evidence_url"
        case evidenceLabel = "evidence_label"
        case note
        case sourceTier = "source_tier"
        case createdAt = "created_at"
    }
}

struct DiscussionPost: Decodable, Identifiable, Hashable {
    let id: String
    let topicKey: String
    let authorID: String
    let displayName: String
    let parentID: String?
    let body: String
    let createdAt: String
    var media: [DiscussionMedia] = []

    enum CodingKeys: String, CodingKey {
        case id
        case topicKey = "topic_key"
        case authorID = "author_id"
        case displayName = "display_name"
        case parentID = "parent_id"
        case body
        case createdAt = "created_at"
    }
}

struct DiscussionMedia: Decodable, Identifiable, Hashable {
    let id: String
    let postID: String
    let storagePath: String
    let kind: String
    let width: Int?
    let height: Int?
    var signedURL: URL?
    var signingError: String?

    enum CodingKeys: String, CodingKey {
        case id
        case postID = "post_id"
        case storagePath = "storage_path"
        case kind
        case width
        case height
    }
}

struct NewFieldNote: Encodable {
    let pitchSlug: String
    let displayName: String
    let tweak: String
    let playerLevel: CommunityPlayerLevel
    let armSlot: CommunityArmSlot
    let intent: CommunityPitchIntent
    let claimedResultKind: CommunityClaimedResultKind
    let claimedResultNote: String?
    let sampleSize: Int?
    let evidenceURL: String?
    let evidenceLabel: String?
    let sourceTier: CommunitySourceTier
    let note: String?

    enum CodingKeys: String, CodingKey {
        case pitchSlug = "pitch_slug"
        case displayName = "display_name"
        case tweak
        case playerLevel = "player_level"
        case armSlot = "arm_slot"
        case intent
        case claimedResultKind = "claimed_result_kind"
        case claimedResultNote = "claimed_result_note"
        case sampleSize = "sample_size"
        case evidenceURL = "evidence_url"
        case evidenceLabel = "evidence_label"
        case sourceTier = "source_tier"
        case note
    }
}

enum CommunityValidationError: LocalizedError, Equatable {
    case missingTweak
    case invalidDisplayName
    case valueTooLong(field: String, max: Int)
    case invalidSampleSize
    case invalidEvidenceURL

    var errorDescription: String? {
        switch self {
        case .missingTweak:
            return "Add the grip change or cue before filing."
        case .invalidDisplayName:
            return "Your display name must be 2 to 40 characters."
        case .valueTooLong(let field, let max):
            return "\(field) must be \(max) characters or fewer."
        case .invalidSampleSize:
            return "Sample size must be a number from 0 to 100000."
        case .invalidEvidenceURL:
            return "Evidence URL must start with http:// or https://."
        }
    }
}

enum CommunityFieldNoteLimits {
    static let displayName = 40
    static let tweak = 160
    static let resultNote = 200
    static let evidenceURL = 512
    static let evidenceLabel = 80
    static let note = 200
    static let sampleSize = 0...100_000
}

extension NewFieldNote {
    static func validated(
        pitchSlug: String,
        displayName: String,
        tweak: String,
        playerLevel: CommunityPlayerLevel,
        armSlot: CommunityArmSlot,
        intent: CommunityPitchIntent,
        claimedResultKind: CommunityClaimedResultKind,
        claimedResultNote: String,
        sampleSizeText: String,
        evidenceURL: String,
        evidenceLabel: String,
        sourceTier: CommunitySourceTier,
        note: String
    ) throws -> NewFieldNote {
        let cleanDisplayName = try validatedDisplayName(displayName)
        let cleanTweak = try requiredText(
            tweak,
            missing: .missingTweak,
            field: "Grip change or cue",
            max: CommunityFieldNoteLimits.tweak
        )
        let cleanResultNote = try optionalText(
            claimedResultNote,
            field: "Result detail",
            max: CommunityFieldNoteLimits.resultNote
        )
        let cleanEvidenceLabel = try optionalText(
            evidenceLabel,
            field: "Evidence label",
            max: CommunityFieldNoteLimits.evidenceLabel
        )
        let cleanEvidenceURL = try validatedEvidenceURL(evidenceURL)
        let cleanNote = try optionalText(
            note,
            field: "Plain words note",
            max: CommunityFieldNoteLimits.note
        )
        let sampleSize = try parsedSampleSize(sampleSizeText)

        return NewFieldNote(
            pitchSlug: pitchSlug,
            displayName: cleanDisplayName,
            tweak: cleanTweak,
            playerLevel: playerLevel,
            armSlot: armSlot,
            intent: intent,
            claimedResultKind: claimedResultKind,
            claimedResultNote: cleanResultNote,
            sampleSize: sampleSize,
            evidenceURL: cleanEvidenceURL,
            evidenceLabel: cleanEvidenceLabel,
            sourceTier: sourceTier,
            note: cleanNote
        )
    }

    private static func validatedDisplayName(_ value: String) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (2...CommunityFieldNoteLimits.displayName).contains(trimmed.count) else {
            throw CommunityValidationError.invalidDisplayName
        }
        return trimmed
    }

    private static func requiredText(
        _ value: String,
        missing: CommunityValidationError,
        field: String,
        max: Int
    ) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw missing }
        guard trimmed.count <= max else {
            throw CommunityValidationError.valueTooLong(field: field, max: max)
        }
        return trimmed
    }

    private static func optionalText(_ value: String, field: String, max: Int) throws -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.count <= max else {
            throw CommunityValidationError.valueTooLong(field: field, max: max)
        }
        return trimmed
    }

    static func parsedSampleSize(_ value: String) throws -> Int? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let parsed = Int(trimmed), CommunityFieldNoteLimits.sampleSize.contains(parsed) else {
            throw CommunityValidationError.invalidSampleSize
        }
        return parsed
    }

    static func validatedEvidenceURL(_ value: String) throws -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.count <= CommunityFieldNoteLimits.evidenceURL else {
            throw CommunityValidationError.valueTooLong(
                field: "Evidence URL",
                max: CommunityFieldNoteLimits.evidenceURL
            )
        }
        guard
            let components = URLComponents(string: trimmed),
            let scheme = components.scheme?.lowercased(),
            (scheme == "http" || scheme == "https"),
            let host = components.host,
            !host.isEmpty
        else {
            throw CommunityValidationError.invalidEvidenceURL
        }
        return trimmed
    }
}

struct NewDiscussionPost: Encodable {
    let id: String
    let topicKey: String
    let displayName: String
    let body: String
    let parentID: String?

    enum CodingKeys: String, CodingKey {
        case id
        case topicKey = "topic_key"
        case displayName = "display_name"
        case body
        case parentID = "parent_id"
    }
}

enum DiscussionPostLimits {
    static let displayName = 40
    static let body = 4000
}

extension NewDiscussionPost {
    static func validated(
        id: String,
        topicKey: String,
        displayName: String,
        body: String,
        parentID: String?
    ) throws -> NewDiscussionPost {
        let cleanDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (2...DiscussionPostLimits.displayName).contains(cleanDisplayName.count) else {
            throw CommunityServiceError.invalidDiscussionPost("Your display name must be 2 to 40 characters.")
        }

        let cleanBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanBody.isEmpty else {
            throw CommunityServiceError.invalidDiscussionPost("Add a post before submitting.")
        }
        guard cleanBody.count <= DiscussionPostLimits.body else {
            throw CommunityServiceError.invalidDiscussionPost("Discussion posts must be 4000 characters or fewer.")
        }

        return NewDiscussionPost(
            id: id,
            topicKey: topicKey,
            displayName: cleanDisplayName,
            body: cleanBody,
            parentID: parentID
        )
    }
}

struct NewDiscussionMedia: Encodable {
    let id: String
    let postID: String
    let topicKey: String
    let storagePath: String
    let mimeType: String
    let kind: String
    let byteSize: Int
    let width: Int?
    let height: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case postID = "post_id"
        case topicKey = "topic_key"
        case storagePath = "storage_path"
        case mimeType = "mime_type"
        case kind
        case byteSize = "byte_size"
        case width
        case height
    }
}

struct CommunityReport: Encodable {
    let noteID: String?
    let postID: String?
    let mediaID: String?
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case noteID = "note_id"
        case postID = "post_id"
        case mediaID = "media_id"
        case reason
    }
}

struct BlockedContributor: Decodable, Identifiable, Hashable {
    let blockedID: String
    let displayName: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case blockedID = "blocked_id"
        case displayName = "display_name"
        case createdAt = "created_at"
    }

    var id: String { blockedID }
}

struct BlockUserParams: Encodable {
    let targetUser: String

    enum CodingKeys: String, CodingKey {
        case targetUser = "target_user"
    }
}

struct PreparedCommunityImage: Equatable {
    let data: Data
    let mimeType: String
    let width: Int
    let height: Int
    let fileExtension: String
}

enum CommunityVisibility {
    static func hiddenAuthorIDs(from contributors: [BlockedContributor]) -> Set<String> {
        Set(contributors.map(\.blockedID))
    }

    static func visibleFieldNotes(_ notes: [CommunityFieldNote], hiddenAuthorIDs: Set<String>) -> [CommunityFieldNote] {
        notes.filter { !hiddenAuthorIDs.contains($0.authorID) }
    }

    static func visibleDiscussionPosts(_ posts: [DiscussionPost], hiddenAuthorIDs: Set<String>) -> [DiscussionPost] {
        posts.filter { !hiddenAuthorIDs.contains($0.authorID) }
    }
}

/// Contribution gating for the community composers. Sign-in is deliberately
/// absent from this decision: participation is anonymous-first, and the account
/// is minted lazily on write intent (AuthSessionStore.ensureSessionForWrite).
/// The two attestations stay mandatory — the App Review notes rely on them.
enum CommunityContributionGate {
    static func canContribute(guidelinesAccepted: Bool, ageConfirmed: Bool) -> Bool {
        guidelinesAccepted && ageConfirmed
    }
}
