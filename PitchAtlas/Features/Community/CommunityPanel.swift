import AVKit
import PhotosUI
import SwiftUI

/// A topic's discussion thread (web sections/DiscussionForum.tsx): the
/// composer, the safety line, and the posts with their replies and media. It
/// lives inside DiscussionDrawer, which frames and names the thread; a pitch's
/// field notes are their own chapter (FieldNotesChapter).
struct CommunityPanel: View {
    /// A user-facing status line with a tone, so a success reads as a success
    /// (not in the warning color) and a real error reads as an error.
    private enum ActionTone { case success, error }
    private struct ActionMessage: Equatable { let text: String; let tone: ActionTone }
    private struct BlockUndo: Equatable { let authorID: String; let displayName: String }
    private struct PendingMediaRetry: Equatable {
        let postID: String
        let topicKey: String
        let userID: String
        let image: PreparedCommunityImage
    }
    /// A post, or one file attached to a post, that a report dialog is open for.
    private enum ReportTarget: Equatable {
        case post(String)
        case media(String)
    }
    private struct PlayingVideo: Identifiable { let url: URL; var id: URL { url } }

    /// The web's outage line. The heading names what failed; this says why, and
    /// no server text reaches the reader (FieldNotes.tsx, DiscussionForum.tsx).
    static let outageReason = "The server didn't answer."

    @Environment(AuthSessionStore.self) private var auth
    @Environment(ToastCenter.self) private var toasts
    @AppStorage(ContributionGate.guidelinesKey) private var guidelinesAccepted = false
    @AppStorage(ContributionGate.ageKey) private var ageConfirmed = false
    @AppStorage("pa.community.mediaTermsAccepted") private var mediaTermsAccepted = false

    let topic: CommunityTopic
    /// The thread's name as a reader says it ("Four-Seam Fastball").
    let topicName: String

    @State private var postsState: CommunityLoadState<[DiscussionPost]> = .idle
    @State private var postBody = ""
    /// The handle posts and replies file under (the site's "Your name"), seeded from
    /// the profile's handle over an existing session; never from the email.
    @State private var handle = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var preparedImage: PreparedCommunityImage?
    @State private var actionMessage: ActionMessage?
    @State private var undoBlock: BlockUndo?
    @State private var pendingMediaRetry: PendingMediaRetry?
    @State private var hiddenAuthorIDs: Set<String> = []
    /// The reader and block-list revision the hidden set was read for.
    @State private var hiddenAuthorsHydratedFor: String?
    /// In-flight guard: blocks a second submit Task from spawning before the first
    /// await returns, so a slow-network double-tap can't file two identical rows.
    @State private var isSubmitting = false
    /// The top-level post the reply box is open under; one at a time, like the web.
    @State private var replyTo: String?
    @State private var replyBody = ""
    @State private var replyError: String?
    /// The post a reply is being filed under, so only that button says "Filing…".
    @State private var filingReplyTo: String?
    @State private var reporting: ReportTarget?
    @State private var reportReason = ""
    /// The viewer's own post a delete confirmation is open for.
    @State private var deleting: String?
    @State private var playingVideo: PlayingVideo?

