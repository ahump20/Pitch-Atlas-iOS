import SwiftUI

// =============================================================================
// FieldNotesChapter — tier 03 on the pitch page
// =============================================================================
// Web: sections/FieldNotes.tsx and hooks/useFieldNotes.ts, in their order. The
// workbench band; how notes rank and the vocabulary, which always show (the
// site's quality promise); then, while the layer is open, the bullpen card, the
// note form, the ranked notes in four states and the honest-bullpen panel, or
// the "opening soon" panel when it isn't; then the provenance line. Reading
// never mints an account; a write mints one lazily. A block list that won't
// load pauses the notes rather than show someone the reader blocked.
// =============================================================================

struct FieldNotesChapter: View {
    let entry: PitchAtlasEntry

    /// FieldNotes.tsx REPORT_REASONS.
    static let reportReasons = [
        SiteOption(value: "abusive-unsafe", label: "Abusive / unsafe"),
        SiteOption(value: "off-topic", label: "Off-topic"),
        SiteOption(value: "spam", label: "Spam"),
    ]
    /// Why the notes are paused when the reader's block list won't load.
    static let blockListReason = "Your block list didn't load, so community posts are paused until it can be checked."

    @Environment(AuthSessionStore.self) private var auth
    @Environment(PitchStore.self) private var store
    @Environment(ToastCenter.self) private var toasts

    @State private var notesState: CommunityLoadState<[CommunityFieldNote]> = .idle
    @State private var identity: ContributorIdentityState = .signedOut
    @State private var viewerTried: Set<String> = []
    @State private var viewerHelpful: Set<String> = []
    @State private var hiddenAuthorIDs: Set<String> = []
    @State private var refreshCount = 0
    @State private var blocked: BlockedNotice?

    private struct BlockedNotice: Equatable {
        let authorID: String
        let displayName: String
    }

