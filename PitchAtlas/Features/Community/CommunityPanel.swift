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
    @State private var hiddenAuthorIDs: Set<String> = []
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
        .task(id: pitchSlug) { await reload() }
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

    @ViewBuilder
    private var fieldNotesList: some View {
        switch notesState {
        case .idle, .loading:
            LoadingTile(label: "Loading field notes")
        case .empty:
            EmptyStateView(message: "No field notes have been filed for \(pitchName) yet. Reading is open; posting requires sign-in.")
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
            EmptyStateView(message: "No discussion posts have been filed for \(pitchName) yet. Pitch Atlas never seeds fake posts.")
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
                    SectionLabel(text: note.sourceTier.rawValue, size: 8)
                }
                Spacer()
                safetyMenu(authorID: note.authorID, displayName: note.displayName) {
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

            VStack(alignment: .leading, spacing: 4) {
                Text("\(note.playerLevel.label) · \(note.armSlot.label) · \(note.intent.label)")
                Text("Result: \(note.claimedResultKind.label)")
                if let sample = note.sampleSize {
                    Text("Sample: \(sample)")
                }
                if let label = note.evidenceLabel, !label.isEmpty {
                    Text("Evidence: \(label)")
                }
            }
            .font(PitchAtlasTheme.hanken(12))
            .foregroundStyle(PitchAtlasTheme.ink3)
            .fixedSize(horizontal: false, vertical: true)
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
                safetyMenu(authorID: post.authorID, displayName: post.displayName) {
                    Task { await reportPost(post.id) }
                }
            }
            Text(post.body)
                .font(PitchAtlasTheme.hanken(15))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
            if !post.media.isEmpty {
                mediaGallery(post.media)
            }
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

                Picker("Player level", selection: $fieldPlayerLevel) {
                    ForEach(CommunityPlayerLevel.allCases) { level in
                        Text(level.label).tag(level)
                    }
                }
                .pickerStyle(.menu)

                Picker("Arm slot", selection: $fieldArmSlot) {
                    ForEach(CommunityArmSlot.allCases) { slot in
                        Text(slot.label).tag(slot)
                    }
                }
                .pickerStyle(.menu)

                Picker("Intent", selection: $fieldIntent) {
                    ForEach(CommunityPitchIntent.allCases) { intent in
                        Text(intent.label).tag(intent)
                    }
                }
                .pickerStyle(.menu)

                Picker("Result", selection: $fieldResultKind) {
                    ForEach(CommunityClaimedResultKind.allCases) { result in
                        Text(result.label).tag(result)
                    }
                }
                .pickerStyle(.menu)

                TextField("Result detail (optional)", text: $fieldResultNote, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                TextField("Sample size (optional)", text: $fieldSampleSize)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                TextField("Evidence label (optional)", text: $fieldEvidenceLabel)
                    .textFieldStyle(.roundedBorder)
                TextField("Evidence URL (optional)", text: $fieldEvidenceURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
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
                    Label(preparedImage == nil ? "Attach image" : "Replace image", systemImage: "photo")
                }
                .buttonStyle(.bordered)
                .disabled(!mediaTermsAccepted)
                .onChange(of: selectedPhoto) { _, item in
                    Task { await preparePhoto(item) }
                }

                if let preparedImage {
                    attachmentPreview(preparedImage)
                }

                if pendingMediaRetry != nil {
                    Button {
                        Task { await retryPendingMedia() }
                    } label: {
                        Label("Retry image upload", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isSubmitting || !mediaTermsAccepted)
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

    private func mediaGallery(_ media: [DiscussionMedia]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PitchAtlasSpacing.sm) {
                ForEach(media) { item in
                    mediaTile(item)
                }
            }
        }
        .accessibilityLabel("Attached media")
    }

    private func mediaTile(_ item: DiscussionMedia) -> some View {
        Group {
            if let url = item.signedURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Label("Media unavailable", systemImage: "photo")
                            .font(PitchAtlasTheme.hanken(12))
                            .foregroundStyle(PitchAtlasTheme.ink3)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Label(item.signingError ?? "Media unavailable", systemImage: "photo")
                    .font(PitchAtlasTheme.hanken(12))
                    .foregroundStyle(PitchAtlasTheme.ink3)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 150, height: 108)
        .clipShape(RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous).stroke(PitchAtlasTheme.machined))
        .accessibilityLabel(item.signedURL == nil ? "Attached media unavailable" : "Attached image")
    }

    private func attachmentPreview(_ image: PreparedCommunityImage) -> some View {
        HStack(alignment: .center, spacing: PitchAtlasSpacing.sm) {
            if let uiImage = UIImage(data: image.data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                Image(systemName: "photo")
                    .frame(width: 72, height: 54)
                    .background(PitchAtlasTheme.void, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Image ready")
                    .font(PitchAtlasTheme.hankenMedium(13))
                    .foregroundStyle(PitchAtlasTheme.bone)
                Text("\(image.width)x\(image.height) · \(ByteCountFormatter.string(fromByteCount: Int64(image.data.count), countStyle: .file))")
                    .font(PitchAtlasTheme.hanken(12))
                    .foregroundStyle(PitchAtlasTheme.ink3)
            }
            Spacer()
            Button {
                preparedImage = nil
                selectedPhoto = nil
                pendingMediaRetry = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove attached image")
        }
        .padding(PitchAtlasSpacing.sm)
        .background(PitchAtlasTheme.void, in: RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous).stroke(PitchAtlasTheme.machined))
    }

    private func safetyMenu(authorID: String, displayName: String, reportAction: @escaping () -> Void) -> some View {
        Menu {
            Button("Report") { reportAction() }
            if let userID = auth.userID, userID != authorID {
                Button("Block user", role: .destructive) {
                    Task { await block(authorID, displayName: displayName) }
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
            let visibleRows = rows.filter { !hiddenAuthorIDs.contains($0.authorID) }
            notesState = visibleRows.isEmpty ? .empty : .loaded(visibleRows)
        } catch {
            notesState = .failed(CommunityService.userMessage(for: error, fallback: "Could not load field notes just now. Try again."))
        }
    }

    private func loadDiscussion() async {
        postsState = .loading
        do {
            let rows = try await service.discussionPosts(topicKey: topicKey)
            let visibleRows = rows.filter { !hiddenAuthorIDs.contains($0.authorID) }
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
            let sampleSize = try parsedSampleSize()
            let note = NewFieldNote(
                pitchSlug: pitchSlug,
                displayName: auth.displayName,
                tweak: fieldTweak.trimmingCharacters(in: .whitespacesAndNewlines),
                playerLevel: fieldPlayerLevel,
                armSlot: fieldArmSlot,
                intent: fieldIntent,
                claimedResultKind: fieldResultKind,
                claimedResultNote: nilIfBlank(fieldResultNote),
                sampleSize: sampleSize,
                evidenceURL: nilIfBlank(fieldEvidenceURL),
                evidenceLabel: nilIfBlank(fieldEvidenceLabel),
                sourceTier: .communityFirsthand,
                note: nilIfBlank(fieldNote)
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
            hiddenAuthorIDs.insert(authorID)
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
            hiddenAuthorIDs.remove(authorID)
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

    private func parsedSampleSize() throws -> Int? {
        let trimmed = fieldSampleSize.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let value = Int(trimmed), (0...100_000).contains(value) else {
            throw CommunityServiceError.invalidFieldNote("Sample size must be a number from 0 to 100000.")
        }
        return value
    }

    private func nilIfBlank(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
