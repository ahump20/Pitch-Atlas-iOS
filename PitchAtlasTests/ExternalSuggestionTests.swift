import XCTest
@testable import PitchAtlas

/// The media suggestion, pinned to lib/external-content.test.ts and
/// data/media/external.ts (web 47e21e6). Nothing here reaches the server: the
/// tests cover validation and the encoded insert only.
final class ExternalSuggestionTests: XCTestCase {
    /// external-content.test.ts: a supported public post normalizes.
    func testNormalizesASupportedPublicPost() throws {
        let parsed = try ExternalSuggestion.validate(url: " https://x.com/PitchingNinja/status/1061649568847269889 ",
                                                     rationale: "Rivera teaches the cutter grip hand to hand.")
        XCTAssertEqual(parsed.platform, "x")
        XCTAssertEqual(parsed.externalID, "1061649568847269889")
        XCTAssertEqual(parsed.canonicalURL, "https://x.com/PitchingNinja/status/1061649568847269889")
    }

    /// external-content.test.ts: an unsupported host and a context-free reason are refused
    /// with the site's words.
    func testRejectsUnsupportedHostsAndContextFreeSubmissions() {
        XCTAssertThrowsError(try ExternalSuggestion.validate(url: "https://example.com/video/1", rationale: "This belongs here.")) {
            XCTAssertEqual(($0 as? ExternalSuggestion.Failure)?.message,
                           "Paste a public X, Instagram, TikTok, or YouTube post URL.")
        }
        XCTAssertThrowsError(try ExternalSuggestion.validate(url: "https://youtu.be/abc123", rationale: "good")) {
            XCTAssertEqual(($0 as? ExternalSuggestion.Failure)?.message,
                           "Tell us why it belongs in the atlas in 10 to 300 characters.")
        }
        XCTAssertThrowsError(try ExternalSuggestion.validate(url: "https://youtu.be/abc123",
                                                             rationale: String(repeating: "a", count: 301)))
    }

    /// platformFromUrl / externalIdFromUrl, every form the site reads.
    func testEveryPlatformsIdForm() throws {
        let cases: [(String, String, String)] = [
            ("https://www.tiktok.com/@coach/video/7300000000000000001", "tiktok", "7300000000000000001"),
            ("https://twitter.com/PitchingNinja/status/123456", "x", "123456"),
            ("https://www.instagram.com/p/Cabc123/", "instagram", "Cabc123"),
            ("https://instagram.com/reel/Rxyz789", "instagram", "Rxyz789"),
            ("https://youtu.be/dQw4w9WgXcQ", "youtube", "dQw4w9WgXcQ"),
            ("https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=10", "youtube", "dQw4w9WgXcQ"),
            ("https://youtube.com/shorts/abcDEF123", "youtube", "abcDEF123"),
        ]
        for (url, platform, id) in cases {
            let parsed = try ExternalSuggestion.validate(url: url, rationale: "A real grip lesson, hand to hand.")
            XCTAssertEqual(parsed.platform, platform, url)
            XCTAssertEqual(parsed.externalID, id, url)
        }
        XCTAssertThrowsError(try ExternalSuggestion.validate(url: "https://x.com/PitchingNinja", rationale: "A real grip lesson."))
        XCTAssertThrowsError(try ExternalSuggestion.validate(url: "not a url", rationale: "A real grip lesson."))
    }

    /// The insert carries exactly the six columns the site sends.
    func testTheInsertCarriesExactlyTheSixColumns() throws {
        let parsed = try ExternalSuggestion.validate(url: "https://youtu.be/abc123", rationale: "  A real grip lesson.  ")
        let insert = ExternalSuggestion.Insert(submittedBy: "user-1", parsed: parsed, rationale: "  A real grip lesson.  ",
                                               pitchSlug: " cutter ")
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(insert)) as? [String: Any])
        XCTAssertEqual(Set(object.keys), ["submitted_by", "canonical_url", "platform", "external_id", "rationale", "pitch_slug"])
        XCTAssertEqual(object["rationale"] as? String, "A real grip lesson.")
        XCTAssertEqual(object["pitch_slug"] as? String, "cutter")
        let general = ExternalSuggestion.Insert(submittedBy: "user-1", parsed: parsed, rationale: "A real grip lesson.", pitchSlug: nil)
        let generalObject = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(general)) as? [String: Any])
        XCTAssertTrue(generalObject["pitch_slug"] is NSNull)
    }

    /// submitExternalSuggestion's refusal words.
    func testTheServersRefusalsReadAsTheSitesWords() {
        XCTAssertEqual(ExternalSuggestion.refusal(for: "rate_limit: too many suggestions in a short time"),
                       "You have filed several suggestions recently. Try again later.")
        XCTAssertEqual(ExternalSuggestion.refusal(for: "duplicate key value violates unique constraint"),
                       "That post is already in the review queue.")
        XCTAssertEqual(ExternalSuggestion.refusal(for: "something else"), "Could not file that suggestion just now. Try again.")
    }
}
