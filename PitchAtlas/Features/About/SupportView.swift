import SwiftUI

// =============================================================================
// Pitch Atlas — Support
// =============================================================================
// Web: pages/SupportPage.tsx, in its order and words. The header, the three
// help routes as numbered rows, the contact paragraph, the footer. One row
// changes: the site's delete route speaks about the app from outside it, so in
// here it names the app's own path. No invented email, phone, or address; the
// contact route is the in-product Report flow.
// =============================================================================

struct SupportView: View {
    @Environment(DeepLinkRouter.self) private var router
    @Environment(PitchStore.self) private var store

    var body: some View {
        ZStack {
            FieldBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHero(eyebrow: "Support",
                                title: Text("Something off? ") + Text("Flag it.").foregroundStyle(PitchAtlasMaterials.holoType()),
                                sub: Text(SupportCopy.sub),
                                trail: [Crumb(label: "Pitch Atlas", path: "home"), Crumb(label: "Support")])
                    PageSection {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(SupportCopy.rows.enumerated()), id: \.offset) { index, row in
                                NumberedRow(index: index, label: row.label, text: row.text)
                            }
                        }
                        .overlay(alignment: .top) { PageInk.rule.frame(height: 1).accessibilityHidden(true) }
                    }
                    PageSection {
                        SectionKick(text: "Contact")
                        contact.padding(.top, 16)
                    }
                    SiteFooter(path: "/support")
                }
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                .emitsScrollProgress()
            }
        }
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { BrandLockup(size: .sm) }
        }
    }

    /// `mt-4 max-w-[64ch] text-[16px] leading-relaxed text-ink-2`, its two links in
    /// the seam: the policy opens the site in Safari, the registry opens the tab.
    private var contact: some View {
        Text(SupportCopy.contact)
            .font(PitchAtlasType.font(.hanken400, size: 16, relativeTo: .body))
            .foregroundStyle(PitchAtlasTheme.ink2)
            .tint(PitchAtlasTheme.seamBright)
            .cssLineHeight(1.625, face: .hanken400, size: 16, relativeTo: .body)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 64 * 0.56 * 16, alignment: .leading)
            .environment(\.openURL, OpenURLAction { url in
                guard url.scheme == "pitchatlas" else { return .systemAction }
                router.handle(url, store: store)
                return .handled
            })
    }
}

/// SupportPage.tsx's words.
enum SupportCopy {
    static let sub = "Pitch Atlas is a sourced archive for how pitchers grip and shape a baseball. It is a reference site and an iOS app, with an optional community layer for field notes and discussion. This page covers the three help routes people need most."

    /// HELP_ROWS, the delete route walked the way the app lays it out.
    static let rows: [(label: String, text: String)] = [
        ("Report a problem with a note or post",
         "Every field note and discussion post carries a Report action. Use it. Reports go to a moderation queue, and a post reported by enough separate accounts is hidden pending review. In the iOS app you can also block a contributor outright."),
        ("Delete your account",
         "In the Pitch Atlas iOS app, open Atlas, then Account and Safety, and choose Delete account. That removes your community posts, your uploaded media, and the account itself. On the web you can delete your own discussion posts from the page where they appear."),
        ("Question a claim in the archive",
         "Every figure on a specimen page is labeled with where it came from. Start at the source registry. If a claim looks wrong, the source link is one click away, and the label tells you how much weight it was ever meant to carry."),
    ]

    /// The contact paragraph with its two links.
    static var contact: AttributedString {
        func link(_ text: String, _ url: String) -> AttributedString {
            var run = AttributedString(text)
            run.link = URL(string: url)
            run.foregroundColor = PitchAtlasTheme.seamBright
            run.underlineStyle = Text.LineStyle(pattern: .solid, color: PageInk.seamUnderline)
            return run
        }
        var line = AttributedString("Report issues through the in-product Report flow on any note or post. Every report is reviewed. For how the archive handles your data, read the ")
        line.append(link("privacy policy", "https://pitch-atlas.com/privacy"))
        line.append(AttributedString("; for how archive claims are sourced, read the "))
        line.append(link("source registry", "pitchatlas://sources"))
        line.append(AttributedString("."))
        return line
    }
}
