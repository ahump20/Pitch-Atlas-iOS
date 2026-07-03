import AuthenticationServices
import SwiftUI

struct AccountView: View {
    @Environment(AuthSessionStore.self) private var auth
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var claimEmail = ""
    @State private var deleteRequested = false
    @State private var deleteFinished = false
    @State private var anonymousSignOutRequested = false
    @State private var blockedState: CommunityLoadState<[BlockedContributor]> = .idle

    private var service: CommunityService { CommunityService(client: auth.client) }

    var body: some View {
        ZStack {
            FieldBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xl) {
                    masthead
                    accountState
                    safety
                    links
                }
                .padding(PitchAtlasSpacing.lg)
                .padding(.bottom, PitchAtlasSpacing.xl3)
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: auth.userID) { await loadBlockedContributors() }
        .alert("Delete this account?", isPresented: $deleteRequested) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    deleteFinished = await auth.deleteAccount()
                    if deleteFinished { Haptics.success() } else { Haptics.failure() }
                }
            }
        } message: {
            Text("This removes your Pitch Atlas account and community records tied to it.")
        }
        .alert("Account deleted", isPresented: $deleteFinished) {
            Button("Done") { dismiss() }
        } message: {
            Text("The app is back in logged-out reference mode.")
        }
        .alert("Abandon this anonymous record?", isPresented: $anonymousSignOutRequested) {
            Button("Cancel", role: .cancel) {}
            Button("Sign out", role: .destructive) {
                Task { await auth.signOut() }
            }
        } message: {
            Text("Signing out abandons this anonymous record — its notes stay public but can never be claimed.")
        }
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            HStack(alignment: .center, spacing: PitchAtlasSpacing.sm) {
                BrandSealMark(size: 48)
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs2) {
                    SectionLabel(text: "Account and Safety", color: PitchAtlasTheme.powder)
                    Text("PITCH ATLAS")
                        .font(PitchAtlasTheme.anton(38))
                        .foregroundStyle(PitchAtlasTheme.bone)
                        .antonSkew()
                }
            }
            Text("The field manual is readable without an account, and posting, reports, and blocks work anonymously. Sign in only to keep your record across devices; image uploads need a claimed account.")
                .font(PitchAtlasTheme.hanken(15))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var accountState: some View {
        if auth.isClaimed {
            claimedPanel
        } else if auth.isSignedIn {
            anonymousPanel
        } else {
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.md) {
                SignInPanel(email: $email)
                Text("Reading the atlas and posting anonymously need no account. Sign in only if you want your record to travel with you.")
                    .font(PitchAtlasTheme.hanken(13))
                    .foregroundStyle(PitchAtlasTheme.ink3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .leatherPress()
        }
    }

    private var claimedPanel: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.md) {
            SectionLabel(text: "Signed in")
            // Never the raw user id: a UUID as an account title reads like a bug.
            Text(auth.email ?? "Pitch Atlas account")
                .font(PitchAtlasTheme.newsreader(22))
                .foregroundStyle(PitchAtlasTheme.bone)

            if let error = auth.errorMessage {
                Text(error)
                    .font(PitchAtlasTheme.hanken(13))
                    .foregroundStyle(PitchAtlasTheme.amberBright)
            }

            HStack {
                Button {
                    Task { await auth.signOut() }
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    deleteRequested = true
                } label: {
                    Label("Delete account", systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .leatherPress()
    }

    private var anonymousPanel: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.md) {
            SectionLabel(text: "Signed in")
            Text("Anonymous contributor")
                .font(PitchAtlasTheme.newsreader(22))
                .foregroundStyle(PitchAtlasTheme.bone)
            Text("Everything you file rides this device's anonymous record. Claim it below to keep your notes across devices.")
                .font(PitchAtlasTheme.hanken(14))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)

            Divider().overlay(PitchAtlasTheme.machined)
            SectionLabel(text: "Claim this record")

            // Links the Apple identity onto the anonymous account — the store's
            // completeAppleSignIn branches to the link path while the session is
            // anonymous, so the user id and filed notes are preserved.
            SignInWithAppleButton(.signIn) { request in
                auth.configureAppleRequest(request)
            } onCompletion: { result in
                Task { await auth.completeAppleSignIn(result) }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 46)

            VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs2) {
                PitchFormLabel("Email")
                TextField("you@example.com", text: $claimEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(PitchAtlasTheme.hanken(15))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .pitchTextFieldSurface()
                PitchFormCaption(text: "We send a confirmation link that attaches this email to your record.")
            }

            Button {
                Task { await auth.claimEmail(claimEmail.trimmingCharacters(in: .whitespacesAndNewlines)) }
            } label: {
                Label(auth.isWorking ? "Sending…" : "Claim with email", systemImage: "envelope")
            }
            .buttonStyle(.borderedProminent)
            .disabled(claimEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || auth.isWorking)
            .opacity((claimEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || auth.isWorking) ? 0.55 : 1)

            if let sentTo = auth.claimEmailSentTo {
                Label("Check your email to confirm — your filed notes ride along. The link went to \(sentTo).", systemImage: "checkmark.circle")
                    .font(PitchAtlasTheme.hanken(13))
                    .foregroundStyle(PitchAtlasTheme.okBright)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let error = auth.errorMessage {
                Text(error)
                    .font(PitchAtlasTheme.hanken(13))
                    .foregroundStyle(PitchAtlasTheme.amberBright)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider().overlay(PitchAtlasTheme.machined)

            HStack {
                Button {
                    anonymousSignOutRequested = true
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    deleteRequested = true
                } label: {
                    Label("Delete account", systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .leatherPress()
    }

    private var safety: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "Community rules")
            Text("Post your own experience only. No minors in uploads. No copyrighted media. No abusive, unsafe, or medical-advice claims. Reports can hide content before review.")
                .font(PitchAtlasTheme.hanken(14))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
            Text("Blocking hides community content both ways. The list below is private to your signed-in account.")
                .font(PitchAtlasTheme.newsreaderItalic(14))
                .foregroundStyle(PitchAtlasTheme.ink3)
                .fixedSize(horizontal: false, vertical: true)
            blockedContributorsSection
        }
        .leatherPress()
    }

    @ViewBuilder
    private var blockedContributorsSection: some View {
        if auth.isSignedIn {
            Divider().overlay(PitchAtlasTheme.machined)
            SectionLabel(text: "Blocked Contributors")
            switch blockedState {
            case .idle, .loading:
                LoadingTile(label: "Loading blocked contributors")
            case .empty:
                EmptyStateView(message: "No contributors blocked.")
            case .failed(let reason):
                ErrorStateView(title: "Blocked list unavailable", reason: reason)
            case .loaded(let contributors):
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                    ForEach(contributors) { contributor in
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(contributor.displayName)
                                    .font(PitchAtlasTheme.hankenMedium(14))
                                    .foregroundStyle(PitchAtlasTheme.bone)
                                Text("Blocked contributor")
                                    .font(PitchAtlasTheme.hanken(12))
                                    .foregroundStyle(PitchAtlasTheme.ink3)
                            }
                            Spacer()
                            Button {
                                Task { await unblock(contributor) }
                            } label: {
                                Label("Unblock", systemImage: "person.crop.circle.badge.minus")
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("Unblock \(contributor.displayName)")
                        }
                        .padding(PitchAtlasSpacing.sm)
                        .background(PitchAtlasTheme.void, in: RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous).stroke(PitchAtlasTheme.machined))
                    }
                }
            }
        } else {
            Text("No contributor record on this device yet. Block someone from a community post and the private list appears here.")
                .font(PitchAtlasTheme.hanken(13))
                .foregroundStyle(PitchAtlasTheme.ink3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var links: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "Links")
            Button {
                openURL(URL(string: "https://pitch-atlas.com/support")!)
            } label: {
                Label("Support", systemImage: "lifepreserver")
            }
            Button {
                openURL(URL(string: "https://pitch-atlas.com/privacy")!)
            } label: {
                Label("Privacy", systemImage: "hand.raised")
            }
        }
        .buttonStyle(.bordered)
        .leatherPress()
    }

    private func loadBlockedContributors() async {
        guard auth.isSignedIn, let userID = auth.userID else {
            blockedState = .idle
            return
        }
        blockedState = .loading
        do {
            let contributors = try await service.blockedContributors()
            guard auth.userID == userID else { return }
            blockedState = contributors.isEmpty ? .empty : .loaded(contributors)
        } catch {
            guard auth.userID == userID else { return }
            blockedState = .failed(CommunityService.userMessage(for: error, fallback: "Could not load blocked contributors just now. Try again."))
        }
    }

    private func unblock(_ contributor: BlockedContributor) async {
        guard let userID = auth.userID else { return }
        do {
            try await service.unblockUser(blockedID: contributor.blockedID)
            guard auth.userID == userID else { return }
            await loadBlockedContributors()
            Haptics.success()
        } catch {
            guard auth.userID == userID else { return }
            blockedState = .failed(CommunityService.userMessage(for: error))
            Haptics.failure()
        }
    }
}

