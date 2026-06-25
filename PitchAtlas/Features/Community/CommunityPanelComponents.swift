import PhotosUI
import SwiftUI
import UIKit

struct CommunityFieldNotesList: View {
    let state: CommunityLoadState<[CommunityFieldNote]>
    let pitchName: String
    let currentUserID: String?
    let onReport: (CommunityFieldNote) -> Void
    let onBlock: (String, String) -> Void

    var body: some View {
        switch state {
        case .idle, .loading:
            LoadingTile(label: "Loading field notes")
        case .empty:
            EmptyStateView(message: "No field notes have been filed for \(pitchName) yet. Reading is open; posting requires sign-in.")
        case .failed(let reason):
            ErrorStateView(title: "Field notes unavailable", reason: reason)
        case .loaded(let notes):
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                ForEach(notes) { note in
                    CommunityFieldNoteCard(
                        note: note,
                        currentUserID: currentUserID,
                        onReport: { onReport(note) },
                        onBlock: onBlock
                    )
                }
            }
        }
    }
}

private struct CommunityFieldNoteCard: View {
    let note: CommunityFieldNote
    let currentUserID: String?
    let onReport: () -> Void
    let onBlock: (String, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.displayName)
                        .font(PitchAtlasTheme.hankenMedium(14))
                        .foregroundStyle(PitchAtlasTheme.bone)
                    SectionLabel(text: note.sourceTier.rawValue, size: 8)
                }
                Spacer()
                CommunitySafetyMenu(
                    authorID: note.authorID,
                    displayName: note.displayName,
                    currentUserID: currentUserID,
                    onReport: onReport,
                    onBlock: onBlock
                )
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
            .foregroundStyle(PitchAtlasTheme.bone2)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(PitchAtlasSpacing.sm)
        .background(PitchAtlasTheme.void, in: RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous).stroke(PitchAtlasTheme.machined))
    }
}

struct CommunityDiscussionList: View {
    let state: CommunityLoadState<[DiscussionPost]>
    let pitchName: String
    let currentUserID: String?
    let onReport: (DiscussionPost) -> Void
    let onBlock: (String, String) -> Void

    var body: some View {
        switch state {
        case .idle, .loading:
            LoadingTile(label: "Loading discussion")
        case .empty:
            EmptyStateView(message: "No discussion posts have been filed for \(pitchName) yet. Pitch Atlas never seeds fake posts.")
        case .failed(let reason):
            ErrorStateView(title: "Discussion unavailable", reason: reason)
        case .loaded(let posts):
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                ForEach(posts) { post in
                    CommunityDiscussionPostCard(
                        post: post,
                        currentUserID: currentUserID,
                        onReport: { onReport(post) },
                        onBlock: onBlock
                    )
                }
            }
        }
    }
}

private struct CommunityDiscussionPostCard: View {
    let post: DiscussionPost
    let currentUserID: String?
    let onReport: () -> Void
    let onBlock: (String, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            HStack(alignment: .top) {
                Text(post.displayName)
                    .font(PitchAtlasTheme.hankenMedium(14))
                    .foregroundStyle(PitchAtlasTheme.bone)
                Spacer()
                CommunitySafetyMenu(
                    authorID: post.authorID,
                    displayName: post.displayName,
                    currentUserID: currentUserID,
                    onReport: onReport,
                    onBlock: onBlock
                )
            }
            Text(post.body)
                .font(PitchAtlasTheme.hanken(15))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
            if !post.media.isEmpty {
                CommunityMediaGallery(media: post.media)
            }
        }
        .padding(PitchAtlasSpacing.sm)
        .background(PitchAtlasTheme.void, in: RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous).stroke(PitchAtlasTheme.machined))
    }
}

