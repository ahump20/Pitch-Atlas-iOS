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
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            try await client.auth.signInWithOTP(
                email: email,
                redirectTo: SupabaseConfig.authRedirectURL
            )
        } catch {
            errorMessage = "Magic link failed: \(error.localizedDescription)"
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
            errorMessage = "Apple sign-in failed: \(error.localizedDescription)"
        }
    }

    func signOut() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await client.auth.signOut()
            apply(session: nil)
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
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
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = Data("{}".utf8)

            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if !(200..<300).contains(status) {
                let body = String(data: data, encoding: .utf8) ?? "no response body"
                errorMessage = "Delete account failed (\(status)): \(body)"
                return false
            }

            try? await client.auth.signOut()
            apply(session: nil)
            return true
        } catch {
            errorMessage = "Delete account failed: \(error.localizedDescription)"
            return false
        }
    }

    private func observeAuthChanges() {
        guard authTask == nil else { return }
        authTask = Task { [weak self] in
            guard let self else { return }
            for await (_, session) in await client.auth.authStateChanges {
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
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(status).")
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
