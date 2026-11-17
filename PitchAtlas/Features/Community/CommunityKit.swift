import SwiftUI

/// Versioned terms and 18+ consent cover every contribution form. Reading,
/// hiding, reporting, and blocking remain available without either attestation.
struct ContributionGate: View {
    static let guidelinesKey = CommunityConsent.termsKey
    static let ageKey = CommunityConsent.adultKey

    @AppStorage(Self.guidelinesKey) private var guidelinesAccepted = false
    @AppStorage(Self.ageKey) private var ageConfirmed = false
    @State private var showGuidelines = false

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            PitchToggleField(
                text: CommunityConsent.termsLabel,
                isOn: $guidelinesAccepted
            )

            Button {
                showGuidelines = true
            } label: {
                Label("Community Terms and EULA", systemImage: "doc.text")
                    .font(PitchAtlasTheme.hanken(13))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(PitchAtlasTheme.caution)
            .accessibilityHint("Read the agreement before accepting")

            PitchToggleField(
                text: CommunityConsent.adultLabel,
                isOn: $ageConfirmed
            )
        }
        .sheet(isPresented: $showGuidelines) {
            CommunityGuidelinesView()
        }
    }
}
