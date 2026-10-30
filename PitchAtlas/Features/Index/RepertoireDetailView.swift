import SwiftUI

// =============================================================================
// RepertoireDetailView — the basic file
// =============================================================================
// Web: pages/RepertoireChapter.tsx, in its order. Every accepted pitch the atlas
// has not filed as a full specimen still gets a real page: the header, the
// plain-language read beside a schematic cover (the ball, not a movement claim),
// Austin's grip evidence where he has photographed it, the grip, what it does and
// what it really is as sourced prose, who throws it, the specimen to study first,
// the honest "basic file" marker, the rest of its family, the discussion, the
// previous and next files, and the site's footer. A filed pitch opens its full
// specimen instead, as the site redirects it.
// =============================================================================

struct RepertoireDetailView: View {
    let entry: RepertoireEntry
    @Environment(PitchStore.self) private var store

    var body: some View {
        if let slug = entry.filedSlug, let filed = store.pitch(slug: slug) {
            PitchDetailView(entry: filed)
        } else {
            BasicFileView(entry: entry)
        }
    }
}

private struct BasicFileView: View {
    let entry: RepertoireEntry
    @Environment(PitchStore.self) private var store

    private var edge: Bool { BasicFile.isEdge(entry.status) }

    var body: some View {
        let grip = store.gripEntry(forKey: entry.id)
        let around = BasicFile.neighbors(of: entry, in: store.repertoire.entries)
        ZStack {
            FieldBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHero(eyebrow: BasicFile.eyebrow(entry.family),
                                title: Text(entry.name),
                                sub: BasicFile.akaLine(entry).map { Text($0) },
                                trail: [Crumb(label: "The Atlas", path: "home"),
                                        Crumb(label: "The Pitch Index", path: "repertoire"),
                                        Crumb(label: entry.name)],
                                accent: edge ? .seam : .powder) {
                        badge
                    } extra: {
                        EmptyView()
                    }
                    lede
                    if let grip {
                        // grip footage is viewed in the dark — the one coal band on the basic file
                        SpecimenGripEvidence(grip: grip, accentRGB: BasicFile.accentRGB(entry),
                                             includePhotos: true, pauseControl: true, flush: true)
                            .padding(.horizontal, 20)
                            .background(CoalScene())
                    }
                    room("01", "The grip", claim: entry.grip)
                    room("02", "What it does", claim: entry.movement)
                    if let relationship = entry.relationship {
                        room("03", "What it really is", claim: relationship)
                    }
                    if let throwers = entry.notableThrowers, !throwers.isEmpty {
                        whoThrows(throwers)
                    }
                    if let slug = entry.studyFirstSlug, let target = store.pitch(slug: slug) {
                        studyFirst(target)
                    }
                    basicFileMarker
                    familyRail
                    DiscussionDrawer(topic: .repertoire(id: entry.id), topicName: entry.name)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 48)
                    chapterNav(previous: around.previous, next: around.next)
                    SiteFooter(path: "/repertoire/\(entry.id)")
                }
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
            }
        }
        // The site's header carries the brand on every page; the title still names
        // the back button on the pages this one opens.
        .navigationTitle(entry.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { BrandLockup(size: .sm) }
        }
    }

    // MARK: - Header badge

    /// HeroBadge: the status in mono caps on a hairline box — the seam for the
    /// honest edge cases, bone for the live pitches.
    private var badge: some View {
        Text(entry.status.displayLabel.uppercased())
            .font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .caption))
            .tracking(em: 0.12, size: 12)
            .foregroundStyle(edge ? PitchAtlasTheme.seamBright : PitchAtlasTheme.bone)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .overlay(RoundedRectangle(cornerRadius: 6)
                .strokeBorder(edge ? PitchAtlasTheme.seamBright.opacity(0.5) : PitchAtlasTheme.bone.opacity(0.3), lineWidth: 1))
            .accessibilityLabel("Status: \(entry.status.displayLabel)")
    }

    // MARK: - Lede

    /// The plain-language read (or, without one, the movement claim with its
    /// tier), then the schematic cover and its honest caption.
    private var lede: some View {
        VStack(alignment: .leading, spacing: 40) {
            VStack(alignment: .leading, spacing: 12) {
                Text(entry.plain ?? entry.movement.value)
                    .font(PitchAtlasType.font(.newsreader400, size: 24, relativeTo: .title2))
                    .tracking(em: -0.012, size: 24)
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .cssLineHeight(1.375, face: .newsreader400, size: 24, relativeTo: .title2)
                    .fixedSize(horizontal: false, vertical: true)
                if entry.plain == nil {
                    ConfidenceLabel(confidence: entry.movement.confidence)
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                SchematicCover()
                    .frame(width: 208, height: 208)
                    .frame(maxWidth: .infinity)
                Text("Schematic baseball cover. This pitch has no filed seam geometry yet; the grip and shape below are sourced in words, not measured here.")
                    .font(PitchAtlasType.font(.hanken400, size: 12, relativeTo: .caption))
                    .foregroundStyle(PitchAtlasTheme.ink3)
                    .cssLineHeight(1.375, face: .hanken400, size: 12, relativeTo: .caption)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 34 * 0.56 * 12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 56)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Rooms

    /// A numbered room: the tier marker, then the claim as prose at 20 on 1.625.
    private func room(_ index: String, _ label: String, claim: Claim) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            StageTierMarker(index: index, label: label)
            ClaimProse(claim: claim, size: 20, ink: PitchAtlasTheme.bone)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 56)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Who throws it: the mono label leading the sentence, under a hairline.
    private func whoThrows(_ throwers: String) -> some View {
        (Text("Who throws it".uppercased())
            .font(MonoLabel.font)
            .tracking(MonoLabel.trackingEm * MonoLabel.size)
            .foregroundStyle(PitchAtlasTheme.ink3)
         + Text("\u{2002}")
         + Text(throwers)
            .font(PitchAtlasType.body())
            .foregroundStyle(PitchAtlasTheme.ink2))
            .cssLineHeight(1.625, face: .hanken400, size: 16, relativeTo: .body)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) { Rectangle().fill(PitchAtlasTheme.bone.opacity(0.15)).frame(height: 1) }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
    }

    // MARK: - Study this first

    /// The study hook: the filed specimen that teaches this pitch's mechanic, with
    /// its sourced bridge when one is written.
    private func studyFirst(_ target: PitchAtlasEntry) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Study this first".uppercased())
                .font(MonoLabel.font)
                .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                .foregroundStyle(PitchAtlasTheme.seamBright)
                .padding(.bottom, 12)
                .accessibilityAddTraits(.isHeader)
            if let note = entry.contextNote {
                ClaimProse(claim: note, size: 18, ink: PitchAtlasTheme.bone)
                    .padding(.bottom, 20)
            }
            NavigationLink { PitchDetailView(entry: target) } label: {
                HStack(spacing: 12) {
                    Text("Filed specimen".uppercased())
                        .font(MonoLabel.font)
                        .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                        .foregroundStyle(PitchAtlasTheme.ink3)
                    Text(target.canonical.name.uppercased())
                        .font(PitchAtlasTheme.anton(18, relativeTo: .headline))
                        .foregroundStyle(PitchAtlasTheme.bone)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("→")
                        .font(PitchAtlasType.body())
                        .foregroundStyle(PitchAtlasTheme.seamBright)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 6).fill(PitchAtlasTheme.void))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(PitchAtlasTheme.bone.opacity(0.2), lineWidth: 1))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Filed specimen: \(target.canonical.name)")
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 6).fill(PitchAtlasTheme.paper2))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(PitchAtlasTheme.bone.opacity(0.2), lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
    }

    // MARK: - The honest marker

    private var basicFileMarker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Basic file".uppercased())
                .font(MonoLabel.font)
                .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                .foregroundStyle(PitchAtlasTheme.seamBright)
            Text("This pitch has a sourced one-line grip and movement and an honest explanation, not yet a filed specimen with authored grip geometry and a full craft chapter. A fuller breakdown is coming; the source trail stays attached.")
                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.ink2)
                .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 6).fill(PitchAtlasTheme.paper2))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(PitchAtlasTheme.seamBright.opacity(0.3), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
    }

    // MARK: - The family rail

    /// FamilyRail: the rest of the family as pills in two columns, each opening
    /// its specimen or its basic file. Nothing when the family is this one pitch.
    @ViewBuilder
    private var familyRail: some View {
        let siblings = BasicFile.siblings(of: entry, in: store.repertoire.entries)
        if !siblings.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                Text(BasicFile.railHeading(entry.family).uppercased())
                    .font(PitchAtlasType.font(.martian400, size: 11, relativeTo: .caption2))
                    .tracking(em: 0.16, size: 11)
                    .foregroundStyle(PitchAtlasTheme.ink2)
                    .accessibilityAddTraits(.isHeader)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(siblings) { sibling in
                        NavigationLink { RepertoireDetailView(entry: sibling) } label: { pill(sibling) }
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 48)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) { Rectangle().fill(PitchAtlasTheme.bone.opacity(0.15)).frame(height: 1) }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Others in this family")
        }
    }

    private func pill(_ sibling: RepertoireEntry) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Circle().fill(Color(rgb: BasicFile.accentRGB(sibling))).frame(width: 10, height: 10)
                    .accessibilityHidden(true)
                Text(sibling.name)
                    .font(PitchAtlasType.font(.hanken700, size: 14, relativeTo: .subheadline))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .cssLineHeight(1.375, face: .hanken700, size: 14, relativeTo: .subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Text("→")
                .font(PitchAtlasType.font(.martian400, size: 11, relativeTo: .caption2))
                .foregroundStyle(PitchAtlasTheme.ink3)
                .accessibilityHidden(true)
        }
        .padding(.leading, 12)
        .padding(.trailing, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 44)
        .overlay(Capsule().strokeBorder(PitchAtlasTheme.bone.opacity(0.15), lineWidth: 1))
        .contentShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(sibling.filedSlug == nil ? "\(sibling.name), open basic file" : "\(sibling.name), open specimen")
    }

    // MARK: - Chapter nav

    /// ChapterNav: the previous file, the way back to the Index, the next file.
    private func chapterNav(previous: RepertoireEntry?, next: RepertoireEntry?) -> some View {
        VStack(spacing: 16) {
            if let previous {
                NavigationLink { RepertoireDetailView(entry: previous) } label: {
                    neighbor("← Previous", previous.name, alignment: .leading)
                }
                .buttonStyle(.plain)
            } else {
                // the empty grid cell still takes its gap on the site
                Color.clear.frame(height: 0).accessibilityHidden(true)
            }
            RouteButton(path: "repertoire") {
                VStack(spacing: 4) {
                    Text("The Pitch Index".uppercased())
                        .font(MonoLabel.font)
                        .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                        .foregroundStyle(PitchAtlasTheme.seamBright)
                    Text("Back to every pitch →")
                        .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                        .foregroundStyle(PitchAtlasTheme.ink2)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 44)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(PitchAtlasTheme.bone.opacity(0.15), lineWidth: 1))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if let next {
                NavigationLink { RepertoireDetailView(entry: next) } label: {
                    neighbor("Next →", next.name, alignment: .trailing)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 48)
        .background(PitchAtlasTheme.paper2)
        .overlay(alignment: .top) { Rectangle().fill(PitchAtlasTheme.bone.opacity(0.15)).frame(height: 1) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pitch index chapters")
    }

    private func neighbor(_ label: String, _ name: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(label.uppercased())
                .font(MonoLabel.font)
                .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                .foregroundStyle(PitchAtlasTheme.ink3)
            Text(name.uppercased())
                .font(PitchAtlasTheme.anton(18, relativeTo: .headline))
                .foregroundStyle(PitchAtlasTheme.bone)
                .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: alignment == .leading ? .leading : .trailing)
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(PitchAtlasTheme.bone.opacity(0.15), lineWidth: 1))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// SeamSchematic with no axis and no hand: the plain stitched cover on its floor
/// shadow. Decorative — the caption beside it says what it is and is not.
private struct SchematicCover: View {
    var body: some View {
        // the site's 240-unit drawing puts an 86-unit ball in a 208pt frame
        let radius: CGFloat = 86.0 / 240.0 * 208.0
        ZStack {
            Ellipse()
                .fill(EllipticalGradient(colors: [Color.black.opacity(0.7), .clear], center: .center,
                                         startRadiusFraction: 0, endRadiusFraction: 0.5))
                .frame(width: radius * 0.94 * 2, height: radius * 0.16 * 2)
                .offset(x: radius * 0.08, y: radius * 1.1)
            SeamBall(motion: .schematicReference, size: radius * 2 / 0.92, showMovement: false)
        }
        .accessibilityHidden(true)
    }
}
