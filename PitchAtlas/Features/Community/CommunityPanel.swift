import PhotosUI
import SwiftUI

struct CommunityPanel: View {
    enum Mode: String, CaseIterable, Identifiable {
        case notes = "Field Notes"
        case discussion = "Discussion"
        var id: String { rawValue }
    }

    /// A user-facing status line with a tone, so a success reads as a success
    /// (not in the warning color) and a real error reads as an error.
    private enum ActionTone { case success, error }
    private struct ActionMessage: Equatable { let text: String; let tone: ActionTone }
    private struct BlockUndo: Equatable { let authorID: String; let displayName: String }
    private struct PendingMediaRetry: Equatable { let postID: String; let image: PreparedCommunityImage }

    @Environment(AuthSessionStore.self) private var auth
    @AppStorage("pa.community.guidelinesAccepted") private var guidelinesAccepted = false
    @AppStorage("pa.community.ageConfirmed") private var ageConfirmed = false
    @AppStorage("pa.community.mediaTermsAccepted") private var mediaTermsAccepted = false

    let pitchSlug: String
    let pitchName: String
    let provenanceNote: String
    let safetyNote: String

    @State private var mode: Mode = .notes
    @State private var notesState: CommunityLoadState<[CommunityFieldNote]> = .idle
    @State private var postsState: CommunityLoadState<[DiscussionPost]> = .idle
    @State private var fieldTweak = ""
    @State private var fieldNote = ""
    @State private var fieldResultNote = ""
    @State private var fieldSampleSize = ""
    @State private var fieldEvidenceLabel = ""
    @State private var fieldEvidenceURL = ""
    @State private var fieldPlayerLevel: CommunityPlayerLevel = .collegePlus
    @State private var fieldArmSlot: CommunityArmSlot = .threeQuarter
    @State private var fieldIntent: CommunityPitchIntent = .moreMovement
    @State private var fieldResultKind: CommunityClaimedResultKind = .workedInBullpen
    @State private var postBody = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var preparedImage: PreparedCommunityImage?
    @State private var actionMessage: ActionMessage?
    @State private var undoBlock: BlockUndo?
    @State private var pendingMediaRetry: PendingMediaRetry?
    @State private var blockedAuthorIDs: Set<String> = []
    @State private var blockedAuthorsConfirmed = false
    /// In-flight guard: blocks a second submit Task from spawning before the first
    /// await returns, so a slow-network double-tap can't file two identical rows.
    @State private var isSubmitting = false
    @State private var signInEmail = ""
    @State private var showGuidelines = false

