import AuthenticationServices
import SwiftUI

struct AccountView: View {
    @Environment(AuthSessionStore.self) private var auth
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var deleteRequested = false
    @State private var deleteFinished = false
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
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
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
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            HStack(alignment: .center, spacing: PitchAtlasSpacing.sm) {
                BrandSealMark(size: 48)
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs2) {
                    SectionLabel(text: "Account and Safety", color: PitchAtlasTheme.powder)
                    Text("ACCOUNT & SAFETY")
                        .font(PitchAtlasTheme.anton(30))
                        .foregroundStyle(PitchAtlasTheme.bone)
                        .antonSkew()
                }
            }
            Text("The field manual is readable without an account. Posting, reports, blocks, uploads, and account deletion require sign-in.")
                .font(PitchAtlasTheme.hanken(15))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var accountState: some View {
        if auth.isSignedIn {
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.md) {
                SectionLabel(text: "Signed in")
                Text(auth.email ?? auth.userID ?? "Pitch Atlas account")
                    .font(PitchAtlasTheme.newsreader(22))
                    .foregroundStyle(PitchAtlasTheme.bone)

                if let error = auth.errorMessage {
                    Text(error)
                        .font(PitchAtlasTheme.hanken(13))
                        .foregroundStyle(PitchAtlasTheme.amberBright)
                }

                HStack {
                    Button("Sign out") {
                        Task { await auth.signOut() }
                    }
                    .buttonStyle(.bordered)

                    Button("Delete account", role: .destructive) {
                        deleteRequested = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .leatherPress()
        } else {
            SignInPanel(email: $email)
                .leatherPress()
        }
    }

    private var safety: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "Community rules")
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
                safetyRule("Post your own experience only.")
                safetyRule("No minors, copyrighted media, abusive content, unsafe claims, or medical advice.")
                safetyRule("Reports can hide content before review.")
            }
            Label("Blocking hides community content both ways. Your blocked list is private to this signed-in account.", systemImage: "hand.raised.fill")
                .font(PitchAtlasTheme.hankenMedium(13))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
            blockedContributorsSection
        }
        .leatherPress()
    }

    private func safetyRule(_ text: String) -> some View {
        HStack(alignment: .top, spacing: PitchAtlasSpacing.xs) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(PitchAtlasTheme.okBright)
                .padding(.top, 2)
            Text(text)
                .font(PitchAtlasTheme.hanken(14))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
        }
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
                            Button("Unblock") {
                                Task { await unblock(contributor) }
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
            Text("Sign in to review or change blocked contributors.")
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
        guard auth.isSignedIn else {
            blockedState = .idle
            return
        }
        blockedState = .loading
        do {
            let contributors = try await service.blockedContributors()
            blockedState = contributors.isEmpty ? .empty : .loaded(contributors)
        } catch {
            blockedState = .failed(CommunityService.userMessage(for: error, fallback: "Could not load blocked contributors just now. Try again."))
        }
    }

    private func unblock(_ contributor: BlockedContributor) async {
        do {
            try await service.unblockUser(blockedID: contributor.blockedID)
            await loadBlockedContributors()
            Haptics.success()
        } catch {
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
                Text("Email for magic link")
                    .font(PitchAtlasTheme.hankenMedium(13))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                ZStack(alignment: .leading) {
                    if email.isEmpty {
                        Text("you@example.com")
                            .font(PitchAtlasTheme.hanken(16))
                            .foregroundStyle(PitchAtlasTheme.ink3)
                            .allowsHitTesting(false)
                    }
                    TextField("", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .tint(PitchAtlasTheme.cyan)
                        .foregroundStyle(PitchAtlasTheme.bone)
                        .accessibilityLabel("Email for magic link")
                }
                .padding(12)
                .background(PitchAtlasTheme.void, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(PitchAtlasTheme.machined))
            }

            Button {
                Task { await auth.sendMagicLink(email: email.trimmingCharacters(in: .whitespacesAndNewlines)) }
            } label: {
                Label(magicLinkButtonTitle, systemImage: auth.isWorking ? "hourglass" : "envelope")
            }
            .buttonStyle(.borderedProminent)
            .tint(canSendMagicLink ? PitchAtlasTheme.cyanDeep : PitchAtlasTheme.paper3)
            .foregroundStyle(canSendMagicLink ? PitchAtlasTheme.bone : PitchAtlasTheme.bone2)
            .disabled(!canSendMagicLink)

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

    private var canSendMagicLink: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !auth.isWorking
    }

    private var magicLinkButtonTitle: String {
        if auth.isWorking { return "Sending..." }
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Enter email to send link" }
        return "Send magic link"
    }
}
