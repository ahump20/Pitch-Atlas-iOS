import SwiftUI

// =============================================================================
// Pitch Atlas — Learn, the craft record's contents page
// =============================================================================
// Web: pages/KnowledgeHub.tsx, in its order. The section header, then two
// shelves (the craft, the scope boundaries), each filed in teaching order: a
// long shelf leads and closes with a full-width plate and holds the grid
// between, every card numbered by its place in the whole order. The famous
// distance closes the page. Four-state aware: a decode failure shows the error,
// an empty bundle says the wings are still being filed.
// =============================================================================

struct LearnView: View {
    @Environment(PitchStore.self) private var store

    var body: some View {
        ZStack {
            FieldBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHero(eyebrow: "The craft record",
                                title: Text("The craft underneath the pitch."),
                                sub: Text(LearnHubReads.heroSub),
                                trail: [Crumb(label: "The Atlas", path: "home"), Crumb(label: "Learn")])
                    content
                    SiteFooter(path: "/learn")
                }
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                .emitsScrollProgress()
            }
        }
        // The site's header carries the brand on every page; the title still names
        // the back button on the pages this one opens.
        .navigationTitle("Learn")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { BrandLockup(size: .sm) }
        }
        // Its wings open through the Atlas stack's root destination (AtlasView).
    }

    // MARK: - Four states

    @ViewBuilder
    private var content: some View {
        if case .failed(let msg) = store.status {
            ErrorStateView(reason: msg).padding(20)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                if store.knowledge.isEmpty {
                    // Verbatim, KnowledgeHub.tsx.
                    Text("The teaching wings are still being filed.")
                        .font(PitchAtlasType.font(.hanken400, size: 18, relativeTo: .title3))
                        .foregroundStyle(PitchAtlasTheme.ink2)
                        .cssLineHeight(28.0 / 18.0, face: .hanken400, size: 18, relativeTo: .title3)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 56 * 0.56 * 18, alignment: .leading)
                } else {
                    shelves
                }
                // a shelf's 56 bottom margin outranks the mark's own 48 above it
                distance.padding(.top, store.knowledge.isEmpty ? 48 : 56)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 64)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - The shelves

    private var shelves: some View {
        let wings = store.knowledge
        return VStack(alignment: .leading, spacing: 56) {
            ForEach(LearnHubReads.shelves(wings)) { shelf in
                VStack(alignment: .leading, spacing: 0) {
                    // The heading is inline-flex on its block's 16/24 line: 7.8 down.
                    KickerLabel(text: shelf.label)
                        .padding(.vertical, 1.65)
                        .padding(.top, 7.8)
                        .padding(.bottom, 24)
                    VStack(spacing: 16) {
                        if let lead = shelf.lead { open(lead) { WingFeature(wing: lead, no: number(lead, in: wings)) } }
                        ForEach(shelf.middle) { wing in
                            open(wing) { WingCard(wing: wing, no: number(wing, in: wings)) }
                        }
                        if let closer = shelf.closer { open(closer) { WingFeature(wing: closer, no: number(closer, in: wings)) } }
                    }
                }
            }
        }
    }

    private func number(_ wing: KnowledgeWing, in wings: [KnowledgeWing]) -> String {
        LearnHubReads.pad(LearnHubReads.readingNo(wing, in: wings))
    }

    private func open<Label: View>(_ wing: KnowledgeWing, @ViewBuilder label: () -> Label) -> some View {
        NavigationLink(value: wing) { label() }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(LearnHubReads.accessibilityLabel(wing, in: store.knowledge))
            .accessibilityAddTraits(.isButton)
    }

    /// A cryptic filing mark: the famous distance, hiding a note about why.
    private var distance: some View {
        EggButton(note: .sixtySix) {
            Text("60′\u{2009}6″")
                .font(MonoLabel.font)
                .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                .foregroundStyle(PitchAtlasTheme.ink3)
                .cssLineHeight(1, face: .martian400, size: MonoLabel.size, relativeTo: .caption2)
        }
        .frame(maxWidth: .infinity, minHeight: 24, alignment: .trailing)
    }
}