    private var service: CommunityService { CommunityService(client: auth.client) }
    private var live: Bool { entry.community.enabled }
    /// What the bullpen card may say right now: a signed-in reader's score is
    /// unknown until their profile has been read, so it never shows a zero
    /// the server didn't give.
    private var cardIdentity: ContributorIdentityState {
        guard auth.isSignedIn else { return .signedOut }
        return identity == .signedOut ? .loading : identity
    }
    private var pitchName: String { entry.canonical.name }
    /// A new reader (the account a first write mints), a block or an unblock
    /// from any screen, or a refresh re-reads the chapter.
    private var loadKey: String {
        "\(entry.slug)|\(auth.userID ?? "-")|\(auth.communityBlockRevision)|\(refreshCount)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            band
            VStack(alignment: .leading, spacing: 0) {
                explainer
                liveColumn.padding(.top, 56)
                if live {
                    notesBlock.padding(.top, 64)
                }
                relaxed(entry.community.provenanceNote, size: 14, ink: PitchAtlasTheme.bone2)
                    .padding(.top, 24)
                    .overlay(alignment: .top) { rule }
                    .padding(.top, 48)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 80)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: loadKey) { await load() }
    }

    // MARK: The band

    private var band: some View {
        VStack(alignment: .leading, spacing: 0) {
            stratumKicker("Tier 03 / Field Notes")
            athletic("Field notes from the bullpen.", size: 38.4, leading: 1.02)
                .frame(maxWidth: 16 * 0.51 * 38.4, alignment: .leading)
                .padding(.top, 16)
                .accessibilityAddTraits(.isHeader)
            // bone, not bone-2: the line sits on the workbench behind the scrim
            relaxed("Every pitcher fiddles. A thumb creeps lower, a seam catches more leather, a cue from a coach suddenly makes the pitch move. Pitch Atlas files those experiments as specimens with context, so the small discoveries stop disappearing into group chats and comment sections.",
                    size: 18, ink: PitchAtlasTheme.bone)
                .frame(maxWidth: 54 * 0.56 * 18, alignment: .leading)
                .padding(.top, 24)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 80)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { WorkbenchGround() }
    }

    // MARK: How notes rank, and the vocabulary

    private var explainer: some View {
        let guide = store.fieldNotesGuide
        return VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 0) {
                stratumKicker("How notes rank")
                athletic("Evidence and context, never who shouts loudest.", size: 24, leading: 1.375)
                    .padding(.top, 12)
                    .accessibilityAddTraits(.isHeader)
                relaxed("There is no single correct way to throw a pitch, but there are better and worse claims. A funny line should never outrank a tested grip. So notes do not rise on raw votes. They rise on weighted signals - provenance and adoption first.",
                        size: 16, ink: PitchAtlasTheme.bone2)
                    .padding(.top, 16)
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(guide.rankSignals) { signal in
                    HStack(alignment: .top, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(signal.percent)%")
                                .font(PitchAtlasType.font(.martian400, size: 14, relativeTo: .footnote))
                                .monospacedDigit()
                                .foregroundStyle(PitchAtlasTheme.cyan)
                            WeightBar(percent: signal.percent)
                        }
                        .frame(width: 112, alignment: .leading)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(signal.label.uppercased())
                                .font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .caption))
                                .tracking(em: 0.12, size: 12)
                                .foregroundStyle(PitchAtlasTheme.bone)
                                .frame(minHeight: 24)
                            relaxed(signal.blurb, size: 14, ink: PitchAtlasTheme.bone2)
                        }
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .top) { rule }
                    .accessibilityElement(children: .combine)
                }
            }
            VStack(alignment: .leading, spacing: 0) {
                stratumKicker("The vocabulary")
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(guide.vocabulary) { item in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.term.uppercased())
                                .font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .caption))
                                .tracking(em: 0.1, size: 12)
                                .foregroundStyle(PitchAtlasTheme.bone)
                            Text(item.gloss)
                                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                                .foregroundStyle(PitchAtlasTheme.bone2)
                                .cssLineHeight(1.375, face: .hanken400, size: 14, relativeTo: .subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(alignment: .top) { rule }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.top, 16)
            }
        }
    }

    // MARK: The live loop, or the honest preview

    @ViewBuilder private var liveColumn: some View {
        if live {
            VStack(alignment: .leading, spacing: 24) {
                BullpenCardPanel(identity: cardIdentity, accountClaimed: auth.isClaimed) { email in
                    await claim(email)
                }
                FieldNoteForm(pitchName: pitchName, defaultName: BullpenCard.handle(cardIdentity)) { draft in
                    try await submit(draft)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 0) {
                stratumKicker("The living layer")
                athletic("Field notes open soon.", size: 20, leading: 1.4)
                    .padding(.top, 12)
                    .accessibilityAddTraits(.isHeader)
                relaxed("Soon you will file your own grip tweak, mark the ones you have tried, and flag anything off, anonymously or under a handle you keep. Field Notes stay limited to grip and technique, with no medical, injury, workload, or youth-training prescriptions.",
                        size: 14, ink: PitchAtlasTheme.bone2)
                    .padding(.top, 12)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { PanelSurface(radius: 12) }
            .inkContext(.object)
        }
    }

    // MARK: The ranked notes

    private var notesBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom, spacing: 16) {
                athletic("Field notes for the \(pitchName.lowercased())", size: 24, leading: 4 / 3)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                Text(countLabel.uppercased())
                    .font(MonoLabel.font)
                    .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                    .foregroundStyle(PitchAtlasTheme.ink3)
                    .fixedSize()
            }
            .padding(.bottom, 16)
            .overlay(alignment: .bottom) { rule }
            .padding(.bottom, 24)

            if let blocked {
                blockedLine(blocked).padding(.bottom, 16)
            }

            switch notesState {
            case .idle, .loading:
                VStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { _ in SiteSkeleton(height: 112) }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Loading field notes")
            case .failed(let reason):
                failure(reason)
            case .empty:
                emptyNotes
            case .loaded(let notes):
                VStack(spacing: 16) {
                    ForEach(notes) { note in
                        NoteCard(
                            note: note,
                            isMine: CommunityVisibility.viewerIsAuthor(note.authorID, viewerID: auth.userID),
                            tried: viewerTried.contains(note.id),
                            helpful: viewerHelpful.contains(note.id),
                            blockable: note.authorID != nil,
                            onTried: { Task { await toggle(note.id, kind: .tried) } },
                            onHelpful: { Task { await toggle(note.id, kind: .helpful) } },
                            onReport: { reason in try await report(note.id, reason: reason) },
                            onBlock: { Task { await block(note) } }
                        )
                    }
                }
            }

            honestPanel.padding(.top, 24)
        }
    }

    /// The count prints only once the notes are in, as the site's does.
    private var countLabel: String {
        switch notesState {
        case .empty: "0 notes"
        case .loaded(let notes): notes.count == 1 ? "1 note" : "\(notes.count) notes"
        default: ""
        }
    }

    /// Alert, destructive: the heading names what failed and the line says why;
    /// no server text reaches the reader.
    private func failure(_ reason: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Couldn't load the field notes.")
                .font(PitchAtlasType.font(.hanken500, size: 14, relativeTo: .subheadline))
            Text(reason)
                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                .fixedSize(horizontal: false, vertical: true)
            Button {
                refreshCount += 1
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 11, weight: .medium))
                    siteButtonLabel("Try again", size: 12)
                }
                .foregroundStyle(SiteKitInk.destructive)
            }
            .buttonStyle(.site(.outline))
            .padding(.top, 12)
        }
        .foregroundStyle(SiteKitInk.destructive)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(SiteKitInk.card))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(SiteKitInk.border, lineWidth: 1))
    }

    /// Empty: the trophy, the heading and the reason, inside a dashed frame.
    private var emptyNotes: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(SiteKitInk.primary)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(SiteKitInk.primary.opacity(0.12)))
                .padding(.bottom, 8)
                .accessibilityHidden(true)
            athletic("No field notes filed yet", size: 24, leading: 4 / 3, ink: PitchAtlasTheme.bone2, trackingEm: -0.025)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text("No field notes filed yet for this pitch. The first one starts the drawer. Add how you throw it above.")
                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                .foregroundStyle(SiteKitInk.mutedForeground)
                .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 384)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 64)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(SiteKitInk.card.opacity(0.7)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
    }

    /// The community floor in plain sight: the guidelines and how flagging works.
    private var honestPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            stratumKicker("Keeping the bullpen honest")
            SiteSeparator().padding(.top, 12)
            (Text("\(entry.community.safetyNote) No abuse, no personal attacks, no off-topic spam, nothing aimed at minors. New field notes stay private until review. See a problem with a public note? Use ")
                + Text("Report").foregroundStyle(PitchAtlasTheme.bone)
                + Text(" on it; a note flagged by enough people is hidden automatically until it is checked."))
                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { PanelSurface(radius: 12) }
        .inkContext(.object)
    }

    private func blockedLine(_ notice: BlockedNotice) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Label("Contributor blocked.", systemImage: "checkmark.circle")
                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.success)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button {
                Task { await unblock(notice) }
            } label: {
                siteButtonLabel("Undo", size: 12)
            }
            .buttonStyle(.site(.outline))
            .accessibilityLabel("Unblock \(notice.displayName)")
        }
    }

    // MARK: Reads

    private func load() async {
        guard live else { return }
        // A re-read keeps what is on screen until the new answer lands.
        if case .loaded = notesState {} else { notesState = .loading }
        async let identityRead: Void = loadIdentity()
        // Fail closed: nothing shows until the reader's blocks can be honored.
        if auth.isSignedIn {
            do {
                hiddenAuthorIDs = CommunityVisibility.hiddenAuthorIDs(from: try await service.blockedContributors())
            } catch {
                guard !Task.isCancelled else { return }
                notesState = .failed(Self.blockListReason)
                await identityRead
                return
            }
        } else {
            hiddenAuthorIDs = []
        }
        do {
            let rows = try await service.fieldNotes(pitchSlug: entry.slug)
            let visible = CommunityVisibility.visibleFieldNotes(rows, hiddenAuthorIDs: hiddenAuthorIDs)
            // The reader's own marks hydrate only over a session that already
            // exists: this is a read, and reads never mint an account.
            if auth.isSignedIn, !visible.isEmpty {
                let engagement = await service.viewerEngagement(noteIDs: visible.map(\.id))
                viewerTried = engagement.tried
                viewerHelpful = engagement.helpful
            } else {
                viewerTried = []
                viewerHelpful = []
            }
            guard !Task.isCancelled else { return }
            notesState = visible.isEmpty ? .empty : .loaded(visible)
        } catch {
            guard !Task.isCancelled else { return }
            notesState = .failed(CommunityPanel.outageReason)
        }
        await identityRead
    }

    /// The bullpen card's profile. A signed-out reader truly has nothing filed;
    /// a failed read leaves the score off rather than print a zero.
    private func loadIdentity() async {
        guard let userID = auth.userID else {
            identity = .signedOut
            return
        }
        if case .loaded = identity {} else { identity = .loading }
        do {
            let row = try await service.contributorIdentity(userID: userID)
            guard auth.userID == userID else { return }
            identity = .loaded(row ?? ContributorIdentity(displayName: nil, isClaimed: nil, contributionScore: 0, notesCount: 0))
        } catch {
            guard auth.userID == userID, !Task.isCancelled else { return }
            if case .loaded = identity { return }
            identity = .failed
        }
    }

    // MARK: Writes

    /// useFieldNotes.toggleEngagement: flip at once, then persist; a failure
    /// re-reads the server's counts and marks.
    private func toggle(_ noteID: String, kind: CommunityEngagementKind) async {
        guard case .loaded(let notes) = notesState,
              let note = notes.first(where: { $0.id == noteID }),
              !CommunityVisibility.viewerIsAuthor(note.authorID, viewerID: auth.userID) else { return }
        Haptics.selection()
        let outcome = CommunityEngagement.toggled(noteID: noteID, kind: kind, tried: viewerTried,
                                                  helpful: viewerHelpful, notes: notes)
        viewerTried = outcome.tried
        viewerHelpful = outcome.helpful
        notesState = .loaded(outcome.notes)
        let hadSession = auth.isSignedIn
        do {
            // Write intent: the only moment an account may be minted.
            _ = try await auth.ensureSessionForWrite()
            switch kind {
            case .tried: try await service.setTried(noteID: noteID, on: outcome.isNowOn)
            case .helpful: try await service.setHelpful(noteID: noteID, on: outcome.isNowOn)
            }
            // A first mark minted the account mid-read; read again now the mark
            // has landed, so its count and its flag come from the server.
            if hadSession { await loadIdentity() } else { refreshCount += 1 }
        } catch {
            Haptics.failure()
            toasts.show(CommunityService.userMessage(for: error), isFailure: true)
            refreshCount += 1
        }
    }

    /// lib/community submitNote: the handle is kept on the profile, then the
    /// note is filed; it waits for review before it shows.
    private func submit(_ draft: FieldNoteDraft) async throws {
        let note = try draft.newFieldNote(pitchSlug: entry.slug)
        let userID = try await auth.ensureSessionForWrite()
        try await service.setDisplayName(note.displayName, userID: userID)
        try await service.submitFieldNote(note)
        refreshCount += 1
    }

    private func report(_ noteID: String, reason: String) async throws {
        _ = try await auth.ensureSessionForWrite()
        try await service.reportFieldNote(id: noteID, reason: reason)
    }

    /// lib/community claimWithEmail: an account first (minted if need be), then
    /// the address. True when the email went out.
    private func claim(_ email: String) async -> Bool {
        do {
            _ = try await auth.ensureSessionForWrite()
        } catch {
            return false
        }
        await auth.claimEmail(email)
        let sent = auth.claimEmailSentTo == email
        await loadIdentity()
        return sent
    }

    private func block(_ note: CommunityFieldNote) async {
        guard let authorID = note.authorID else { return }
        do {
            _ = try await auth.ensureSessionForWrite()
            guard !CommunityVisibility.viewerIsAuthor(authorID, viewerID: auth.userID) else { return }
            try await service.blockUser(blockedID: authorID)
            hiddenAuthorIDs.insert(authorID)
            if case .loaded(let notes) = notesState {
                let visible = CommunityVisibility.visibleFieldNotes(notes, hiddenAuthorIDs: [authorID])
                notesState = visible.isEmpty ? .empty : .loaded(visible)
            }
            blocked = BlockedNotice(authorID: authorID, displayName: note.displayName)
            Haptics.success()
            auth.noteBlockListChanged()
        } catch {
            Haptics.failure()
            toasts.show(CommunityService.userMessage(for: error), isFailure: true)
        }
    }

    private func unblock(_ notice: BlockedNotice) async {
        do {
            _ = try await auth.ensureSessionForWrite()
            try await service.unblockUser(blockedID: notice.authorID)
            hiddenAuthorIDs.remove(notice.authorID)
            blocked = nil
            Haptics.success()
            auth.noteBlockListChanged()
        } catch {
            Haptics.failure()
            toasts.show(CommunityService.userMessage(for: error), isFailure: true)
        }
    }

    private var rule: some View {
        Rectangle().fill(PitchAtlasTheme.bone.opacity(0.15)).frame(height: 1).accessibilityHidden(true)
    }
}

