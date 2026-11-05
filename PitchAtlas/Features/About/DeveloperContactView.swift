import SwiftUI

/// A private developer-contact channel, available without an existing post or
/// sign-in. The first send may create an anonymous session; opening never does.
struct DeveloperContactView: View {
    @Environment(AuthSessionStore.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var message = ""
    @State private var replyEmail = ""
    @State private var isSending = false
    @State private var receipt: UUID?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                FieldBackdrop()
                ScrollView {
                    VStack(alignment: .leading, spacing: PitchAtlasSpacing.lg) {
                        if receipt != nil {
                            Label("Message sent", systemImage: "checkmark.circle")
                                .font(PitchAtlasTheme.hankenMedium(20))
                                .foregroundStyle(PitchAtlasTheme.success)
                        } else {
                            VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                                PitchFormLabel("Message", required: true)
                                TextField("Describe the issue or inappropriate activity", text: $message, axis: .vertical)
                                    .lineLimit(6...12)
                                    .font(PitchAtlasTheme.hanken(15))
                                    .foregroundStyle(PitchAtlasTheme.bone)
                                    .pitchTextFieldSurface(minHeight: 150)
                                    .accessibilityLabel("Message to developer")
                                    .onChange(of: message) { _, text in
                                        if text.count > SafetyContactRequest.messageLimit {
                                            message = String(text.prefix(SafetyContactRequest.messageLimit))
                                        }
                                    }
                                PitchFormLabel("Reply email (optional)")
                                TextField("Email", text: $replyEmail)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(PitchAtlasTheme.hanken(15))
                                    .foregroundStyle(PitchAtlasTheme.bone)
                                    .pitchTextFieldSurface()
                                    .accessibilityLabel("Reply email, optional")
                            }
                            Text("Your message and optional reply email are private. We use your contributor ID, anonymous if you have not signed in, for customer support and safety.")
                                .font(PitchAtlasTheme.hanken(13))
                                .foregroundStyle(PitchAtlasTheme.bone2)
                            if let errorMessage {
                                Label(errorMessage, systemImage: "exclamationmark.triangle")
                                    .font(PitchAtlasTheme.hanken(14))
                                    .foregroundStyle(PitchAtlasTheme.caution)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Button {
                                Task { await send() }
                            } label: {
                                Label(isSending ? "Sending…" : "Send to developer", systemImage: "paperplane")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .disabled(isSending || message.trimmingCharacters(in: .whitespacesAndNewlines).count < SafetyContactRequest.messageMinimum)
                        }
                    }
                    .padding(PitchAtlasSpacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("Contact Austin Humphrey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func send() async {
        guard !isSending else { return }
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        do {
            let request = try SafetyContactRequest.validated(message: message, replyEmail: replyEmail)
            _ = try await auth.ensureSessionForWrite()
            receipt = try await CommunityService(client: auth.client).contactDeveloper(request)
            message = ""
            replyEmail = ""
            Haptics.success()
            AccessibilityNotification.Announcement("Message sent to developer").post()
        } catch {
            errorMessage = SafetyContactRequest.userMessage(for: error)
            Haptics.failure()
        }
    }
}
