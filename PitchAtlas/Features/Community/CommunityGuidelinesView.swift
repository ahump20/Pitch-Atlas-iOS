import SwiftUI

/// The published community guidelines, readable in-app before anyone accepts them.
/// Every rule here maps to something the app actually enforces: reports insert to
/// the moderation tables, blocking hides content both ways at the database layer,
/// the age gate stands in front of posting, and account deletion is one tap away.
/// Nothing here is aspirational copy — it is the contract the moderation suite keeps.
struct CommunityGuidelinesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ZStack {
                PitchAtlasTheme.void.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: PitchAtlasSpacing.xl) {
                        masthead
                        rule(
                            "Post only what is yours to post",
                            "Share your own pitching experience, grips, and craft. No copyrighted media you do not own, no minors in any upload, and no medical or injury claims stated as fact."
                        )
                        rule(
                            "There is no room for objectionable content",
                            "Harassment, hate, threats, sexual content, and anything illegal are not allowed. There is zero tolerance — accounts that post it are removed."
                        )
                        rule(
                            "You control what you see",
                            "Report any note or post, and block any contributor. A report can hide content before a human looks at it. Blocking hides that person's content for you both ways and stops replies across that edge."
                        )
                        rule(
                            "We act within 24 hours",
                            "Reported content and the accounts behind it are reviewed and acted on within 24 hours. Confirmed violations are removed and the contributor is ejected."
                        )
                        rule(
                            "Seventeen and older to contribute",
                            "Reading the field manual needs no account. Posting, replying, and uploading require sign-in and confirmation that you are 17 or older."
                        )
                        contact
                    }
                    .padding(PitchAtlasSpacing.lg)
                    .padding(.bottom, PitchAtlasSpacing.xl3)
                }
            }
            .navigationTitle("Community Guidelines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "The contract")
            Text("HOW THIS PLACE WORKS")
                .font(PitchAtlasTheme.anton(34))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
            Text("Pitch Atlas keeps a small community room around the craft — field notes and discussion on how pitches are actually thrown. These are the rules that keep it usable, and the tools behind every one of them ship in the app.")
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
            Text("Posting is also governed by the standard license agreement. If something here needs a human, contact us through support.")
                .font(PitchAtlasTheme.hanken(14))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                openURL(URL(string: "https://pitch-atlas.com/support")!)
            } label: {
                Label("Support", systemImage: "lifepreserver")
            }
            .buttonStyle(.bordered)
        }
        .leatherPress()
    }
}
