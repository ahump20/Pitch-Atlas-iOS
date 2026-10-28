import SwiftUI

// =============================================================================
// SiteFooter — the archive's back cover
// =============================================================================
// Web: layout/SiteFooter.tsx and RotatingQuote.tsx. One closing line and the way
// back to the front door, the page's own rotating quote with its source, the
// brand lockup with the tagline and the brand line, the footer links, and the
// address. The site's no-JavaScript line has no meaning in the app and is left
// out; the hidden-notes counter joins when the hidden notes ship.
// =============================================================================

struct SiteFooter: View {
    /// The web path of the page this footer closes ("/", "/repertoire"): it picks
    /// the page's own quote, as the site does.
    let path: String

    @Environment(DeepLinkRouter.self) private var router
    @Environment(PitchStore.self) private var store

    /// layout/SiteFooter.tsx LINKS in the site's order. Softball joins with the
    /// softball wing; Privacy opens the site's own page in Safari.
    private static let links: [(label: String, path: String)] = [
        ("The Pitch Index", "repertoire"),
        ("The Craftsmen", "craftsmen"),
        ("Lost Pitches", "lost-pitches"),
        ("Sources", "sources"),
        ("About", "about"),
        ("Privacy", "https://pitch-atlas.com/privacy"),
        ("Support", "account"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                SeamGuide(variant: .orbit)
                    .padding(.bottom, 16)
                Text("The archive stays open.")
                    .font(PitchAtlasTheme.anton(20, relativeTo: .title3))
                    .textCase(.uppercase)
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .accessibilityAddTraits(.isHeader)
                Text(frontDoorLine)
                    .font(Self.labelFont)
                    .tracking(Self.labelTracking)
                    .lineSpacing(6)
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
                    .environment(\.openURL, OpenURLAction { url in
                        guard url.scheme == "pitchatlas" else { return .systemAction }
                        router.handle(url, store: store)
                        return .handled
                    })
                RotatingQuote(path: path)
                    .padding(.top, 20)
                    .overlay(alignment: .top) { Rectangle().fill(PitchAtlasTheme.bone.opacity(0.08)).frame(height: 1) }
                    .padding(.top, 24)
            }
            .padding(.top, 48)

            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 12) {
                    BrandLockup()
                    label("The pitch, in your hand.")
                    label("Preserving & Progressing the Art of the Pitch").opacity(0.75)
                }
                FlowRow(spacing: 24, lineSpacing: 8) {
                    ForEach(Self.links, id: \.path) { link in
                        if let site = URL(string: link.path), site.scheme == "https" {
                            Link(destination: site) { touchLabel(link.label) }
                                .accessibilityHint("Opens in Safari")
                        } else {
                            RouteButton(path: link.path) { touchLabel(link.label) }
                                .buttonStyle(.plain)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    if let site = URL(string: "https://pitch-atlas.com") {
                        Link(destination: site) { touchLabel("pitch-atlas.com") }
                            .accessibilityHint("Opens in Safari")
                    }
                    label("Heritage · history · craft · conversation").opacity(0.75)
                }
            }
            .padding(.vertical, 48)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { Rectangle().fill(PitchAtlasTheme.cyan.opacity(0.12)).frame(height: 1) }
    }

    /// "…start at the front door: the Pitch Index." with the index underlined and live.
    private var frontDoorLine: AttributedString {
        var line = AttributedString("Everything above wears its source. When you want the set again, start at the front door: ".uppercased())
        var door = AttributedString("the Pitch Index".uppercased())
        door.link = URL(string: "pitchatlas://repertoire")
        door.underlineStyle = .single
        door.foregroundColor = PitchAtlasTheme.bone
        line.append(door)
        line.append(AttributedString("."))
        return line
    }

    // `.mono-label-stage`: 11pt mono, upper case, tracked .18em, bone-2.
    static let labelFont = PitchAtlasType.font(.martian400, size: 11, relativeTo: .caption)
    static let labelTracking: CGFloat = 11 * 0.18