// MARK: - A wing's card

/// WingCard: a Tier B plate on the cyan (a scope boundary takes the seam and a
/// dashed frame), its kind and its number, its name, three lines of summary, and
/// the foot that opens it.
private struct WingCard: View {
    let wing: KnowledgeWing
    let no: String

    var body: some View {
        let boundary = wing.boundaryOnly == true
        let kindInk = boundary ? AnyShapeStyle(PitchAtlasTheme.seamBright) : AnyShapeStyle(PitchAtlasTheme.text3)
        Plate(accent: boundary ? PitchAtlasTheme.seamBright : PitchAtlasTheme.cyan,
              variant: boundary ? .edgeDashed : .standard) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                mono(wing.eyebrow, ink: kindInk)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Text(no)
                    .font(PitchAtlasType.font(.anton400, size: 24, relativeTo: .title2))
                    .monospacedDigit()
                    .foregroundStyle(PitchAtlasTheme.bone.opacity(0.25))
                    .cssLineHeight(1, face: .anton400, size: 24, relativeTo: .title2)
            }
            TightLines(LearnHubReads.shortTitle(wing).uppercased(), face: .anton400, size: 24,
                       lineHeight: 32.0 / 24.0, relativeTo: .title2, trackingEm: 0.01)
                .foregroundStyle(PitchAtlasTheme.bone)
            Text(wing.summary)
                .font(PitchAtlasType.font(.hanken400, size: 15.2, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 15.2, relativeTo: .subheadline)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 12) {
                Rectangle().fill(Color.white.opacity(0.10)).frame(height: 1)
                HStack(spacing: 12) {
                    mono(boundary ? "Scope boundary" : "The craft", ink: kindInk)
                    Spacer(minLength: 0)
                    mono("Open →", ink: AnyShapeStyle(PitchAtlasTheme.cyan))
                }
            }
        }
    }

    private func mono(_ text: String, ink: AnyShapeStyle) -> some View {
        PlateMono(text, ink: ink)
            .cssLineHeight(1, face: .martian400, size: MonoLabel.size, relativeTo: .caption2)
    }
}

/// WingFeature: the lead and the closing wing, full width on the cyan, without
/// the corner ticks — the contents page gets a reading order, not ten identical
/// cards. The site's atmosphere layer collapses to nothing (it computes
/// `position: relative` at zero height) but still takes its 14pt gap, so the
/// words start that much lower and no texture shows.
private struct WingFeature: View {
    let wing: KnowledgeWing
    let no: String

    var body: some View {
        Plate(accent: PitchAtlasTheme.cyan, ticks: false) {
            VStack(alignment: .leading, spacing: 0) {
                (Text("Wing \(no)").foregroundStyle(PitchAtlasTheme.cyan)
                    + Text(" · \(wing.eyebrow)").foregroundStyle(PitchAtlasTheme.text3))
                    .font(MonoLabel.font)
                    .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                    .textCase(.uppercase)
                    .cssLineHeight(1, face: .martian400, size: MonoLabel.size, relativeTo: .caption2)
                    .fixedSize(horizontal: false, vertical: true)
                TightLines(LearnHubReads.shortTitle(wing).uppercased(), face: .anton400, size: 30,
                           lineHeight: 36.0 / 30.0, relativeTo: .title, trackingEm: 0.01)
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .padding(.top, 4)
                Text(wing.summary)
                    .font(PitchAtlasType.font(.hanken400, size: 16.32, relativeTo: .body))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .cssLineHeight(1.625, face: .hanken400, size: 16.32, relativeTo: .body)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                PlateMono("Open the wing →", ink: PitchAtlasTheme.cyan)
                    .cssLineHeight(1, face: .martian400, size: MonoLabel.size, relativeTo: .caption2)
                    .padding(.bottom, 4)
                    .padding(.top, 12)
            }
            // py-3 inside the plate, under the collapsed atmosphere's gap
            .padding(.top, 14 + 12)
            .padding(.bottom, 12)
        }
    }
}
