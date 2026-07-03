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

    /// Ranked, visible field notes for one pitch. Sorts on `base_rank` — the live
    /// ranking a DB trigger maintains via note_base_rank() — with created_at as
    /// the tiebreak, matching the web's listNotes. Ordering is purely SQL; the
    /// client never re-sorts.
    func fieldNotes(pitchSlug: String) async throws -> [CommunityFieldNote] {
        try await client
            .from("field_notes")
            .select("id, pitch_slug, author_id, display_name, tweak, player_level, arm_slot, intent, claimed_result_kind, claimed_result_note, sample_size, evidence_url, evidence_label, note, source_tier, adoption_count, helpful_count, base_rank, created_at")
            .eq("pitch_slug", value: pitchSlug)
            .order("base_rank", ascending: false)
            .order("created_at", ascending: false)
            .limit(25)
            .execute()
            .value
    }

    /// The viewer's own Tried This / Helpful marks for the visible notes.
    ///
    /// READ path: never call ensureSessionForWrite from here — the caller only
    /// invokes this when a session already exists, so hydrating flags can never
    /// mint an account. RLS scopes both tables to the viewer's own rows.
    ///
    /// Direct selects first; if a deployment still has older engagement grants,
    /// fall back to the legacy `viewer_note_engagement` RPC filtered to the
    /// visible ids (the web's fallbackViewerEngagement). If both paths fail the
    /// flags degrade to neutral — counts still render, and the trigger-maintained
    /// server counts correct any divergence on the next reload.
    func viewerEngagement(noteIDs: [String]) async -> (tried: Set<String>, helpful: Set<String>) {
        let ids = Array(Set(noteIDs.filter { !$0.isEmpty }))
        guard !ids.isEmpty else { return ([], []) }

        do {
            async let triedRows: [NoteEngagementRef] = client
                .from("note_tries")
                .select("note_id")
                .in("note_id", values: ids.map { $0 as any PostgrestFilterValue })
                .execute()
                .value
            async let helpfulRows: [NoteEngagementRef] = client
                .from("note_helpful")
                .select("note_id")
                .in("note_id", values: ids.map { $0 as any PostgrestFilterValue })
                .execute()
                .value
            return (Set(try await triedRows.map(\.noteID)), Set(try await helpfulRows.map(\.noteID)))
        } catch {
            do {
                let rows: [ViewerNoteEngagementRow] = try await client
                    .rpc("viewer_note_engagement")
                    .execute()
                    .value
                let visible = Set(ids)
                let scoped = rows.filter { visible.contains($0.noteID) }
                return (
                    Set(scoped.filter(\.tried).map(\.noteID)),
                    Set(scoped.filter(\.helpful).map(\.noteID))
                )
            } catch {
                return ([], [])
            }
        }
    }

    /// Toggle "Tried this" (adoption). One row per account is enforced by the DB.
    func setTried(noteID: String, on: Bool) async throws {
        try await setEngagement(table: "note_tries", noteID: noteID, on: on)
    }

    /// Toggle "Helpful". One row per account is enforced by the DB.
    func setHelpful(noteID: String, on: Bool) async throws {
        try await setEngagement(table: "note_helpful", noteID: noteID, on: on)
    }

    private func setEngagement(table: String, noteID: String, on: Bool) async throws {
        if on {
            do {
                try await client
                    .from(table)
                    .insert(NoteEngagementInsert(noteID: noteID))
                    .execute()
            } catch where Self.isUniqueViolation(error) {
                // 23505 = the one-per-account unique violation: the mark is
                // already on, which is the state the user asked for. Success.
            }
        } else {
            let userID = try await currentUserID()
            try await client
                .from(table)
                .delete()
                .eq("note_id", value: noteID)
                .eq("user_id", value: userID)
                .execute()
        }
    }

    /// The signed-in user id for delete scoping. Write callers run
    /// ensureSessionForWrite first, so a missing session here is a real fault,
    /// not a signal to mint — surface it as the session error.
    private func currentUserID() async throws -> String {
        do {
            let session = try await client.auth.session
            return String(describing: session.user.id)
        } catch {
            throw CommunityServiceError.sessionStartFailed
        }
    }

    /// Postgres 23505 (unique violation). The structured PostgrestError code is
    /// authoritative; the message shape is the fallback for any transport that
    /// surfaces the failure as a different error type — same layered matching
    /// as AuthSessionStore.isIdentityConflict.
    static func isUniqueViolation(_ error: Error) -> Bool {
        if let postgrestError = error as? PostgrestError, postgrestError.code == "23505" {
            return true
        }
        let raw = "\(error.localizedDescription) \(String(describing: error))".lowercased()
        return raw.contains("23505") || raw.contains("duplicate key")
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
        let urlsByPath = results.reduce(into: [String: URL]()) { urls, result in
            guard let signedURL = result.signedURL else { return }
            urls[result.path] = signedURL
        }
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
        if let validationError = error as? CommunityValidationError {
            return validationError.errorDescription ?? fallback
        }
        if let communityError = error as? CommunityServiceError {
            return communityError.errorDescription ?? fallback
        }

        let raw = "\(error.localizedDescription) \(String(describing: error))".lowercased()
        if raw.contains("auth_required") || raw.contains("jwt") || raw.contains("not authenticated") || raw.contains("permission denied") {
            return "Sign in before doing that."
        }
        if raw.contains("row-level security") || raw.contains("rls") {
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
    case invalidDiscussionPost(String)
    /// The lazy anonymous session could not be started or read on write intent.
    /// Same copy as the web's SESSION_START_ERROR.
    case sessionStartFailed

    var errorDescription: String? {
        switch self {
        case .unsupportedMedia:
            return "Pitch Atlas iOS accepts still images only."
        case .imageTooLarge:
            return "That image is too large after compression. Choose a smaller file."
        case .sessionStartFailed:
            return "Could not start your community session just now. Try again."
        case .invalidFieldNote(let message):
            return message
        case .invalidDiscussionPost(let message):
            return message
        }
    }
}