    private var service: CommunityService { CommunityService(client: auth.client) }
    private var topicKey: String { "pitch:\(pitchSlug)" }
    private var canContribute: Bool { auth.isSignedIn && guidelinesAccepted && ageConfirmed }
    private var reloadKey: String { "\(pitchSlug)|\(auth.userID ?? "signed-out")" }
    private var blockedAuthorsUnavailableMessage: String {
        "Community posts are hidden until blocked contributors can be checked."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.md) {
            header
            Picker("Community section", selection: $mode) {
                ForEach(Mode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            switch mode {
            case .notes:
                CommunityFieldNotesList(
                    state: notesState,
                    pitchName: pitchName,
                    currentUserID: auth.userID,
                    onReport: { note in Task { await reportFieldNote(note.id) } },
                    onBlock: { authorID, displayName in Task { await block(authorID, displayName: displayName) } }
                )
                if canContribute {
                    CommunityFieldNoteComposer(
                        tweak: $fieldTweak,
                        note: $fieldNote,
                        resultNote: $fieldResultNote,
                        sampleSize: $fieldSampleSize,
                        evidenceLabel: $fieldEvidenceLabel,
                        evidenceURL: $fieldEvidenceURL,
                        playerLevel: $fieldPlayerLevel,
                        armSlot: $fieldArmSlot,
                        intent: $fieldIntent,
                        resultKind: $fieldResultKind,
                        isSubmitting: isSubmitting,
                        onSubmit: { Task { await submitFieldNote() } }
                    )
                } else {
                    contributionGate
                }
            case .discussion:
                CommunityDiscussionList(
                    state: postsState,
                    pitchName: pitchName,
                    currentUserID: auth.userID,
                    onReport: { post in Task { await reportPost(post.id) } },
                    onBlock: { authorID, displayName in Task { await block(authorID, displayName: displayName) } }
                )
                if canContribute {
                    CommunityDiscussionComposer(
                        bodyText: $postBody,
                        selectedPhoto: $selectedPhoto,
                        preparedImage: $preparedImage,
                        mediaTermsAccepted: $mediaTermsAccepted,
                        hasPendingMediaRetry: pendingMediaRetry != nil,
                        isSubmitting: isSubmitting,
                        onPreparePhoto: { item in Task { await preparePhoto(item) } },
                        onRemovePreparedImage: {
                            preparedImage = nil
                            selectedPhoto = nil
                            pendingMediaRetry = nil
                        },
                        onRetryMedia: { Task { await retryPendingMedia() } },
                        onSubmit: { Task { await submitDiscussionPost() } }
                    )
                } else {
                    contributionGate
                }
            }

            if let actionMessage {
                HStack(alignment: .firstTextBaseline, spacing: PitchAtlasSpacing.sm) {
                    Label(
                        actionMessage.text,
                        systemImage: actionMessage.tone == .success ? "checkmark.circle" : "exclamationmark.triangle"
                    )
                    .font(PitchAtlasTheme.hanken(13))
                    .foregroundStyle(actionMessage.tone == .success ? PitchAtlasTheme.okBright : PitchAtlasTheme.amberBright)
                    .fixedSize(horizontal: false, vertical: true)

                    if let undoBlock {
                        Button("Undo") {
                            Task { await unblock(undoBlock.authorID) }
                        }
                        .font(PitchAtlasTheme.hankenMedium(13))
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Unblock \(undoBlock.displayName)")
                    }
                }
            }
        }
        .leatherPress()
        .task(id: reloadKey) { await reload() }
        // Switching between Field Notes and Discussion clears a stale status line
        // so a "submitted" note from one tab doesn't linger over the other.
        .onChange(of: mode) { _, _ in
            actionMessage = nil
            undoBlock = nil
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            SectionLabel(text: "Community")
            Text(provenanceNote)
                .font(PitchAtlasTheme.hanken(13))
                .foregroundStyle(PitchAtlasTheme.ink3)
                .fixedSize(horizontal: false, vertical: true)
            Text(safetyNote)
                .font(PitchAtlasTheme.newsreaderItalic(12))
                .foregroundStyle(PitchAtlasTheme.ink3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var contributionGate: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            if !auth.isSignedIn {
                SignInPanel(email: $signInEmail)
            }

            Toggle("I accept the community guidelines", isOn: $guidelinesAccepted)
                .font(PitchAtlasTheme.hanken(13))
                .foregroundStyle(PitchAtlasTheme.bone2)

            Button {
                showGuidelines = true
            } label: {
                Label("Read the community guidelines", systemImage: "doc.text")
                    .font(PitchAtlasTheme.hanken(13))
            }
            .buttonStyle(.plain)
            .foregroundStyle(PitchAtlasTheme.amberBright)
            .accessibilityHint("Opens the community guidelines you are accepting")

            Toggle("I confirm I am 17 or older before posting or uploading", isOn: $ageConfirmed)
                .font(PitchAtlasTheme.hanken(13))
                .foregroundStyle(PitchAtlasTheme.bone2)
        }
        .sheet(isPresented: $showGuidelines) {
            CommunityGuidelinesView()
        }
    }

    private func reload() async {
        guard await refreshBlockedAuthors() else { return }
        async let notes: Void = loadFieldNotes()
        async let posts: Void = loadDiscussion()
        _ = await (notes, posts)
    }

    private func refreshBlockedAuthors() async -> Bool {
        guard auth.isSignedIn else {
            blockedAuthorIDs = []
            blockedAuthorsConfirmed = true
            return true
        }
        do {
            let contributors = try await service.blockedContributors()
            blockedAuthorIDs = Set(contributors.map(\.blockedID))
            blockedAuthorsConfirmed = true
            return true
        } catch {
            blockedAuthorIDs = []
            blockedAuthorsConfirmed = false
            let message = CommunityService.userMessage(
                for: error,
                fallback: blockedAuthorsUnavailableMessage
            )
            notesState = .failed(message)
            postsState = .failed(message)
            if actionMessage == nil {
                actionMessage = ActionMessage(text: message, tone: .error)
            }
            return false
        }
    }

    private func loadFieldNotes() async {
        guard blockedAuthorsConfirmed else {
            notesState = .failed(blockedAuthorsUnavailableMessage)
            return
        }
        notesState = .loading
        do {
            let rows = try await service.fieldNotes(pitchSlug: pitchSlug)
            let visibleRows = CommunityVisibilityFilter(blockedAuthorIDs: blockedAuthorIDs).fieldNotes(rows)
            notesState = visibleRows.isEmpty ? .empty : .loaded(visibleRows)
        } catch {
            notesState = .failed(CommunityService.userMessage(for: error, fallback: "Could not load field notes just now. Try again."))
        }
    }

    private func loadDiscussion() async {
        guard blockedAuthorsConfirmed else {
            postsState = .failed(blockedAuthorsUnavailableMessage)
            return
        }
        postsState = .loading
        do {
            let rows = try await service.discussionPosts(topicKey: topicKey)
            let visibleRows = CommunityVisibilityFilter(blockedAuthorIDs: blockedAuthorIDs).discussionPosts(rows)
            postsState = visibleRows.isEmpty ? .empty : .loaded(visibleRows)
        } catch {
            postsState = .failed(CommunityService.userMessage(for: error, fallback: "Could not load the discussion just now. Try again."))
        }
    }

    private func submitFieldNote() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let note = try NewFieldNote.validated(
                pitchSlug: pitchSlug,
                displayName: auth.displayName,
                tweak: fieldTweak,
                playerLevel: fieldPlayerLevel,
                armSlot: fieldArmSlot,
                intent: fieldIntent,
                claimedResultKind: fieldResultKind,
                claimedResultNote: fieldResultNote,
                sampleSizeText: fieldSampleSize,
                evidenceURL: fieldEvidenceURL,
                evidenceLabel: fieldEvidenceLabel,
                sourceTier: .communityFirsthand,
                note: fieldNote
            )
            try await service.submitFieldNote(note)
            fieldTweak = ""
            fieldNote = ""
            fieldResultNote = ""
            fieldSampleSize = ""
            fieldEvidenceLabel = ""
            fieldEvidenceURL = ""
            actionMessage = ActionMessage(text: "Field note submitted.", tone: .success)
            Haptics.success()
            await loadFieldNotes()
        } catch {
            actionMessage = ActionMessage(text: CommunityService.userMessage(for: error), tone: .error)
            Haptics.failure()
        }
    }