// MARK: - The bullpen card

/// IdentityStrip: the score, the handle filed under, and the claim — an email
/// that keeps the notes and points on any device, never required.
private struct BullpenCardPanel: View {
    let identity: ContributorIdentityState
    let accountClaimed: Bool
    /// Sends the claim email; true when it went out.
    let onClaim: (String) async -> Bool

    private enum Phase: Equatable { case idle, sending, sent, failed }

    @State private var email = ""
    @State private var phase: Phase = .idle

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                KickerLabel(text: "Your bullpen card")
                Spacer(minLength: 0)
                if let points = BullpenCard.points(identity) {
                    Text(points)
                        .font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .caption))
                        .monospacedDigit()
                        .foregroundStyle(PitchAtlasTheme.bone2)
                }
            }
            filingLine.padding(.top, 8)
            if BullpenCard.isClaimed(identity, accountClaimed: accountClaimed) {
                small(BullpenCard.claimedLine).padding(.top, 12)
            } else if phase == .sent {
                small(BullpenCard.claimSent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background { PanelSurface(radius: 12) }
                    .padding(.top, 12)
            } else {
                claimForm.padding(.top, 12)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { PanelSurface(radius: 12) }
        .inkContext(.object)
    }

    private var filingLine: some View {
        let name = BullpenCard.handle(identity) ?? "an unclaimed contributor"
        let claimed = BullpenCard.isClaimed(identity, accountClaimed: accountClaimed)
        return (Text("Filing as ") + Text(name).foregroundStyle(PitchAtlasTheme.bone)
            + Text(claimed ? " · claimed ✓." : " · anonymous."))
            .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
            .foregroundStyle(PitchAtlasTheme.bone2)
            .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var claimForm: some View {
        VStack(alignment: .leading, spacing: 0) {
            small(BullpenCard.claimPrompt(identity)).padding(.bottom, 8)
            HStack(spacing: 8) {
                SiteTextField(label: "Email to claim your contributor account", placeholder: "you@email.com",
                              text: $email, keyboard: .emailAddress, contentType: .emailAddress,
                              capitalization: .never, autocorrect: false)
                Button {
                    Task { await claim() }
                } label: {
                    siteButtonLabel(phase == .sending ? "Sending…" : "Claim", size: 12)
                }
                .buttonStyle(.site(.primary))
                .disabled(phase == .sending || !email.contains("@"))
                .fixedSize()
            }
            if phase == .failed {
                SiteFieldError(text: BullpenCard.claimFailed).padding(.top, 8)
            }
        }
    }

    private func claim() async {
        let address = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard address.contains("@") else { return }
        phase = .sending
        if await onClaim(address) {
            phase = .sent
            AccessibilityNotification.Announcement(BullpenCard.claimSent).post()
        } else {
            phase = .failed
            Haptics.failure()
        }
    }

    /// text-xs leading-relaxed, bone-2.
    private func small(_ text: String) -> some View {
        Text(text)
            .font(PitchAtlasType.font(.hanken400, size: 12, relativeTo: .footnote))
            .foregroundStyle(PitchAtlasTheme.bone2)
            .cssLineHeight(1.625, face: .hanken400, size: 12, relativeTo: .footnote)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - The note form

/// SubmitForm: "Log a field note" until it is opened, then the form. On iPhone
/// the community guidelines and the 17+ confirmation sit at the top of the
/// opened form and filing waits on them.
private struct FieldNoteForm: View {
    let pitchName: String
    /// The handle the bullpen card already files under.
    let defaultName: String?
    /// Files the note, or throws the reason it didn't.
    let onSubmit: (FieldNoteDraft) async throws -> Void

    @AppStorage(ContributionGate.guidelinesKey) private var guidelinesAccepted = false
    @AppStorage(ContributionGate.ageKey) private var ageConfirmed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var open = false
    @State private var draft = FieldNoteDraft()
    @State private var busy = false
    @State private var error: String?
    @State private var done = false
    @State private var showExtras = false
    @State private var settle: Task<Void, Never>?

    private static let sentForReview = "Sent for review ✓ · it stays private until approved."

    private var canContribute: Bool {
        CommunityContributionGate.canContribute(guidelinesAccepted: guidelinesAccepted, ageConfirmed: ageConfirmed)
    }

    var body: some View {
        Group {
            if open { form } else { invitation }
        }
        .onDisappear { settle?.cancel() }
    }

    private var invitation: some View {
        VStack(alignment: .leading, spacing: 0) {
            athletic("Log a field note", size: 20, leading: 1.4)
                .accessibilityAddTraits(.isHeader)
            relaxed("Throw the \(pitchName.lowercased()) with a wrinkle of your own? Add it. Label where it comes from: your own report, a coach, or a hunch. Keep it to grip and technique only. No medical, injury, workload, or youth-training prescriptions. Every contribution keeps its source context.",
                    size: 14, ink: PitchAtlasTheme.bone2)
                .padding(.top, 8)
            if done {
                Text(Self.sentForReview)
                    .font(PitchAtlasType.font(.hanken400, size: 12, relativeTo: .footnote))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .cssLineHeight(1.625, face: .hanken400, size: 12, relativeTo: .footnote)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background { PanelSurface(radius: 12) }
                    .padding(.top, 12)
            }
            Button {
                if draft.displayName.isEmpty, let defaultName { draft.displayName = defaultName }
                open = true
                done = false
            } label: {
                siteButtonLabel("Write a note →", size: 14)
            }
            .buttonStyle(.site(.primary))
            .accessibilityLabel("Write a note")
            .padding(.top, 16)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { PanelSurface(radius: 12) }
        .inkContext(.object)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                Text("New field note · \(pitchName)".uppercased())
                    .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                    .tracking(em: 0.16, size: 10)
                    .foregroundStyle(PitchAtlasTheme.cyan)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                Button {
                    open = false
                } label: {
                    siteButtonLabel("Cancel", size: 10, trackingEm: 0.14, uppercase: true)
                        .foregroundStyle(PitchAtlasTheme.text3)
                }
                .buttonStyle(.site(.ghost))
            }
            .padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 20) {
                if !canContribute { ContributionGate() }

                SiteField(label: "Submitted by", description: "A handle, 2-40 characters. No real name needed.",
                          invalid: error != nil && draft.displayName.trimmingCharacters(in: .whitespaces).isEmpty) {
                    SiteTextField(label: "Submitted by", placeholder: "e.g. RHP_threequarter", text: $draft.displayName,
                                  maxLength: CommunityFieldNoteLimits.displayName, capitalization: .never, autocorrect: false)
                }

                SiteField(label: "The tweak",
                          description: "The change from the standard grip. \(draft.tweak.count)/\(CommunityFieldNoteLimits.tweak)",
                          invalid: error != nil && draft.tweak.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                    SiteTextField(label: "The tweak", placeholder: "Thumb tucked deeper under the leather, ring finger off the seam…",
                                  text: $draft.tweak, multiline: true, maxLength: CommunityFieldNoteLimits.tweak)
                }

                VStack(alignment: .leading, spacing: 16) {
                    SiteSelect(label: "Level",
                               options: CommunityPlayerLevel.allCases.map { SiteOption(value: $0, label: $0.label) },
                               selection: $draft.playerLevel)
                    SiteSelect(label: "Arm slot",
                               options: CommunityArmSlot.allCases.map { SiteOption(value: $0, label: $0.label) },
                               selection: $draft.armSlot)
                    SiteSelect(label: "Pace context",
                               options: [SiteOption<CommunityVelocityBand?>(value: nil, label: "-")]
                                   + CommunityVelocityBand.allCases.map { SiteOption(value: Optional($0), label: $0.label) },
                               selection: $draft.velocityBand)
                }

                VStack(alignment: .leading, spacing: 16) {
                    SiteSelect(label: "Going for",
                               options: CommunityPitchIntent.allCases.map { SiteOption(value: $0, label: $0.label) },
                               selection: $draft.intent)
                    SiteSelect(label: "What happened",
                               options: CommunityClaimedResultKind.allCases.map { SiteOption(value: $0, label: $0.label) },
                               selection: $draft.claimedResultKind)
                }

                SiteSelect(label: "Source",
                           options: CommunityWritableTier.allCases.map { SiteOption(value: $0, label: $0.label) },
                           selection: $draft.sourceTier,
                           hint: draft.noteRequired
                               ? "A relayed or untested claim must say where it comes from."
                               : "Where this comes from. Sets how the note ranks.")

                if draft.showsContext {
                    SiteField(label: draft.noteRequired ? "Context (required)" : "Context",
                              description: "Why it is worth logging. \(draft.note.count)/\(CommunityFieldNoteLimits.note)",
                              invalid: error != nil && draft.noteRequired
                                  && draft.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                        SiteTextField(label: "Context", placeholder: "Where you heard it, or what you saw…",
                                      text: $draft.note, maxLength: CommunityFieldNoteLimits.note)
                    }
                }

                extras

                if let error {
                    SiteFieldError(text: error)
                }

                HStack(spacing: 12) {
                    Button {
                        Task { await submit() }
                    } label: {
                        siteButtonLabel(busy ? "Filing… →" : "File field note →", size: 14)
                    }
                    .buttonStyle(.site(.primary))
                    .disabled(!draft.isValid || busy || !canContribute)
                    .fixedSize()
                    .accessibilityLabel(busy ? "Filing" : "File field note")
                    Text("Filed under your handle. You can take part anonymously.")
                        .font(PitchAtlasType.font(.hanken400, size: 12, relativeTo: .footnote))
                        .foregroundStyle(PitchAtlasTheme.bone2)
                        .cssLineHeight(1.375, face: .hanken400, size: 12, relativeTo: .footnote)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(20)
        .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(PitchAtlasTheme.bone.opacity(0.15), lineWidth: 1))
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { PanelSurface(radius: 12) }
        .inkContext(.object)
    }

    /// The disclosure the site folds the optional fields behind.
    private var extras: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) { showExtras.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Text("›")
                        .rotationEffect(.degrees(showExtras ? 90 : 0))
                        .accessibilityHidden(true)
                    Text("Optional · reps + evidence link".uppercased())
                }
                .font(MonoLabel.font)
                .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                .foregroundStyle(PitchAtlasTheme.bone2)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Optional: reps and evidence link")
            .accessibilityValue(showExtras ? "Open" : "Closed")

            if showExtras {
                VStack(alignment: .leading, spacing: 16) {
                    SiteField(label: "Reps") {
                        SiteTextField(label: "Reps", placeholder: "e.g. 40", text: $draft.sampleSize, keyboard: .numberPad)
                    }
                    SiteField(label: "Evidence label") {
                        SiteTextField(label: "Evidence label", placeholder: "Bullpen clip", text: $draft.evidenceLabel,
                                      maxLength: CommunityFieldNoteLimits.evidenceLabel)
                    }
                    SiteField(label: "Evidence URL") {
                        SiteTextField(label: "Evidence URL", placeholder: "https://…", text: $draft.evidenceURL,
                                      maxLength: CommunityFieldNoteLimits.evidenceURL, keyboard: .URL, contentType: .URL,
                                      capitalization: .never, autocorrect: false)
                    }
                }
                .padding(.top, 12)
            }
        }
    }

    private func submit() async {
        guard draft.isValid, canContribute, !busy else { return }
        busy = true
        error = nil
        defer { busy = false }
        do {
            try await onSubmit(draft)
            draft.clearAfterFiling()
            showExtras = false
            open = false
            done = true
            Haptics.success()
            AccessibilityNotification.Announcement(Self.sentForReview).post()
            settle?.cancel()
            settle = Task {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                done = false
            }
        } catch {
            self.error = CommunityService.userMessage(for: error, fallback: "Could not file the note. Try again.")
            Haptics.failure()
        }
    }
}

