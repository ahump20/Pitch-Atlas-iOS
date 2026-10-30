import SwiftUI

// =============================================================================
// Pitch Atlas — the Lost Pitches hall's rooms
// =============================================================================
// Web: sections/WhyPitchesDie.tsx, lost-pitches/EraTimeline.tsx and
// lost-pitches/ArchiveImageRail.tsx. The through-line (four forces and the
// receipts under each), the record laid against the decades, and the image
// record (its counts, then every filed plate). Each reads only what the bundle
// carries; a room with nothing filed under it draws nothing.
// =============================================================================

// MARK: - Why pitches die

/// WhyPitchesDie: the spine under the tiered entries. A section rule and the
/// seam's tear, the section number, the title and its lede, then each force on
/// a seam rule: its era, its heading, its account, and the sourced statements
/// the account paraphrases, filed as claim cards.
struct WhyPitchesDie: View {
    let forces: [LostPitchForce]

    var body: some View {
        if !forces.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                SeamGuide(variant: .tear).opacity(0.6)
                VStack(alignment: .leading, spacing: 0) {
                    // .archive-section__no: mono 10 on the body's 1.5 line
                    Text("The Through-Line".uppercased())
                        .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                        .tracking(em: 0.18, size: 10)
                        .foregroundStyle(PitchAtlasTheme.ink3)
                        .cssLineHeight(1.5, face: .martian400, size: 10, relativeTo: .caption2)
                    TightLines("Why pitches die.".uppercased(), face: .anton400, size: 30, lineHeight: 1.25,
                               relativeTo: .title, balanced: true)
                        .foregroundStyle(PitchAtlasTheme.bone)
                        .padding(.top, 8)
                        .accessibilityAddTraits(.isHeader)
                    // Verbatim, WhyPitchesDie.tsx.
                    Text("An archive of lost pitches is really an archive of how pitches get lost. Four forces take a pitch out of the game. The entries below are what each one left behind.")
                        .font(PitchAtlasType.font(.hanken400, size: 16, relativeTo: .body))
                        .foregroundStyle(PitchAtlasTheme.ink2)
                        .cssLineHeight(1.625, face: .hanken400, size: 16, relativeTo: .body)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 68 * 0.56 * 16, alignment: .leading)
                        .padding(.top, 16)
                    VStack(alignment: .leading, spacing: 40) {
                        ForEach(forces, id: \.heading) { ForceRoom(force: $0) }
                    }
                    .padding(.top, 48)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 64)
            }
            .padding(.top, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) { SectionRule() }
        }
    }
}

/// One force: the era on the row's 24pt line, the heading in athletic type, the
/// account, and its receipts, all on a 2pt seam rule.
private struct ForceRoom: View {
    let force: LostPitchForce

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // The era is a mono span on its block's 16/24 line; the line holds it 6 down.
            Text(force.era.uppercased())
                .font(MonoLabel.font)
                .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                .foregroundStyle(PitchAtlasTheme.seamBright)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
                .frame(minHeight: 24, alignment: .top)
            VStack(alignment: .leading, spacing: 0) {
                TightLines(force.heading.uppercased(), face: .anton400, size: 20, lineHeight: 1.4, relativeTo: .title3)
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .accessibilityAddTraits(.isHeader)
                Text(force.body)
                    .font(PitchAtlasType.font(.hanken400, size: 16, relativeTo: .body))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .cssLineHeight(1.625, face: .hanken400, size: 16, relativeTo: .body)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 64 * 0.56 * 16, alignment: .leading)
                    .padding(.top, 8)
                VStack(spacing: 12) {
                    ForEach(Array(force.claims.enumerated()), id: \.offset) { _, claim in
                        ClaimCard(claim: claim)
                    }
                }
                .padding(.top, 16)
            }
        }
        .padding(.leading, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .leading) {
            Rectangle().fill(PitchAtlasTheme.seamBright.opacity(0.4)).frame(width: 2).accessibilityHidden(true)
        }
        .accessibilityElement(children: .contain)
    }
}