    private func submitDiscussionPost() async {
        guard !isSubmitting, let userID = auth.userID else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        let postID = UUID().uuidString

        do {
            let post = try NewDiscussionPost.validated(
                id: postID,
                topicKey: topicKey,
                displayName: auth.displayName,
                body: postBody,
                parentID: nil
            )
            try await service.submitPost(post)
        } catch {
            // The post itself failed — keep the composer intact so the user can retry.
            actionMessage = ActionMessage(text: CommunityService.userMessage(for: error), tone: .error)
            Haptics.failure()
            return
        }

        // The post is committed. Clear the text now so a retry can't double-post
        // the same body. Keep the image around if only the media attach fails.
        let pendingImage = preparedImage
        postBody = ""

        if let pendingImage, mediaTermsAccepted {
            do {
                try await service.acceptMediaTerms()
                try await service.uploadImage(pendingImage, topicKey: topicKey, postID: postID, userID: userID)
                preparedImage = nil
                selectedPhoto = nil
                pendingMediaRetry = nil
                actionMessage = ActionMessage(text: "Post submitted.", tone: .success)
            } catch {
                preparedImage = pendingImage
                pendingMediaRetry = PendingMediaRetry(postID: postID, image: pendingImage)
                actionMessage = ActionMessage(
                    text: "Post submitted. The image did not attach; it is still ready to retry.",
                    tone: .success
                )
            }
        } else if let pendingImage {
            preparedImage = pendingImage
            pendingMediaRetry = PendingMediaRetry(postID: postID, image: pendingImage)
            actionMessage = ActionMessage(text: "Post submitted. Accept upload terms to attach the image.", tone: .success)
        } else {
            selectedPhoto = nil
            actionMessage = ActionMessage(text: "Post submitted.", tone: .success)
        }
        Haptics.success()
        await loadDiscussion()
    }

