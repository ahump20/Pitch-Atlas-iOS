import Foundation
import Observation

// =============================================================================
// PitchStore — the bundled-content store
// =============================================================================
// Loads every Resources/Content/*.json synchronously at launch. Observable, so
// it drops straight into SwiftUI via @State + @Environment. Per-file isolation:
// one corrupt bundle records an error and empties its own collection rather than
// taking down the whole app, so the four-state surfaces can show an honest error
// instead of a crash. The bundle is static, so load is effectively instant —
// there is no async "loading" state to model here; the live states are populated
// (normal), error (a decode failure that should never ship), and empty (a slice
// or search that legitimately has no rows).
// =============================================================================

@Observable
final class PitchStore {

    enum Status: Equatable {
        case ready
        case failed(String)
    }

    let pitches: [PitchAtlasEntry]
    let repertoire: RepertoireRoot
    let craftsmen: [Craftsman]
    let lostPitches: LostPitchesRoot
    let knowledge: [KnowledgeWing]
    let grips: GripsFile
    let sources: [Source]
    let manifest: ContentManifest
    let status: Status

    init(bundle: Bundle = .main) {
        var problems: [String] = []

        func load<T: Decodable>(_ name: String, _ type: T.Type, fallback: T) -> T {
            do {
                return try PitchStore.decode(name, as: type, from: bundle)
            } catch {
                problems.append("\(name).json — \(error)")
                return fallback
            }
        }

        self.manifest = load("manifest", ContentManifest.self,
                             fallback: ContentManifest(counts: [:], sourcesLastChecked: ""))
        self.pitches = load("pitches", [PitchAtlasEntry].self, fallback: [])
        self.repertoire = load("repertoire", RepertoireRoot.self,
                               fallback: RepertoireRoot(families: [], entries: []))
        self.craftsmen = load("craftsmen", [Craftsman].self, fallback: [])
        self.lostPitches = load("lost-pitches", LostPitchesRoot.self,
                                fallback: LostPitchesRoot(tiers: [], entries: []))
        self.knowledge = load("knowledge", [KnowledgeWing].self, fallback: [])
        self.grips = load("grips", GripsFile.self,
                          fallback: GripsFile(intro: "", arsenal: "", commandNote: "",
                                              attackPlan: GripAttackPlan(intro: "", sequenceTitle: "",
                                                                         sequenceNote: "", sequence: []),
                                              proofLimit: "", entries: []))
        self.sources = load("sources", [Source].self, fallback: [])

        self.status = problems.isEmpty ? .ready : .failed(problems.joined(separator: " | "))
    }

    // MARK: - Decode

    enum ContentError: LocalizedError {
        case missing(String)
        var errorDescription: String? {
            switch self {
            case .missing(let name): return "\(name).json not found in app bundle"
            }
        }
    }

    static func decode<T: Decodable>(_ name: String, as type: T.Type, from bundle: Bundle) throws -> T {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw ContentError.missing(name)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Freshness (computed, never hardcoded)

    /// The date the sources were last checked, straight from the build manifest.
    var sourcesLastChecked: String { manifest.sourcesLastChecked }

    // MARK: - Lookups

    func pitch(slug: String) -> PitchAtlasEntry? { pitches.first { $0.slug == slug } }
    func pitch(id: String) -> PitchAtlasEntry? { pitches.first { $0.id == id } }
    func craftsman(slug: String) -> Craftsman? { craftsmen.first { $0.slug == slug } }
    func lostPitch(slug: String) -> LostPitch? { lostPitches.entries.first { $0.slug == slug } }
    func wing(slug: String) -> KnowledgeWing? { knowledge.first { $0.slug == slug } }
    func repertoireEntry(id: String) -> RepertoireEntry? { repertoire.entries.first { $0.id == id } }
    func gripEntry(id: String) -> GripEntry? { grips.entries.first { $0.id == id } }
}