    private var service: CommunityService { CommunityService(client: auth.client) }
    private var topicKey: String { topic.key }
    /// Anonymous-first: the attestations gate contribution, sign-in does not.
    /// The account is minted lazily inside each write via ensureSessionForWrite.
    private var canContribute: Bool {
        CommunityContributionGate.canContribute(guidelinesAccepted: guidelinesAccepted, ageConfirmed: ageConfirmed)
    }
    /// Includes the user id so a lazy anonymous mint mid-session re-runs reload
    /// under the new identity, and the block revision so a block or unblock on
    /// any screen re-reads the block list here.
    private var reloadKey: String {
        "\(topic.key)|\(auth.userID ?? "signed-out")|\(auth.communityBlockRevision)"
    }
    private var postSubmitDisabled: Bool {
        isSubmitting || postBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private var replySubmitDisabled: Bool {
        isSubmitting || replyBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.md) {
            // The web's order: the composer first, then what's been filed below it.
            discussionComposer
            actionLine
            discussionSafetyLine
            discussionList
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: reloadKey) { await reload() }
        .alert(
            "Report this?",
            isPresented: Binding(get: { reporting != nil }, set: { if !$0 { reporting = nil } }),
            presenting: reporting
        ) { target in
            TextField("What is wrong?", text: $reportReason)
            Button("Submit report") { Task { await fileReport(target, reason: reportReason) } }
            Button("Cancel", role: .cancel) { reportReason = "" }
        } message: { _ in
            Text("Tell us briefly what is wrong. A few reports hide it for review. The reason is optional; keep it short.")
        }
        .sheet(item: $playingVideo) { video in
            MotionSpecimenPlayer(url: video.url, topicName: topicName)
        }
    }

    /// The composer's result sits right under it, where the tap happened.
    @ViewBuilder
    private var actionLine: some View {
        if let actionMessage {
            HStack(alignment: .firstTextBaseline, spacing: PitchAtlasSpacing.sm) {
                Label(
                    actionMessage.text,
                    systemImage: actionMessage.tone == .success ? "checkmark.circle" : "exclamationmark.triangle"
                )
                .font(PitchAtlasTheme.hanken(13))
                .foregroundStyle(actionMessage.tone == .success ? PitchAtlasTheme.success : PitchAtlasTheme.caution)
                .fixedSize(horizontal: false, vertical: true)

                if let undoBlock {
                    Button("Undo") {
                        Task { await unblock(undoBlock.authorID) }
                    }
                    .font(PitchAtlasTheme.hankenMedium(13))
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .accessibilityLabel("Unblock \(undoBlock.displayName)")
                }
            }
        }
    }

    /// The web's line under the discussion composer (DiscussionForum.tsx).
    private var discussionSafetyLine: some View {
        Text("Filed as experience and technique, not personal medical advice. Nothing here replaces a coach or physician. Reports from a few accounts auto-hide a post or a clip for review.")
            .font(PitchAtlasTheme.hanken(12))
            .foregroundStyle(PitchAtlasTheme.text3)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The quiet replacement for the old mandatory sign-in panel: contribution
    /// works without an account, and the claim path lives in Account & Safety.
    @ViewBuilder
    private var anonymousContributionFooter: some View {
        if !auth.isClaimed {
            Text("You're contributing anonymously on this device. Claim the record in Account & Safety to keep it across devices.")
                .font(PitchAtlasTheme.hanken(12))
                .foregroundStyle(PitchAtlasTheme.text3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Discussion

    @ViewBuilder
    private var discussionComposer: some View {
        if canContribute {
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                SectionLabel(text: "Start a conversation")
                handleField
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs2) {
                    PitchFormLabel("Comment", required: true)
                    TextField("File a grip cue, breakdown, image, or clip. Keep it about the pitch.", text: $postBody, axis: .vertical)
                        .font(PitchAtlasTheme.hanken(15))
                        .foregroundStyle(PitchAtlasTheme.bone)
                        .pitchTextFieldSurface(minHeight: 96)
                    PitchFormCaption(text: "\(postBody.count)/\(DiscussionPostLimits.body)")
                }

                // Server policy restricts uploads and media-terms acceptance to
                // permanent accounts, so the picker never dangles for an
                // anonymous contributor; the server error mapping stays as backstop.
                if auth.isClaimed {
                    PitchToggleField(
                        text: "I accept the image upload terms",
                        caption: "Still images only. Upload only media you have the right to share.",
                        isOn: $mediaTermsAccepted
                    )

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(preparedImage == nil ? "Attach image" : "Replace image", systemImage: "photo")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
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
                        .controlSize(.large)
                        .disabled(isSubmitting || !mediaTermsAccepted)
                        .opacity((isSubmitting || !mediaTermsAccepted) ? 0.55 : 1)
                    }
                } else {
                    Text("Image uploads need a claimed account — attach Apple or email in Account & Safety.")
                        .font(PitchAtlasTheme.hanken(12))
                        .foregroundStyle(PitchAtlasTheme.text3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    Task { await submitDiscussionPost() }
                } label: {
                    Label(isSubmitting && filingReplyTo == nil ? "Filing…" : "File post", systemImage: "paperplane")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(postSubmitDisabled)
                .opacity(postSubmitDisabled ? 0.55 : 1)

                anonymousContributionFooter
            }
        } else {
            ContributionGate()
        }
    }

    private var discussionList: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            switch postsState {
            case .idle, .loading:
                LoadingTile(label: "Loading discussion")
            case .empty:
                EmptyStateView(
                    title: "No specimens filed yet",
                    message: "Start the file with a grip cue, clip, image, or breakdown."
                )
            case .failed(let reason):
                ErrorStateView(title: "Could not load the discussion.", reason: reason) {
                    Task { await reload() }
                }
            case .loaded(let posts):
                ForEach(posts) { post in
                    VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                        discussionPostCard(post, isReply: false)
                        ForEach(post.replies) { reply in
                            discussionPostCard(reply, isReply: true)
                                .padding(.leading, PitchAtlasSpacing.md)
                        }
                        if replyTo == post.id {
                            replyComposer(to: post)
                                .padding(.leading, PitchAtlasSpacing.md)
                        }
                    }
                }
            }
        }
        .alert(
            "Delete this post?",
            isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
            presenting: deleting
        ) { postID in
            Button("Delete", role: .destructive) { Task { await confirmDelete(postID) } }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("This removes your post from the thread. Media attached to it stops showing with the post.")
        }
    }

