import SwiftUI

/// The agreement presented before a reader accepts the contribution terms.
struct CommunityGuidelinesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showContact = false

    var body: some View {
        NavigationStack {
            ZStack {
                FieldBackdrop()
                ScrollView {
                    VStack(alignment: .leading, spacing: PitchAtlasSpacing.xl) {
                        masthead
                        rule(
                            "Post only what is yours to post",
                            "Share your own pitching experience, grips, and craft. No copyrighted media you do not own, no minors in any upload, and no medical or injury claims stated as fact."
                        )
                        rule(
                            "There is no room for objectionable content",
                            "There is zero tolerance for objectionable content or abusive users. Harassment, hate, threats, sexual content, and illegal material are prohibited. Violating content is removed and offending accounts are ejected."
                        )
                        rule(
                            "You control what you see",
                            "Hide any post, reply, note, or attached media immediately from your feed. Report also hides the item for you and sends it for moderation. Block a contributor to hide their content and stop replies across that connection."
                        )
                        rule(
                            "We act within 24 hours",
                            "Within 24 hours of a report, automated safeguards remove the content from public view and restrict the contributor. Confirmed violations lead to permanent content removal and ejection of the contributor."
                        )
                        rule(
                            "Eighteen and older to contribute",
                            "You must be 18 or older and accept these Community Terms and EULA before posting, replying, suggesting a public post, or uploading. Reading needs no account. Uploading an image requires a claimed account and the image upload terms; images remain private until reviewed."
                        )
                        contact
                    }
                    .padding(PitchAtlasSpacing.lg)
                    .padding(.bottom, PitchAtlasSpacing.xl3)
                }
            }
            .navigationTitle("Community Terms and EULA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showContact) { DeveloperContactView() }
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            Text("COMMUNITY TERMS")
                .font(PitchAtlasTheme.anton(34))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
            Text("By accepting, you agree to these community rules and Apple’s Standard End User License Agreement. These terms apply to everything you contribute to Pitch Atlas.")
                .font(PitchAtlasTheme.hanken(15))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func rule(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: title)
            Text(body)
                .font(PitchAtlasTheme.hanken(14))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .leatherPress()
    }

    private var contact: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "Reach us")
            Text("Contact the developer to report inappropriate activity, including anything you cannot report from a post.")
                .font(PitchAtlasTheme.hanken(14))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                showContact = true
            } label: {
                Label("Contact developer", systemImage: "envelope")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            Link("Apple’s Standard EULA", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                .font(PitchAtlasTheme.hanken(14))
                .frame(minHeight: 44)
        }
        .leatherPress()
    }
}
