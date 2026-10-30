import SwiftUI

/// The two attestations every community write stands behind on iPhone: the
/// guidelines accepted and the 17+ confirmation (the App Store's rule for
/// user-generated content; the site asks for neither). Both persist on the
/// device under the keys the discussion composer has always read, so accepting
/// once covers field notes and discussion alike. Reading, marking and reporting
/// never wait on them; only filing does.
struct ContributionGate: View {
    static let guidelinesKey = "pa.community.guidelinesAccepted"
    static let ageKey = "pa.community.ageConfirmed"

    @AppStorage(Self.guidelinesKey) private var guidelinesAccepted = false
    @AppStorage(Self.ageKey) private var ageConfirmed = false
    @State private var showGuidelines = false

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            PitchToggleField(
                text: "I accept the community guidelines",
                caption: "Post your own experience. Report problems. Keep the archive clean.",
                isOn: $guidelinesAccepted
            )

            Button {
                showGuidelines = true
            } label: {
                Label("Read the community guidelines", systemImage: "doc.text")
                    .font(PitchAtlasTheme.hanken(13))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(PitchAtlasTheme.caution)
            .accessibilityHint("Opens the community guidelines you are accepting")

            PitchToggleField(
                text: "I confirm I am 17 or older before posting or uploading",
                caption: "Required before community posting or image uploads.",
                isOn: $ageConfirmed
            )
        }
        .sheet(isPresented: $showGuidelines) {
            CommunityGuidelinesView()
        }
    }
}