/// `.archive-section::before`: ink-3 at 38% out to 64% of the width, then gone.
private struct SectionRule: View {
    var body: some View {
        Rectangle()
            .fill(LinearGradient(stops: [.init(color: PitchAtlasTheme.ink3.opacity(0.38), location: 0),
                                         .init(color: PitchAtlasTheme.ink3.opacity(0.38), location: 0.64),
                                         .init(color: .clear, location: 1)],
                                 startPoint: .leading, endPoint: .trailing))
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

// MARK: - The record, in time

/// EraTimeline: every recovered plate laid to scale against the decades, a lane
/// per documentation tier in that tier's trust ink, each marker the plate's
/// number and a way into its file. The scale is the reading, so the chart holds
/// its type at the largest standard size; each marker still names its pitch,
/// tier and era to VoiceOver, and the tiers below list the same files in full.
struct EraTimeline: View {
    let root: LostPitchesRoot

    /// `--row-h` on touch: every marker a full 44pt target.
    static let rowHeight: CGFloat = 44

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("The record, in time".uppercased())
                .font(MonoLabel.font)
                .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                .foregroundStyle(PitchAtlasTheme.seamBright)
                .cssLineHeight(1, face: .martian400, size: MonoLabel.size, relativeTo: .caption2)
            // .rfx-stitle at clamp(24px, 3.6vw, 40px), leading 1.04, max 20ch
            // (Anton's zero is .494em wide).
            TightLines("When the lost pitches cluster.".uppercased(), face: .anton400, size: 24, lineHeight: 1.04,
                       relativeTo: .title2, balanced: true)
                .foregroundStyle(PitchAtlasTheme.bone)
                .frame(maxWidth: 20 * 0.494 * 24, alignment: .leading)
                .padding(.top, 12)
                .accessibilityAddTraits(.isHeader)
            // Verbatim, EraTimeline.tsx.
            Text("Every recovered plate, laid against the decades and colored by how solid the record is. The cluster in the 1920s is the doctored-ball and Paige-named cohort; the color is the honesty. Each marker opens its file.")
                .font(PitchAtlasType.font(.hanken400, size: 16, relativeTo: .body))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 16, relativeTo: .body)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 64 * 0.56 * 16, alignment: .leading)
                .padding(.top, 16)
            panel.padding(.top, 36)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 64)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            axis
            VStack(alignment: .leading, spacing: 28) {
                // A tier with nothing filed under it draws no lane, as the site's Lane returns null.
                ForEach(LostArchiveReads.tierGroups(root)) { lane($0.info, entries: $0.entries) }
            }
            .padding(.top, 20)
        }
        .padding(21)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 6).fill(ArchiveInk.timelinePanel))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(PitchAtlasTheme.bone.opacity(0.1), lineWidth: 1))
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    /// The decade axis: each decade's name centered on its year, over a bone rule.
    private var axis: some View {
        GeometryReader { geo in
            ForEach(LostTimeline.decades, id: \.self) { decade in
                Text("\(decade)s".uppercased())
                    .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                    .tracking(em: 0.1, size: 10)
                    .foregroundStyle(PitchAtlasTheme.bone2.opacity(0.75))
                    .fixedSize()
                    .position(x: geo.size.width * LostTimeline.position(Double(decade)), y: 7.5)
            }
        }
        .frame(height: 20)
        .overlay(alignment: .bottom) {
            Rectangle().fill(PitchAtlasTheme.bone.opacity(0.12)).frame(height: 1).accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }

    private func lane(_ info: LostPitchTierInfo, entries: [LostPitch]) -> some View {
        let packed = LostTimeline.pack(entries)
        let ink = info.tier.tone
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Circle().fill(ink).frame(width: 10, height: 10).accessibilityHidden(true)
                (Text(info.label.uppercased())
                    + Text(" \u{00B7} \(entries.count)").foregroundStyle(PitchAtlasTheme.bone2.opacity(0.75)))
                    .font(MonoLabel.font)
                    .tracking(MonoLabel.trackingEm * MonoLabel.size)
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .cssLineHeight(1, face: .martian400, size: MonoLabel.size, relativeTo: .caption2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            GeometryReader { geo in
                ForEach(packed.placed) { placed in
                    NavigationLink(value: placed.pitch) { marker(placed, ink: ink) }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(placed.pitch.name), \(info.label.lowercased()), \(placed.pitch.era)")
                        .accessibilityHint("Opens the file")
                        .offset(x: geo.size.width * placed.left, y: CGFloat(placed.row) * Self.rowHeight)
                }
            }
            .frame(height: CGFloat(packed.rows) * Self.rowHeight)
        }
    }

    /// The dot and the plate's number (the year joins it only at desktop widths).
    private func marker(_ placed: LostTimeline.Placed, ink: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(ink).frame(width: 10, height: 10)
            Text(placed.pitch.specimenNo.uppercased())
                .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                .tracking(em: 0.08, size: 10)
                .foregroundStyle(PitchAtlasTheme.bone2.opacity(0.75))
                .fixedSize()
        }
        .frame(height: Self.rowHeight)
        .contentShape(Rectangle())
    }
}