struct SignInPanel: View {
    @Environment(AuthSessionStore.self) private var auth
    @Binding var email: String

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.md) {
            SectionLabel(text: "Sign in")
            SignInWithAppleButton(.signIn) { request in
                auth.configureAppleRequest(request)
            } onCompletion: { result in
                Task { await auth.completeAppleSignIn(result) }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 46)

            VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs2) {
                PitchFormLabel("Email")
                TextField("you@example.com", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(PitchAtlasTheme.hanken(15))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .pitchTextFieldSurface()
                PitchFormCaption(text: "Used only to send the magic sign-in link.")
            }

            Button {
                Task { await auth.sendMagicLink(email: email.trimmingCharacters(in: .whitespacesAndNewlines)) }
            } label: {
                Label(auth.isWorking ? "Sending…" : "Send magic link", systemImage: "envelope")
            }
            .buttonStyle(.borderedProminent)
            .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || auth.isWorking)
            .opacity((email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || auth.isWorking) ? 0.55 : 1)

            if let sentTo = auth.magicLinkSentTo {
                Label("Check your email. We sent a sign-in link to \(sentTo). Open it on this device to finish.", systemImage: "checkmark.circle")
                    .font(PitchAtlasTheme.hanken(13))
                    .foregroundStyle(PitchAtlasTheme.okBright)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let error = auth.errorMessage {
                Text(error)
                    .font(PitchAtlasTheme.hanken(13))
                    .foregroundStyle(PitchAtlasTheme.amberBright)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