// MARK: - One field note

/// NoteCard: a plate edged in cyan — who filed it and their context, the tier
/// and the age, the tweak, what they were going for and what happened, the
/// reader's marks, and the inline flag.
private struct NoteCard: View {
    let note: CommunityFieldNote
    let isMine: Bool
    let tried: Bool
    let helpful: Bool
    let blockable: Bool
    let onTried: () -> Void
    let onHelpful: () -> Void
    let onReport: (String) async throws -> Void
    let onBlock: () -> Void

    private enum ReportPhase: Equatable { case idle, choosing, sending, done, failed }
    @State private var phase: ReportPhase = .idle

    private var context: String {
        [note.playerLevel.label, note.armSlot.label, note.velocityBand?.label ?? ""]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    var body: some View {
        Plate(accent: PitchAtlasTheme.cyan) {
            VStack(alignment: .leading, spacing: 0) {
                header.padding(.bottom, 12)
                Text(note.tweak)
                    .font(PitchAtlasType.font(.hanken400, size: 15, relativeTo: .body))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .cssLineHeight(1.625, face: .hanken400, size: 15, relativeTo: .body)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                outcomeLine.padding(.top, 12)
                if let result = note.claimedResultNote, !result.isEmpty {
                    relaxed(result, size: 14, ink: PitchAtlasTheme.bone2).padding(.top, 8)
                }
                if let detail = note.note, !detail.isEmpty {
                    relaxed(detail, size: 14, ink: PitchAtlasTheme.bone2)
                        .padding(.leading, 12)
                        .overlay(alignment: .leading) {
                            Rectangle().fill(PitchAtlasTheme.seamBright.opacity(0.4)).frame(width: 1)
                        }
                        .padding(.top, 8)
                }
                if let url = note.evidenceLink {
                    Link(destination: url) {
                        Text("\(note.evidenceLabel.flatMap { $0.isEmpty ? nil : $0 } ?? "Evidence") ↗")
                            .font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .caption))
                            .foregroundStyle(PitchAtlasTheme.seamBright)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                            .padding(.vertical, -14)
                    }
                    .accessibilityHint("Opens the evidence outside the app")
                    .padding(.top, 12)
                }
                actions
                    .padding(.top, 16)
                    .overlay(alignment: .top) {
                        Rectangle().fill(PitchAtlasTheme.bone.opacity(0.15)).frame(height: 1).accessibilityHidden(true)
                    }
                    .padding(.top, 20)
            }
        }
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 16) {
                identity
                Spacer(minLength: 0)
                provenance
            }
            VStack(alignment: .leading, spacing: 8) {
                identity
                provenance
            }
        }
    }

    private var identity: some View {
        FlowRow(spacing: 12, lineSpacing: 4, rowAlignment: .center) {
            athletic(note.displayName, size: 16, leading: 1.5, ink: PitchAtlasTheme.cyan)
            if !context.isEmpty {
                Text(context)
                    .font(PitchAtlasType.font(.hanken400, size: 12, relativeTo: .caption))
                    .foregroundStyle(PitchAtlasTheme.text3)
            }
        }
    }

    private var provenance: some View {
        HStack(spacing: 12) {
            ConfidenceLabel(confidence: ClaimConfidence(lenient: note.sourceTier.rawValue))
            if let age = FieldNoteAge.label(createdAt: note.createdAt) {
                Text(age.uppercased())
                    .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                    .tracking(em: 0.14, size: 10)
                    .foregroundStyle(PitchAtlasTheme.text3)
                    .accessibilityLabel("Filed \(age)")
            }
        }
        .fixedSize()
    }

    private var outcomeLine: some View {
        var line = Text("Going for").foregroundStyle(PitchAtlasTheme.text3)
            + Text(" \(note.intent.label)")
            + Text(" · result").foregroundStyle(PitchAtlasTheme.text3)
            + Text(" \(note.claimedResultKind.label)")
        if let reps = note.sampleSize {
            line = line + Text(" · \(reps) reps").foregroundStyle(PitchAtlasTheme.text3)
        }
        return line
            .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
            .foregroundStyle(PitchAtlasTheme.bone2)
            .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actions: some View {
        FlowRow(spacing: 8, lineSpacing: 8, rowAlignment: .center, trailingLast: true) {
            if isMine {
                SiteOutlineBadge(text: "Your note")
                    .accessibilityLabel("Your note")
            } else {
                mark(tried ? "✓ Tried this" : "Tried this", count: note.adoptionCount, isOn: tried,
                     name: "Tried this", action: onTried)
                mark(helpful ? "✓ Helpful" : "Helpful", count: note.helpfulCount, isOn: helpful,
                     name: "Helpful", action: onHelpful)
            }
            flag
        }
    }

    private func mark(_ title: String, count: Int, isOn: Bool, name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            siteButtonLabel("\(title) · \(count)", size: 12)
        }
        .buttonStyle(.site(isOn ? .marked : .outline))
        .accessibilityLabel(name)
        .accessibilityValue("\(count)")
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
        .accessibilityHint(isOn ? "Removes your mark" : "Adds your mark")
    }

    @ViewBuilder private var flag: some View {
        switch phase {
        case .idle:
            Button {
                phase = .choosing
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "flag").font(.system(size: 11, weight: .medium))
                    siteButtonLabel("Report", size: 10, trackingEm: 0.14, uppercase: true)
                }
                .foregroundStyle(PitchAtlasTheme.text3)
            }
            .buttonStyle(.site(.ghost))
            .accessibilityLabel("Report this note")
        case .sending:
            status("Flagging…")
        case .done:
            status("Flagged for review. Thank you.")
        case .failed:
            Button {
                phase = .choosing
            } label: {
                siteButtonLabel("Couldn't send. Tap to retry.", size: 10, trackingEm: 0.14, uppercase: true)
                    .foregroundStyle(PitchAtlasTheme.seamBright)
            }
            .buttonStyle(.site(.ghost))
        case .choosing:
            FlowRow(spacing: 8, lineSpacing: 8, rowAlignment: .center) {
                status("Flag as")
                ForEach(FieldNotesChapter.reportReasons, id: \.self) { reason in
                    Button {
                        Task { await flag(reason.value) }
                    } label: {
                        siteButtonLabel(reason.label, size: 10, trackingEm: 0.1, uppercase: true)
                            .foregroundStyle(PitchAtlasTheme.bone2)
                    }
                    .buttonStyle(.site(.outline))
                }
                // The App Store's rule for user content: a reader can also stop
                // seeing a contributor altogether.
                if blockable && !isMine {
                    Button(action: onBlock) {
                        siteButtonLabel("Block contributor", size: 10, trackingEm: 0.1, uppercase: true)
                            .foregroundStyle(PitchAtlasTheme.seamBright)
                    }
                    .buttonStyle(.site(.outline))
                    .accessibilityHint("Hides this contributor's notes and posts")
                }
                Button {
                    phase = .idle
                } label: {
                    siteButtonLabel("Cancel", size: 10, trackingEm: 0.14, uppercase: true)
                        .foregroundStyle(PitchAtlasTheme.text3)
                }
                .buttonStyle(.site(.ghost))
            }
        }
    }

    private func status(_ text: String) -> some View {
        Text(text.uppercased())
            .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
            .tracking(em: 0.14, size: 10)
            .foregroundStyle(PitchAtlasTheme.text3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: 44)
    }

    private func flag(_ reason: String) async {
        phase = .sending
        do {
            try await onReport(reason)
            phase = .done
            AccessibilityNotification.Announcement("Flagged for review. Thank you.").post()
        } catch {
            // A safety report never claims a success it didn't earn.
            phase = .failed
            Haptics.failure()
        }
    }
}

