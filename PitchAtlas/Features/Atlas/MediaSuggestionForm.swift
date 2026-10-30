import SwiftUI

// =============================================================================
// MediaSuggestionForm — suggest a pitching post for review
// =============================================================================
// Web: components/media/MediaSuggestionForm.tsx, folded shut under the media rail
// where the site allows it (the home, Grips, a pitch chapter with its slug, a
// craftsman's film). Validation runs before anything else, so a bad URL never mints
// an account; a send makes the anonymous account if there is none yet, then files
// the six columns. Offline or refused, the reason shows and the words stay.
// =============================================================================

struct MediaSuggestionForm: View {
    var pitchSlug: String?
    @Environment(AuthSessionStore.self) private var auth
    @State private var open = false
    @State private var url = ""
    @State private var rationale = ""
    @State private var busy = false
    @State private var status: String?
    @State private var error: String?

    static let summary = "Know a pitching post that belongs here?"
    static let urlLabel = "Public post URL"
    static let urlPrompt = "https://x.com/… or Instagram, TikTok, YouTube"
    static let reasonLabel = "Why it belongs"
    static let reasonPrompt = "What grip, story, lesson, or piece of pitching heritage does it preserve?"
    static let send = "Send to review"
    static let filing = "Filing…"
    static let fineprint = "Public URLs only · no uploads · reviewed before publication"
    static let filed = "Filed for review. Nothing publishes until it is checked and tagged."

    var body: some View {
        DisclosureGroup(isExpanded: $open) {
            VStack(alignment: .leading, spacing: 12) {
                field(Self.urlLabel) {
                    TextField("", text: $url, prompt: Text(verbatim: Self.urlPrompt).foregroundStyle(PitchAtlasTheme.placeholder))
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .background(box)
                }
                field(Self.reasonLabel) {
                    TextField("", text: $rationale, prompt: Text(verbatim: Self.reasonPrompt).foregroundStyle(PitchAtlasTheme.placeholder),
                              axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                        .padding(12)
                        .background(box)
                }
                FlowRow(spacing: 12, lineSpacing: 8, rowAlignment: .center) {
                    Button { Task { await submit() } } label: {
                        Text((busy ? Self.filing : Self.send).uppercased())
                            .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                            .tracking(em: 0.12, size: 10)
                            .foregroundStyle(PitchAtlasTheme.cyan)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 44)
                            .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(PitchAtlasTheme.cyan.opacity(0.45), lineWidth: 1))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(busy)
                    Text(Self.fineprint.uppercased())
                        .font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2))
                        .tracking(em: 0.08, size: 9)
                        .foregroundStyle(PitchAtlasTheme.bone2.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let status {
                    Text(status).font(PitchAtlasType.body(size: 14)).foregroundStyle(PitchAtlasTheme.cyan)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let error {
                    Text(error).font(PitchAtlasType.body(size: 14)).foregroundStyle(PitchAtlasTheme.seamBright)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 16)
        } label: {
            Text(Self.summary.uppercased())
                .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                .tracking(em: 0.12, size: 10)
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 44, alignment: .leading)
        }
        .tint(PitchAtlasTheme.bone2)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(PitchAtlasTheme.bone.opacity(0.12), lineWidth: 1))
        .padding(.top, 24)
        .onChange(of: status) { _, line in if let line { AccessibilityNotification.Announcement(line).post() } }
        .onChange(of: error) { _, line in if let line { AccessibilityNotification.Announcement(line).post() } }
    }

    private var box: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.black.opacity(0.35))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(PitchAtlasTheme.bone.opacity(0.15), lineWidth: 1))
    }

    private func field<Input: View>(_ label: String, @ViewBuilder input: () -> Input) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2))
                .tracking(em: 0.12, size: 9)
                .foregroundStyle(PitchAtlasTheme.bone2)
                .accessibilityHidden(true)
            input()
                .font(PitchAtlasType.body(size: 14))
                .foregroundStyle(PitchAtlasTheme.bone)
                .accessibilityLabel(label)
        }
    }

    /// Only ever on a reader's own tap. No test, screenshot run or check calls it.
    private func submit() async {
        busy = true
        status = nil
        error = nil
        defer { busy = false }
        let parsed: ExternalSuggestion.Parsed
        do {
            parsed = try ExternalSuggestion.validate(url: url, rationale: rationale)
        } catch let failure as ExternalSuggestion.Failure {
            error = failure.message
            return
        } catch {
            self.error = ExternalSuggestion.badURL
            return
        }
        do {
            let userID = try await auth.ensureSessionForWrite()
            try await CommunityService(client: auth.client)
                .fileSuggestion(.init(submittedBy: userID, parsed: parsed, rationale: rationale, pitchSlug: pitchSlug))
            url = ""
            rationale = ""
            status = Self.filed
        } catch {
            self.error = ExternalSuggestion.refusal(for: "\(error.localizedDescription) \(String(describing: error))")
        }
    }
}
