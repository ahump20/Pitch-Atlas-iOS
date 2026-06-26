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

    /// Drives the grip-fact layout: at accessibility text sizes the fixed label
    /// column can't hold "PRESSURE FINGER" without clipping, so the row stacks.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var canonical: CanonicalPitchRecord { entry.canonical }
    private var display: PitchDisplay { entry.display }
    private var physics: PhysicsReference { canonical.physics }

    /// The photo that carries the hero when no film is on file. The grip lab
    /// below skips it so the same frame never renders twice on one screen.
    private var heroPhoto: VisualReference? {
        canonical.gripFilm == nil ? canonical.gripImages?.first : nil
    }

    var body: some View {
        ZStack {
            FieldBackdrop()
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
                    // When real footage or photography carries the hero, the
                    // drawn specimen files down here beside the seam-geometry
                    // record.
                    if canonical.gripFilm != nil || heroPhoto != nil { specimenCard }
                    seamGeometry
                }
                .padding(PitchAtlasSpacing.lg)
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
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

            // The specimen face: real footage first, then real photography,
            // the drawn SeamBall only where nothing real is on file.
            if let film = canonical.gripFilm {
                GripFilmCard(film: film)
                    .specimenCardFrame(padding: PitchAtlasSpacing.sm, radius: PitchAtlasRadius.card, foilIntensity: 0.72)
            } else if let photo = heroPhoto {
                GripStillCard(photo: photo)
            } else {
                specimenCard
            }

            BlazeInlineCompanionView(style: .pitch, mood: .chasing)

            Text(display.heroIntro)
                .font(PitchAtlasTheme.hanken(16))
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Drawn specimen (SeamBall)

    private var specimenCard: some View {
        VStack(spacing: PitchAtlasSpacing.xs) {
            SeamBall(motion: entry.motion, size: 240, contacts: canonical.fingerPlacement)
                .frame(maxWidth: .infinity)
                .padding(.vertical, PitchAtlasSpacing.sm)

            // Legend for the numbered pips on the seam — only when contacts exist.
            if !canonical.fingerPlacement.isEmpty {
                fingerLegend
            }

            Text(entry.motion.forceLabel)
                .font(PitchAtlasTheme.martian(9))
                .tracking(1)
                .foregroundStyle(PitchAtlasTheme.cyan)
            SectionLabel(text: humanize(entry.seam.accuracyLevel.rawValue), size: 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PitchAtlasSpacing.lg)
        .specimenCardFrame(padding: PitchAtlasSpacing.lg, foilIntensity: 0.82)
    }

    /// Maps the seam pips (1 index, 2 middle, 3 ring, 4 pinky, T thumb) to names so
    /// the numbered dots on the specimen are legible. Pure derived data, no sourcing.
    private var fingerLegend: some View {
        let pips = canonical.fingerPlacement.map { contact -> String in
            let n: String
            switch contact.finger {
            case .index: n = "1"
            case .middle: n = "2"
            case .ring: n = "3"
            case .pinky: n = "4"
            case .thumb: n = "T"
            }
            return "\(n) \(contact.label)"
        }
        return Text(pips.joined(separator: "   ·   "))
            .font(PitchAtlasTheme.martian(8))
            .tracking(0.5)
            .foregroundStyle(PitchAtlasTheme.ink3)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, PitchAtlasSpacing.sm)
            .accessibilityHidden(true)
    }

    // MARK: Foundation gauges

    private var foundation: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
            SectionLabel(text: "FOUNDATION")
            Text(display.foundationCaption)
                .font(PitchAtlasTheme.hanken(13))
                .foregroundStyle(PitchAtlasTheme.ink3)
                .fixedSize(horizontal: false, vertical: true)

            if let shape = physics.shape {
                GaugeView(label: "Shape", claim: shape, accent: true)
            }

            if let primary = physics.primaryBreak {
                GaugeView(label: primary.label,
                          claim: primary.claim,
                          accent: primary.accent ?? true)
            }

            if let secondary = physics.secondaryBreak {
                GaugeView(label: secondary.label, claim: secondary.claim,
                          accent: secondary.accent ?? false)
            }
            if let spinRate = physics.spinRateRpm {
                GaugeView(label: "Spin rate", claim: spinRate)
            }
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

            // First-party grip photography — minus the frame already carrying
            // the hero, so nothing renders twice.
            let labPhotos = (canonical.gripImages ?? []).filter { $0 != heroPhoto }
            if !labPhotos.isEmpty {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.sm) {
                    SectionLabel(text: "FROM THE HAND", size: 9)
                    ForEach(Array(labPhotos.enumerated()), id: \.offset) { _, photo in
                        GripPhotoTile(photo: photo)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func gripFact(_ label: String, _ value: String) -> some View {
        let labelText = Text(label.uppercased())
            .font(PitchAtlasTheme.martian(8))
            .tracking(1)
            .foregroundStyle(PitchAtlasTheme.ink3)
        let valueText = Text(value)
            .font(PitchAtlasTheme.hanken(14))
            .foregroundStyle(PitchAtlasTheme.bone)

        if dynamicTypeSize.isAccessibilitySize {
            // Stack at accessibility sizes so neither the label nor the value
            // truncates inside a fixed column.
            VStack(alignment: .leading, spacing: 2) {
                labelText.fixedSize(horizontal: false, vertical: true)
                valueText.fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(alignment: .top, spacing: PitchAtlasSpacing.sm) {
                labelText
                    .frame(width: 96, alignment: .leading)
                valueText
                    .fixedSize(horizontal: false, vertical: true)
            }
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

            if let distinction = variant.distinction {
                ClaimText(claim: distinction, valueFont: PitchAtlasTheme.hanken(14))
            }

            ForEach(Array(variant.recordNumbers.enumerated()), id: \.offset) { i, number in
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
