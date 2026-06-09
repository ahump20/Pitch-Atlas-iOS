import Foundation

enum CommunityLoadState<Value> {
    case idle
    case loading
    case empty
    case loaded(Value)
    case failed(String)
}

struct CommunityFieldNote: Decodable, Identifiable, Hashable {
    let id: String
    let pitchSlug: String
    let authorID: String
    let displayName: String
    let tweak: String
    let playerLevel: String
    let armSlot: String
    let intent: String
    let claimedResultKind: String
    let claimedResultNote: String?
    let note: String?
    let sourceTier: String
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
    let playerLevel: String
    let armSlot: String
    let intent: String
    let claimedResultKind: String
    let claimedResultNote: String?
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

struct BlockedUserInsert: Encodable {
    let blockerID: String
    let blockedID: String

    enum CodingKeys: String, CodingKey {
        case blockerID = "blocker_id"
        case blockedID = "blocked_id"
    }
}

struct MediaTermsInsert: Encodable {
    let userID: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
    }
}

struct PreparedCommunityImage {
    let data: Data
    let mimeType: String
    let width: Int
    let height: Int
    let fileExtension: String
}
