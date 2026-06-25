import SwiftUI

// =============================================================================
// Pitch Atlas — The Grip Library
// =============================================================================
// First-party grip photography plus the owner's own first-person account of how
// he grips and throws each pitch. This is the one surface in the app built from
// the owner's hand, not from a measured source — so every record wears the
// "not tracked data" tag and its own proof limit. Nothing here is fabricated:
// the screen renders only what the bundled GripsFile carries, and omits any
// optional field that is absent rather than inventing a stand-in.
// =============================================================================

struct GripsView: View {
    @Environment(PitchStore.self) private var store

    var body: some View {
        ZStack {
            FieldBackdrop()

            content
        }
        .navigationTitle("Grips")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Four states

    @ViewBuilder
    private var content: some View {
        if case .failed(let msg) = store.status {
            ScrollView {
                ErrorStateView(reason: msg)
                    .padding(PitchAtlasSpacing.lg)
                    .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
            }
        } else if store.grips.entries.isEmpty {
            ScrollView {
                VStack(spacing: PitchAtlasSpacing.lg) {
                    masthead
                    EmptyStateView(message: "The grip library couldn't load.")
                }
                .padding(PitchAtlasSpacing.lg)
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
            }
        } else {
            populated
        }
    }

    // MARK: - Populated

    private var populated: some View {
        ScrollView {
            // LazyVStack so the heavy grip entries — each can carry a looping
            // AVPlayer film card and several decoded webp photos — instantiate only
            // as they scroll into view, instead of all ~dozen building (and spinning
            // up players) at once on first paint.
            LazyVStack(alignment: .leading, spacing: PitchAtlasSpacing.xl) {
                masthead
                honestyBanner
                gripThumbnailRail
                arsenalCard
                commandCard
                attackPlanCard

                ForEach(store.grips.entries) { entry in
                    gripEntrySection(entry)
                }
            }
            .padding(PitchAtlasSpacing.lg)
            .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
            .emitsBlazeScrollProgress()
        }
    }

    // MARK: - Masthead

    private var masthead: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "The Grip Library", color: PitchAtlasTheme.powder)

            Text("GRIPS")
                .font(PitchAtlasTheme.anton(56))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
                .padding(.vertical, PitchAtlasSpacing.xs)