// MARK: - The image record

/// ArchiveImageRail: "I Image record" on the film frame's near-black, between
/// two bone hairlines. The title and its lede, the three counts, then every
/// filed plate.
struct LostArchiveImageRail: View {
    let images: [ArchiveImage]

    var body: some View {
        if !images.isEmpty {
            let stats = LostArchiveReads.stats(images)
            VStack(alignment: .leading, spacing: 0) {
                StageTierMarker(index: "I", label: "Image record")
                // .display, text-4xl, leading-none, max 10ch
                Text("Give the record a filed image.")
                    .font(PitchAtlasType.font(.newsreader400, size: 36, relativeTo: .largeTitle))
                    .tracking(em: -0.012, size: 36)
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .cssLineHeight(1, face: .newsreader400, size: 36, relativeTo: .largeTitle)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 10 * 0.5665 * 36, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                // Verbatim, ArchiveImageRail.tsx.
                Text("The lost-pitches wing can carry historical material without pretending the grip survived. Each entry now gets a public-domain plate or a first-party study, and the card says which one it is.")
                    .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 48 * 0.56 * 14, alignment: .leading)
                    .padding(.top, 16)
                HStack(alignment: .top, spacing: 8) {
                    count(stats.filed, "plates filed")
                    count(stats.publicDomain, "public domain")
                    count(stats.original, "original")
                }
                .padding(13)
                .background(RoundedRectangle(cornerRadius: 6).fill(PitchAtlasTheme.void.opacity(0.5)))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(PitchAtlasTheme.bone.opacity(0.1), lineWidth: 1))
                .padding(.top, 32)
                // Lazy so each plate decodes its image only as it scrolls in.
                LazyVStack(spacing: 16) {
                    ForEach(images) { ArchiveImageCard(image: $0) }
                }
                .padding(.top, 40)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 65)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ArchiveInk.filmFrame)
            .overlay(alignment: .top) { Rectangle().fill(PitchAtlasTheme.bone.opacity(0.1)).frame(height: 1).accessibilityHidden(true) }
            .overlay(alignment: .bottom) { Rectangle().fill(PitchAtlasTheme.bone.opacity(0.1)).frame(height: 1).accessibilityHidden(true) }
        }
    }

    /// One count: the number in athletic type, its name in the mono label under it.
    private func count(_ value: Int, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TightLines("\(value)", face: .anton400, size: 30, lineHeight: 1, relativeTo: .title)
                .foregroundStyle(PitchAtlasTheme.bone)
            Text(label.uppercased())
                .font(MonoLabel.font)
                .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                .foregroundStyle(PitchAtlasTheme.ink2)
                .cssLineHeight(1, face: .martian400, size: MonoLabel.size, relativeTo: .caption2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// ArchiveImageCard: a filed plate on press stock. The frame (the image at 4:3,
/// in grayscale), its label and kind, the title, the caption, the quality note,
/// its rights and source, and the way to the file it belongs to. On that file's
/// own page (`detail`) the words sit 20 under the frame and the way back to the
/// same page is left off. The site files newsreel context under two plates but
/// shows none of it, so neither does the app.
struct ArchiveImageCard: View {
    enum Variant { case grid, detail }

    let image: ArchiveImage
    var variant: Variant = .grid

    @Environment(PitchStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: variant == .detail ? 20 : 16) {
            frame
            words
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 6).fill(PitchAtlasTheme.press))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(PitchAtlasTheme.bone.opacity(0.1), lineWidth: 1))
        .accessibilityElement(children: .contain)
    }

    private var frame: some View {
        Color.clear
            .aspectRatio(4.0 / 3.0, contentMode: .fit)
            .overlay {
                BundledImage(src: image.imageSrc, alt: image.alt, contentMode: .fill)
                    .grayscale(1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .padding(1)
            .background(RoundedRectangle(cornerRadius: 6).fill(ArchiveInk.mediaField))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(PitchAtlasTheme.bone.opacity(0.15), lineWidth: 1).accessibilityHidden(true))
    }

    private var words: some View {
        VStack(alignment: .leading, spacing: 0) {
            // flex-wrap, justify-between: one line when both fit, else the kind drops under.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    mono(image.label, ink: PitchAtlasTheme.bone2).fixedSize()
                    Spacer(minLength: 0)
                    mono(LostArchiveReads.kindLine(image), ink: PitchAtlasTheme.cyan).fixedSize()
                }
                VStack(alignment: .leading, spacing: 8) {
                    mono(image.label, ink: PitchAtlasTheme.bone2)
                    mono(LostArchiveReads.kindLine(image), ink: PitchAtlasTheme.cyan)
                }
            }
            TightLines(image.title.uppercased(), face: .anton400, size: 24, lineHeight: 1, relativeTo: .title2)
                .foregroundStyle(PitchAtlasTheme.bone)
                .padding(.top, 12)
                .accessibilityAddTraits(.isHeader)
            Text(image.caption)
                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            Text(image.qualityNote)
                .font(PitchAtlasType.font(.hanken400, size: 12, relativeTo: .caption))
                .foregroundStyle(PitchAtlasTheme.ink2)
                .cssLineHeight(1.625, face: .hanken400, size: 12, relativeTo: .caption)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
            FlowRow(spacing: 8, lineSpacing: 4, rowAlignment: .center) {
                mono(LostArchiveReads.rightsLine(image), ink: PitchAtlasTheme.cyan)
                if let source = image.source {
                    Text("/")
                        .font(PitchAtlasType.body())
                        .foregroundStyle(PitchAtlasTheme.ink3)
                        .cssLineHeight(1.5, face: .hanken400, size: 16, relativeTo: .body)
                        .accessibilityHidden(true)
                    RefractorSourceLink(source: source, ground: .panel)
                }
            }
            .padding(.top, 12)
            if variant == .grid, let pitch = store.lostPitch(slug: image.relatedSlug) {
                NavigationLink(value: pitch) {
                    HStack(alignment: .center, spacing: 0) {
                        mono(LostArchiveReads.openLine(image), ink: PitchAtlasTheme.bone2)
                        mono("→", ink: PitchAtlasTheme.bone2).accessibilityHidden(true)
                    }
                    .frame(minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(LostArchiveReads.openLine(image))
                .padding(.top, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func mono(_ text: String, ink: Color) -> some View {
        Text(text.uppercased())
            .font(MonoLabel.font)
            .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
            .foregroundStyle(ink)
            .cssLineHeight(1, face: .martian400, size: MonoLabel.size, relativeTo: .caption2)
            .fixedSize(horizontal: false, vertical: true)
    }
}
