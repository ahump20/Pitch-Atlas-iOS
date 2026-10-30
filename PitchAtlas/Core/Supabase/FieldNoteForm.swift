import Foundation

// =============================================================================
// The field-note form and the bullpen card, as values
// =============================================================================
// Web: sections/FieldNotes.tsx (SubmitForm, IdentityStrip, timeAgo),
// data/field-notes.ts (VELOCITY_BANDS) and lib/community.ts
// (SOURCE_TIER_OPTIONS, paceToDb/paceFromDb, getIdentity). The view draws these;
// the rules live here so they can be held to the site's values.
// =============================================================================

/// VELOCITY_BANDS: the form's pace context. The raw value is the database's band
/// (paceToDb); a stored row may carry either form, so reading is lenient
/// (paceFromDb) and an unknown band reads as none.
enum CommunityVelocityBand: String, CaseIterable, Identifiable, Hashable, Encodable {
    case lowEffort = "under-60"
    case developingArm = "60-69"
    case prepArm = "70-79"
    case collegeArm = "80-89"
    case powerArm = "90-plus"

    var id: String { rawValue }

    /// The site's own name for the band (the value VELOCITY_BANDS is keyed on).
    var formValue: String {
        switch self {
        case .lowEffort: "low-effort"
        case .developingArm: "developing-arm"
        case .prepArm: "prep-arm"
        case .collegeArm: "college-arm"
        case .powerArm: "power-arm"
        }
    }

    var label: String {
        switch self {
        case .lowEffort: "Low-effort context"
        case .developingArm: "Developing pace context"
        case .prepArm: "Intermediate pace context"
        case .collegeArm: "Advanced pace context"
        case .powerArm: "Power pace context"
        }
    }

    /// paceFromDb: the database band or the site's own name.
    init?(stored: String) {
        if let band = Self(rawValue: stored) {
            self = band
        } else if let band = Self.allCases.first(where: { $0.formValue == stored }) {
            self = band
        } else {
            return nil
        }
    }
}

/// SOURCE_TIER_OPTIONS: the four tiers a contributor can file under. A relayed
/// claim or a hunch must say where it comes from (the server's
/// weak_tier_requires_note check says the same).
enum CommunityWritableTier: String, CaseIterable, Identifiable, Hashable {
    case ownReport = "community-firsthand"
    case coach = "coach-observed"
    case relayed = "secondhand-attributed"
    case hunch = "unverified"

    var id: String { rawValue }

    var tier: CommunitySourceTier {
        switch self {
        case .ownReport: .communityFirsthand
        case .coach: .coachObserved
        case .relayed: .secondhandAttributed
        case .hunch: .unverified
        }
    }

    var label: String {
        switch self {
        case .ownReport: "My own report"
        case .coach: "A coach I work with reported it"
        case .relayed: "Relayed from someone else"
        case .hunch: "A hunch - untested"
        }
    }

    var requiresNote: Bool { self == .relayed || self == .hunch }
}

/// SubmitForm's state: the fields, the empty form's defaults (EMPTY_FORM), and
/// the rule that enables "File field note". The site's form has no result-note
/// field, so a note never carries one.
struct FieldNoteDraft: Equatable {
    var displayName = ""
    var tweak = ""
    var playerLevel: CommunityPlayerLevel = .highSchool
    var armSlot: CommunityArmSlot = .threeQuarter
    var velocityBand: CommunityVelocityBand?
    var intent: CommunityPitchIntent = .moreMovement
    var claimedResultKind: CommunityClaimedResultKind = .workedInBullpen
    var sampleSize = ""
    var sourceTier: CommunityWritableTier = .ownReport
    var note = ""
    var evidenceURL = ""
    var evidenceLabel = ""

    var noteRequired: Bool { sourceTier.requiresNote }
    /// The context field shows when the source needs it or something is in it.
    var showsContext: Bool { noteRequired || !note.isEmpty }

