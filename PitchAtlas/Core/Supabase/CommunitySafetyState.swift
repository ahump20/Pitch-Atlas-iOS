import Foundation
import Observation

/// New consent keys deliberately do not inherit the former 17+ attestations.
/// Bump the terms version when the agreement changes materially.
enum CommunityConsent {
    static let termsVersion = "2026-11-04"
    static let termsKey = "pa.community.termsAccepted.\(termsVersion)"
    static let adultKey = "pa.community.age18Confirmed.v1"
    static let termsLabel = "I accept the Community Terms and EULA"
    static let adultLabel = "I confirm I am 18 or older"

    static func canContribute(in defaults: UserDefaults) -> Bool {
        defaults.bool(forKey: termsKey) && defaults.bool(forKey: adultKey)
    }
}

/// Hiding is a local reading preference, independent of authentication and
/// network availability. One shared instance updates every open community view.
@MainActor @Observable
final class HiddenCommunityContent {
    static let shared = HiddenCommunityContent()
    private static let storageKey = "pa.community.hiddenContent.v1"
    private static let reportsKey = "pa.community.pendingReports.v1"

    enum Kind: String, Codable { case post, note, media }
    struct PendingReport: Codable, Identifiable, Equatable {
        let contentID: String
        let kind: Kind
        let reason: String?
        var id: String { "\(kind.rawValue):\(contentID)" }
    }
    enum DeliveryResult: Equatable { case sent, failed, alreadySending, noPendingReport }

    private(set) var postIDs: Set<String>
    private(set) var noteIDs: Set<String>
    private(set) var mediaIDs: Set<String>
    private(set) var pendingReports: [PendingReport]
    private(set) var sendingReportIDs: Set<String> = []
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let saved = defaults.dictionary(forKey: Self.storageKey) ?? [:]
        postIDs = Set(saved[Kind.post.rawValue] as? [String] ?? [])
        noteIDs = Set(saved[Kind.note.rawValue] as? [String] ?? [])
        mediaIDs = Set(saved[Kind.media.rawValue] as? [String] ?? [])
        pendingReports = defaults.data(forKey: Self.reportsKey)
            .flatMap { try? JSONDecoder().decode([PendingReport].self, from: $0) } ?? []
    }

    func hide(_ id: String, kind: Kind) {
        guard !id.isEmpty else { return }
        switch kind {
        case .post: postIDs.insert(id)
        case .note: noteIDs.insert(id)
        case .media: mediaIDs.insert(id)
        }
        defaults.set([
            Kind.post.rawValue: postIDs.sorted(),
            Kind.note.rawValue: noteIDs.sorted(),
            Kind.media.rawValue: mediaIDs.sorted()
        ], forKey: Self.storageKey)
    }

    /// Persist before attempting delivery, so leaving the screen or quitting
    /// during a failed request cannot discard the only retry target.
    @discardableResult
    func queueReport(_ contentID: String, kind: Kind, reason: String?) -> PendingReport {
        hide(contentID, kind: kind)
        let report = PendingReport(contentID: contentID, kind: kind,
                                   reason: reason.flatMap(CommunityReport.cleanReason))
        if let existing = pendingReports.first(where: { $0.id == report.id }) { return existing }
        pendingReports.append(report)
        saveReports()
        return report
    }

    func deliverReport(_ reportID: String, using auth: AuthSessionStore) async -> DeliveryResult {
        await deliverReport(reportID) { report in
            _ = try await auth.ensureSessionForWrite()
            let service = CommunityService(client: auth.client)
            switch report.kind {
            case .post: try await service.reportPost(id: report.contentID, reason: report.reason)
            case .note: try await service.reportFieldNote(id: report.contentID, reason: report.reason)
            case .media: try await service.reportMedia(id: report.contentID, reason: report.reason)
            }
        }
    }

    /// The injected send keeps delivery/failure/persistence independently testable.
    func deliverReport(_ reportID: String, send: @MainActor (PendingReport) async throws -> Void) async -> DeliveryResult {
        guard let report = pendingReports.first(where: { $0.id == reportID }) else { return .noPendingReport }
        guard !sendingReportIDs.contains(reportID) else { return .alreadySending }
        sendingReportIDs.insert(reportID)
        defer { sendingReportIDs.remove(reportID) }
        do {
            try await send(report)
            pendingReports.removeAll { $0.id == reportID }
            saveReports()
            return .sent
        } catch {
            return .failed
        }
    }

    private func saveReports() {
        guard let data = try? JSONEncoder().encode(pendingReports) else { return }
        defaults.set(data, forKey: Self.reportsKey)
    }
}
