import SwiftUI

// =============================================================================
// Pitch Atlas — About
// =============================================================================
// The screen that says, in plain words, what this thing is and why it can be
// trusted offline. It reinforces the native value (a bundled, offline reference),
// the provenance model (every number wears its tier), and v1 honesty (content is
// generated from the companion web reference and checked, not auto-refreshed).
//
// Pure prose: there is no collection to enumerate, so there are no detail pushes.
// The one freshness fact is store.sourcesLastChecked, computed off the build
// manifest — never a hardcoded "today" or "live." If the bundle failed to decode,
// the screen still renders, with a small honest error noting content may be
// incomplete.
// =============================================================================

struct AboutView: View {
    @Environment(PitchStore.self) private var store

    var body: some View {
        ZStack {
            PitchAtlasTheme.void.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xl) {
                    masthead
                    whatThisIsCard
                    provenanceModelCard
                    honestyCard
                    footer
                    statusNote
                }
                .padding(.horizontal, PitchAtlasSpacing.lg)
                .padding(.top, PitchAtlasSpacing.lg)
                .padding(.bottom, PitchAtlasSpacing.xl3)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Masthead

    private var masthead: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "About")
            Text("PITCH ATLAS")
                .font(PitchAtlasTheme.anton(52))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
            Text("Sourced, not corrected.")
                .font(PitchAtlasTheme.newsreaderItalic(18))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("About. Pitch Atlas. Sourced, not corrected.")
    }

    // MARK: - What this is

    private var whatThisIsCard: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "What this is")
            Text("An offline, sourced reference for how pitches are gripped and thrown. A pitch index, filed specimens, a first-party grip library, a craftsmen hall, the lost-pitches wing, and a full sources colophon — all in one place, all readable without a connection.")
                .font(PitchAtlasTheme.hanken(15))
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
            Text("Every number wears its confidence tier. Nothing is marked right or wrong — a grip is filed, never graded.")
                .font(PitchAtlasTheme.newsreaderItalic(14))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .leatherPress()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("What this is. An offline, sourced reference for how pitches are gripped and thrown — a pitch index, filed specimens, a first-party grip library, a craftsmen hall, the lost-pitches wing, and a full sources colophon. Every number wears its confidence tier. Nothing is marked right or wrong.")
    }

    // MARK: - The provenance model

    private var provenanceModelCard: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "The provenance model")
            Text("Every figure carries a tier dot. A confident claim shows where it came from — its source travels with it. A weaker claim carries a note that says what is uncertain and why. When something can't be verified, it is shown as unverified rather than hidden, so the gap stays visible instead of dressed up.")
                .font(PitchAtlasTheme.hanken(15))
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
            Text("The dot is the evidence. Read it before the number.")
                .font(PitchAtlasTheme.newsreaderItalic(14))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .leatherPress()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("The provenance model. Every figure carries a tier dot. A confident claim shows its source. A weaker claim carries a note that says what is uncertain. Unverified claims are shown so the gap stays visible. The dot is the evidence. Read it before the number.")
    }

    // MARK: - How it stays honest (freshness computed, never hardcoded)

    @ViewBuilder
    private var honestyCard: some View {
        let checked = store.sourcesLastChecked
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "How it stays honest")
            Text("The content is generated from the companion web reference and bundled into the app, so the whole atlas works fully offline. There is no live feed and nothing refreshes on its own.")
                .font(PitchAtlasTheme.hanken(15))
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)

            HairlineDivider()

            VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
                SectionLabel(text: "Sources last checked", size: 9)
                if checked.isEmpty {
                    Text("Not recorded in this build.")
                        .font(PitchAtlasTheme.hanken(14))
                        .foregroundStyle(PitchAtlasTheme.ink3)
                } else {
                    Text(checked)
                        .font(PitchAtlasTheme.newsreader(22))
                        .foregroundStyle(PitchAtlasTheme.bone)
                }
                Text("Checked, not auto-refreshed.")
                    .font(PitchAtlasTheme.hanken(13))
                    .foregroundStyle(PitchAtlasTheme.ink3)
            }
        }
        .leatherPress()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            checked.isEmpty
                ? "How it stays honest. Content is generated from the companion web reference and bundled, so it works fully offline. Sources last checked, not recorded in this build. Checked, not auto-refreshed."
                : "How it stays honest. Content is generated from the companion web reference and bundled, so it works fully offline. Sources last checked \(checked). Checked, not auto-refreshed."
        )
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            HairlineDivider()
            HStack(alignment: .center, spacing: PitchAtlasSpacing.sm) {
                SealMark(size: 34)
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs2) {
                    SectionLabel(text: "Pitch Atlas")
                    Text("A field manual for the craft of the pitch.")
                        .font(PitchAtlasTheme.newsreaderItalic(14))
                        .foregroundStyle(PitchAtlasTheme.ink3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pitch Atlas. A field manual for the craft of the pitch.")
    }

    // MARK: - Status (four-state honesty even on a prose screen)

    @ViewBuilder
    private var statusNote: some View {
        if case .failed(let msg) = store.status {
            ErrorStateView(
                title: "Some content didn't load",
                reason: "Part of the bundle couldn't be read, so what you see may be incomplete. \(msg)"
            )
        }
    }
}
