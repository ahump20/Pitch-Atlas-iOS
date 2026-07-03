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
    /// True while the session belongs to an unclaimed anonymous account.
    /// False when signed out (there is no account to be anonymous).
    private(set) var isAnonymous = false
    private(set) var isWorking = false
    var errorMessage: String?
    /// Set to the address a magic link was just sent to, so the sign-in panel can
    /// confirm "check your email" instead of leaving a successful tap looking like
    /// nothing happened. Cleared when a new send starts or the user signs in.
    private(set) var magicLinkSentTo: String?
    /// Set to the address an anonymous-account email claim was just sent to, so
    /// the claim block can confirm "check your email" the same way the magic-link
    /// panel does. Cleared when a new claim starts or once the claim confirms.
    private(set) var claimEmailSentTo: String?
    private var lastMagicLinkAt: Date?
    private let magicLinkCooldown: TimeInterval = 30

    private var authTask: Task<Void, Never>?
    private var pendingAppleNonce: String?

    init(client: SupabaseClient = SupabaseConfig.makeClient()) {
        self.client = client
    }

    var isSignedIn: Bool { userID != nil }

    /// A permanent account: signed in AND not anonymous. Server policy restricts
    /// media uploads and media-terms acceptance to claimed accounts, so upload UI
    /// gates on this, not on `isSignedIn`.
    var isClaimed: Bool { isSignedIn && !isAnonymous }

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

    /// Write-intent session: return the signed-in user id (anonymous or claimed),
    /// minting an anonymous account only when no session exists at all.
    ///
    /// This is the ONLY place in the app allowed to call `signInAnonymously()`.
    /// It mirrors the web's no-minting contract (pinned by
    /// `src/lib/community.read-path.test.ts` in the web repo): reads NEVER mint —
    /// the anon role's SELECT grants already serve the public set to a sessionless
    /// caller — and an account appears only when someone actually posts, reports,
    /// or blocks. A failed session lookup surfaces as an error instead of minting
    /// a replacement account that would orphan the existing record.
    func ensureSessionForWrite() async throws -> String {
        do {
            let session = try await client.auth.session
            apply(session: session)
            return String(describing: session.user.id)
        } catch AuthError.sessionMissing {
            // Genuinely signed out — fall through and mint on this write intent.
        } catch {
            // The session exists but could not be read (refresh failure, network).
            // Do NOT mint a replacement over it.
            throw CommunityServiceError.sessionStartFailed
        }

        do {
            let session = try await client.auth.signInAnonymously()
            apply(session: session)
            return String(describing: session.user.id)
        } catch {
            throw CommunityServiceError.sessionStartFailed
        }
    }

    func sendMagicLink(email: String) async {
        guard !isWorking else { return }
        // A magic link signs into a DIFFERENT account, which would orphan every
        // note filed under this device's anonymous record. Claiming an anonymous
        // account goes through claimEmail; this path is for signed-out sign-in only.
        if isSignedIn && isAnonymous {
            errorMessage = "This device has an anonymous record. Use \"Claim this record\" so your filed notes ride along."
            return
        }
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

            let credentials = OpenIDConnectCredentials(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )

            if isSignedIn && isAnonymous {
                // Claim path: LINK the Apple identity onto the anonymous account
                // so the user id — and every note filed under it — is preserved.
                // Never fall back to signInWithIdToken here: that would sign into
                // a different account and orphan the anonymous record.
                let session = try await client.auth.linkIdentityWithIdToken(credentials: credentials)
                apply(session: session)
            } else {
                let session = try await client.auth.signInWithIdToken(credentials: credentials)
                apply(session: session)
            }
        } catch let error where Self.isAppleIdentityConflict(error) {
            errorMessage = Self.appleIdentityConflictMessage
        } catch {
            errorMessage = "Apple sign-in failed. Try again from the Apple button."
        }
    }

    /// The Apple identity is already attached to a different Pitch Atlas account,
    /// so it cannot also claim this anonymous record. Matched by Supabase error
    /// code first, message shape second — never exact string equality.
    nonisolated static func isAppleIdentityConflict(_ error: Error) -> Bool {
        guard let authError = error as? AuthError else { return false }
        return isIdentityConflict(code: authError.errorCode.rawValue, message: authError.message)
    }

    /// Pure matcher behind isAppleIdentityConflict, testable without constructing
    /// SDK error types. The structured code is authoritative; older gateways may
    /// omit it, so the message SHAPE is the fallback — never exact equality,
    /// which a server wording change would silently break.
    nonisolated static func isIdentityConflict(code: String?, message: String) -> Bool {
        if code == "identity_already_exists" { return true }
        let lowered = message.lowercased()
        return lowered.contains("identity") && lowered.contains("already")
    }

    nonisolated static var appleIdentityConflictMessage: String {
        "That Apple ID already has a Pitch Atlas account. Sign in with it instead — notes filed anonymously on this device stay under the anonymous record."
    }

    /// Claim the anonymous account by attaching an email. The user id never
    /// changes, so every filed note survives; Supabase emails a confirmation
    /// link and the account stops being anonymous when it is confirmed.
    ///
    /// This must NEVER route through `sendMagicLink`/`signInWithOTP` for an
    /// anonymous session — OTP signs into a different account and orphans the
    /// anonymous record. Mirrors the web's `claimWithEmail`.
    func claimEmail(_ email: String) async {
        guard !isWorking else { return }
        isWorking = true
        errorMessage = nil
        claimEmailSentTo = nil
        defer { isWorking = false }

        do {
            try await client.auth.update(
                user: UserAttributes(email: email),
                redirectTo: SupabaseConfig.authRedirectURL
            )
            claimEmailSentTo = email
            // The SDK already refreshed the local user; re-apply so isAnonymous
            // and email reflect the server's view of the claim in progress.
            await refreshSession()
        } catch {
            errorMessage = "Could not send the claim email just now. Check the address and try again."
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
        isAnonymous = session?.user.isAnonymous ?? false
        if session != nil { magicLinkSentTo = nil }
        // The claim confirmation stays visible while the account is still
        // anonymous (the auth stream re-applies the session on every update);
        // it clears once the claim confirms and the record stops being anonymous.
        if let session, !session.user.isAnonymous { claimEmailSentTo = nil }
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
