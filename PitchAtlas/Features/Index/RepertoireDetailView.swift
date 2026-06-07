import SwiftUI

// =============================================================================
// Pitch Atlas — Repertoire detail (the basic pitch read)
// =============================================================================
// The detail behind an index row. Specimen-style header, the plain-English lede,
// then the grip and movement as sourced claims. Aliases, illusions, and not-a-
// pitch entries get a "what it really is" card so the honest label is the point.
// When a fuller filed specimen exists it offers a push to it; when it doesn't, it
// says so plainly rather than dangling a dead link.
// =============================================================================

struct RepertoireDetailView: View {
    @Environment(PitchStore.self) private var store
    let entry: RepertoireEntry

    /// The filed specimen this entry points to, if one is actually bundled.
    private var filedEntry: PitchAtlasEntry? {
        guard let slug = entry.filedSlug else { return nil }
        return store.pitch(slug: slug)
    }

    var body: some View {
        ZStack {
            PitchAtlasTheme.void.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xl) {
                    header

                    if let plain = entry.plain, !plain.isEmpty {
                        ledeCard(plain)
                    }

                    claimSection(label: "Grip", claim: entry.grip)
                    claimSection(label: "Movement", claim: entry.movement)

                    if let velocity = entry.velocity, !velocity.isEmpty {
                        velocitySection(velocity)
                    }

                    if let relationship = entry.relationship {
                        relationshipCard(relationship)
                    }

                    if let throwers = entry.notableThrowers, !throwers.isEmpty {
                        thrownBySection(throwers)
                    }

                    filedSpecimenLink
                }
                .padding(.horizontal, PitchAtlasSpacing.lg)
                .padding(.top, PitchAtlasSpacing.md)
                .padding(.bottom, PitchAtlasSpacing.xl4)
            }
        }
        .navigationTitle(entry.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: PitchAtlasEntry.self) { PitchDetailView(entry: $0) }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            HStack(spacing: PitchAtlasSpacing.xs) {
                FamilyDot(color: entry.family.accent)
                SectionLabel(text: entry.family.rawValue, color: entry.family.accent)
            }

            Text(entry.name.uppercased())
                .font(PitchAtlasTheme.anton(44))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
                .padding(.vertical, 2)

            StatusPill(text: entry.status.displayLabel, tone: entry.status.tone)

            if let aka = entry.aka, !aka.isEmpty {
                Text("also: \(aka.joined(separator: ", "))")
                    .font(PitchAtlasTheme.newsreaderItalic(15))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(headerAccessibility)
    }

    private var headerAccessibility: String {
        var parts = ["\(entry.name), \(entry.family.label)", entry.status.displayLabel]
        if let aka = entry.aka, !aka.isEmpty {
            parts.append("also known as \(aka.joined(separator: ", "))")
        }
        return parts.joined(separator: ". ")
    }

    // MARK: - Lede

    private func ledeCard(_ plain: String) -> some View {
        Text(plain)
            .font(PitchAtlasTheme.hanken(16))
            .foregroundStyle(PitchAtlasTheme.bone)
            .fixedSize(horizontal: false, vertical: true)
            .leatherPress()
            .accessibilityLabel(plain)
    }

    // MARK: - Sourced claim section

    private func claimSection(label: String, claim: Claim) -> some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: label)
            ClaimText(claim: claim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .leatherPress()
    }

    // MARK: - Velocity

    private func velocitySection(_ velocity: String) -> some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            SectionLabel(text: "Velocity", size: 9)
            Text(velocity)
                .font(PitchAtlasTheme.newsreader(24))
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .leatherPress(padding: PitchAtlasSpacing.sm, radius: PitchAtlasRadius.panel)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Velocity, \(velocity)")
    }

    // MARK: - Relationship (alias / illusion / not-a-pitch)

    private func relationshipCard(_ relationship: Claim) -> some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "What it really is", color: PitchAtlasTheme.amberBright)
            ClaimText(claim: relationship)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .leatherPress()
    }

    // MARK: - Thrown by

    private func thrownBySection(_ throwers: String) -> some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            SectionLabel(text: "Thrown by")
            Text(throwers)
                .font(PitchAtlasTheme.hanken(15))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .leatherPress()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Thrown by, \(throwers)")
    }

    // MARK: - Filed specimen link (honest about absence)

    @ViewBuilder
    private var filedSpecimenLink: some View {
        if let filed = filedEntry {
            NavigationLink(value: filed) {
                HStack(spacing: PitchAtlasSpacing.sm) {
                    VStack(alignment: .leading, spacing: 2) {
                        SectionLabel(text: "Filed specimen", color: PitchAtlasTheme.cyan, size: 9)
                        Text("View the filed specimen")
                            .font(PitchAtlasTheme.hankenMedium(16))
                            .foregroundStyle(PitchAtlasTheme.cyan)
                    }
                    Spacer(minLength: PitchAtlasSpacing.xs)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(PitchAtlasTheme.cyan)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .leatherPress(padding: PitchAtlasSpacing.md, radius: PitchAtlasRadius.panel)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("View the filed specimen for \(entry.name)")
            .accessibilityAddTraits(.isButton)
        } else {
            SectionLabel(text: "Fuller breakdown coming", color: PitchAtlasTheme.ink3, size: 9)
                .padding(.top, PitchAtlasSpacing.xs)
        }
    }
}
