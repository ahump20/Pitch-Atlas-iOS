import Foundation

/// Where a discussion lives. One value builds every key in the web's format, so a
/// post filed in the app lands in the same thread on pitch-atlas.com and the
/// reverse: a specimen is its bare slug (PitchChapter.tsx), a basic file is
/// `repertoire:<id>`, a lost pitch `lost:<slug>`, a Learn wing `learn:<slug>`,
/// a softball chapter `softball:<slug>`.
enum CommunityTopic: Hashable {
    case specimen(slug: String)
    case repertoire(id: String)
    case lost(slug: String)
    case learn(slug: String)
    case softball(slug: String)

    var key: String {
        switch self {
        case .specimen(let slug): slug
        case .repertoire(let id): "repertoire:\(id)"
        case .lost(let slug): "lost:\(slug)"
        case .learn(let slug): "learn:\(slug)"
        case .softball(let slug): "softball:\(slug)"
        }
    }

    /// Field notes are a specimen's drawer; every other surface carries discussion only.
    var allowsFieldNotes: Bool { fieldNoteSlug != nil }

    /// The pitch a field note files under, for a specimen.
    var fieldNoteSlug: String? {
        if case .specimen(let slug) = self { return slug }
        return nil
    }

    /// A boundary-only wing (arm health and the like) stops at education: no
    /// discussion, the same gate the web's KnowledgePage applies.
    static func learnWing(_ wing: KnowledgeWing) -> CommunityTopic? {
        wing.allowsDiscussion ? .learn(slug: wing.slug) : nil
    }
}
