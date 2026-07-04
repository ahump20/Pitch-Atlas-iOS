import SwiftUI

// =============================================================================
// KnowledgeWingView — one wing of the field manual (a sourced essay)
// =============================================================================
// The teaching layer rendered long-form: an eyebrow + Anton title + editorial
// sub, then each section as prose with its pull-stat gauge and the sources
// standing behind it. Closes with how the wing was sourced and any related
// reading. Provenance is the point — every measured value rides ClaimText,
// GaugeView, or SourceClaimLabel, never a bare string.
// =============================================================================

struct KnowledgeWingView: View {
    let wing: KnowledgeWing

    var body: some View {
        ZStack {
            PitchAtlasTheme.void.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xl) {
                    header

                    if wing.educational == true {
                        educationalBanner
                    }

                    sections

                    footer
                }
                .padding(.horizontal, PitchAtlasSpacing.md)
                .padding(.top, PitchAtlasSpacing.md)
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
            }
        }
        .navigationTitle(wing.navLabel.isEmpty ? wing.title : wing.navLabel)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: wing.eyebrow)
            Text(wing.title)
                .font(PitchAtlasTheme.anton(wing.title.count > 18 ? 30 : 40))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
                .fixedSize(horizontal: false, vertical: true)
            Text(wing.sub)
                .font(PitchAtlasTheme.newsreaderItalic(17))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(wing.eyebrow). \(wing.title). \(wing.sub)")
    }

    // MARK: - Educational banner

    private var educationalBanner: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            SectionLabel(text: "EDUCATIONAL USE", color: PitchAtlasTheme.amberBright)
            Text("This wing is teaching, not medical care.")
                .font(PitchAtlasTheme.hanken(13))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .leatherPress(padding: PitchAtlasSpacing.sm, radius: PitchAtlasRadius.panel)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Educational use — not medical care. This wing is teaching, not medical care.")
    }

    // MARK: - Sections

    private var sections: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xl) {
            ForEach(Array(wing.sections.enumerated()), id: \.offset) { _, section in
                WingSectionView(section: section)
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.lg) {
            HairlineDivider()

            VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
                SectionLabel(text: "HOW THIS WING WAS SOURCED")
                Text(wing.confidenceNote)
                    .font(PitchAtlasTheme.hanken(13))
                    .foregroundStyle(PitchAtlasTheme.ink3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("How this wing was sourced. \(wing.confidenceNote)")

            if let related = wing.related, !related.isEmpty {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
                    SectionLabel(text: "RELATED")
                    ForEach(Array(related.enumerated()), id: \.offset) { _, link in
                        Text(link.label)
                            .font(PitchAtlasTheme.hanken(13))
                            .foregroundStyle(PitchAtlasTheme.ink3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Related. " + related.map(\.label).joined(separator: ". "))
            }
        }
    }
}

// MARK: - One section

private struct WingSectionView: View {
    let section: KnowledgeSection

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            Text(section.heading)
                .font(PitchAtlasTheme.newsreader(18))
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                    .font(PitchAtlasTheme.hanken(15))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let pull = section.pullStat {
                GaugeView(label: pull.label, claim: pull.claim, accent: true)
            }

            if let claims = section.claims, !claims.isEmpty {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                    SectionLabel(text: "SOURCES BEHIND THIS SECTION", size: 9)
                    ForEach(Array(claims.enumerated()), id: \.offset) { _, claim in
                        SourceClaimLabel(claim: claim)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .leatherPress(padding: PitchAtlasSpacing.sm, radius: PitchAtlasRadius.panel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
