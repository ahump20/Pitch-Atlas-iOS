import SwiftUI
import UIKit
import WebKit

// =============================================================================
// TeachingClipCard — a credited teaching clip embedded on a filed specimen
// =============================================================================
// Embed-or-link, never rehost (web repo docs/MEDIA-LEDGER.md, rows T1–T3). The
// app embeds TikTok's OWN player from the post reference and links out to the
// original post, fully credited; no media file ships in the bundle. The clip is
// a sourced pointer to what the post teaches, never a measured claim. Promoted to
// the iOS bundle 2026-06-25 at the owner's direction — see docs/APP-REVIEW-NOTES.md.
// =============================================================================

/// Embeds TikTok's official player in a `WKWebView`. The platform serves the
/// media; the app downloads nothing. No autoplay — the reader taps the player's
/// own play control (a user gesture satisfies the playback requirement). Inline
/// (not forced fullscreen) so the clip sits in the card.
struct TikTokPlayerWebView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var loadedURL: URL?
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = .all

        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = .black
        web.scrollView.isScrollEnabled = false
        web.scrollView.backgroundColor = .black
        web.scrollView.bounces = false
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        guard context.coordinator.loadedURL != url else { return }
        context.coordinator.loadedURL = url
        web.load(URLRequest(url: url))
    }
}

/// The teaching-clip card: the embedded player, the title, the plain-language
/// pointer, the creator's own caption, and the credited outbound link. Mirrors the
/// web `TikTokEmbed` so the two surfaces teach the same thing the same way.
struct TeachingClipCard: View {
    let clip: TeachingClip
    var accent: Color = PitchAtlasTheme.cyan

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                SectionLabel(text: "SEE IT TAUGHT · \(clip.author) ON TIKTOK", color: accent, size: 9)
                Spacer(minLength: PitchAtlasSpacing.sm)
                SectionLabel(text: "ADDED \(addedLabel)", size: 8)
            }

            // The actual video — TikTok's own player, embedded, capped and centered
            // so a vertical clip doesn't overwhelm the screen.
            if let player = clip.playerURL {
                Color.clear
                    .aspectRatio(9.0 / 16.0, contentMode: .fit)
                    .frame(maxWidth: 300)
                    .overlay { TikTokPlayerWebView(url: player) }
                    .clipShape(RoundedRectangle(cornerRadius: PitchAtlasRadius.card, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: PitchAtlasRadius.card, style: .continuous)
                            .strokeBorder(PitchAtlasTheme.machined, lineWidth: 1)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Text(clip.title.uppercased())
                .font(PitchAtlasTheme.anton(24))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
                .fixedSize(horizontal: false, vertical: true)

            Text(clip.lede)
                .font(PitchAtlasTheme.hanken(15))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)

            Text("\u{201C}\(clip.caption)\u{201D}")
                .font(PitchAtlasTheme.newsreaderItalic(13))
                .foregroundStyle(PitchAtlasTheme.ink3)
                .fixedSize(horizontal: false, vertical: true)

            if let post = clip.postURL {
                Button {
                    openURL(post)
                } label: {
                    HStack(spacing: 6) {
                        Text("WATCH ON TIKTOK")
                        Text("\u{2197}")
                    }
                    .font(PitchAtlasTheme.martian(10))
                    .tracking(1.5)
                    .foregroundStyle(accent)
                    .padding(.vertical, 9)
                    .padding(.horizontal, 16)
                    .overlay { Capsule().strokeBorder(accent.opacity(0.5), lineWidth: 1) }
                }
                .accessibilityLabel("Watch on TikTok. Opens the original post.")
            }

            Text("ORIGINAL POST, EMBEDDED FROM TIKTOK AND CREDITED. NOT REHOSTED.")
                .font(PitchAtlasTheme.martian(8))
                .tracking(1)
                .foregroundStyle(PitchAtlasTheme.ink3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .leatherPress(padding: PitchAtlasSpacing.lg)
    }

    /// The "added" month, computed from the real `retrievedAt` — never a hardcoded
    /// freshness string. Falls back to the raw date if it ever fails to parse.
    private var addedLabel: String {
        let parse = DateFormatter()
        parse.locale = Locale(identifier: "en_US_POSIX")
        parse.dateFormat = "yyyy-MM-dd"
        guard let date = parse.date(from: clip.retrievedAt) else { return clip.retrievedAt }
        let show = DateFormatter()
        show.locale = Locale(identifier: "en_US")
        show.dateFormat = "MMM yyyy"
        return show.string(from: date).uppercased()
    }
}
