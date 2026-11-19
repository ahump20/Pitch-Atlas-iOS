import SwiftUI

// =============================================================================
// Pitch Atlas — the Craftsmen hall
// =============================================================================
// Web: pages/CraftsmenHall.tsx and components/craftsmen/CraftsmanMedia.tsx, in
// their order. The section header, the film filed under the arms, the masters
// in the order their eras began (each card's band laid against the same
// century), then the one pitch that is a legend rather than a person, filed
// apart and labeled as such, and the site's footer. Four-state aware: a decode
// failure shows the error, an empty hall says why.
// =============================================================================

struct CraftsmenView: View {
    @Environment(PitchStore.self) private var store

    var body: some View {
        ZStack {
            FieldBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHero(eyebrow: "The hall",
                                title: Text("The arms that defined the pitches."),
                                sub: Text("The arms that owned a pitch, and the one pitch that is a legend, not a person. Every quote sourced."),
                                trail: [Crumb(label: "The Atlas", path: "home"), Crumb(label: "The Craftsmen")])
                    content
                    SiteFooter(path: "/craftsmen")
                }
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                .emitsScrollProgress()
            }
        }
        // The site's header carries the brand on every page; the title still names
        // the back button on the pages this one opens.
        .navigationTitle("Craftsmen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { BrandLockup(size: .sm) }
        }
        .navigationDestination(for: Craftsman.self) { CraftsmanDetailView(craftsman: $0) }
    }

    // MARK: - Four states

    @ViewBuilder
    private var content: some View {
        if case .failed(let msg) = store.status {
            ErrorStateView(reason: msg).padding(20)
        } else if store.craftsmen.isEmpty {
            EmptyStateView(message: "The hall couldn't load.").padding(20)
        } else {
            CraftsmenFilmShelf(items: CraftsmenHallReads.featuredFilm(store.craftsmanMedia))
            masters
        }
    }

    // MARK: - The masters, then the legend

    private var masters: some View {
        let order = store.craftsmenByEra
        let masters = order.filter { $0.kind == .craftsman }
        let legends = order.filter { $0.kind == .legend }
        return VStack(alignment: .leading, spacing: 0) {
            StageTierMarker(index: "C", label: "The masters")
            if let note = CraftsmenHallReads.mastersNote(masters) {
                Text(note.uppercased())
                    .font(PitchAtlasType.font(.martian400, size: 11, relativeTo: .caption2))
                    .tracking(em: 0.13, size: 11)
                    .foregroundStyle(PitchAtlasTheme.ink3)
                    .cssLineHeight(1.5, face: .martian400, size: 11, relativeTo: .caption2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, -8)
                    .padding(.bottom, 28)
                    .accessibilityLabel(note)
            }
            // Lazy so each plate builds only as it scrolls into view.
            LazyVStack(spacing: 20) {
                ForEach(masters) { plate($0) }
            }
            if !legends.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    StageTierMarker(index: "L", label: "The legend")
                    VStack(spacing: 20) {
                        ForEach(legends) { plate($0) }
                        whyALegend
                    }
                }
                .padding(.top, 64)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 80)
    }

    private func plate(_ craftsman: Craftsman) -> some View {
        NavigationLink(value: craftsman) {
            CraftsmanCard(craftsman: craftsman)
        }
        .buttonStyle(.plain)
    }

    /// The dashed note beside the legend. Its heading is a hidden note.
    private var whyALegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            EggButton(note: .knuckleball) {
                Text("Why a legend, not a master".uppercased())
                    .font(MonoLabel.font)
                    .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                    .foregroundStyle(PitchAtlasTheme.ink2)
                    .cssLineHeight(1, face: .martian400, size: MonoLabel.size, relativeTo: .caption2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            // Verbatim, CraftsmenHall.tsx.
            Text("The gyroball is filed apart on purpose. It is a real pitch, but most of what is said about it is myth. We keep it to show the difference between a sourced record and a good story, and to label which is which.")
                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.ink2)
                .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 52 * 0.56 * 14, alignment: .leading)
        }
        .padding(25)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(PitchAtlasTheme.bone.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Film filed

/// A still of each pitcher opens his file, where the original teaching clip is linked.
struct CraftsmenFilmShelf: View {
    let items: [CraftsmanMediaItem]

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("Teaching film")
                    .font(PitchAtlasType.font(.newsreader400, size: 36, relativeTo: .largeTitle))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .accessibilityAddTraits(.isHeader)
                ForEach(items) { FilmShelfCard(item: $0) }
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct FilmShelfCard: View {
    let item: CraftsmanMediaItem
    @Environment(PitchStore.self) private var store

    var body: some View {
        if let craftsman = store.craftsman(slug: item.craftsmanSlug) {
            NavigationLink(value: craftsman) { card }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(item.craftsmanName). \(item.title). \(item.lede) \(CraftsmenHallReads.providerName(item)), filed \(MediaShelf.monthYear(item.retrievedAt).capitalized).")
                .accessibilityHint("Opens \(item.craftsmanName)'s file")
                .accessibilityIdentifier("craftsmen-film-\(item.craftsmanSlug)")
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let image = CraftsmanPhoto.catalog[item.craftsmanSlug]?.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(item.craftsmanName.uppercased())
                        .font(PitchAtlasType.font(.anton400, size: 24, relativeTo: .title2))
                        .foregroundStyle(PitchAtlasTheme.bone)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(PitchAtlasTheme.bone2)
                }
                TightLines(item.title.uppercased(), face: .martian400, size: MonoLabel.size, lineHeight: 1,
                           relativeTo: .caption2, trackingEm: MonoLabel.trackingEm)
                    .foregroundStyle(PitchAtlasTheme.cyan)
                    .padding(.top, 6)
                Text(item.lede)
                    .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                Text("\(CraftsmenHallReads.providerName(item)) · filed \(MediaShelf.monthYear(item.retrievedAt))".uppercased())
                    .font(MonoLabel.font)
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .padding(.top, 12)
            }
            .padding(17)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PitchAtlasTheme.press)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(PitchAtlasTheme.bone.opacity(0.15), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 6))
    }
}