    private func discussionPostCard(_ post: DiscussionPost, isReply: Bool) -> some View {
        let isMine = CommunityVisibility.viewerIsAuthor(post.authorID, viewerID: auth.userID)
        return VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            HStack(alignment: .top) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: PitchAtlasSpacing.xs) { postByline(post, isMine: isMine) }
                    VStack(alignment: .leading, spacing: 2) { postByline(post, isMine: isMine) }
                }
                Spacer(minLength: 0)
                safetyMenu(authorID: post.authorID, displayName: post.displayName) {
                    reportReason = ""
                    reporting = .post(post.id)
                }
            }
            Text(post.body)
                .font(PitchAtlasTheme.hanken(15))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
            if !post.media.isEmpty {
                mediaGallery(post.media, displayName: post.displayName)
            }
            // The web's row under a post: Reply on a top-level post (one level
            // deep), Delete on the viewer's own.
            if !isReply || isMine {
                HStack(spacing: PitchAtlasSpacing.md) {
                    if !isReply {
                        postAction("Reply", systemImage: "arrowshape.turn.up.left", label: "Reply to \(post.displayName)") {
                            replyError = nil
                            if replyTo != post.id { replyBody = "" }
                            replyTo = post.id
                        }
                    }
                    if isMine {
                        postAction("Delete", systemImage: "trash", label: "Delete your post") {
                            deleting = post.id
                        }
                    }
                }
            }
        }
        .padding(PitchAtlasSpacing.sm)
        .background(PitchAtlasTheme.void, in: RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous).stroke(PitchAtlasTheme.machined))
    }

    /// Name, how long ago it was filed (from the row's own timestamp), and a
    /// "you" mark on the viewer's own post, like the web's byline.
    @ViewBuilder
    private func postByline(_ post: DiscussionPost, isMine: Bool) -> some View {
        Text(post.displayName)
            .font(PitchAtlasTheme.hankenMedium(14))
            .foregroundStyle(PitchAtlasTheme.cyan)
        if let ago = CommunityTime.ago(post.createdAt) {
            Text(ago)
                .font(PitchAtlasTheme.martian(9))
                .foregroundStyle(PitchAtlasTheme.text3)
        }
        if isMine {
            Text("YOU")
                .font(PitchAtlasTheme.martian(8))
                .tracking(1)
                .foregroundStyle(PitchAtlasTheme.seamBright)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .overlay(Capsule().stroke(PitchAtlasTheme.seamBright.opacity(0.7)))
                .accessibilityLabel("Your post")
        }
    }

    private func postAction(_ title: String, systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title.uppercased(), systemImage: systemImage)
                .font(PitchAtlasTheme.martian(9))
                .tracking(1.4)
                .foregroundStyle(PitchAtlasTheme.text3)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    /// The site's "Your name" field: a handle, 2–40 characters, no real name needed.
    private var handleField: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs2) {
            PitchFormLabel(DiscussionHandle.label, required: true)
            TextField(DiscussionHandle.label, text: $handle)
                .font(PitchAtlasTheme.hanken(15))
                .foregroundStyle(PitchAtlasTheme.bone)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.nickname)
                .onChange(of: handle) { _, next in
                    if next.count > DiscussionPostLimits.displayName { handle = String(next.prefix(DiscussionPostLimits.displayName)) }
                }
                .pitchTextFieldSurface()
            PitchFormCaption(text: DiscussionHandle.caption)
        }
    }

    @ViewBuilder
    private func replyComposer(to post: DiscussionPost) -> some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs2) {
            if canContribute {
                handleField
                PitchFormLabel("Reply", required: true)
                TextField("Reply to \(post.displayName)…", text: $replyBody, axis: .vertical)
                    .font(PitchAtlasTheme.hanken(15))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .pitchTextFieldSurface(minHeight: 62)
                PitchFormCaption(text: "\(replyBody.count)/\(DiscussionPostLimits.body)")
                if let replyError {
                    Label(replyError, systemImage: "exclamationmark.triangle")
                        .font(PitchAtlasTheme.hanken(13))
                        .foregroundStyle(PitchAtlasTheme.caution)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Text("Accept the community guidelines and confirm you are 17 or older above to reply.")
                    .font(PitchAtlasTheme.hanken(13))
                    .foregroundStyle(PitchAtlasTheme.text3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: PitchAtlasSpacing.sm) {
                if canContribute {
                    Button {
                        Task { await submitReply(to: post) }
                    } label: {
                        Label(filingReplyTo == post.id ? "Filing…" : "Reply", systemImage: "arrowshape.turn.up.left")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(replySubmitDisabled)
                    .opacity(replySubmitDisabled ? 0.55 : 1)
                }
                Button {
                    replyTo = nil
                    replyBody = ""
                    replyError = nil
                } label: {
                    Text("Cancel")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(.leading, PitchAtlasSpacing.sm)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(PitchAtlasTheme.cyan.opacity(0.4))
                .frame(width: 2)
                .accessibilityHidden(true)
        }
    }

    private func mediaGallery(_ media: [DiscussionMedia], displayName: String) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: PitchAtlasSpacing.sm) {
                ForEach(media) { item in
                    VStack(alignment: .leading, spacing: 0) {
                        mediaTile(item, displayName: displayName)
                        Button {
                            reportReason = ""
                            reporting = .media(item.id)
                        } label: {
                            Text("REPORT MEDIA")
                                .font(PitchAtlasTheme.martian(9))
                                .tracking(1.2)
                                .foregroundStyle(PitchAtlasTheme.text3)
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Report media uploaded by \(displayName)")
                    }
                }
            }
        }
    }

    private func mediaTile(_ item: DiscussionMedia, displayName: String) -> some View {
        let isVideo = item.kind == "video"
        return Group {
            if let url = item.signedURL, isVideo {
                Button {
                    playingVideo = PlayingVideo(url: url)
                } label: {
                    ZStack {
                        PitchAtlasTheme.void
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(PitchAtlasTheme.bone)
                        SectionLabel(text: "Motion specimen", size: 8)
                            .padding(8)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Play the \(topicName) motion specimen uploaded by \(displayName)")
            } else if let url = item.signedURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        mediaSkeleton(displayName: displayName)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        mediaNotice("Image didn't load")
                    @unknown default:
                        EmptyView()
                    }
                }
                .accessibilityLabel("\(topicName) specimen uploaded by \(displayName)")
            } else {
                mediaNotice(item.signingError ?? "Specimen under review")
            }
        }
        .frame(width: 150, height: 108)
        .clipShape(RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous).stroke(PitchAtlasTheme.machined))
    }

    /// Loading: a tagged tile that says what's coming and whose it is — never a bare spinner.
    private func mediaSkeleton(displayName: String) -> some View {
        ZStack(alignment: .bottomLeading) {
            PitchAtlasTheme.machined.opacity(0.35)
            SectionLabel(text: "Loading image · \(displayName)", size: 8)
                .lineLimit(2)
                .padding(8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading the image \(displayName) filed")
    }

    private func mediaNotice(_ text: String) -> some View {
        Label(text, systemImage: "photo")
            .font(PitchAtlasTheme.hanken(12))
            .foregroundStyle(PitchAtlasTheme.text3)
            .multilineTextAlignment(.center)
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PitchAtlasTheme.void)
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
                    .foregroundStyle(PitchAtlasTheme.text3)
            }
            Spacer()
            Button {
                preparedImage = nil
                selectedPhoto = nil
                pendingMediaRetry = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .imageScale(.large)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove attached image")
        }
        .padding(PitchAtlasSpacing.sm)
        .background(PitchAtlasTheme.void, in: RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous).stroke(PitchAtlasTheme.machined))
    }

    /// Always enabled: report and block are write intents, so they mint the
    /// anonymous session lazily via ensureSessionForWrite when none exists.
    /// Block needs a person behind the row: a deleted account's row can still
    /// be reported, and a viewer never blocks themselves.
    private func safetyMenu(authorID: String?, displayName: String, reportAction: @escaping () -> Void) -> some View {
        let blockable = authorID.map { !CommunityVisibility.viewerIsAuthor($0, viewerID: auth.userID) } ?? false
        return Menu {
            Button("Report") { reportAction() }
            if blockable, let authorID {
                Button("Block user", role: .destructive) {
                    Task { await block(authorID, displayName: displayName) }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(PitchAtlasTheme.text3)
                .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel("More actions")
        .accessibilityHint(blockable ? "Report or block this contributor" : "Report this")
    }

    // MARK: Reads

    private func reload() async {
        guard await hydrateHiddenAuthorsForCurrentUser() else { return }
        await seedHandle()
        await loadDiscussion()
    }

    /// useDiscussion: `prev || identity?.displayName || ''`. A read over an existing
    /// session only; a reader with no session starts with an empty field.
    private func seedHandle() async {
        guard handle.isEmpty, auth.isSignedIn, let userID = auth.userID else { return }
        let profileName = try? await service.contributorIdentity(userID: userID)?.displayName
        handle = DiscussionHandle.initial(current: handle, profileName: profileName ?? nil)
    }

    private func hydrateHiddenAuthorsForCurrentUser() async -> Bool {
        guard auth.isSignedIn, let userID = auth.userID else {
            hiddenAuthorIDs = []
            hiddenAuthorsHydratedFor = nil
            return true
        }

        let readFor = "\(userID)|\(auth.communityBlockRevision)"
        guard hiddenAuthorsHydratedFor != readFor else { return true }

        do {
            let contributors = try await service.blockedContributors()
            hiddenAuthorIDs = CommunityVisibility.hiddenAuthorIDs(from: contributors)
            hiddenAuthorsHydratedFor = readFor
            return true
        } catch {
            // Fail closed: nothing shows until the viewer's blocks can be honored.
            // The reason rides the error tile alone, so it isn't said twice.
            postsState = .failed(FieldNotesChapter.blockListReason)
            return false
        }
    }

    private func loadDiscussion() async {
        postsState = .loading
        do {
            let rows = try await service.discussionPosts(topicKey: topicKey)
            let visibleRows = CommunityVisibility.visibleDiscussionPosts(rows, hiddenAuthorIDs: hiddenAuthorIDs)
            postsState = visibleRows.isEmpty ? .empty : .loaded(visibleRows)
        } catch {
            postsState = .failed(Self.outageReason)
        }
    }

    // MARK: Writes

    private func submitDiscussionPost() async {
        guard !isSubmitting else { return }
        guard pendingMediaRetry == nil || preparedImage == nil else {
            actionMessage = ActionMessage(text: "Retry the pending image before submitting another image.", tone: .error)
            Haptics.failure()
            return
        }

        // Validate before the write intent, so a bad name or body never mints an account.
        let post: NewDiscussionPost
        do {
            post = try NewDiscussionPost.validated(topicKey: topicKey, displayName: handle, body: postBody, parentID: nil)
        } catch {
            actionMessage = ActionMessage(text: CommunityService.userMessage(for: error), tone: .error)
            Haptics.failure()
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        // Write intent: the only moment an account may be minted.
        let userID: String
        do {
            userID = try await auth.ensureSessionForWrite()
        } catch {
            actionMessage = ActionMessage(text: CommunityService.userMessage(for: error), tone: .error)
            Haptics.failure()
            return
        }

        let postTopicKey = topicKey

        // The server generates the post id (the INSERT grant does not include
        // the id column); the insert returns it for the media attach below.
        let postID: String
        do {
            // lib/discussion createPost: the handle is kept on the profile first.
            try await service.setDisplayName(post.displayName, userID: userID)
            postID = try await service.submitPost(post)
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
                try await service.uploadImage(pendingImage, topicKey: postTopicKey, postID: postID, userID: userID)
                preparedImage = nil
                selectedPhoto = nil
                if pendingMediaRetry?.postID == postID {
                    pendingMediaRetry = nil
                }
                actionMessage = ActionMessage(text: "Filed ✓", tone: .success)
            } catch {
                preparedImage = pendingImage
                pendingMediaRetry = PendingMediaRetry(postID: postID, topicKey: postTopicKey, userID: userID, image: pendingImage)
                actionMessage = ActionMessage(
                    text: "Filed. The image did not attach; it is still ready to retry.",
                    tone: .success
                )
            }
        } else if let pendingImage {
            preparedImage = pendingImage
            pendingMediaRetry = PendingMediaRetry(postID: postID, topicKey: postTopicKey, userID: userID, image: pendingImage)
            actionMessage = ActionMessage(text: "Filed. Accept upload terms to attach the image.", tone: .success)
        } else {
            selectedPhoto = nil
            actionMessage = ActionMessage(text: "Filed ✓", tone: .success)
        }
        Haptics.success()
        await loadDiscussion()
    }

    /// A one-level reply, the web's reply box: text only here; the server
    /// refuses a reply to a reply (too_deep) or to a post that's gone.
    private func submitReply(to parent: DiscussionPost) async {
        guard !isSubmitting else { return }
        isSubmitting = true
        filingReplyTo = parent.id
        defer {
            isSubmitting = false
            filingReplyTo = nil
        }
        replyError = nil
        do {
            let reply = try NewDiscussionPost.validated(
                topicKey: topicKey,
                displayName: handle,
                body: replyBody,
                parentID: parent.id
            )
            let userID = try await auth.ensureSessionForWrite()
            try await service.setDisplayName(reply.displayName, userID: userID)
            _ = try await service.submitPost(reply)
            // Collapse the box once it saved so it can't be filed twice.
            replyBody = ""
            replyTo = nil
            toasts.show("Reply filed ✓")
            await loadDiscussion()
        } catch {
            replyError = CommunityService.userMessage(for: error)
            Haptics.failure()
        }
    }

    private func confirmDelete(_ postID: String) async {
        do {
            let viewerID = try await auth.ensureSessionForWrite()
            try await service.deletePost(id: postID, viewerID: viewerID)
            if replyTo == postID { replyTo = nil }
            toasts.show("Post deleted.")
            await loadDiscussion()
        } catch {
            toasts.show(CommunityService.userMessage(for: error, fallback: "Post didn't delete. Try again."), isFailure: true)
        }
    }

    private func fileReport(_ target: ReportTarget, reason: String) async {
        let cleanReason = CommunityReport.cleanReason(reason)
        reportReason = ""
        do {
            _ = try await auth.ensureSessionForWrite()
            switch target {
            case .post(let id):
                try await service.reportPost(id: id, reason: cleanReason)
            case .media(let id):
                try await service.reportMedia(id: id, reason: cleanReason)
            }
            toasts.show("Report sent")
        } catch {
            toasts.show("Report didn't send. Try again.", isFailure: true)
        }
    }

    private func block(_ authorID: String, displayName: String) async {
        do {
            _ = try await auth.ensureSessionForWrite()
            try await service.blockUser(blockedID: authorID)
            hiddenAuthorIDs.insert(authorID)
            hideAuthor(authorID)
            undoBlock = BlockUndo(authorID: authorID, displayName: displayName)
            actionMessage = ActionMessage(text: "Contributor blocked.", tone: .success)
            Haptics.success()
            // Every community list on screen re-reads the block list (this one
            // through reloadKey).
            auth.noteBlockListChanged()
        } catch {
            actionMessage = ActionMessage(text: CommunityService.userMessage(for: error), tone: .error)
            Haptics.failure()
        }
    }

    private func unblock(_ authorID: String) async {
        do {
            _ = try await auth.ensureSessionForWrite()
            try await service.unblockUser(blockedID: authorID)
            hiddenAuthorIDs.remove(authorID)
            undoBlock = nil
            actionMessage = ActionMessage(text: "Contributor unblocked.", tone: .success)
            Haptics.success()
            auth.noteBlockListChanged()
        } catch {
            actionMessage = ActionMessage(text: CommunityService.userMessage(for: error), tone: .error)
            Haptics.failure()
        }
    }

    private func retryPendingMedia() async {
        guard let retry = pendingMediaRetry, let userID = auth.userID else { return }
        guard retry.userID == userID else {
            actionMessage = ActionMessage(text: "Sign back in with the account that created that post before retrying the image.", tone: .error)
            return
        }
        guard mediaTermsAccepted else {
            actionMessage = ActionMessage(text: "Accept upload terms before retrying the image.", tone: .error)
            return
        }
        guard !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await service.acceptMediaTerms()
            try await service.uploadImage(retry.image, topicKey: retry.topicKey, postID: retry.postID, userID: retry.userID)
            preparedImage = nil
            selectedPhoto = nil
            if pendingMediaRetry == retry {
                pendingMediaRetry = nil
            }
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
        if case .loaded(let posts) = postsState {
            let visible = CommunityVisibility.visibleDiscussionPosts(posts, hiddenAuthorIDs: [authorID])
            postsState = visible.isEmpty ? .empty : .loaded(visible)
        }
    }

}

/// A clip filed on the website plays here: the system player, sound off until
/// the viewer turns it up, nothing autoplays.
private struct MotionSpecimenPlayer: View {
    let url: URL
    let topicName: String
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?

    var body: some View {
        NavigationStack {
            Group {
                if let player {
                    VideoPlayer(player: player)
                        .accessibilityLabel("\(topicName) motion specimen")
                } else {
                    PitchAtlasTheme.void
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .background(PitchAtlasTheme.void)
            .navigationTitle("Motion specimen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            if player == nil {
                let player = AVPlayer(url: url)
                player.isMuted = true
                self.player = player
            }
        }
        .onDisappear { player?.pause() }
    }
}
