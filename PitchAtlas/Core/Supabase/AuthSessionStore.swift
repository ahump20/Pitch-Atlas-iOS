import AuthenticationServices
import CryptoKit
import Foundation
import Observation
import Security
import Supabase

@MainActor
@Observable
final class AuthSessionStore {
    let client: SupabaseClient

    private(set) var userID: String?
    private(set) var email: String?
    private(set) var accessToken: String?
    private(set) var isWorking = false
    var errorMessage: String?
    /// Set to the address a magic link was just sent to, so the sign-in panel can
    /// confirm "check your email" instead of leaving a successful tap looking like
    /// nothing happened. Cleared when a new send starts or the user signs in.
    private(set) var magicLinkSentTo: String?
    private var lastMagicLinkAt: Date?
    private let magicLinkCooldown: TimeInterval = 30

    private var authTask: Task<Void, Never>?
    private var pendingAppleNonce: String?

    init(client: SupabaseClient = SupabaseConfig.makeClient()) {
        self.client = client
    }

    var isSignedIn: Bool { userID != nil }

    var displayName: String {
        if let email, let prefix = email.split(separator: "@").first {
            return String(prefix).replacingOccurrences(of: ".", with: " ")
        }
        return "Pitch Atlas contributor"
    }

    func start() async {
        await refreshSession()
        observeAuthChanges()
    }

    func refreshSession() async {
        do {
            let session = try await client.auth.session
            apply(session: session)
        } catch {
            apply(session: nil)
        }
    }

    func handle(url: URL) {
        guard url.scheme == "pitchatlas" else { return }
        client.auth.handle(url)
        Task { await refreshSession() }
    }

    func sendMagicLink(email: String) async {
        guard !isWorking else { return }
        // Resend cooldown: a sign-in link is already in their inbox, so a second
        // tap a moment later just spams them. Tell them, don't re-send.
        if let last = lastMagicLinkAt {
            let since = Date().timeIntervalSince(last)
            if since < magicLinkCooldown {
                errorMessage = "A link is already on its way. You can request another in \(Int(ceil(magicLinkCooldown - since)))s."
                return
            }
        }
        isWorking = true
        errorMessage = nil
        magicLinkSentTo = nil
        defer { isWorking = false }

        do {
            try await client.auth.signInWithOTP(
                email: email,
                redirectTo: SupabaseConfig.authRedirectURL
            )
            magicLinkSentTo = email
            lastMagicLinkAt = Date()
        } catch {
            errorMessage = "Magic link failed. Check the address and try again."
        }
    }

    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonceString()
        pendingAppleNonce = nonce
        request.requestedScopes = [.email, .fullName]
        request.nonce = Self.sha256(nonce)
    }

    func completeAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            let authorization = try result.get()
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8),
                let nonce = pendingAppleNonce
            else {
                errorMessage = "Apple did not return a usable identity token."
                return
            }

            let session = try await client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
            apply(session: session)
        } catch {
            errorMessage = "Apple sign-in failed. Try again from the Apple button."
        }
    }

    func signOut() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await client.auth.signOut()
            apply(session: nil)
        } catch {
            errorMessage = "Sign out failed. Try again."
        }
    }

    func deleteAccount() async -> Bool {
        guard let accessToken else {
            errorMessage = "You need to sign in before deleting an account."
            return false
        }

        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            var request = URLRequest(url: SupabaseConfig.functionsURL.appendingPathComponent("delete-account"))
            request.httpMethod = "POST"
            // A flaky network must not leave the user staring at a spinner forever.
            request.timeoutInterval = 30
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = Data("{}".utf8)

            let (_, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if !(200..<300).contains(status) {
                errorMessage = status == 401
                    ? "Sign in again before deleting this account."
                    : "Delete account failed. Try again, or use Support if it keeps failing."
                return false
            }

            try? await client.auth.signOut()
            apply(session: nil)
            return true
        } catch {
            errorMessage = "Delete account failed. Check your connection and try again."
            return false
        }
    }

    private func observeAuthChanges() {
        guard authTask == nil else { return }
        authTask = Task { [weak self] in
            guard let self else { return }
            for await (_, session) in client.auth.authStateChanges {
                await MainActor.run {
                    self.apply(session: session)
                }
            }
        }
    }

    private func apply(session: Session?) {
        userID = session.map { String(describing: $0.user.id) }
        email = session?.user.email
        accessToken = session?.accessToken
        if session != nil { magicLinkSentTo = nil }
    }

    private static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if status != errSecSuccess {
                // SecRandomCopyBytes effectively never fails, but if it ever did,
                // fall back to the system RNG (same secure source on Apple
                // platforms) rather than crash a user in the middle of sign-in.
                randoms = randoms.map { _ in UInt8.random(in: 0...255) }
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if Int(random) < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
}
