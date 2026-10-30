import SwiftUI

// =============================================================================
// ShapeMapView — every filed pitch on one field, by direction
// =============================================================================
// Web: pages/MovementMapPage.tsx over sections/MovementMap.tsx. The hero, the RHP /
// LHP mirror, the 640 × 500 field (axis guides, poles, the spinless ball, a dashed
// connector and a tappable dot per pitch), the legend, a "{shortName} →" link row
// and the two footnotes. The field keeps its drawn width and scrolls sideways on a
// phone, as the site's does under md. No hover here, so no tooltip: each dot speaks
// the site's aria-label and opens its specimen.
// =============================================================================

struct ShapeMapView: View {
    @Environment(PitchStore.self) private var store
    @Environment(DeepLinkRouter.self) private var router
    @State private var hand: Handedness = .right

    var body: some View {
        ZStack {
            FieldBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHero(eyebrow: "The shape map",
                                title: Text("Every pitch, by direction."),
                                sub: Text(ShapeMap.heroSub),
                                trail: [Crumb(label: "The Atlas", path: "home"), Crumb(label: "Shape map")])
                    VStack(alignment: .leading, spacing: 24) {
                        handToggle
                        Text(ShapeMap.scrollHint)
                            .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                            .foregroundStyle(PitchAtlasTheme.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                        ScrollView(.horizontal, showsIndicators: true) {
                            ShapeMapField(dots: ShapeMap.dots(store.pitches, hand: hand), hand: hand)
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Scrollable pitch shape map")
                        legend
                        linkRow
                        footnotes
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 56)
                    SiteFooter(path: "/movement-map")
                }
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                .emitsScrollProgress()
            }
        }
        .navigationTitle("Shape map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { BrandLockup(size: .sm) }
        }
    }

    private var handToggle: some View {
        HStack(spacing: 12) {
            monoLabel("Handedness", ink: PitchAtlasTheme.ink3)
            SegmentToggle(selection: $hand, options: [(.right, "RHP"), (.left, "LHP")])
        }
    }

    private var legend: some View {
        FlowRow(spacing: 24, lineSpacing: 8) {
            ForEach(PitchFamily.allCases, id: \.self) { family in
                HStack(spacing: 8) {
                    Circle().fill(ShapeMapInk.family(family)).frame(width: 12, height: 12)
                        .accessibilityHidden(true)
                    monoLabel(family.label)
                }
            }
        }
    }

    private var linkRow: some View {
        FlowRow(spacing: 16, lineSpacing: 0) {
            ForEach(store.pitches) { entry in
                NavigationLink { PitchDetailView(entry: entry) } label: {
                    Text("\(entry.display.shortName) →".uppercased())
                        .font(PitchAtlasType.font(.martian400, size: 11, relativeTo: .caption2))
                        .tracking(em: 0.14, size: 11)
                        .foregroundStyle(PitchAtlasTheme.seamBright)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(entry.display.shortName), open specimen")
            }
        }
    }

    private var footnotes: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(.init("\(ShapeMap.footnote) [Spin & Movement](pitchatlas://learn/spin)."))
            Text(.init("Want the tracked version: induced break, spin rates, the numbers this page refuses to fake? That craft has its own keepers: [Baseball Savant ↗](https://baseballsavant.mlb.com) and the [FanGraphs model primer ↗](https://library.fangraphs.com/pitching/stuff-location-and-pitching-primer/). How to read them without losing the feel is its own wing: [Reading Models](pitchatlas://learn/metrics)."))
        }
        .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
        .lineSpacing(4)
        .foregroundStyle(PitchAtlasTheme.ink2)
        .tint(PitchAtlasTheme.seamBright)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 24)
        .overlay(alignment: .top) { PitchAtlasTheme.bone.opacity(0.15).frame(height: 1) }
        .environment(\.openURL, OpenURLAction { url in
            guard url.scheme == "pitchatlas" else { return .systemAction }
            router.handle(url, store: store)
            return .handled
        })
    }

    private func monoLabel(_ text: String, ink: Color = PitchAtlasTheme.ink2) -> some View {
        Text(text.uppercased())
            .font(PitchAtlasType.font(.martian400, size: 11, relativeTo: .caption2))
            .tracking(em: 0.14, size: 11)
            .foregroundStyle(ink)
    }
}

