import Foundation
import Supabase
import UIKit

struct CommunityService {
    private static let mediaBucket = "discussion-media"
    private static let signedURLTTL = 3600

    let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fieldNotes(pitchSlug: String) async throws -> [CommunityFieldNote] {
        try await client
            .from("field_notes")
            .select("id, pitch_slug, author_id, display_name, tweak, player_level, arm_slot, intent, claimed_result_kind, claimed_result_note, sample_size, evidence_url, evidence_label, note, source_tier, created_at")
            .eq("pitch_slug", value: pitchSlug)
            .order("created_at", ascending: false)
            .limit(25)
            .execute()
            .value
    }

    func discussionPosts(topicKey: String) async throws -> [DiscussionPost] {
        var posts: [DiscussionPost] = try await client
            .from("discussion_posts")
            .select("id, topic_key, author_id, display_name, parent_id, body, created_at")
            .eq("topic_key", value: topicKey)
            .order("created_at", ascending: false)
            .limit(40)
            .execute()
            .value

        let postIDs = posts.map(\.id)
        guard !postIDs.isEmpty else { return posts }

        let mediaRows: [DiscussionMedia] = try await client
            .from("discussion_media")
            .select("id, post_id, storage_path, kind, width, height")
            .in("post_id", values: postIDs.map { $0 as any PostgrestFilterValue })
            .execute()
            .value

        let signedMedia = try await signMedia(mediaRows)
        for index in posts.indices {
            posts[index].media = signedMedia[posts[index].id] ?? []
        }
        return posts
    }

    func submitFieldNote(_ note: NewFieldNote) async throws {
        let trimmedTweak = note.tweak.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTweak.isEmpty else {
            throw CommunityServiceError.invalidFieldNote("Add the grip change or cue before filing.")
        }

        try await client
            .from("field_notes")
            .insert(note)
            .execute()
    }

    func submitPost(_ post: NewDiscussionPost) async throws {
        try await client
            .from("discussion_posts")
            .insert(post)
            .execute()
    }

    func acceptMediaTerms() async throws {
        try await client
            .rpc("accept_media_terms")
            .execute()
    }

    func uploadImage(_ image: PreparedCommunityImage, topicKey: String, postID: String, userID: String) async throws {
        guard image.mimeType == "image/jpeg" || image.mimeType == "image/png" || image.mimeType == "image/webp" else {
            throw CommunityServiceError.unsupportedMedia
        }

        let mediaID = UUID().uuidString
        let path = "\(userID)/\(mediaID).\(image.fileExtension)"
        try await client.storage
            .from(Self.mediaBucket)
            .upload(
                path,
                data: image.data,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: image.mimeType,
                    upsert: false
                )
            )

        let row = NewDiscussionMedia(
            id: mediaID,
            postID: postID,
            topicKey: topicKey,
            storagePath: path,
            mimeType: image.mimeType,
            kind: "image",
            byteSize: image.data.count,
            width: image.width,
            height: image.height
        )

