import SwiftUI

// =============================================================================
// HomeDiscovery — "Every grip opens a story."
// =============================================================================
// Web: v2/ArchiveDiscovery.tsx (styles in world.css). A folio with the grip on
// the left leaf and the person who threw it on the right, one older file further
// back, then the routes into the archive. Navigation framing only: every claim
// shown is the craftsman's own filed quote with its tier and source.
// =============================================================================

struct HomeDiscovery: View {
    @Environment(PitchStore.self) private var store

    var body: some View {
        if let craftsman = store.craftsman(slug: "adam-wainwright"),
           let pitch = craftsman.signaturePitchSlug.flatMap(store.pitch(slug:)),
           let history = store.lostPitch(slug: "rube-foster-fadeaway") {
            VStack(alignment: .leading, spacing: 0) {
                heading
                    .padding(.bottom, 28)
                folio(pitch: pitch, craftsman: craftsman, history: history)
                routes
                    .padding(.top, 34)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 48)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(ArchiveInk.discoveryText)
        }
    }

    // MARK: Heading

    private var heading: some View {
        VStack(alignment: .leading, spacing: 20) {
            ArchiveEyebrow(text: "Follow the craft", ink: ArchiveInk.discoveryEyebrow)
            VStack(alignment: .leading, spacing: -11) {
                Text("Every grip")
                    .font(PitchAtlasType.heroTitle(size: 44))
                Text("opens a story.")
                    .font(PitchAtlasType.heroItalic(size: 44))
                    .foregroundStyle(ArchiveInk.discoveryAccent)
            }
            .tracking(44 * -0.035)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Text("Start with the hand. Follow the pitch into the life behind it, then bring what you notice back to the ball.")
                .font(PitchAtlasTheme.hanken(15))
                .lineSpacing(6)
                .foregroundStyle(ArchiveInk.discoveryLede)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: The folio

    private func folio(pitch: PitchAtlasEntry, craftsman: Craftsman, history: LostPitch) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            specimenLeaf(pitch)
            storyLeaf(craftsman: craftsman, history: history)
        }
        .background(ArchiveInk.folioFill)
        .overlay { Rectangle().strokeBorder(ArchiveInk.folioBorder, lineWidth: 1) }
        .overlay(alignment: .top) { Rectangle().fill(ArchiveInk.folioTopLight).frame(height: 1) }
        .shadow(color: .black, radius: 32, y: 32)
        // `::before`: the sheet tucked under the folio, turned a hair off square.
        .background {
            Rectangle()
                .fill(ArchiveInk.folioUnder)
                .overlay { Rectangle().strokeBorder(ArchiveInk.folioUnderBorder, lineWidth: 1) }
                .padding(EdgeInsets(top: 8, leading: 5, bottom: -7, trailing: -6))
                .rotationEffect(.degrees(-0.45))
                .accessibilityHidden(true)
        }
    }

    private func specimenLeaf(_ pitch: PitchAtlasEntry) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ArchiveEyebrow(text: "The grip · \(pitch.display.specimenNo)", ink: ArchiveInk.specimenEyebrow)
                .padding(.bottom, 20)
            NavigationLink(value: pitch) {
                PitchSpecimenCard(entry: pitch, style: .wall(width: 290))
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Open specimen \(pitch.display.specimenNo), \(pitch.canonical.name)")
            .accessibilityAddTraits(.isButton)
            .frame(maxWidth: .infinity)
            Text("Grip demonstration by Austin H.")
                .font(PitchAtlasTheme.hanken(12, relativeTo: .footnote))
                .foregroundStyle(ArchiveInk.referenceCredit)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
            NavigationLink(value: pitch) {
                ArchiveLinkLabel(title: "Inspect the \(pitch.display.shortName.lowercased()) grip", arrow: "↗",
                                 ink: ArchiveInk.specimenText, size: 13)
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RadialGradient(colors: [ArchiveInk.specimenGlow, ArchiveInk.specimenFloor],
                           center: UnitPoint(x: 0.5, y: 0.15), startRadius: 0, endRadius: 420)
                .accessibilityHidden(true)
        }
        .overlay(alignment: .bottom) { Rectangle().fill(ArchiveInk.specimenRule).frame(height: 1) }
    }

    private func storyLeaf(craftsman: Craftsman, history: LostPitch) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ArchiveEyebrow(text: "The person · \(craftsman.era)", ink: ArchiveInk.storyEyebrow)
            Text(craftsman.name)
                .font(PitchAtlasTheme.hanken(20, relativeTo: .title3))
                .foregroundStyle(ArchiveInk.discoveryText)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .accessibilityAddTraits(.isHeader)
            if let quote = craftsman.quote {
                VStack(alignment: .leading, spacing: 22) {
                    Text("“\(quote.value)”")
                        .font(PitchAtlasType.heroTitle(size: 32))
                        .tracking(32 * -0.018)
                        .lineSpacing(-2)
                        .foregroundStyle(ArchiveInk.storyQuote)
                        .fixedSize(horizontal: false, vertical: true)
                    SourceClaimLabel(claim: quote)
                }
            }
            Text("Look at the hold. Read his account. Return to the grip with a different question.")
                .font(PitchAtlasTheme.hanken(15))
                .lineSpacing(5)
                .foregroundStyle(ArchiveInk.storyBody)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 24)
            RouteButton(path: "craftsmen/\(craftsman.slug)") {
                ArchiveLinkLabel(title: "Read the craftsman’s file", ink: ArchiveInk.discoveryText)
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
            historyNote(history)
                .padding(.top, 32)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func historyNote(_ history: LostPitch) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ArchiveEyebrow(text: "Further back in the archive", ink: ArchiveInk.storyEyebrow)
            NavigationLink(value: history) {
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Text(history.name)
                        .font(PitchAtlasType.heroTitle(size: 27))
                        .foregroundStyle(ArchiveInk.discoveryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Text("↗").foregroundStyle(ArchiveInk.discoveryText).accessibilityHidden(true)
                }
                .padding(.vertical, 7)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 3)
            Text("\(history.tagline). Follow the surviving account into the screwball’s file.")
                .font(PitchAtlasTheme.hanken(14))
                .lineSpacing(4)
                .foregroundStyle(ArchiveInk.storyBody)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 24)
        .overlay(alignment: .top) { Rectangle().fill(ArchiveInk.historyRule).frame(height: 1) }
    }

    // MARK: Routes

    private var routes: some View {
        VStack(alignment: .leading, spacing: 0) {
            RouteButton(path: "repertoire") {
                routeRow("Find your pitch", "Search the complete index")
            }
            .buttonStyle(.plain)
            if let sequencing = store.wing(slug: "sequencing") {
                Rectangle().fill(ArchiveInk.routeRule).frame(height: 1)
                NavigationLink(value: sequencing) {
                    routeRow("Put two pitches together", "Read the sequencing lesson")
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(alignment: .top) { Rectangle().fill(ArchiveInk.routeRule).frame(height: 1) }
        .overlay(alignment: .bottom) { Rectangle().fill(ArchiveInk.routeRule).frame(height: 1) }
    }

    private func routeRow(_ title: String, _ note: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(PitchAtlasType.heroTitle(size: 23))
                    .foregroundStyle(ArchiveInk.discoveryText)
                Text(note)
                    .font(PitchAtlasTheme.hanken(12, relativeTo: .footnote))
                    .foregroundStyle(ArchiveInk.routeNote)
            }
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Text("→")
                .font(PitchAtlasTheme.hanken(16))
                .foregroundStyle(ArchiveInk.routeArrow)
                .padding(.top, 2)
                .padding(.trailing, 14)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