// MARK: - Pieces

/// The band's ground: the stage, the workbench at 70%, the scrim falling off to
/// the right.
private struct WorkbenchGround: View {
    var body: some View {
        ZStack {
            SiteKitInk.stage
            GeometryReader { geo in
                BundledImage(src: "/brand/workbench.webp", alt: "", contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .opacity(0.7)
            }
            LinearGradient(stops: [
                .init(color: SiteKitInk.bandScrim.opacity(0.92), location: 0),
                .init(color: SiteKitInk.bandScrim.opacity(0.62), location: 0.52),
                .init(color: SiteKitInk.bandScrim.opacity(0.30), location: 1),
            ], startPoint: .leading, endPoint: .trailing)
        }
        .clipped()
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// A signal's weight as a 4pt bar: the cyan track at 15%, filled to its share.
private struct WeightBar: View {
    let percent: Int

    var body: some View {
        Capsule()
            .fill(PitchAtlasTheme.cyan.opacity(0.15))
            .frame(height: 4)
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    Capsule()
                        .fill(PitchAtlasTheme.cyan)
                        .frame(width: geo.size.width * CGFloat(min(max(percent, 0), 100)) / 100)
                }
            }
            .accessibilityHidden(true)
    }
}

/// A kicker set as the site sets it inside a block: an inline box on the
/// paragraph's 24pt line, so it rides 8 below the line's top.
private func stratumKicker(_ text: String) -> some View {
    KickerLabel(text: text).padding(.top, 8)
}

/// Body prose at a size, on 1.625.
private func relaxed(_ text: String, size: CGFloat, ink: Color) -> some View {
    Text(text)
        .font(PitchAtlasType.font(.hanken400, size: size, relativeTo: size >= 15 ? .body : .subheadline))
        .foregroundStyle(ink)
        .cssLineHeight(1.625, face: .hanken400, size: size, relativeTo: size >= 15 ? .body : .subheadline)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
}

/// rfx-athletic rfx-skew: Anton in caps, skewed −7° about its own center as CSS
/// transforms do.
private func athletic(_ text: String, size: CGFloat, leading: CGFloat, ink: Color = PitchAtlasTheme.bone,
                      trackingEm: CGFloat = 0.01) -> some View {
    TightLines(text.uppercased(), face: .anton400, size: size, lineHeight: leading,
               relativeTo: size >= 22 ? .title2 : .headline, trackingEm: trackingEm)
        .foregroundStyle(ink)
        .modifier(CenteredSkew(degrees: -7))
}

/// CSS skewX about the box's center (transform-origin 50% 50%).
private struct CenteredSkew: GeometryEffect {
    var degrees: Double

    func effectValue(size: CGSize) -> ProjectionTransform {
        let shear = CGFloat(tan(degrees * .pi / 180))
        return ProjectionTransform(CGAffineTransform(a: 1, b: 0, c: shear, d: 1, tx: -shear * size.height / 2, ty: 0))
    }
}
