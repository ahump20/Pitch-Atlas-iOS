import Foundation
import Supabase
import UIKit

struct CommunityService {
    let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fieldNotes(pitchSlug: String) async throws -> [CommunityFieldNote] {
        try await client
            .from("field_notes")
            .select()
            .eq("pitch_slug", value: pitchSlug)
            .order("created_at", ascending: false)
            .limit(25)
            .execute()
            .value
    }

    func discussionPosts(topicKey: String) async throws -> [DiscussionPost] {
        try await client
            .from("discussion_posts")
            .select()
            .eq("topic_key", value: topicKey)
            .order("created_at", ascending: false)
            .limit(40)
            .execute()
            .value
    }

    func submitFieldNote(_ note: NewFieldNote) async throws {
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

    func acceptMediaTerms(userID: String) async throws {
        let row = MediaTermsInsert(userID: userID)
        _ = try? await client
            .from("discussion_media_terms")
            .insert(row)
            .execute()
    }

    func uploadImage(_ image: PreparedCommunityImage, topicKey: String, postID: String, userID: String) async throws {
        guard image.mimeType == "image/jpeg" || image.mimeType == "image/png" || image.mimeType == "image/webp" else {
            throw CommunityServiceError.unsupportedMedia
        }

        let mediaID = UUID().uuidString
        let path = "\(userID)/\(mediaID).\(image.fileExtension)"
        try await client.storage
            .from("discussion-media")
            .upload(
                path: path,
                file: image.data,
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
            _ = try? await client.storage.from("discussion-media").remove(paths: [path])
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

    func blockUser(blockerID: String, blockedID: String) async throws {
        try await client
            .from("blocked_users")
            .insert(BlockedUserInsert(blockerID: blockerID, blockedID: blockedID))
            .execute()
    }

    func unblockUser(blockerID: String, blockedID: String) async throws {
        try await client
            .from("blocked_users")
            .delete()
            .eq("blocker_id", value: blockerID)
            .eq("blocked_id", value: blockedID)
            .execute()
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
}

enum CommunityServiceError: LocalizedError, Equatable {
    case unsupportedMedia
    case imageTooLarge

    var errorDescription: String? {
        switch self {
        case .unsupportedMedia:
            return "Pitch Atlas iOS accepts still images only."
        case .imageTooLarge:
            return "That image is too large after compression. Choose a smaller file."
        }
    }
}
