import Foundation

// =============================================================================
// ExternalSuggestion — a reader's suggested pitching post, filed for review
// =============================================================================
// Web: lib/external-content.ts (validateExternalSuggestion, submitExternalSuggestion)
// and data/media/external.ts (platformFromUrl, externalIdFromUrl). Public X,
// Instagram, TikTok and YouTube posts only, a 10–300 character reason, and an insert
// into external_content_suggestions with exactly the six columns the site sends.
// Nothing publishes from here: a person reviews and tags every suggestion first.
// =============================================================================

enum ExternalSuggestion {
    struct Failure: Error, Equatable {
        let message: String
    }

    struct Parsed: Equatable {
        let platform: String
        let externalID: String
        let canonicalURL: String
    }

    /// The row, column for column; `pitch_slug` is null for a general suggestion.
    struct Insert: Encodable {
        let submittedBy: String
        let canonicalURL: String
        let platform: String
        let externalID: String
        let rationale: String
        let pitchSlug: String?

        init(submittedBy: String, parsed: Parsed, rationale: String, pitchSlug: String?) {
            self.submittedBy = submittedBy
            canonicalURL = parsed.canonicalURL
            platform = parsed.platform
            externalID = parsed.externalID
            self.rationale = rationale.trimmingCharacters(in: .whitespacesAndNewlines)
            let slug = pitchSlug?.trimmingCharacters(in: .whitespacesAndNewlines)
            self.pitchSlug = slug?.isEmpty == false ? slug : nil
        }

        enum CodingKeys: String, CodingKey {
            case submittedBy = "submitted_by"
            case canonicalURL = "canonical_url"
            case platform
            case externalID = "external_id"
            case rationale
            case pitchSlug = "pitch_slug"
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(submittedBy, forKey: .submittedBy)
            try c.encode(canonicalURL, forKey: .canonicalURL)
            try c.encode(platform, forKey: .platform)
            try c.encode(externalID, forKey: .externalID)
            try c.encode(rationale, forKey: .rationale)
            try c.encode(pitchSlug, forKey: .pitchSlug)
        }
    }

    static let badURL = "Paste a public X, Instagram, TikTok, or YouTube post URL."
    static let badReason = "Tell us why it belongs in the atlas in 10 to 300 characters."

    static func validate(url raw: String, rationale: String) throws -> Parsed {
        let canonical = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: canonical), let platform = platform(url), let id = externalID(url, platform: platform) else {
            throw Failure(message: badURL)
        }
        let reason = rationale.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (10...300).contains(reason.count) else { throw Failure(message: badReason) }
        return Parsed(platform: platform, externalID: id, canonicalURL: canonical)
    }

    /// The server's refusal, in the site's words; never the server's own text.
    static func refusal(for raw: String) -> String {
        if raw.contains("rate_limit:") { return "You have filed several suggestions recently. Try again later." }
        if raw.contains("duplicate key") || raw.contains("23505") { return "That post is already in the review queue." }
        return "Could not file that suggestion just now. Try again."
    }

    // MARK: platformFromUrl / externalIdFromUrl

    private static func bareHost(_ url: URL) -> String? {
        guard let host = url.host()?.lowercased() else { return nil }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    private static func platform(_ url: URL) -> String? {
        guard let host = bareHost(url) else { return nil }
        if host == "tiktok.com" || host.hasSuffix(".tiktok.com") { return "tiktok" }
        if host == "x.com" || host == "twitter.com" { return "x" }
        if host == "instagram.com" { return "instagram" }
        if host == "youtube.com" || host == "youtu.be" { return "youtube" }
        return nil
    }

    private static func externalID(_ url: URL, platform: String) -> String? {
        let parts = url.path().split(separator: "/").map(String.init)
        func after(_ markers: Set<String>, digits: Bool = false) -> String? {
            guard let i = parts.firstIndex(where: markers.contains), i + 1 < parts.count else { return nil }
            let id = parts[i + 1]
            if digits {
                let run = id.prefix { $0.isASCII && $0.isNumber }
                return run.isEmpty ? nil : String(run)
            }
            return id
        }
        switch platform {
        case "tiktok", "x": return after(["video", "status"], digits: true)
        case "instagram": return after(["p", "reel"])
        default:
            if bareHost(url) == "youtu.be" { return parts.first }
            let v = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "v" }?.value
            return v ?? after(["shorts"])
        }
    }
}
