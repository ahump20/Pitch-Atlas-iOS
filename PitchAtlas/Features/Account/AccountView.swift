import AuthenticationServices
import SwiftUI

struct AccountView: View {
    @Environment(AuthSessionStore.self) private var auth
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var deleteRequested = false
    @State private var deleteFinished = false

    var body: some View {
        ZStack {
            PitchAtlasTheme.void.ignoresSafeArea()
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
            SectionLabel(text: "Account and Safety")
            Text("PITCH ATLAS")
                .font(PitchAtlasTheme.anton(42))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
            Text("The field manual is readable without an account. Posting, reporting, blocking, and uploads require sign-in.")
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
            Text("Post your own experience only. No minors in uploads. No copyrighted media. No abusive, unsafe, or medical-advice claims. Reports can hide content before review.")
                .font(PitchAtlasTheme.hanken(14))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
            Text("Blocking hides community content both ways and stops direct replies across that edge.")
                .font(PitchAtlasTheme.newsreaderItalic(14))
                .foregroundStyle(PitchAtlasTheme.ink3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .leatherPress()
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

            TextField("Email for magic link", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(PitchAtlasTheme.void, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(PitchAtlasTheme.machined))
                .foregroundStyle(PitchAtlasTheme.bone)

            Button {
                Task { await auth.sendMagicLink(email: email.trimmingCharacters(in: .whitespacesAndNewlines)) }
            } label: {
                Label("Send magic link", systemImage: "envelope")
            }
            .buttonStyle(.borderedProminent)
            .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || auth.isWorking)

            if let error = auth.errorMessage {
                Text(error)
                    .font(PitchAtlasTheme.hanken(13))
                    .foregroundStyle(PitchAtlasTheme.amberBright)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
