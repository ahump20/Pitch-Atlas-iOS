import SwiftUI

// =============================================================================
// PitchDetailView: the filed specimen (v1 native)
// =============================================================================
// The flagship surface. Native everything: the SeamBall specimen, the foundation
// gauges, the grip lab, the coaching guide, the master-variant ledger, and the
// seam-geometry honesty card. This native version is what makes the screen valid
// and complete on its own.
// =============================================================================

struct PitchDetailView: View {
    let entry: PitchAtlasEntry

    private var canonical: CanonicalPitchRecord { entry.canonical }
    private var display: PitchDisplay { entry.display }
    private var physics: PhysicsReference { canonical.physics }

    var body: some View {
        ZStack {
            PitchAtlasTheme.void.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.xl) {
                    hero
                    foundation
                    teaching
                    gripLab
                    if let guide = entry.guide { coaching(guide) }
                    mechanics
                    if let voice = canonical.voice { voiceQuote(voice) }
                    if !entry.masterVariants.isEmpty { mastersLedger }
                    communityPreview
                    seamGeometry
                }
                .padding(PitchAtlasSpacing.lg)
                .padding(.bottom, PitchAtlasSpacing.xl3)
            }
        }
        .navigationTitle(display.shortName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Hero + specimen

    private var hero: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            HStack {
                SectionLabel(text: "SPECIMEN \(display.specimenNo)", color: PitchAtlasTheme.cyanDeep, size: 9)
                Spacer()
                SectionLabel(text: canonical.family.label, color: canonical.family.accent, size: 9)
            }

            Text(canonical.name.uppercased())
                .font(PitchAtlasTheme.anton(40))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()

            Text(display.heroSub)
                .font(PitchAtlasTheme.newsreaderItalic(17))
                .foregroundStyle(PitchAtlasTheme.bone2)

            // The native specimen.
            VStack(spacing: PitchAtlasSpacing.xs) {
                SeamBall(motion: entry.motion, size: 240)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PitchAtlasSpacing.sm)
                Text(entry.motion.forceLabel)
                    .font(PitchAtlasTheme.martian(9))
                    .tracking(1)
                    .foregroundStyle(PitchAtlasTheme.cyan)
                SectionLabel(text: humanize(entry.seam.accuracyLevel.rawValue), size: 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PitchAtlasSpacing.lg)
            .leatherPress(padding: PitchAtlasSpacing.lg)
            .foilRake()

            BlazeInlineCompanionView(style: .pitch, mood: .chasing)

            Text(display.heroIntro)
                .font(PitchAtlasTheme.hanken(16))
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Foundation gauges

    private var foundation: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "FOUNDATION")
            Text(display.foundationCaption)
                .font(PitchAtlasTheme.hanken(13))
                .foregroundStyle(PitchAtlasTheme.ink3)
                .fixedSize(horizontal: false, vertical: true)

            GaugeView(label: physics.primaryBreak.label,
                      claim: physics.primaryBreak.claim,
                      accent: physics.primaryBreak.accent ?? true)

            if let secondary = physics.secondaryBreak {
                GaugeView(label: secondary.label, claim: secondary.claim,
                          accent: secondary.accent ?? false)
            }
            GaugeView(label: "Spin rate", claim: physics.spinRateRpm)
            if let active = physics.activeSpinPct {
                GaugeView(label: "Active spin", claim: active)
            }
            GaugeView(label: "Spin axis", claim: physics.spinAxis)
        }
    }

    // MARK: Teaching line

    private var teaching: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "WHAT MAKES IT MOVE")
            Text(physics.teaching.value)
                .font(PitchAtlasTheme.newsreader(20))
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
            SourceClaimLabel(claim: physics.teaching)
        }
        .leatherPress()
    }

    // MARK: Grip lab

    private var gripLab: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.md) {
            SectionLabel(text: "THE GRIP")
            ClaimText(claim: canonical.grip, valueFont: PitchAtlasTheme.hanken(17))

            if !canonical.gripDetails.isEmpty {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                    ForEach(Array(canonical.gripDetails.enumerated()), id: \.offset) { _, detail in
                        ClaimText(claim: detail, valueFont: PitchAtlasTheme.hanken(15))
                    }
                }
            }

            // Grip model prose
            let model = canonical.gripModel
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
                gripFact("Ball depth", humanize(model.ballDepth.rawValue))
                gripFact("Finger spacing", humanize(model.fingerSpacing.rawValue))
                gripFact("Pressure finger", humanize(model.primaryPressureFinger.rawValue))
                gripFact("Thumb", model.thumbRole)
                gripFact("Palm gap", model.palmGapCue)
                gripFact("Release", model.releaseCue)
            }
            .leatherPress()

            // Per-finger contacts
            if !model.contacts.isEmpty {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                    SectionLabel(text: "ON THE SEAM", size: 9)
                    ForEach(Array(model.contacts.enumerated()), id: \.offset) { _, contact in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: PitchAtlasSpacing.xs) {
                                FamilyDot(color: canonical.family.accent)
                                Text("\(humanize(contact.finger.rawValue)) · \(contact.label)")
                                    .font(PitchAtlasTheme.hankenMedium(14))
                                    .foregroundStyle(PitchAtlasTheme.bone)
                            }
                            Text(contact.cue)
                                .font(PitchAtlasTheme.hanken(13))
                                .foregroundStyle(PitchAtlasTheme.bone2)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("\(contact.seamRelation) · \(contact.pressureRole)")
                                .font(PitchAtlasTheme.martian(8))
                                .foregroundStyle(PitchAtlasTheme.ink3)
                        }
                    }
                }
            }

            Text(model.visualCaveat)
                .font(PitchAtlasTheme.newsreaderItalic(13))
                .foregroundStyle(PitchAtlasTheme.ink3)
                .fixedSize(horizontal: false, vertical: true)

            // First-party grip photography, if any.
            if let images = canonical.gripImages, !images.isEmpty {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                    SectionLabel(text: "FROM THE HAND", size: 9)
                    ForEach(Array(images.enumerated()), id: \.offset) { _, photo in
                        GripPhotoTile(photo: photo)
                    }
                }
            }
        }
    }

    private func gripFact(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: PitchAtlasSpacing.sm) {
            Text(label.uppercased())
                .font(PitchAtlasTheme.martian(8))
                .tracking(1)
                .foregroundStyle(PitchAtlasTheme.ink3)
                .frame(width: 96, alignment: .leading)
            Text(value)
                .font(PitchAtlasTheme.hanken(14))
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Coaching guide

    private func coaching(_ guide: GripGuide) -> some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: guide.family, color: PitchAtlasTheme.cyan)
            Text(guide.tagline)
                .font(PitchAtlasTheme.newsreader(19))
                .foregroundStyle(PitchAtlasTheme.bone)
            Text(guide.feel)
                .font(PitchAtlasTheme.hanken(15))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
                ForEach(Array(guide.steps.enumerated()), id: \.offset) { i, step in
                    HStack(alignment: .top, spacing: PitchAtlasSpacing.xs) {
                        Text("\(i + 1)")
                            .font(PitchAtlasTheme.martian(11))
                            .foregroundStyle(PitchAtlasTheme.cyan)
                            .frame(width: 18, alignment: .leading)
                        Text(step)
                            .font(PitchAtlasTheme.hanken(14))
                            .foregroundStyle(PitchAtlasTheme.bone)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.vertical, PitchAtlasSpacing.xs)

            VStack(alignment: .leading, spacing: 4) {
                SectionLabel(text: guide.does.headline, size: 9)
                Text(guide.does.plain)
                    .font(PitchAtlasTheme.hanken(14))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .leatherPress()
    }

    // MARK: Mechanics

    private var mechanics: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "MECHANICS")
            ClaimText(claim: canonical.mechanics, valueFont: PitchAtlasTheme.hanken(15))
        }
    }

    // MARK: Voice quote

    private func voiceQuote(_ voice: Claim) -> some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            Text("\u{201C}\(voice.value)\u{201D}")
                .font(PitchAtlasTheme.newsreaderItalic(20))
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
            SourceClaimLabel(claim: voice)
        }
        .leatherPress()
    }

    // MARK: Master-variant ledger

    private var mastersLedger: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.md) {
            SectionLabel(text: "MASTER VARIANTS")
            Text(display.mastersIntro)
                .font(PitchAtlasTheme.hanken(14))
                .foregroundStyle(PitchAtlasTheme.ink3)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(entry.masterVariants.enumerated()), id: \.offset) { _, variant in
                masterCard(variant)
            }
        }
    }

    private func masterCard(_ variant: MasterVariantRecord) -> some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            HStack {
                Text(variant.pitcher.uppercased())
                    .font(PitchAtlasTheme.anton(20))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .antonSkew()
                Spacer()
                if variant.verifiedPro {
                    StatusPill(text: "Verified", tone: PitchAtlasTheme.okBright)
                }
            }
            Text(variant.context)
                .font(PitchAtlasTheme.hanken(14))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(variant.numbers.enumerated()), id: \.offset) { i, number in
                GaugeView(label: number.label, claim: number.claim, accent: i == 0)
            }

            if let quote = variant.quote {
                Text("\u{201C}\(quote.value)\u{201D}")
                    .font(PitchAtlasTheme.newsreaderItalic(15))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .fixedSize(horizontal: false, vertical: true)
                SourceClaimLabel(claim: quote)
            }
        }
        .leatherPress()
    }

    // MARK: Community

    private var communityPreview: some View {
        CommunityPanel(
            pitchSlug: entry.slug,
            pitchName: canonical.name,
            provenanceNote: entry.community.provenanceNote,
            safetyNote: entry.community.safetyNote
        )
    }

    // MARK: Seam geometry honesty card

    private var seamGeometry: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            SectionLabel(text: "HOW THIS SEAM IS DRAWN")
            Text(entry.seam.equationPlain)
                .font(PitchAtlasTheme.martian(11))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
            Text(entry.seam.parameterization)
                .font(PitchAtlasTheme.hanken(13))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
            ClaimText(claim: entry.seam.stitchCount, valueFont: PitchAtlasTheme.hanken(14))
            ClaimText(claim: entry.seam.accuracyNote, valueFont: PitchAtlasTheme.hanken(13))
        }
        .leatherPress()
    }

    // MARK: helpers

    private func humanize(_ raw: String) -> String {
        raw.replacingOccurrences(of: "-", with: " ")
            .prefix(1).uppercased() + raw.replacingOccurrences(of: "-", with: " ").dropFirst()
    }
}
