import PhotosUI
import SwiftUI

struct CommunityPanel: View {
    enum Mode: String, CaseIterable, Identifiable {
        case notes = "Field Notes"
        case discussion = "Discussion"
        var id: String { rawValue }
    }

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
    @State private var actionMessage: String?
    @State private var signInEmail = ""

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
                Text(actionMessage)
                    .font(PitchAtlasTheme.hanken(13))
                    .foregroundStyle(PitchAtlasTheme.amberBright)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .leatherPress()
        .task(id: pitchSlug) { await reload() }
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
                .disabled(fieldTweak.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
                .disabled(postBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

            Toggle("I confirm I am 17 or older before posting or uploading", isOn: $ageConfirmed)
                .font(PitchAtlasTheme.hanken(13))
                .foregroundStyle(PitchAtlasTheme.bone2)
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
        }
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
            actionMessage = "Field note submitted."
            await loadFieldNotes()
        } catch {
            actionMessage = error.localizedDescription
        }
    }

    private func submitDiscussionPost() async {
        guard let userID = auth.userID else { return }
        do {
            let postID = UUID().uuidString
            let post = NewDiscussionPost(
                id: postID,
                topicKey: topicKey,
                displayName: auth.displayName,
                body: postBody.trimmingCharacters(in: .whitespacesAndNewlines),
                parentID: nil
            )
            try await service.submitPost(post)
            if let preparedImage {
                guard mediaTermsAccepted else { throw CommunityServiceError.unsupportedMedia }
                try await service.acceptMediaTerms(userID: userID)
                try await service.uploadImage(preparedImage, topicKey: topicKey, postID: postID, userID: userID)
            }
            postBody = ""
            preparedImage = nil
            selectedPhoto = nil
            actionMessage = "Post submitted."
            await loadDiscussion()
        } catch {
            actionMessage = error.localizedDescription
        }
    }

    private func reportFieldNote(_ id: String) async {
        do {
            try await service.reportFieldNote(id: id, reason: "reported from iOS")
            actionMessage = "Report filed."
        } catch {
            actionMessage = error.localizedDescription
        }
    }

    private func reportPost(_ id: String) async {
        do {
            try await service.reportPost(id: id, reason: "reported from iOS")
            actionMessage = "Report filed."
        } catch {
            actionMessage = error.localizedDescription
        }
    }

    private func block(_ authorID: String) async {
        guard let blockerID = auth.userID else { return }
        do {
            try await service.blockUser(blockerID: blockerID, blockedID: authorID)
            actionMessage = "User blocked."
            await reload()
        } catch {
            actionMessage = error.localizedDescription
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
            actionMessage = "Image ready. Still images only."
        } catch {
            actionMessage = error.localizedDescription
        }
    }
}