struct CommunityFieldNoteComposer: View {
    @Binding var tweak: String
    @Binding var note: String
    @Binding var resultNote: String
    @Binding var sampleSize: String
    @Binding var evidenceLabel: String
    @Binding var evidenceURL: String
    @Binding var playerLevel: CommunityPlayerLevel
    @Binding var armSlot: CommunityArmSlot
    @Binding var intent: CommunityPitchIntent
    @Binding var resultKind: CommunityClaimedResultKind

    let isSubmitting: Bool
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "File a note")
            TextField("Grip change or cue", text: $tweak, axis: .vertical)
                .textFieldStyle(.roundedBorder)

            Picker("Player level", selection: $playerLevel) {
                ForEach(CommunityPlayerLevel.allCases) { level in
                    Text(level.label).tag(level)
                }
            }
            .pickerStyle(.menu)

            Picker("Arm slot", selection: $armSlot) {
                ForEach(CommunityArmSlot.allCases) { slot in
                    Text(slot.label).tag(slot)
                }
            }
            .pickerStyle(.menu)

            Picker("Intent", selection: $intent) {
                ForEach(CommunityPitchIntent.allCases) { intent in
                    Text(intent.label).tag(intent)
                }
            }
            .pickerStyle(.menu)

            Picker("Result", selection: $resultKind) {
                ForEach(CommunityClaimedResultKind.allCases) { result in
                    Text(result.label).tag(result)
                }
            }
            .pickerStyle(.menu)

            TextField("Result detail (optional)", text: $resultNote, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            TextField("Sample size (optional)", text: $sampleSize)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
            TextField("Evidence label (optional)", text: $evidenceLabel)
                .textFieldStyle(.roundedBorder)
            TextField("Evidence URL (optional)", text: $evidenceURL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
            TextField("What happened, in plain words", text: $note, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            Button(action: onSubmit) {
                Label("Submit field note", systemImage: "tray.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isSubmitting || tweak.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

struct CommunityDiscussionComposer: View {
    @Binding var bodyText: String
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var preparedImage: PreparedCommunityImage?
    @Binding var mediaTermsAccepted: Bool

    let hasPendingMediaRetry: Bool
    let isSubmitting: Bool
    let onPreparePhoto: (PhotosPickerItem?) -> Void
    let onRemovePreparedImage: () -> Void
    let onRetryMedia: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "Post")
            TextField("Add a sourced, firsthand note", text: $bodyText, axis: .vertical)
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
                onPreparePhoto(item)
            }

            if let preparedImage {
                CommunityAttachmentPreview(image: preparedImage, onRemove: onRemovePreparedImage)
            }

            if hasPendingMediaRetry {
                Button(action: onRetryMedia) {
                    Label("Retry image upload", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(isSubmitting || !mediaTermsAccepted)
            }

            Button(action: onSubmit) {
                Label("Submit post", systemImage: "paperplane")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isSubmitting || bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

struct CommunityMediaGallery: View {
    let media: [DiscussionMedia]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PitchAtlasSpacing.sm) {
                ForEach(media) { item in
                    CommunityMediaTile(item: item)
                }
            }
        }
        .accessibilityLabel("Attached media")
    }
}

struct CommunityMediaTile: View {
    let item: DiscussionMedia

    var body: some View {
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
}

struct CommunityAttachmentPreview: View {
    let image: PreparedCommunityImage
    let onRemove: () -> Void

    var body: some View {
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
            Button(action: onRemove) {
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
}

struct CommunitySafetyMenu: View {
    let authorID: String
    let displayName: String
    let currentUserID: String?
    let onReport: () -> Void
    let onBlock: (String, String) -> Void

    private var canBlock: Bool {
        guard let currentUserID else { return false }
        return currentUserID != authorID
    }

    var body: some View {
        Menu {
            Button("Report", action: onReport)
            if canBlock {
                Button("Block user", role: .destructive) {
                    onBlock(authorID, displayName)
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(PitchAtlasTheme.ink3)
                .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel("More actions")
        .accessibilityHint("Report or block this contributor")
        .disabled(currentUserID == nil)
    }
}