    private func reportFieldNote(_ id: String) async {
        do {
            try await service.reportFieldNote(id: id, reason: "reported from iOS")
            actionMessage = ActionMessage(text: "Report filed.", tone: .success)
            Haptics.success()
        } catch {
            actionMessage = ActionMessage(text: CommunityService.userMessage(for: error), tone: .error)
            Haptics.failure()
        }
    }

    private func reportPost(_ id: String) async {
        do {
            try await service.reportPost(id: id, reason: "reported from iOS")
            actionMessage = ActionMessage(text: "Report filed.", tone: .success)
            Haptics.success()
        } catch {
            actionMessage = ActionMessage(text: CommunityService.userMessage(for: error), tone: .error)
            Haptics.failure()
        }
    }

    private func block(_ authorID: String, displayName: String) async {
        do {
            try await service.blockUser(blockedID: authorID)
            blockedAuthorIDs.insert(authorID)
            hideAuthor(authorID)
            undoBlock = BlockUndo(authorID: authorID, displayName: displayName)
            actionMessage = ActionMessage(text: "Contributor blocked.", tone: .success)
            Haptics.success()
            await reload()
        } catch {
            actionMessage = ActionMessage(text: CommunityService.userMessage(for: error), tone: .error)
            Haptics.failure()
        }
    }

    private func unblock(_ authorID: String) async {
        do {
            try await service.unblockUser(blockedID: authorID)
            blockedAuthorIDs.remove(authorID)
            undoBlock = nil
            actionMessage = ActionMessage(text: "Contributor unblocked.", tone: .success)
            Haptics.success()
            await reload()
        } catch {
            actionMessage = ActionMessage(text: CommunityService.userMessage(for: error), tone: .error)
            Haptics.failure()
        }
    }

    private func retryPendingMedia() async {
        guard let retry = pendingMediaRetry, let userID = auth.userID else { return }
        guard mediaTermsAccepted else {
            actionMessage = ActionMessage(text: "Accept upload terms before retrying the image.", tone: .error)
            return
        }
        guard !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await service.acceptMediaTerms()
            try await service.uploadImage(retry.image, topicKey: topicKey, postID: retry.postID, userID: userID)
            preparedImage = nil
            selectedPhoto = nil
            pendingMediaRetry = nil
            actionMessage = ActionMessage(text: "Image attached.", tone: .success)
            Haptics.success()
            await loadDiscussion()
        } catch {
            actionMessage = ActionMessage(text: CommunityService.userMessage(for: error), tone: .error)
            Haptics.failure()
        }
    }

    private func preparePhoto(_ item: PhotosPickerItem?) async {
        preparedImage = nil
        guard let item else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw CommunityServiceError.unsupportedMedia
            }
            preparedImage = try CommunityService.prepareImage(data: data)
            pendingMediaRetry = nil
            actionMessage = ActionMessage(text: "Image ready. Still images only.", tone: .success)
        } catch {
            actionMessage = ActionMessage(text: CommunityService.userMessage(for: error), tone: .error)
        }
    }

    private func hideAuthor(_ authorID: String) {
        if case .loaded(let notes) = notesState {
            let visible = notes.filter { $0.authorID != authorID }
            notesState = visible.isEmpty ? .empty : .loaded(visible)
        }
        if case .loaded(let posts) = postsState {
            let visible = posts.filter { $0.authorID != authorID }
            postsState = visible.isEmpty ? .empty : .loaded(visible)
        }
    }

}
