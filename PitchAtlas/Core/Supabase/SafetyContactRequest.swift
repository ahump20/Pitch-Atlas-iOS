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
        guard (messageMinimum...messageLimit).contains(message.count) else { throw ValidationError.messageLength }
        if !email.isEmpty {
            guard email.count <= 254,
                  email.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil else {
                throw ValidationError.email
            }
        }
        return Self(message: message, replyEmail: email.isEmpty ? nil : email)
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
