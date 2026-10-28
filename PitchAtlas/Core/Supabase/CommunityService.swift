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

    /// Approved, visible field notes for one pitch, through the server's moderated
    /// public read (`list_public_field_notes`, the web's listNotes). The function
    /// owns the review gate, the hidden flag, and the viewer-block gate, and sorts
    /// on `base_rank` then `created_at`; the client never re-sorts. A held note —
    /// including the viewer's own pending one — never comes back from it.
    func fieldNotes(pitchSlug: String) async throws -> [CommunityFieldNote] {
        let rows: [LossyRow<CommunityFieldNote>] = try await client
            .rpc("list_public_field_notes", params: FieldNotesParams(pitchSlug: pitchSlug))
            .execute()
            .value
        return rows.compactMap(\.value)
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
            return AuthSessionStore.idString(session.user.id)
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

    /// The whole thread for one topic, the web's listThread: every visible post
    /// oldest first, media looked up in batches, then shaped by
    /// `CommunityThread.build` (top-level newest first, replies under their post).
    /// RLS returns only the public set; reading never mints a session.
    func discussionPosts(topicKey: String) async throws -> [DiscussionPost] {
        let rows: [LossyRow<DiscussionPost>] = try await client
            .from("discussion_posts")
            .select("id, topic_key, author_id, display_name, parent_id, body, created_at")
            .eq("topic_key", value: topicKey)
            .order("created_at", ascending: true)
            .execute()
            .value
        var posts = rows.compactMap(\.value)

        let postIDs = posts.map(\.id)
        guard !postIDs.isEmpty else { return [] }

        var mediaRows: [DiscussionMedia] = []
        for batch in Self.batches(postIDs) {
            let page: [DiscussionMedia] = try await client
                .from("discussion_media")
                .select("id, post_id, storage_path, kind, width, height")
                .in("post_id", values: batch.map { $0 as any PostgrestFilterValue })
                .execute()
                .value
            mediaRows.append(contentsOf: page)
        }

        let signedMedia = try await signMedia(mediaRows)
        for index in posts.indices {
            posts[index].media = signedMedia[posts[index].id] ?? []
        }
        return CommunityThread.build(posts)
    }

    /// The web's batch size for id lists and storage removes (lib/discussion.ts).
    static let batchSize = 100

    static func batches<T>(_ items: [T], size: Int = batchSize) -> [[T]] {
        stride(from: 0, to: items.count, by: size).map { Array(items[$0..<min($0 + size, items.count)]) }
    }

    /// The viewer's contributor profile (lib/community getIdentity): the handle,
    /// the claimed flag and the score. READ path: the caller only asks over an
    /// existing session, so a bullpen card never mints an account.
    func contributorIdentity(userID: String) async throws -> ContributorIdentity? {
        let rows: [ContributorIdentity] = try await client
            .from("profiles")
            .select("display_name, is_claimed, contribution_score, notes_count")
            .eq("id", value: userID)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// Keeps the handle a contributor files under (lib/community submitNote saves
    /// it before the insert). The profiles UPDATE grant covers display_name only.
    func setDisplayName(_ name: String, userID: String) async throws {
        try await client
            .from("profiles")
            .update(DisplayNameUpdate(displayName: name))
            .eq("id", value: userID)
            .execute()
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

    /// Insert the post and return the server-generated id. RETURNING is scoped
    /// to the id column on purpose: the column-scoped SELECT grant covers id,
    /// while `select()` (RETURNING *) would touch ungranted columns and fail.
    func submitPost(_ post: NewDiscussionPost) async throws -> String {
        struct InsertedPost: Decodable { let id: String }
        let inserted: InsertedPost = try await client
            .from("discussion_posts")
            .insert(post)
            .select("id")
            .single()
            .execute()
            .value
        return inserted.id
    }

    /// Delete the viewer's own post (the web's deletePost). A reply from another
    /// living contributor keeps it in place; the viewer's own files go best-effort
    /// after the row — the delete is the outcome the person sees.
    func deletePost(id postID: String, viewerID: String) async throws {
        struct ReplyRef: Decodable {
            let id: String
            let authorID: String?
            enum CodingKeys: String, CodingKey { case id, authorID = "author_id" }
        }
        struct MediaPathRef: Decodable {
            let storagePath: String?
            enum CodingKeys: String, CodingKey { case storagePath = "storage_path" }
        }
        let replies: [ReplyRef] = try await client
            .from("discussion_posts")
            .select("id, author_id")
            .eq("parent_id", value: postID)
            .execute()
            .value
        guard CommunityVisibility.canDeletePost(replyAuthorIDs: replies.map(\.authorID), viewerID: viewerID) else {
            throw CommunityServiceError.deleteBlockedByReplies
        }
        let cascade = [postID] + replies.map(\.id)
        var media: [MediaPathRef] = []
        for batch in Self.batches(cascade) {
            let page: [MediaPathRef] = try await client
                .from("discussion_media")
                .select("storage_path")
                .in("post_id", values: batch.map { $0 as any PostgrestFilterValue })
                .execute()
                .value
            media.append(contentsOf: page)
        }
        let ownPaths = media.compactMap(\.storagePath).filter { $0.hasPrefix("\(viewerID)/") }
        try await client
            .from("discussion_posts")
            .delete()
            .eq("id", value: postID)
            .execute()
        // The row delete already hid the post. Storage cleanup is best-effort and
        // never surfaces as an error the person can't act on.
        for batch in Self.batches(ownPaths) {
            _ = try? await client.storage.from(Self.mediaBucket).remove(paths: batch)
        }
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

        let fileName = UUID().uuidString
        let path = "\(userID)/\(fileName).\(image.fileExtension)"
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
        try await fileReport(table: "note_reports", CommunityReport(noteID: id, postID: nil, mediaID: nil, reason: reason))
    }

    func reportPost(id: String, reason: String?) async throws {
        try await fileReport(table: "discussion_reports", CommunityReport(noteID: nil, postID: id, mediaID: nil, reason: reason))
    }

    /// The web's reportMedia: a report on one attached file, not the whole post.
    func reportMedia(id: String, reason: String?) async throws {
        try await fileReport(table: "discussion_reports", CommunityReport(noteID: nil, postID: nil, mediaID: id, reason: reason))
    }

    /// One report per account per item: a second report of the same thing is
    /// already on file, which is what the person asked for (the web skips 23505 too).
    private func fileReport(table: String, _ report: CommunityReport) async throws {
        do {
            try await client
                .from(table)
                .insert(report)
                .execute()
        } catch where Self.isUniqueViolation(error) {
        }
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

        var results: [SignedURLResult] = []
        for batch in Self.batches(rows.map(\.storagePath)) {
            let page: [SignedURLResult] = try await client.storage
                .from(Self.mediaBucket)
                .createSignedURLs(paths: batch, expiresIn: Self.signedURLTTL)
            results.append(contentsOf: page)
        }
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
                // The web's wording for a file it can't show yet (DiscussionForum.tsx MediaItem).
                row.signingError = "Specimen under review"
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

    /// The safety triggers' tagged messages, with the web's fallback for each
    /// (lib/discussion.ts taggedErrorMessages, lib/community.ts friendlyDbError).
    /// The server's own sentence after the tag is what a contributor reads.
    static let taggedMessages: [(tag: String, fallback: String)] = [
        ("content_blocked:", "That post contains language we do not allow here."),
        ("rate_limit:", "Too many posts in a short time - please slow down."),
        ("media_blocked:", "That media file is not allowed here."),
        ("too_deep:", "Replies can only go one level deep."),
        ("invalid_parent:", "That reply target is no longer available."),
    ]

    /// The server's sentence after a tag, as a sentence: capitalized, closed.
    static func taggedMessage(in raw: String) -> String? {
        for entry in taggedMessages {
            guard let range = raw.range(of: entry.tag) else { continue }
            var tail = raw[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
            // PostgREST may wrap the message in quotes or append its own detail after a newline.
            if let cut = tail.firstIndex(where: { $0 == "\"" || $0 == "\n" }) { tail = String(tail[..<cut]) }
            tail = tail.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let first = tail.first else { return entry.fallback }
            let sentence = first.uppercased() + tail.dropFirst()
            return sentence.hasSuffix(".") || sentence.hasSuffix("?") || sentence.hasSuffix("!") ? sentence : sentence + "."
        }
        return nil
    }

    static func userMessage(for error: Error, fallback: String = "Could not save that just now. Try again.") -> String {
        if let validationError = error as? CommunityValidationError {
            return validationError.errorDescription ?? fallback
        }
        if let communityError = error as? CommunityServiceError {
            return communityError.errorDescription ?? fallback
        }
        if let tagged = taggedMessage(in: error.localizedDescription) ?? taggedMessage(in: String(describing: error)) {
            return tagged
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
        if raw.contains("mime") || raw.contains("file type") {
            return "That image could not be attached. Check the file type and upload terms."
        }
        if raw.contains("weak_tier_requires_note") {
            return "A relayed or untested claim needs a short source note - say where it came from."
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
    /// The web's deletePost guard: another contributor has replied.
    case deleteBlockedByReplies

    var errorDescription: String? {
        switch self {
        case .unsupportedMedia:
            return "Pitch Atlas iOS accepts still images only."
        case .imageTooLarge:
            return "That image is too large after compression. Choose a smaller file."
        case .sessionStartFailed:
            return "Could not start your community session just now. Try again."
        case .deleteBlockedByReplies:
            return "That post has replies from other contributors, so it cannot be deleted."
        case .invalidFieldNote(let message):
            return message
        case .invalidDiscussionPost(let message):
            return message
        }
    }
}

/// The one profile column a contributor may change (grant update (display_name)).
struct DisplayNameUpdate: Encodable {
    let displayName: String
    enum CodingKeys: String, CodingKey { case displayName = "display_name" }
}
