import SwiftUI

// =============================================================================
// HomeMediaRail — "From one hand to another."
// =============================================================================
// Web: media/ExternalMediaRail.tsx + ExternalMediaCard.tsx with the home's
// world.css order (header, story, then the player well). Three featured posts,
// newest first. Nothing loads until the reader asks: a TikTok post plays in
// TikTok's official player inside the card; an X post stays a credited link out.
// Every post is the poster's own, credited and never rehosted.
// =============================================================================

struct HomeMediaRail: View {
    @Environment(PitchStore.self) private var store

    var body: some View {
        let items = MediaShelf.home(store.externalMedia.items, limit: 3)
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                kicker
                AthleticTitle(text: Text("From one hand to another."), size: 28)
                    .padding(.top, 12)
                Text("Listen to a pitcher explain it. Watch a grip turn. These lessons and recovered conversations keep the people beside the pitch. Choose a player when you are ready to watch.")
                    .font(PitchAtlasTheme.hanken(15))
                    .lineSpacing(6)
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 20)
                VStack(spacing: 20) {
                    ForEach(items) { MediaCard(item: $0) }
                }
                .padding(.top, 36)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 56)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    ArchiveInk.mediaField
                    RadialGradient(colors: [PitchAtlasTheme.cyan.opacity(0.07), .clear], center: UnitPoint(x: 0.12, y: 0.2),
                                   startRadius: 0, endRadius: 260)
                    RadialGradient(colors: [PitchAtlasTheme.seamBright.opacity(0.08), .clear], center: UnitPoint(x: 0.88, y: 0.82),
                                   startRadius: 0, endRadius: 280)
                }
                .accessibilityHidden(true)
            }
            .overlay(alignment: .top) { Rectangle().fill(PitchAtlasTheme.bone.opacity(0.08)).frame(height: 1) }
            .overlay(alignment: .bottom) { Rectangle().fill(PitchAtlasTheme.bone.opacity(0.08)).frame(height: 1) }
        }
    }

    /// `.rfx-skick`: the short rule and the mono kicker, in cyan.
    private var kicker: some View {
        HStack(spacing: 9) {
            Rectangle().frame(width: 22, height: 2).accessibilityHidden(true)
            Text("Fresh from the game")
                .font(PitchAtlasType.font(.martian500, size: 11, relativeTo: .caption2))
                .textCase(.uppercase)
                .tracking(11 * 0.2)
        }
        .foregroundStyle(PitchAtlasTheme.cyan)
    }
}

/// One credited post: who and when, the story in its own words, the way out to
/// the original, and the player well that only fills on request.
private struct MediaCard: View {
    let item: ExternalContentItem

    @State private var phase: ClipLoadPhase = .poster
    private let loadTimeout: TimeInterval = 12