/// The 640 × 500 field at its drawn size: guides, poles, the spinless ball and the
/// connectors in a Canvas; each dot a NavigationLink to its specimen.
private struct ShapeMapField: View {
    let dots: [ShapeMap.Dot]
    let hand: Handedness

    var body: some View {
        let c = ShapeMap.center, clamp = ShapeMap.clamp
        let poles = ShapeMap.poles(hand: hand)
        ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                var guides = Path()
                guides.move(to: CGPoint(x: c.x, y: c.y - clamp - 16))
                guides.addLine(to: CGPoint(x: c.x, y: c.y + clamp + 16))
                guides.move(to: CGPoint(x: c.x - clamp - 16, y: c.y))
                guides.addLine(to: CGPoint(x: c.x + clamp + 16, y: c.y))
                context.stroke(guides, with: .color(PitchAtlasTheme.ink3), lineWidth: 1)

                func pole(_ word: String, _ x: CGFloat, _ y: CGFloat) {
                    context.draw(Text(word).font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .caption))
                                    .tracking(2).foregroundStyle(PitchAtlasTheme.ink2),
                                 at: CGPoint(x: x, y: y), anchor: .bottom)
                }
                pole("RIDE", c.x, c.y - clamp - 16)
                pole("DROP", c.x, c.y + clamp + 28)
                pole(poles.left, c.x - clamp - 20, c.y - 8)
                pole(poles.right, c.x + clamp + 20, c.y - 8)

                context.stroke(Path(ellipseIn: CGRect(x: c.x - 6, y: c.y - 6, width: 12, height: 12)),
                               with: .color(PitchAtlasTheme.ink2.opacity(0.7)),
                               style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

                for dot in dots {
                    var link = Path()
                    link.move(to: c)
                    link.addLine(to: dot.point)
                    context.stroke(link, with: .color(ShapeMapInk.family(dot.entry.canonical.family).opacity(0.32)),
                                   style: StrokeStyle(lineWidth: 0.8, dash: [2, 3]))
                }
                for dot in dots {
                    let at = CGPoint(x: dot.point.x + dot.label.dx, y: dot.point.y + dot.label.dy)
                    let anchor: UnitPoint = dot.label.anchor == .start ? .leading : dot.label.anchor == .end ? .trailing : .center
                    let name = Text(dot.entry.display.shortName)
                        .font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .caption))
                    // The site's paint-order halo: the void ground under the name.
                    for (dx, dy) in [(-1.5, 0.0), (1.5, 0.0), (0.0, -1.5), (0.0, 1.5)] {
                        context.draw(name.foregroundStyle(PitchAtlasTheme.void),
                                     at: CGPoint(x: at.x + dx, y: at.y + dy), anchor: anchor)
                    }
                    context.draw(name.foregroundStyle(PitchAtlasTheme.bone), at: at, anchor: anchor)
                }
            }
            .frame(width: ShapeMap.width, height: ShapeMap.height)
            .accessibilityHidden(true)

            ForEach(dots, id: \.entry.slug) { dot in
                NavigationLink { PitchDetailView(entry: dot.entry) } label: {
                    ZStack {
                        Circle().fill(Color.clear)
                        Circle().fill(ShapeMapInk.family(dot.entry.canonical.family).opacity(0.9))
                            .overlay(Circle().strokeBorder(PitchAtlasTheme.void, lineWidth: 1))
                            .frame(width: 14, height: 14)
                    }
                    .frame(width: ShapeMap.hitRadius * 2, height: ShapeMap.hitRadius * 2)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .position(dot.point)
                .accessibilityLabel(ShapeMap.markerLabel(dot.entry))
                .accessibilityAddTraits(.isLink)
            }
        }
        .frame(width: ShapeMap.width, height: ShapeMap.height)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(ShapeMap.mapLabel(hand: hand))
    }
}