    private func label(_ text: String) -> some View {
        Text(text.uppercased())
            .font(Self.labelFont)
            .tracking(Self.labelTracking)
            .lineSpacing(4)
            .foregroundStyle(PitchAtlasTheme.bone2)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// `.touch-link`: the label at a full 44pt, padded 6 either side.
    private func touchLabel(_ text: String) -> some View {
        label(text)
            .padding(.horizontal, 6)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
    }
}

/// RotatingQuote: the page's line from the quote pool (craft and the philosophy
/// of the game, each sourced), stepping on the site's slow tick. Reduce Motion
/// holds the page's own line.
struct RotatingQuote: View {
    let path: String

    @Environment(PitchStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tick = 0

    var body: some View {
        if let quote = QuotePick.quote(forPath: path, tick: tick, in: store) {
            VStack(alignment: .leading, spacing: 8) {
                Text("“\(quote.claim.value)”")
                    .font(PitchAtlasTheme.newsreaderItalic(15, relativeTo: .callout))
                    .lineSpacing(5)
                    .foregroundStyle(PitchAtlasTheme.bone2.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                attribution(quote)
            }
            .id(quote.id)
            .transition(.opacity)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: quote.id)
            .accessibilityElement(children: .combine)
            .task(id: reduceMotion) { await advance() }
        }
    }

    private func attribution(_ quote: AtlasQuote) -> some View {
        let words = quote.context.map { "\(quote.attribution) · \($0)" } ?? quote.attribution
        return Group {
            if let source = quote.claim.source, let url = URL(string: source.url) {
                Link(destination: url) { Text(words.uppercased()).underline(color: PitchAtlasTheme.bone2.opacity(0.3)) }
                    .accessibilityHint("Opens the source in Safari")
            } else {
                Text(words.uppercased())
            }
        }
        .font(SiteFooter.labelFont)
        .tracking(SiteFooter.labelTracking)
        .lineSpacing(4)
        .foregroundStyle(PitchAtlasTheme.bone2.opacity(0.65))
        .frame(minHeight: 44, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
    }

    @MainActor
    private func advance() async {
        guard !reduceMotion, store.quotes.count > 1 else { return }
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(QuotePick.interval * 1_000_000_000))
            if Task.isCancelled { return }
            withAnimation(.easeInOut(duration: 0.5)) { tick += 1 }
        }
    }
}

/// BrandMark at `md`: the seal and the skewed wordmark, ATLAS in foil.
struct BrandLockup: View {
    var markSize: CGFloat = 44
    var wordSize: CGFloat = 30

    var body: some View {
        HStack(spacing: 12) {
            BrandSealMark(size: markSize, shadow: false)
            (Text("Pitch ") + Text("Atlas").foregroundStyle(PitchAtlasMaterials.foilType()))
                .font(PitchAtlasTheme.anton(wordSize, relativeTo: .title))
                .textCase(.uppercase)
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pitch Atlas")
    }
}

/// `flex-wrap` for a row of links: items left to right, wrapping to a new line.
struct FlowRow: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat
    /// `items-center`: each item centered in its row's height (a dot beside a
    /// source link); `.top` keeps the rows flush, as the footer and map set them.
    var rowAlignment: VerticalAlignment = .top

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let rows = arrange(subviews, width: width)
        let height = rows.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(0, rows.count - 1))
        let used = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? used, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.items {
                let size = Self.size(of: subviews[index], within: bounds.width)
                let drop = rowAlignment == .center ? (row.height - size.height) / 2 : 0
                subviews[index].place(at: CGPoint(x: x, y: y + drop), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row { var items: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    /// An item at its own width, or wrapped to the row's when it runs wider (a
    /// long name at the largest Dynamic Type sizes), never past the edge.
    private static func size(of subview: LayoutSubview, within width: CGFloat) -> CGSize {
        let ideal = subview.sizeThatFits(.unspecified)
        guard width.isFinite, ideal.width > width else { return ideal }
        return subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var row = Row()
        for index in subviews.indices {
            let size = Self.size(of: subviews[index], within: width)
            let needed = row.items.isEmpty ? size.width : row.width + spacing + size.width
            if !row.items.isEmpty, needed > width {
                rows.append(row)
                row = Row()
            }
            row.width = row.items.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.items.append(index)
        }
        if !row.items.isEmpty { rows.append(row) }
        return rows
    }
}
