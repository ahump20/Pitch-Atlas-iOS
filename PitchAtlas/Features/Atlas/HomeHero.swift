import SwiftUI

// =============================================================================
// HomeHero — chapter 01, the specimen case
// =============================================================================
// Web: v2/HeroCase.tsx in archive.css's `.archive-case`. A charcoal case under a
// warm rake of light: the title, two ways in, the four-seam on its ember stock,
// the controls beneath the card, and the case's foot line.
// =============================================================================

struct HomeHero: View {
    let featured: PitchAtlasEntry

    @Environment(PitchStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(MotionPreference.pausedKey) private var motionPaused = false

    /// The pause control only appears where something moves: a filmed face, motion allowed.
    private var hasFilm: Bool {
        if case .film = SpecimenCardContent.make(entry: featured, grip: store.gripEntry(forSpecimen: featured.slug)).face { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChapterMark(.specimen, accent: PitchAtlasTheme.cyan)
                .padding(.bottom, 26)
            title
            Text("A grip to inspect. A seam to follow. A story that brings you back to the ball.")
                .font(PitchAtlasTheme.hanken(15))
                .lineSpacing(5)
                .foregroundStyle(PitchAtlasTheme.bone2)
                .frame(maxWidth: 320, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 22)
            ways
                .padding(.top, 28)
            card
                .padding(.top, 44)
            cardControls
                .padding(.top, 16)
            caseFoot
                .padding(.top, 40)
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { caseLight }
    }

    /// `.archive-case-title`: Newsreader at 52, leaded .98, the second line in italic gold.
    private var title: some View {
        VStack(alignment: .leading, spacing: -14) {
            Text("The pitch,")
                .font(PitchAtlasType.heroTitle(size: 52))
                .foregroundStyle(ArchiveInk.caseTitle)
            Text("in your hand.")
                .font(PitchAtlasType.heroItalic(size: 52))
                .foregroundStyle(ArchiveInk.caseTitleAccent)
        }
        .tracking(52 * PitchAtlasType.Tracking.heroTitle)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var ways: some View {
        VStack(alignment: .leading, spacing: 14) {
            RouteButton(path: "repertoire") { Text("Open the Pitch Index →") }
                .buttonStyle(.pitch(.chrome))
            NavigationLink(value: featured) { Text("Study this grip →") }
                .buttonStyle(.pitch(.ghost))
        }
    }

    private var card: some View {
        NavigationLink(value: featured) {
            PitchSpecimenCard(entry: featured, style: .hero, motionPaused: motionPaused)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Open the featured specimen, \(featured.canonical.name)")
        .accessibilityAddTraits(.isButton)
        // `.archive-case-card::after`: the card's floor, a blurred shadow turned 5°.
        .background {
            Rectangle()
                .fill(ArchiveInk.caseCardShadow)
                .blur(radius: 28)
                .rotationEffect(.degrees(-5))
                .padding(EdgeInsets(top: 54, leading: 22, bottom: -18, trailing: -29))
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
    }

    private var cardControls: some View {
        HStack(spacing: 10) {
            CompareButton(slug: featured.slug)
            if hasFilm && !reduceMotion { PauseMotionButton() }
        }
        .frame(width: PitchSpecimenCard.width(for: .hero), alignment: .leading)
        .frame(maxWidth: .infinity)
    }

    /// `.archive-case-footer`: the case's foot line under a hairline.
    private var caseFoot: some View {
        HStack(alignment: .firstTextBaseline, spacing: 20) {
            Text("The living collection")
            Spacer(minLength: 0)
            Text("Grip / history / craft")
        }
        .font(PitchAtlasType.font(.martian400, size: 8, relativeTo: .caption2))
        .textCase(.uppercase)
        .tracking(8 * 0.16)
        .foregroundStyle(ArchiveInk.caseFooter)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.top, 13)
        .overlay(alignment: .top) { Rectangle().fill(ArchiveInk.caseFooterRule).frame(height: 1) }
        .accessibilityElement(children: .combine)
    }

    /// `.archive-case` + `.archive-case-light`: the warm rake from the upper right and
    /// the shade it leaves on the left, over the charcoal case.
    private var caseLight: some View {
        ZStack {
            ArchiveInk.caseField
            RadialGradient(colors: [ArchiveInk.caseLight, .clear], center: UnitPoint(x: 0.77, y: 0.24),
                           startRadius: 0, endRadius: 380)
            LinearGradient(stops: [.init(color: ArchiveInk.caseShade, location: 0.24), .init(color: .clear, location: 0.65)],
                           startPoint: UnitPoint(x: 0, y: 0.32), endPoint: UnitPoint(x: 1, y: 0.68))
        }
        .accessibilityHidden(true)
    }
}
