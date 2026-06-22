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

    var id: String { rawValue }

    var label: String {
        switch self {
        case .moreMovement: return "More movement"
        case .lessMovement: return "Less movement"
        case .addedVelocity: return "Firmer feel"
        case .reducedVelocity: return "Softer feel"
        case .betterCommand: return "Better command"
        case .deception: return "More deception"
        case .reduceStress: return "Less stress"
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

    var id: String { rawValue }

    var label: String {
        switch self {
        case .moreMovement: return "More movement"
        case .betterCommand: return "Better command"
        case .velocityGain: return "Firmer result"
        case .reducedDiscomfort: return "Less discomfort"
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
    let ownerID: String
    let topicKey: String
    let storagePath: String
    let mimeType: String
    let kind: String
    let byteSize: Int
    let width: Int?
    let height: Int?
    var signedURL: URL?
    var signingError: String?

    enum CodingKeys: String, CodingKey {
        case id
        case postID = "post_id"
        case ownerID = "owner_id"
        case topicKey = "topic_key"
        case storagePath = "storage_path"
        case mimeType = "mime_type"
        case kind
        case byteSize = "byte_size"
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

struct MediaTermsInsert: Encodable {
    let userID: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
    }
}

struct PreparedCommunityImage: Equatable {
    let data: Data
    let mimeType: String
    let width: Int
    let height: Int
    let fileExtension: String
}
