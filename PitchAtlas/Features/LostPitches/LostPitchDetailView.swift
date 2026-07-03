import SwiftUI

// =============================================================================
// Pitch Atlas — Lost Pitch record
// =============================================================================
// A single lost pitch read in full. What it was, why it's lost, the numbers that
// could be recovered — each carrying its source — and a footer that restates what
// this pitch's documentation tier actually means. Every measured value goes
// through its provenance so a thin record reads as thin, never as fact.
// =============================================================================

struct LostPitchDetailView: View {
    @Environment(PitchStore.self) private var store
    @Environment(\.openURL) private var openURL
    let pitch: LostPitch

    /// The tier legend entry that matches this pitch's tier, if it shipped.
    private var tierInfo: LostPitchTierInfo? {
        store.lostPitches.tiers.first { $0.tier == pitch.tier }
    }

    var body: some View {
        ZStack {
            FieldBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.lg) {
                    header
                    introCard
                    archivePlate
                    whatItWas
                    whyItsLost
                    numbers
                    quote
                    tierFooter
                }
                .padding(.horizontal, PitchAtlasSpacing.lg)
                .padding(.top, PitchAtlasSpacing.md)
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
            }
        }
        .navigationTitle(pitch.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            HStack {
                SectionLabel(text: pitch.specimenNo, color: PitchAtlasTheme.cyanDeep, size: 9)
                Spacer()
                StatusPill(text: pitch.tier.label, tone: pitch.tier.tone)
            }

            Text(pitch.name.uppercased())
                .font(PitchAtlasTheme.anton(44))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
                .padding(.vertical, 2)

            Text(pitch.era)
                .font(PitchAtlasTheme.martian(10))
                .foregroundStyle(PitchAtlasTheme.ink3)

            Text(pitch.tagline)
                .font(PitchAtlasTheme.newsreaderItalic(18))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, PitchAtlasSpacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pitch.name), \(pitch.tier.label), \(pitch.era). \(pitch.tagline)")
    }

    // MARK: - Intro

    private var introCard: some View {
        Text(pitch.intro)
            .font(PitchAtlasTheme.hanken(16))
            .foregroundStyle(PitchAtlasTheme.bone2)
            .fixedSize(horizontal: false, vertical: true)
            .leatherPress()
    }

    // MARK: - Archive plate (the filed image record)

    /// Give the record a face before the prose: the one verified public-domain
    /// photo plate or first-party study filed for this pitch, with its rights
    /// label and source. Renders only when a plate shipped; a missing plate image
    /// falls to BundledImage's seal, never a gray box.
    @ViewBuilder
    private var archivePlate: some View {
        if let image = store.archiveImage(forLostPitch: pitch.slug) {
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                HStack {
                    SectionLabel(text: image.label, size: 9)
                    Spacer()
                    SectionLabel(text: image.plateKind.label, color: PitchAtlasTheme.cyanDeep, size: 9)
                }

                BundledImage(src: image.imageSrc, alt: image.alt, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                Text(image.caption)
                    .font(PitchAtlasTheme.hanken(14))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(image.qualityNote)
                    .font(PitchAtlasTheme.martian(9))
                    .foregroundStyle(PitchAtlasTheme.ink3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: PitchAtlasSpacing.xs) {
                    Text(image.rights.label.uppercased())
                        .font(PitchAtlasTheme.martian(9))
                        .tracking(1.0)
                        .foregroundStyle(PitchAtlasTheme.cyan)
                    if let source = image.source {
                        Text("\u{00B7}")
                            .font(PitchAtlasTheme.martian(9))
                            .foregroundStyle(PitchAtlasTheme.ink3)
                        Text(source.label)
                            .font(PitchAtlasTheme.martian(9))
                            .foregroundStyle(PitchAtlasTheme.ink3)
                            .lineLimit(2)
                    }
                }

                if let video = image.video {
                    archiveFilm(video)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .leatherPress()
            .accessibilityElement(children: .combine)
            .accessibilityLabel(plateAccessibilityLabel(image))
        }
    }

    /// Archival film card: motion stays at its official archive. iOS shows the
    /// credit, the linked-only rights label, and a button that opens the archive
    /// page out to Safari. No third-party player is embedded inline, and nothing
    /// is rehosted; the bytes never enter the bundle.
    @ViewBuilder
    private func archiveFilm(_ video: ArchiveFilm) -> some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            SectionLabel(text: "Archival film", color: PitchAtlasTheme.cyanDeep, size: 9)

            Text(video.caption.value)
                .font(PitchAtlasTheme.hanken(13))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: PitchAtlasSpacing.xs) {
                Text(video.rights.label.uppercased())
                    .font(PitchAtlasTheme.martian(9))
                    .tracking(1.0)
                    .foregroundStyle(PitchAtlasTheme.cyan)
                if let source = video.caption.source {
                    Text("\u{00B7}")
                        .font(PitchAtlasTheme.martian(9))
                        .foregroundStyle(PitchAtlasTheme.ink3)
                    Text(source.label)
                        .font(PitchAtlasTheme.martian(9))
                        .foregroundStyle(PitchAtlasTheme.ink3)
                        .lineLimit(2)
                }
            }

            Button {
                if let url = URL(string: video.url) { openURL(url) }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.rectangle")
                    Text("Watch at the archive")
                    Text("\u{2197}")
                }
                .font(PitchAtlasTheme.martian(10))
                .tracking(0.6)
                .foregroundStyle(PitchAtlasTheme.bone)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(PitchAtlasTheme.bone.opacity(0.22))
                )
            }
            .buttonStyle(.plain)

            Text("Embedded from the Internet Archive, not rehosted.")
                .font(PitchAtlasTheme.martian(8))
                .foregroundStyle(PitchAtlasTheme.ink3)
        }
        .padding(PitchAtlasSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(PitchAtlasTheme.bone.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(PitchAtlasTheme.bone.opacity(0.10))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Archival film. \(video.caption.value). Linked only. Opens the Internet Archive.")
    }

    private func plateAccessibilityLabel(_ image: ArchiveImage) -> String {
        var parts = ["\(image.label). \(image.caption)", image.rights.label]
        if let source = image.source { parts.append("source, \(source.label)") }
        return parts.joined(separator: ". ")
    }

    // MARK: - What it was

    private var whatItWas: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "What it was", size: 9)
            ClaimText(claim: pitch.what)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .leatherPress()
    }

    // MARK: - Why it's lost

    private var whyItsLost: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "Why it's lost", size: 9)
            ClaimText(claim: pitch.whyLost)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .leatherPress()
    }

    // MARK: - Numbers (the part that can be recovered)

    @ViewBuilder
    private var numbers: some View {
        if !pitch.recordEntries.isEmpty {
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                SectionLabel(text: "What the record gives back", size: 9)
                ForEach(Array(pitch.recordEntries.enumerated()), id: \.offset) { _, item in
                    GaugeView(label: item.label, claim: item.claim)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Quote

    @ViewBuilder
    private var quote: some View {
        if let q = pitch.quote {
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                Text("\u{201C}\(q.value)\u{201D}")
                    .font(PitchAtlasTheme.newsreader(20))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .fixedSize(horizontal: false, vertical: true)
                SourceClaimLabel(claim: q)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .leatherPress()
        }
    }

    // MARK: - Tier footer (restates what this pitch's tier means)

    @ViewBuilder
    private var tierFooter: some View {
        if let info = tierInfo {
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                StatusPill(text: pitch.tier.label, tone: pitch.tier.tone)
                Text(info.note)
                    .font(PitchAtlasTheme.hanken(14))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .leatherPress()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(pitch.tier.label). \(info.note)")
        }
    }
}