        do {
            try await client
                .from("discussion_media")
                .insert(row)
                .execute()
        } catch {
            // The file uploaded but its row didn't land — don't leave an orphan
            // in storage. Best-effort cleanup, then surface the original failure.
            _ = try? await client.storage.from(Self.mediaBucket).remove(paths: [path])
            throw error
        }
    }

    func reportFieldNote(id: String, reason: String?) async throws {
        try await client
            .from("note_reports")
            .insert(CommunityReport(noteID: id, postID: nil, mediaID: nil, reason: reason))
            .execute()
    }

    func reportPost(id: String, reason: String?) async throws {
        try await client
            .from("discussion_reports")
            .insert(CommunityReport(noteID: nil, postID: id, mediaID: nil, reason: reason))
            .execute()
    }

    func blockUser(blockedID: String) async throws {
        try await client
            .rpc("block_user", params: BlockUserParams(targetUser: blockedID))
            .execute()
    }

    func unblockUser(blockedID: String) async throws {
        try await client
            .rpc("unblock_user", params: BlockUserParams(targetUser: blockedID))
            .execute()
    }

    func blockedContributors() async throws -> [BlockedContributor] {
        try await client
            .rpc("my_blocked_users")
            .execute()
            .value
    }

    private func signMedia(_ rows: [DiscussionMedia]) async throws -> [String: [DiscussionMedia]] {
        guard !rows.isEmpty else { return [:] }

        let results = try await client.storage
            .from(Self.mediaBucket)
            .createSignedURLs(paths: rows.map(\.storagePath), expiresIn: Self.signedURLTTL)
        let urlsByPath = Dictionary(uniqueKeysWithValues: results.compactMap { result -> (String, URL)? in
            guard let signedURL = result.signedURL else { return nil }
            return (result.path, signedURL)
        })
        let failedPaths = Set(results.compactMap { result in
            result.signedURL == nil ? result.path : nil
        })

        var grouped: [String: [DiscussionMedia]] = [:]
        for var row in rows {
            row.signedURL = urlsByPath[row.storagePath]
            if failedPaths.contains(row.storagePath) {
                row.signingError = "Media unavailable."
            }
            grouped[row.postID, default: []].append(row)
        }
        return grouped
    }

    static func prepareImage(data: Data, maxLongEdge: CGFloat = 2048, maxBytes: Int = 8 * 1024 * 1024) throws -> PreparedCommunityImage {
        guard let source = UIImage(data: data), source.size.width > 0, source.size.height > 0 else {
            throw CommunityServiceError.unsupportedMedia
        }

        let longEdge = max(source.size.width, source.size.height)
        let scale = min(1, maxLongEdge / longEdge)
        let targetSize = CGSize(width: floor(source.size.width * scale), height: floor(source.size.height * scale))

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            source.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        guard let jpeg = resized.jpegData(compressionQuality: 0.82), jpeg.count <= maxBytes else {
            throw CommunityServiceError.imageTooLarge
        }

        return PreparedCommunityImage(
            data: jpeg,
            mimeType: "image/jpeg",
            width: Int(targetSize.width),
            height: Int(targetSize.height),
            fileExtension: "jpg"
        )
    }

    static func userMessage(for error: Error, fallback: String = "Could not save that just now. Try again.") -> String {
        if let communityError = error as? CommunityServiceError {
            return communityError.errorDescription ?? fallback
        }

        let raw = "\(error.localizedDescription) \(String(describing: error))".lowercased()
        if raw.contains("auth_required") || raw.contains("jwt") || raw.contains("not authenticated") || raw.contains("permission denied") {
            return "Sign in before doing that."
        }
        if raw.contains("permanent account") {
            return "Use a permanent signed-in account before uploading images."
        }
        if raw.contains("rate_limit") {
            return "Too many community actions in a short time. Wait a bit and try again."
        }
        if raw.contains("content_blocked") || raw.contains("banned") {
            return "That text contains language Pitch Atlas does not allow."
        }
        if raw.contains("media_blocked") || raw.contains("mime") || raw.contains("file type") {
            return "That image could not be attached. Check the file type and upload terms."
        }
        if raw.contains("weak_tier_requires_note") {
            return "Add a short note explaining where the claim came from."
        }
        if raw.contains("blocked_interaction") {
            return "That conversation is not available after a block."
        }
        if raw.contains("self_block_rejected") || raw.contains("blocked_users_no_self_block") {
            return "You cannot block yourself."
        }
        if raw.contains("invalid_block_target") {
            return "Choose a contributor first."
        }
        if raw.contains("duplicate key") || raw.contains("23505") {
            return raw.contains("blocked") ? "That contributor is already blocked." : "That action is already recorded."
        }
        if raw.contains("check constraint") || raw.contains("violates") || raw.contains("value too long") {
            return "One field does not match the allowed choices. Review the form and try again."
        }
        if raw.contains("invalid_parent") || raw.contains("too_deep") {
            return "That reply target is not available."
        }
        return fallback
    }
}

enum CommunityServiceError: LocalizedError, Equatable {
    case unsupportedMedia
    case imageTooLarge
    case invalidFieldNote(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedMedia:
            return "Pitch Atlas iOS accepts still images only."
        case .imageTooLarge:
            return "That image is too large after compression. Choose a smaller file."
        case .invalidFieldNote(let message):
            return message
        }
    }
}