            if !store.grips.intro.isEmpty {
                Text(store.grips.intro)
                    .font(PitchAtlasTheme.newsreader(16))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            BlazeInlineCompanionView(style: .grips, mood: .sniffing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("The Grip Library. Grips. \(store.grips.intro)")
    }

    private var gripThumbnailRail: some View {
        let entries = Array(store.grips.entries.prefix(5))
        return VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "First-party grip files", color: PitchAtlasTheme.powder)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PitchAtlasSpacing.sm) {
                    ForEach(entries) { entry in
                        CompactGripThumbnail(entry: entry)
                    }
                }
                .padding(.vertical, PitchAtlasSpacing.xs2)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("First-party grip files, horizontally scrollable")
    }

    // MARK: - Honesty banner (proof limit, shown once near the top)

    @ViewBuilder
    private var honestyBanner: some View {
        if !store.grips.proofLimit.isEmpty {
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
                SectionLabel(text: "Not tracked data", color: PitchAtlasTheme.ink3)
                Text(store.grips.proofLimit)
                    .font(PitchAtlasTheme.hanken(14))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .leatherPress()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Not tracked data. \(store.grips.proofLimit)")
        }
    }

    // MARK: - Arsenal

    @ViewBuilder
    private var arsenalCard: some View {
        if !store.grips.arsenal.isEmpty {
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
                SectionLabel(text: "The Arsenal")
                Text(store.grips.arsenal)
                    .font(PitchAtlasTheme.hanken(15))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .leatherPress()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("The Arsenal. \(store.grips.arsenal)")
        }
    }

    // MARK: - Command

    @ViewBuilder
    private var commandCard: some View {
        if !store.grips.commandNote.isEmpty {
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
                SectionLabel(text: "Command")
                Text(store.grips.commandNote)
                    .font(PitchAtlasTheme.hanken(15))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .leatherPress()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Command. \(store.grips.commandNote)")
        }
    }

    // MARK: - Attack plan

    private var attackPlanCard: some View {
        let plan = store.grips.attackPlan
        return VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: plan.sequenceTitle)

            if !plan.intro.isEmpty {
                Text(plan.intro)
                    .font(PitchAtlasTheme.hanken(15))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !plan.sequenceNote.isEmpty {
                Text(plan.sequenceNote)
                    .font(PitchAtlasTheme.newsreaderItalic(15))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !plan.sequence.isEmpty {
                HairlineDivider()
                    .padding(.vertical, PitchAtlasSpacing.xs2)

                VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                    ForEach(Array(plan.sequence.enumerated()), id: \.offset) { index, step in
                        attackStepRow(number: index + 1, step: step)
                    }
                }
            }
        }
        .leatherPress()
    }

    private func attackStepRow(number: Int, step: GripAttackStep) -> some View {
        HStack(alignment: .top, spacing: PitchAtlasSpacing.sm) {
            Text("\(number)")
                .font(PitchAtlasTheme.martian(12))
                .foregroundStyle(PitchAtlasTheme.cyan)
                .frame(width: 20, alignment: .leading)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs2) {
                Text(step.label)
                    .font(PitchAtlasTheme.hankenMedium(15))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .fixedSize(horizontal: false, vertical: true)
                Text(step.detail)
                    .font(PitchAtlasTheme.hanken(14))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number). \(step.label). \(step.detail)")
    }

    // MARK: - Grip entry section

    private func gripEntrySection(_ entry: GripEntry) -> some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            // Heading: family dot + label in Anton.
            HStack(alignment: .center, spacing: PitchAtlasSpacing.sm) {
                FamilyDot(color: entry.family.accent, size: 9)
                Text(entry.label.uppercased())
                    .font(PitchAtlasTheme.anton(24))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .antonSkew()
            }
            .padding(.bottom, PitchAtlasSpacing.xs2)

            // The owner's cues.
            if !entry.shortCue.isEmpty {
                Text(entry.shortCue)
                    .font(PitchAtlasTheme.newsreaderItalic(16))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !entry.visibleCue.isEmpty {
                Text(entry.visibleCue)
                    .font(PitchAtlasTheme.hanken(15))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(PitchAtlasTheme.hanken(14))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let movement = entry.movement, !movement.isEmpty {
                HStack(alignment: .top, spacing: PitchAtlasSpacing.xs) {
                    SectionLabel(text: "Movement", color: entry.family.accent, size: 9)
                    Text(movement)
                        .font(PitchAtlasTheme.hanken(14))
                        .foregroundStyle(PitchAtlasTheme.bone)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, PitchAtlasSpacing.xs2)
            }

            // The film leads when one is on file — the owner's hand in motion.
            if let film = entry.film {
                GripFilmCard(film: film, height: 360)
                    .padding(.top, PitchAtlasSpacing.xs)
            }

            // Photos — or an honest "no photos on file" line, never a gray box.
            if entry.photos.isEmpty {
                Text("Photos: \(entry.photoStatus ?? "none on file")")
                    .font(PitchAtlasTheme.hanken(13))
                    .foregroundStyle(PitchAtlasTheme.ink3)
                    .padding(.top, PitchAtlasSpacing.xs2)
            } else {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.md) {
                    ForEach(Array(entry.photos.enumerated()), id: \.offset) { _, photo in
                        GripPhotoTile(photo: photo)
                    }
                }
                .padding(.top, PitchAtlasSpacing.xs)
            }

            HairlineDivider()
                .padding(.vertical, PitchAtlasSpacing.xs)

            // Footer: proof limit + the claim tier in its tier color.
            if !entry.proofLimit.isEmpty {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs2) {
                    SectionLabel(text: "Proof limit")
                    Text(entry.proofLimit)
                        .font(PitchAtlasTheme.hanken(13))
                        .foregroundStyle(PitchAtlasTheme.ink3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: PitchAtlasSpacing.xs) {
                ProvenanceDot(confidence: entry.claimTier)
                SectionLabel(text: entry.claimTier.label, color: entry.claimTier.tierColor, size: 9)
            }
            .padding(.top, PitchAtlasSpacing.xs2)
        }
        .leatherPress()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entryAccessibilityLabel(entry))
    }

    // MARK: - Accessibility

    private func entryAccessibilityLabel(_ entry: GripEntry) -> String {
        var parts: [String] = [entry.label]
        if !entry.shortCue.isEmpty { parts.append(entry.shortCue) }
        if !entry.visibleCue.isEmpty { parts.append(entry.visibleCue) }
        if !entry.note.isEmpty { parts.append(entry.note) }
        if let movement = entry.movement, !movement.isEmpty {
            parts.append("Movement. \(movement)")
        }
        if entry.film != nil {
            parts.append("Grip film on file")
        }
        if entry.photos.isEmpty {
            parts.append("Photos: \(entry.photoStatus ?? "none on file")")
        } else {
            parts.append("\(entry.photos.count) grip \(entry.photos.count == 1 ? "photo" : "photos")")
        }
        if !entry.proofLimit.isEmpty { parts.append("Proof limit. \(entry.proofLimit)") }
        parts.append(entry.claimTier.label)
        return parts.joined(separator: ". ")
    }
}

private struct CompactGripThumbnail: View {
    let entry: GripEntry

    private var thumbnail: (src: String, alt: String)? {
        if let film = entry.film {
            return (film.poster, film.clip.alt)
        }
        if let photo = entry.photos.first {
            return (photo.src, photo.alt)
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            Group {
                if let thumbnail {
                    BundledImage(src: thumbnail.src, alt: thumbnail.alt)
                } else {
                    ZStack {
                        PitchAtlasTheme.paper2
                        SealMark(size: 42)
                    }
                }
            }
            .frame(width: 126, height: 92)
            .clipShape(RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous).stroke(PitchAtlasTheme.machined))

            Text(entry.label)
                .font(PitchAtlasTheme.hankenMedium(12))
                .foregroundStyle(PitchAtlasTheme.bone)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: PitchAtlasSpacing.xs2) {
                FamilyDot(color: entry.family.accent, size: 6)
                Text("NOT TRACKED DATA")
                    .font(PitchAtlasTheme.martian(7))
                    .tracking(0.6)
                    .foregroundStyle(PitchAtlasTheme.bone2)
            }
        }
        .frame(width: 126, alignment: .leading)
        .padding(PitchAtlasSpacing.xs)
        .background(PitchAtlasTheme.paper2.opacity(0.9), in: RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous).stroke(PitchAtlasTheme.machined))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.label). First-party grip file. Not tracked data.")
    }
}
