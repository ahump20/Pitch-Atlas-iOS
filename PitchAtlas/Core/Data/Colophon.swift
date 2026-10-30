import Foundation

// =============================================================================
// Colophon — the whole citation registry, as the Sources page lists it
// =============================================================================
// Web: pages/SourcesPage.tsx and data/knowledge/index.ts (knowledgeSources).
// The registry is the specimen sources in their filed order, then every source
// the teaching wings cite that the registry lacks, by label. Its "as of" is the
// newest retrievedAt across all of them (SourceRegistry.latestRetrievedAt).
// =============================================================================

extension SourceRegistry {
    /// knowledgeSources(): each wing's section claims and pull stat, the first
    /// source filed under each URL, sorted by label.
    static func knowledgeSources(_ wings: [KnowledgeWing]) -> [Source] {
        var seen = Set<String>()
        var sources: [Source] = []
        for wing in wings {
            for section in wing.sections {
                let claims = (section.claims ?? []) + (section.pullStat.map { [$0.claim] } ?? [])
                for case let source? in claims.map(\.source) where seen.insert(source.url).inserted {
                    sources.append(source)
                }
            }
        }
        let english = Locale(identifier: "en_US")
        return sources.sorted { $0.label.compare($1.label, locale: english) == .orderedAscending }
    }

    /// The full credential list: the registry, then the wings' sources it lacks
    /// (deduped by URL, so the page stays a complete colophon).
    static func colophon(registry: [Source], wings: [KnowledgeWing]) -> [Source] {
        let filed = Set(registry.map(\.url))
        return registry + knowledgeSources(wings).filter { !filed.contains($0.url) }
    }
}
