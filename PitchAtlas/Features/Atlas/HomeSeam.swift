import SwiftUI

// =============================================================================
// HomeSeam — chapter 02, inside the cover
// =============================================================================
// Web: v2/RefractionBridge.tsx (archive.css `.archive-bridge`). A charcoal
// inspection desk with the featured seam inset in a bezel: the leather and its
// stitching in three dimensions, or the same seam as a drawing. On the site the
// model is not touchable (pointer-events: none), so it never steals the page's
// scroll here either. Where the dimensional ball can't run (no Metal, Reduce
// Motion) the toggle goes away and the drawing stands alone, as the site hides
// its controls without WebGL.
// =============================================================================

struct HomeSeam: View {
    let featured: PitchAtlasEntry

    enum Presentation { case model, drawing }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var presentation: Presentation = .model

    private var modelAvailable: Bool { SpecimenStage.metalAvailable && !reduceMotion }
    private var showing: Presentation { modelAvailable ? presentation : .drawing }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChapterMark(.seam, accent: Color(rgb: PitchAccents.triad(for: featured.slug).c3),
                        numberInk: ArchiveInk.bridgeMark, nameInk: ArchiveInk.bridgeMark, ruleInk: ArchiveInk.bridgeMarkRule)
            title
                .padding(.vertical, 24)
            Text("One seam, two ways to look. Inspect the leather and stitching, then bring the same seam into a clear drawing.")
                .font(PitchAtlasTheme.hanken(16))
                .lineSpacing(7)
                .foregroundStyle(ArchiveInk.bridgeBody)
                .frame(maxWidth: 340, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Text("Seam-informed schematic. Use the drawing to orient yourself; open the grip to see where the fingers rest.")
                .font(PitchAtlasTheme.hanken(12, relativeTo: .footnote))
                .lineSpacing(5)
                .foregroundStyle(ArchiveInk.bridgeNote)
                .frame(maxWidth: 340, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 22)
            if modelAvailable {
                controls
                    .padding(.top, 26)
            }
            NavigationLink(value: featured) {
                ArchiveLinkLabel(title: "Find the fingers on the \(featured.display.shortName.lowercased())", ink: ArchiveInk.bridgeLink)
            }
            .buttonStyle(.plain)
            .padding(.top, 24)
            figure
                .padding(.top, 40)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 64)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(ArchiveInk.bridgeText)
        .background {
            ZStack {
                ArchiveInk.bridgeField
                RadialGradient(colors: [ArchiveInk.bridgeGlow, .clear], center: UnitPoint(x: 0.8, y: 0.3),
                               startRadius: 0, endRadius: 360)
            }
            .accessibilityHidden(true)
        }
        .overlay(alignment: .top) { Rectangle().fill(ArchiveInk.bridgeBorder).frame(height: 1) }
        .overlay(alignment: .bottom) { Rectangle().fill(ArchiveInk.bridgeBorder).frame(height: 1) }
    }

    /// `.archive-bridge-read h2`: Newsreader at 42, the second line in burnt italic.
    private var title: some View {
        VStack(alignment: .leading, spacing: -10) {
            Text("Follow")
                .font(PitchAtlasType.heroTitle(size: 42))
            Text("the seam.")
                .font(PitchAtlasType.heroItalic(size: 42))
                .foregroundStyle(ArchiveInk.bridgeAccent)
        }
        .tracking(42 * -0.04)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    /// `.archive-seam-controls`: two pressed-or-not buttons in the bridge's leather.
    private var controls: some View {
        HStack(spacing: 8) {
            toggle("Leather & stitching", .model)
            toggle("Seam drawing", .drawing)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Seam presentation")
    }

    private func toggle(_ title: String, _ value: Presentation) -> some View {
        let on = presentation == value
        return Button {
            guard presentation != value else { return }
            presentation = value
            Haptics.selection()
        } label: {
            Text(title)
                .font(PitchAtlasType.font(.martian400, size: 11, relativeTo: .caption))
                .foregroundStyle(on ? ArchiveInk.toggleOnInk : ArchiveInk.toggleInk)
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
                .frame(minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 3).fill(on ? ArchiveInk.toggleOnFill : ArchiveInk.toggleFill))
                .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(on ? ArchiveInk.toggleOnBorder : ArchiveInk.toggleBorder, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? [.isSelected] : [])
    }

    // MARK: The figure

    private var figure: some View {
        VStack(alignment: .leading, spacing: 0) {
            stage
            HStack {
                Text("01 / The cover")
                Spacer(minLength: 12)
                Text("02 / The seam")
            }
            .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
            .textCase(.uppercase)
            .tracking(1)
            .foregroundStyle(ArchiveInk.stageCaption)
            .padding(.top, 23)
            .accessibilityHidden(true)
            Text("Seam-informed schematic · Original geometry")
                .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                .foregroundStyle(ArchiveInk.bridgeNote)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
        }
        .frame(maxWidth: 440)
        .frame(maxWidth: .infinity)
    }

    /// `.archive-seam-stage`: a square well in a 10pt bezel, outlined 3pt off the
    /// bezel, with a faint registration square inside.
    private var stage: some View {
        GeometryReader { geo in
            let side = geo.size.width
            let well = side - 20
            ZStack {
                // the stage's drop is cast by its bezel, not by the seam drawn on it
                RoundedRectangle(cornerRadius: 8).fill(ArchiveInk.stageBezel)
                    .shadow(color: ArchiveInk.stageDrop, radius: 0, x: 0, y: 3)
                    .shadow(color: .black, radius: 20, x: 10, y: 28)
                RoundedRectangle(cornerRadius: 2).fill(ArchiveInk.stageFill).padding(10)
                Rectangle()
                    .strokeBorder(ArchiveInk.stageRegistration, lineWidth: 1)
                    .padding(10 + well * 0.07)
                Group {
                    switch showing {
                    case .model:
                        SpecimenStage(entry: featured, size: well * 0.86, chrome: false)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    case .drawing:
                        SeamBall(motion: featured.motion, size: well * 0.86, showMovement: false)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Seam-informed schematic: the same figure-eight seam projected into two dimensions.")
                    }
                }
                .transition(.opacity)
            }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.4), value: showing)
            .overlay {
                RoundedRectangle(cornerRadius: 11)
                    .strokeBorder(ArchiveInk.stageOutline, lineWidth: 1)
                    .padding(-4)
                    .accessibilityHidden(true)
            }
            .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(4)
    }
}