    private var provider: String { MediaShelf.platformLabel(item.platform) }
    private var player: URL? { MediaShelf.playerURL(item) }
    private var removed: Bool { item.availability == "removed" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            story
            well
        }
        .background {
            LinearGradient(stops: [.init(color: ArchiveInk.mediaCardSheen, location: 0),
                                   .init(color: ArchiveInk.mediaCardStock, location: 0.42)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(PitchAtlasTheme.bone.opacity(0.14), lineWidth: 1)
                .accessibilityHidden(true)
        }
        .shadow(color: .black.opacity(0.95), radius: 22, y: 24)
        .onChange(of: phase) { _, newPhase in
            guard newPhase == .loading else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + loadTimeout) {
                if phase == .loading { phase = .failed }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(MediaShelf.laneLabel(item.trustLane)) · \(provider)")
                .tracking(9 * 0.15)
                .foregroundStyle(PitchAtlasTheme.cyan)
            Spacer(minLength: 0)
            Text(MediaShelf.monthYear(item.publishedAt))
                .tracking(9 * 0.1)
                .foregroundStyle(PitchAtlasTheme.bone2.opacity(0.65))
        }
        .font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2))
        .textCase(.uppercase)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) { Rectangle().fill(PitchAtlasTheme.bone.opacity(0.1)).frame(height: 1) }
        .accessibilityElement(children: .combine)
    }

    private var story: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(item.title)
                .font(PitchAtlasType.heroTitle(size: 25))
                .lineSpacing(1)
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(item.lede)
                .font(PitchAtlasTheme.hanken(14))
                .lineSpacing(5)
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
            if let caption = item.sourceCaption, !caption.isEmpty {
                Text("“\(caption)”")
                    .font(PitchAtlasType.font(.hanken400i, size: 12, relativeTo: .footnote))
                    .lineSpacing(4)
                    .foregroundStyle(PitchAtlasTheme.bone2.opacity(0.75))
                    .lineLimit(3)
                    .padding(.leading, 12)
                    .overlay(alignment: .leading) { Rectangle().fill(PitchAtlasTheme.bone.opacity(0.2)).frame(width: 1) }
                    .padding(.top, 12)
            }
            if let original = URL(string: item.canonicalUrl) {
                Link(destination: original) {
                    Text("Original post ↗")
                        .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                        .textCase(.uppercase)
                        .tracking(10 * 0.11)
                        .foregroundStyle(PitchAtlasTheme.bone2)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(PitchAtlasTheme.bone.opacity(0.18), lineWidth: 1))
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Original post on \(provider), \(item.sourceHandle)")
                .accessibilityHint("Opens outside the app")
                .padding(.top, 20)
            }
            Text("Embedded from \(provider); credited and never rehosted.")
                .font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2))
                .textCase(.uppercase)
                .tracking(9 * 0.08)
                .lineSpacing(3)
                .foregroundStyle(PitchAtlasTheme.bone2.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
        }
        .padding(20)
    }

    /// `.archive-media-player`: a black well with a cyan lamp. Until the reader asks,
    /// it holds the seal and the provider's name; then TikTok's own player, or the
    /// reason it did not load. An X post opens on X.
    private var well: some View {
        Group {
            if phase == .poster {
                wellContent.frame(maxWidth: .infinity).frame(height: 108)
            } else {
                // a TikTok post is portrait: the opened well stands 9 by 13
                wellContent.frame(maxWidth: .infinity).aspectRatio(9.0 / 13.0, contentMode: .fit)
            }
        }
        .overlay(alignment: .top) { Rectangle().fill(ArchiveInk.mediaWellRule).frame(height: 1) }
    }

    private var wellContent: some View {
        ZStack {
            ArchiveInk.mediaWell
            RadialGradient(colors: [PitchAtlasTheme.cyan.opacity(0.14), .clear], center: UnitPoint(x: 0.5, y: 0.3),
                           startRadius: 0, endRadius: 200)
                .accessibilityHidden(true)
            if let player, phase != .poster {
                TikTokPlayerWebView(url: player, phase: $phase)
                    .opacity(phase == .loaded ? 1 : 0)
                if phase == .loading {
                    wellWords("Loading from \(provider)…")
                } else if phase == .failed {
                    VStack(spacing: 12) {
                        wellWords("The \(provider) player did not load. The credited source link still works above.")
                        Button("Retry player") { phase = .loading }
                            .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                            .textCase(.uppercase)
                            .underline()
                            .foregroundStyle(PitchAtlasTheme.bone2)
                            .frame(minHeight: 44)
                    }
                    .padding(.horizontal, 24)
                }
            } else if player != nil {
                Button { phase = .loading } label: { placeholder("Load from \(provider)") }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Load \(item.title) from \(provider)")
                    .accessibilityHint("Plays the post in \(provider)'s player")
            } else if !removed, let original = URL(string: item.canonicalUrl) {
                Link(destination: original) { placeholder("Open on \(provider) ↗") }
                    .accessibilityLabel("Open \(item.title) on \(provider)")
                    .accessibilityHint("Opens outside the app")
            } else {
                placeholder("Original post unavailable")
            }
        }
    }

    private func placeholder(_ words: String) -> some View {
        HStack(spacing: 12) {
            BrandSealMark(size: 24, shadow: false)
                .opacity(0.7)
            Text(words)
                .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                .textCase(.uppercase)
                .tracking(10 * 0.13)
                .foregroundStyle(PitchAtlasTheme.bone2)
        }
        .frame(maxWidth: .infinity, minHeight: 108)
        .contentShape(Rectangle())
    }

    private func wellWords(_ words: String) -> some View {
        Text(words)
            .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
            .textCase(.uppercase)
            .tracking(10 * 0.12)
            .lineSpacing(4)
            .multilineTextAlignment(.center)
            .foregroundStyle(PitchAtlasTheme.bone2)
            .fixedSize(horizontal: false, vertical: true)
    }
}
