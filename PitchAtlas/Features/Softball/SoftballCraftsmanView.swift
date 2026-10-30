import SwiftUI

// =============================================================================
// SoftballCraftsmanView — a craftsman of the circle
// =============================================================================
// Web: pages/SoftballCraftsmanChapter.tsx. The stage (Master · era · hand, the
// name, the tagline, the signature-pitch chip), the intro, 01 the signature pitch
// with the way to its file, 02 the mental edge (or "In the circle" with only a
// quote), 03 the record and the record-keepers, then the chapter nav.
// =============================================================================

struct SoftballCraftsmanView: View {
    let craftsman: Craftsman
    @Environment(PitchStore.self) private var store

    var body: some View {
        let people = store.softball.craftsmen
        let around = SoftballReads.neighbors(people, at: people.firstIndex { $0.slug == craftsman.slug })
        let pitch = craftsman.signaturePitchSlug.flatMap(store.softballPitch(slug:))
        SoftballPage(title: craftsman.name) {
            stage
            Text(craftsman.intro)
                .font(PitchAtlasType.font(.newsreader400, size: 24, relativeTo: .title2))
                .tracking(em: -0.012, size: 24)
                .foregroundStyle(PitchAtlasTheme.bone)
                .cssLineHeight(1.375, face: .newsreader400, size: 24, relativeTo: .title2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)
                .padding(.vertical, 64)
            SoftballRoom(index: "01", label: "The signature pitch") {
                ClaimProse(claim: craftsman.signature, size: 20, ink: PitchAtlasTheme.bone)
                if let pitch {
                    NavigationLink(value: AtlasRoute.softballPitch(slug: pitch.slug)) {
                        SoftballSeamButton(title: "Study the \(pitch.name.lowercased())")
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 24)
                }
            }
            if let edge = craftsman.mentalEdge {
                SoftballRoom(index: "02", label: "The mental edge") {
                    ClaimProse(claim: edge, size: 20, ink: PitchAtlasTheme.bone)
                    if let quote = craftsman.quote { ArchiveQuoteFigure(quote: quote).padding(.top, 40) }
                }
            } else if let quote = craftsman.quote {
                SoftballRoom(index: "02", label: "In the circle") { ArchiveQuoteFigure(quote: quote) }
            }
            if !craftsman.recordProse.isEmpty {
                SoftballRoom(index: "03", label: "The record") {
                    VStack(alignment: .leading, spacing: 40) {
                        ForEach(Array(craftsman.recordProse.enumerated()), id: \.offset) { index, claim in
                            ClaimProse(claim: claim, size: index == 0 ? 20 : 18, ink: PitchAtlasTheme.bone)
                        }
                    }
                    if let links = craftsman.recordLinks, !links.isEmpty {
                        RecordLinksRow(links: links).padding(.top, 48)
                    }
                    SoftballProse(text: SoftballReads.recordNote, size: 14, ink: PitchAtlasTheme.ink2, measure: 78)
                        .padding(.top, 24)
                        .overlay(alignment: .top) { PitchAtlasTheme.bone.opacity(0.15).frame(height: 1) }
                        .padding(.top, 40)
                }
            }
            SoftballChapterNav(label: "Softball craftsmen chapters",
                               previous: around.previous.map { ($0.name, AtlasRoute.softballCraftsman(slug: $0.slug)) },
                               next: around.next.map { ($0.name, AtlasRoute.softballCraftsman(slug: $0.slug)) })
            SiteFooter(path: "/softball/craftsmen/\(craftsman.slug)")
        }
    }

    private var stage: some View {
        VStack(alignment: .leading, spacing: 0) {
            Breadcrumb(trail: [Crumb(label: "The Atlas", path: "home"), Crumb(label: "Softball", path: "softball"),
                               Crumb(label: craftsman.name)],
                       linkInk: PitchAtlasTheme.bone2.opacity(0.8), currentInk: PitchAtlasTheme.bone2)
            KickerLabel(text: "Master · \(craftsman.era)" + (craftsman.hand.map { " · \($0.rawValue)-handed" } ?? ""))
                .padding(.top, 32)
            SoftballStageTitle(text: craftsman.name).padding(.top, 16)
            Text(craftsman.tagline)
                .font(PitchAtlasType.font(.hanken400, size: 18, relativeTo: .title3))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 18, relativeTo: .title3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 20)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Signature pitch".uppercased()).foregroundStyle(PitchAtlasTheme.bone)
                Text(craftsman.signaturePitch.uppercased()).foregroundStyle(Color(web: WebTokens.Palette.powder))
            }
            .font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .caption))
            .tracking(em: 0.12, size: 12)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 17)
            .padding(.vertical, 9)
            .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(PitchAtlasTheme.bone.opacity(0.25), lineWidth: 1))
            .accessibilityElement(children: .combine)
            .padding(.top, 28)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 64)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { ArchiveStageGround(light: ArchiveInk.craftsmanStageLight) }
    }
}
