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
    @State private var postBody = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var preparedImage: PreparedCommunityImage?
    @State private var actionMessage: ActionMessage?
    /// In-flight guard: blocks a second submit Task from spawning before the first
    /// await returns, so a slow-network double-tap can't file two identical rows.
    @State private var isSubmitting = false
    @State private var signInEmail = ""
    @State private var showGuidelines = false

    private var service: CommunityService { CommunityService(client: auth.client) }
    private var topicKey: String { "pitch:\(pitchSlug)" }
    private var canContribute: Bool { auth.isSignedIn && guidelinesAccepted && ageConfirmed }

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
                fieldNotesList
                fieldNoteComposer
            case .discussion:
                discussionList
                discussionComposer
            }

            if let actionMessage {
                Label(
                    actionMessage.text,
                    systemImage: actionMessage.tone == .success ? "checkmark.circle" : "exclamationmark.triangle"
                )
                .font(PitchAtlasTheme.hanken(13))
                .foregroundStyle(actionMessage.tone == .success ? PitchAtlasTheme.okBright : PitchAtlasTheme.amberBright)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .leatherPress()
        .task(id: pitchSlug) { await reload() }
        // Switching between Field Notes and Discussion clears a stale status line
        // so a "submitted" note from one tab doesn't linger over the other.
        .onChange(of: mode) { _, _ in actionMessage = nil }
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

    @ViewBuilder
    private var fieldNotesList: some View {
        switch notesState {
        case .idle, .loading:
            LoadingTile(label: "Loading field notes")
        case .empty:
            EmptyStateView(message: "No field notes have been filed for \(pitchName) yet.")
        case .failed(let reason):
            ErrorStateView(title: "Field notes unavailable", reason: reason)
        case .loaded(let notes):
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                ForEach(notes) { note in
                    communityNoteCard(note)
                }
            }
        }
    }

    @ViewBuilder
    private var discussionList: some View {
        switch postsState {
        case .idle, .loading:
            LoadingTile(label: "Loading discussion")
        case .empty:
            EmptyStateView(message: "No discussion posts have been filed for \(pitchName) yet.")
        case .failed(let reason):
            ErrorStateView(title: "Discussion unavailable", reason: reason)
        case .loaded(let posts):
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                ForEach(posts) { post in
                    discussionPostCard(post)
                }
            }
        }
    }

    private func communityNoteCard(_ note: CommunityFieldNote) -> some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.displayName)
                        .font(PitchAtlasTheme.hankenMedium(14))
                        .foregroundStyle(PitchAtlasTheme.bone)
                    SectionLabel(text: note.sourceTier, size: 8)
                }
                Spacer()
                safetyMenu(authorID: note.authorID) {
                    Task { await reportFieldNote(note.id) }
                }
            }

            Text(note.tweak)
                .font(PitchAtlasTheme.newsreader(18))
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)

            if let detail = note.note, !detail.isEmpty {
                Text(detail)
                    .font(PitchAtlasTheme.hanken(14))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(PitchAtlasSpacing.sm)
        .background(PitchAtlasTheme.void, in: RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous).stroke(PitchAtlasTheme.machined))
    }

    private func discussionPostCard(_ post: DiscussionPost) -> some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            HStack(alignment: .top) {
                Text(post.displayName)
                    .font(PitchAtlasTheme.hankenMedium(14))
                    .foregroundStyle(PitchAtlasTheme.bone)
                Spacer()
                safetyMenu(authorID: post.authorID) {
                    Task { await reportPost(post.id) }
                }
            }
            Text(post.body)
                .font(PitchAtlasTheme.hanken(15))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(PitchAtlasSpacing.sm)
        .background(PitchAtlasTheme.void, in: RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous).stroke(PitchAtlasTheme.machined))
    }

    @ViewBuilder
    private var fieldNoteComposer: some View {
        if canContribute {
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                SectionLabel(text: "File a note")
                TextField("Grip change or cue", text: $fieldTweak, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                TextField("What happened, in plain words", text: $fieldNote, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                Button {
                    Task { await submitFieldNote() }
                } label: {
                    Label("Submit field note", systemImage: "tray.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isSubmitting || fieldTweak.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        } else {
            contributionGate
        }
    }

    @ViewBuilder
    private var discussionComposer: some View {
        if canContribute {
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                SectionLabel(text: "Post")
                TextField("Add a sourced, firsthand note", text: $postBody, axis: .vertical)
                    .textFieldStyle(.roundedBorder)

                Toggle("I accept the image upload terms", isOn: $mediaTermsAccepted)
                    .font(PitchAtlasTheme.hanken(13))
                    .foregroundStyle(PitchAtlasTheme.bone2)

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label(preparedImage == nil ? "Attach image" : "Image ready", systemImage: "photo")
                }
                .buttonStyle(.bordered)
                .disabled(!mediaTermsAccepted)
                .onChange(of: selectedPhoto) { _, item in
                    Task { await preparePhoto(item) }
                }

                Button {
                    Task { await submitDiscussionPost() }
                } label: {
                    Label("Submit post", systemImage: "paperplane")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isSubmitting || postBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        } else {
            contributionGate
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

    private func safetyMenu(authorID: String, reportAction: @escaping () -> Void) -> some View {
        Menu {
            Button("Report") { reportAction() }
            if let userID = auth.userID, userID != authorID {
                Button("Block user", role: .destructive) {
                    Task { await block(authorID) }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(PitchAtlasTheme.ink3)
                .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel("More actions")
        .accessibilityHint("Report or block this contributor")
        .disabled(!auth.isSignedIn)
    }

    private func reload() async {
        async let notes: Void = loadFieldNotes()
        async let posts: Void = loadDiscussion()
        _ = await (notes, posts)
    }

    private func loadFieldNotes() async {
        notesState = .loading
        do {
            let rows = try await service.fieldNotes(pitchSlug: pitchSlug)
            notesState = rows.isEmpty ? .empty : .loaded(rows)
        } catch {
            notesState = .failed(error.localizedDescription)
        }
    }

    private func loadDiscussion() async {
        postsState = .loading
        do {
            let rows = try await service.discussionPosts(topicKey: topicKey)
            postsState = rows.isEmpty ? .empty : .loaded(rows)
        } catch {
            postsState = .failed(error.localizedDescription)
        }
    }

    private func submitFieldNote() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let note = NewFieldNote(
                pitchSlug: pitchSlug,
                displayName: auth.displayName,
                tweak: fieldTweak.trimmingCharacters(in: .whitespacesAndNewlines),
                playerLevel: "adult",
                armSlot: "not specified",
                intent: "firsthand note",
                claimedResultKind: "self-reported",
                claimedResultNote: nil,
                note: fieldNote.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            try await service.submitFieldNote(note)
            fieldTweak = ""
            fieldNote = ""
            actionMessage = ActionMessage(text: "Field note submitted.", tone: .success)
            Haptics.success()
            await loadFieldNotes()
        } catch {
            actionMessage = ActionMessage(text: error.localizedDescription, tone: .error)
            Haptics.failure()
        }
    }

    private func submitDiscussionPost() async {
        guard !isSubmitting, let userID = auth.userID else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        let postID = UUID().uuidString
        let post = NewDiscussionPost(
            id: postID,
            topicKey: topicKey,
            displayName: auth.displayName,
            body: postBody.trimmingCharacters(in: .whitespacesAndNewlines),
            parentID: nil
        )

        do {
            try await service.submitPost(post)
        } catch {
            // The post itself failed — keep the composer intact so the user can retry.
            actionMessage = ActionMessage(text: error.localizedDescription, tone: .error)
            Haptics.failure()
            return
        }

        // The post is committed. Clear the composer NOW — capturing the pending
        // image first — so a retry can't double-post the same body, and an image
        // that fails to attach can never masquerade as a failed post.
        let pendingImage = preparedImage
        postBody = ""
        preparedImage = nil
        selectedPhoto = nil

        if let pendingImage, mediaTermsAccepted {
            do {
                try await service.acceptMediaTerms(userID: userID)
                try await service.uploadImage(pendingImage, topicKey: topicKey, postID: postID, userID: userID)
                actionMessage = ActionMessage(text: "Post submitted.", tone: .success)
            } catch {
                // The post is already live; only the image didn't attach. Say so
                // plainly — the old hard error here is what made people re-tap and
                // double-post.
                actionMessage = ActionMessage(
                    text: "Post submitted — the image couldn't attach. You can add it to a new post.",
                    tone: .success
                )
            }
        } else {
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
            actionMessage = ActionMessage(text: error.localizedDescription, tone: .error)
            Haptics.failure()
        }
    }

    private func reportPost(_ id: String) async {
        do {
            try await service.reportPost(id: id, reason: "reported from iOS")
            actionMessage = ActionMessage(text: "Report filed.", tone: .success)
            Haptics.success()
        } catch {
            actionMessage = ActionMessage(text: error.localizedDescription, tone: .error)
            Haptics.failure()
        }
    }

    private func block(_ authorID: String) async {
        guard let blockerID = auth.userID else { return }
        do {
            try await service.blockUser(blockerID: blockerID, blockedID: authorID)
            actionMessage = ActionMessage(text: "User blocked.", tone: .success)
            Haptics.success()
            await reload()
        } catch {
            actionMessage = ActionMessage(text: error.localizedDescription, tone: .error)
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
            actionMessage = ActionMessage(text: "Image ready. Still images only.", tone: .success)
        } catch {
            actionMessage = ActionMessage(text: error.localizedDescription, tone: .error)
        }
    }
}
