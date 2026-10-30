import SwiftUI

// =============================================================================
// AtlasView: the home
// =============================================================================
// The site's home (web src/pages/AtlasHomeV2.tsx) in its own order: the
// specimen case, the discovery folio, the seam, the filed set, the media rail,
// the other doors, the record, and the archive's back cover. Each chapter is its
// own file (Home*.swift); this view stacks them and owns the Atlas tab's
// destinations.
// =============================================================================

// Atlas wings share the value-based stack used by their filed records. Mixing
// direct destinations here with value links inside a wing can replay the wing
// instead of advancing to the selected record. The wing records (a Learn wing, a
// lost pitch) are registered here at the stack's root, so a link that stacks
// wing and record in one step (DeepLinkRouter) resolves both.

struct AtlasView: View {
    /// The toolbar's way into the account screen, by the name Support's delete
    /// route walks.
    static let accountLabel = "Account and Safety"

    @Environment(PitchStore.self) private var store

    var body: some View {
        ZStack {
            FieldBackdrop()
            ScrollView {
                LazyVStack(spacing: 0) {
                    if case .failed(let reason) = store.status {
                        ErrorStateView(reason: reason)
                            .padding(PitchAtlasSpacing.lg)
                    }
                    if let featured = FeaturedSet.entries(in: store).first {
                        HomeHero(featured: featured)
                        HomeDiscovery()
                        HomeSeam(featured: featured)
                    } else {
                        // Four-state honesty: a bundle without filed specimens says
                        // so, and the doors below still lead into the archive.
                        EmptyStateView(message: "No filed specimens shipped in this build yet. The index, grips, and craftsmen are still here.")
                            .padding(PitchAtlasSpacing.lg)
                    }
                    HomeFiledSet()
                    HomeMediaRail()
                    HomeDoors()
                    HomeRecord()
                    SiteFooter(path: "/")
                }
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                .emitsScrollProgress()
            }
        }
        .navigationTitle("Atlas")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { AtlasMenuButton() }
            ToolbarItem(placement: .principal) {
                BrandLockup(size: .sm)
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: AtlasRoute.account) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(PitchAtlasTheme.bone2)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Self.accountLabel)
                .accessibilityHint("Sign in, report, block, support, and delete account")
            }
        }
        .navigationDestination(for: AtlasRoute.self) { route in
            switch route {
            case .craftsmen: CraftsmenView()
            case .learn: LearnView()
            case .lostPitches: LostPitchesView()
            case .about: AboutView()
            case .account: AccountView()
            case .support: SupportView()
            case .shapeLab(let tilt, let pitch): ShapeLabView(tilt: tilt, pitch: pitch)
            case .shapeMap: ShapeMapView()
            case .softball: SoftballHubView()
            case .fastpitch: SoftballFastpitchView()
            case .slowpitch: SoftballSlowpitchView()
            case .softballPitch(let slug):
                if let pitch = store.softballPitch(slug: slug) { SoftballPitchView(pitch: pitch) } else { SoftballHubView() }
            case .softballCraftsman(let slug):
                if let craftsman = store.softballCraftsman(slug: slug) { SoftballCraftsmanView(craftsman: craftsman) } else { SoftballHubView() }
            }
        }
        .navigationDestination(for: PitchAtlasEntry.self) { PitchDetailView(entry: $0) }
        .navigationDestination(for: KnowledgeWing.self) { KnowledgeWingView(wing: $0) }
        .navigationDestination(for: LostPitch.self) { LostPitchDetailView(pitch: $0) }
    }
}
