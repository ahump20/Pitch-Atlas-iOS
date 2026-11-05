import Foundation
import Supabase

struct SafetyContactRequest: Encodable {
    static let messageMinimum = 10
    static let messageLimit = 4_000
    let message: String
    let replyEmail: String?

    enum CodingKeys: String, CodingKey {
        case message = "p_message"
        case replyEmail = "p_reply_email"
    }

    enum ValidationError: LocalizedError {
        case messageLength, email
        var errorDescription: String? {
            switch self {
            case .messageLength: "Write a message between 10 and 4,000 characters."
            case .email: "Enter a valid reply email or leave it blank."
            }
        }
    }

    static func validated(message: String, replyEmail: String) throws -> Self {
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = replyEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard hasValidMessageLength(message) else { throw ValidationError.messageLength }
        if !email.isEmpty {
            guard email.unicodeScalars.count <= 254,
                  email.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil else {
                throw ValidationError.email
            }
        }
        return Self(message: message, replyEmail: email.isEmpty ? nil : email)
    }

    /// PostgreSQL char_length counts Unicode scalars, not Swift grapheme clusters.
    static func hasValidMessageLength(_ text: String) -> Bool {
        let message = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return (messageMinimum...messageLimit).contains(message.unicodeScalars.count)
    }

    /// Keep complete visible characters while enforcing the server's scalar cap.
    static func boundedMessage(_ text: String) -> String {
        guard text.unicodeScalars.count > messageLimit else { return text }
        var scalarCount = 0
        var end = text.startIndex
        for character in text {
            let nextCount = scalarCount + character.unicodeScalars.count
            guard nextCount <= messageLimit else { break }
            scalarCount = nextCount
            end = text.index(after: end)
        }
        return String(text[..<end])
    }

    static func userMessage(for error: Error) -> String {
        if let validation = error as? ValidationError { return validation.localizedDescription }
        let diagnostic = "\(error.localizedDescription) \(String(describing: error))".lowercased()
        if diagnostic.contains("rate_limit:") { return "Too many messages. Try again in an hour." }
        if diagnostic.contains("contact_invalid:") { return "Check the message and optional reply email, then try again." }
        return "Message did not send. Your text is still here; try again."
    }
}

extension CommunityService {
    func contactDeveloper(_ request: SafetyContactRequest) async throws -> UUID {
        try await client.rpc("submit_safety_contact", params: request).execute().value
    }
}