    /// FieldNotes.tsx `valid`: a handle of two or more characters, a tweak, and
    /// context when the source needs it.
    var isValid: Bool {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
            && !tweak.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (!noteRequired || !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    func newFieldNote(pitchSlug: String) throws -> NewFieldNote {
        try NewFieldNote.validated(
            pitchSlug: pitchSlug,
            displayName: displayName,
            tweak: tweak,
            playerLevel: playerLevel,
            armSlot: armSlot,
            intent: intent,
            claimedResultKind: claimedResultKind,
            claimedResultNote: "",
            sampleSizeText: sampleSize,
            evidenceURL: evidenceURL,
            evidenceLabel: evidenceLabel,
            sourceTier: sourceTier.tier,
            note: note,
            velocityBand: velocityBand
        )
    }

    /// After a filing the form empties but keeps the handle, as the site's does.
    mutating func clearAfterFiling() {
        self = FieldNoteDraft(displayName: displayName)
    }
}

/// The signed-in contributor's profile row (lib/community getIdentity): the
/// handle, the claimed flag, and the score a bullpen card prints.
struct ContributorIdentity: Decodable, Equatable {
    let displayName: String?
    /// nil when the row doesn't say; the account's own state answers then.
    let isClaimed: Bool?
    let contributionScore: Int
    let notesCount: Int

    init(displayName: String?, isClaimed: Bool?, contributionScore: Int, notesCount: Int) {
        self.displayName = displayName
        self.isClaimed = isClaimed
        self.contributionScore = contributionScore
        self.notesCount = notesCount
    }

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case isClaimed = "is_claimed"
        case contributionScore = "contribution_score"
        case notesCount = "notes_count"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        displayName = try c.decodeIfPresent(String.self, forKey: .displayName)
        isClaimed = try c.decodeIfPresent(Bool.self, forKey: .isClaimed)
        contributionScore = try c.decodeIfPresent(Int.self, forKey: .contributionScore) ?? 0
        notesCount = try c.decodeIfPresent(Int.self, forKey: .notesCount) ?? 0
    }
}

/// What the card knows about the reader. A signed-out reader truly has nothing
/// filed; a signed-in reader's score is unknown until the profile loads.
enum ContributorIdentityState: Equatable {
    case signedOut
    case loading
    case loaded(ContributorIdentity)
    case failed
}

/// IdentityStrip's words (FieldNotes.tsx).
enum BullpenCard {
    /// "{score} pts" — never a zero the server didn't give.
    static func points(_ state: ContributorIdentityState) -> String? {
        switch state {
        case .signedOut: "0 pts"
        case .loaded(let identity): "\(identity.contributionScore) pts"
        case .loading, .failed: nil
        }
    }

    static func isClaimed(_ state: ContributorIdentityState, accountClaimed: Bool) -> Bool {
        if case .loaded(let identity) = state { return identity.isClaimed ?? accountClaimed }
        return state == .signedOut ? false : accountClaimed
    }

    static func handle(_ state: ContributorIdentityState) -> String? {
        if case .loaded(let identity) = state, let name = identity.displayName, !name.isEmpty { return name }
        return nil
    }

    static func filingLine(_ state: ContributorIdentityState, accountClaimed: Bool) -> String {
        let name = handle(state) ?? "an unclaimed contributor"
        return "Filing as \(name)\(isClaimed(state, accountClaimed: accountClaimed) ? " · claimed ✓" : " · anonymous")."
    }

    static func claimPrompt(_ state: ContributorIdentityState) -> String {
        var score = 0
        if case .loaded(let identity) = state { score = identity.contributionScore }
        return "You can take part with no account. Add an email to keep your \(score > 0 ? "\(score) " : "")points and notes if you switch devices, never required."
    }

    static let claimedLine = "Your account is claimed. Your notes and credit follow you on any device you sign in on."
    static let claimSent = "Check your email. Click the link to claim this account. Your credit stays put."
    /// lib/community CLAIM_EMAIL_ERROR.
    static let claimFailed = "Could not send the claim email just now. Try again."
}

/// FieldNotes.tsx `timeAgo`: the age a note card prints, from the server's
/// created_at and the reader's clock.
enum FieldNoteAge {
    static func label(seconds: TimeInterval) -> String {
        let secs = max(0, Int(seconds.rounded(.down)))
        if secs < 60 { return "just now" }
        let mins = secs / 60
        if mins < 60 { return "\(mins) min ago" }
        let hrs = mins / 60
        if hrs < 24 { return "\(hrs) hr ago" }
        let days = hrs / 24
        if days < 30 { return "\(days) d ago" }
        let months = days / 30
        if months < 12 { return "\(months) mo ago" }
        return "\(months / 12) yr ago"
    }

    /// nil when the timestamp doesn't parse; the card then prints no age.
    static func label(createdAt: String, now: Date = Date()) -> String? {
        guard let date = parse(createdAt) else { return nil }
        return label(seconds: now.timeIntervalSince(date))
    }

    private static func parse(_ iso: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: iso) { return date }
        return ISO8601DateFormatter().date(from: iso)
    }
}
