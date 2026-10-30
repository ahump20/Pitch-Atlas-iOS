import SwiftUI

// =============================================================================
// ChapterReads — the specimen file below the bench
// =============================================================================
// Web: sections/GripLibrary.tsx SpecimenGrips (photos left at the bench), and
// pages/PitchChapter.tsx ReleaseSection, MovementSection, MasterFilesSection and
// ColophonSection. Each opens on the same head — the kicker behind its accent
// rule, the athletic title, the lede — and every prose claim keeps its tier and
// source. No gauge, no number the record doesn't hold.
// =============================================================================

/// The rule and rhythm every section here shares: a bone hairline at 8%, and
/// clamp(34px, 5vw, 64px) above and below, which is 34 on a phone. A flush
/// section (border-t-0 pt-0) keeps only the space below.
private struct ChapterSection: ViewModifier {
    var flush = false

    func body(content: Content) -> some View {
        content
            .padding(.top, flush ? 0 : 34)
            .padding(.bottom, 34)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) {
                if !flush { Rectangle().fill(PitchAtlasTheme.bone.opacity(0.08)).frame(height: 1) }
            }
    }
}

private extension View {
    func chapterSection(flush: Bool = false) -> some View { modifier(ChapterSection(flush: flush)) }
}

/// `.rfx-panel`: the press ground, its bone hairline, the raking catch and the
/// cyan rim (PanelSurface).
private struct PressPanel: ViewModifier {
    var radius: CGFloat = 14
    var padding: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { PanelSurface(radius: radius) }
    }
}

/// Mono 10 in tracked caps: the small labels on the panels.
private func panelLabel(_ text: String, ink: Color = PitchAtlasTheme.bone2, tracking: CGFloat = 0.14) -> some View {
    Text(text.uppercased())
        .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
        .tracking(em: tracking, size: 10)
        .foregroundStyle(ink)
}

/// Body prose at a size, on 1.625.
private func relaxed(_ text: String, size: CGFloat, ink: Color) -> some View {
    Text(text)
        .font(PitchAtlasType.font(.hanken400, size: size, relativeTo: size >= 15 ? .body : .footnote))
        .foregroundStyle(ink)
        .cssLineHeight(1.625, face: .hanken400, size: size, relativeTo: size >= 15 ? .body : .footnote)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
}

/// The athletic line set in the shear: Anton, upper case, skewed −7°.
private func athletic(_ text: String, size: CGFloat, leading: CGFloat, ink: Color = PitchAtlasTheme.bone) -> some View {
    TightLines(text.uppercased(), face: .anton400, size: size, lineHeight: leading,
               relativeTo: size >= 22 ? .title2 : .headline, trackingEm: 0.01)
        .foregroundStyle(ink)
        .transformEffect(CardSkew.transform(degrees: -7))
}

// MARK: - Grip evidence

/// SpecimenGrips: the clip and Austin's photographs (on the specimen page the
/// photos stay at the bench and a button points back up to them), else an honest
/// empty gallery; then the three evidence lanes, the proof limit, and the way to
/// the Grip Library. `pauseControl` offers the page's Pause beside a clip;
/// `flush` drops the top rule and padding where the section opens its own band.
struct SpecimenGripEvidence: View {
    let grip: GripEntry
    let accentRGB: UInt32
    var includePhotos = false
    var pauseControl = false
    var flush = false
    var showBench: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var accent: Color { Color(rgb: accentRGB) }
    private var ink: Color { PitchAccents.accentInk(accentRGB) }

    // Verbatim, web data/grips/index.ts CIRCLE_CHANGE_DISTINCTION.
    private static let circleChangeMarker = "Circle Changeup · Filed from external sources · No Austin grip photo"
    private static let circleChangeReason = "Austin's personal grip library excludes the circle change because his hand size could not form it cleanly."

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChapterSectionHead(kicker: "Grip Evidence", title: "The photo can say this much", accent: accentRGB,
                               lede: "This is the visual grip-reference layer for \(grip.label). It names visible placement and Austin's own feel notes, then stops before making measured claims.")
            if pauseControl, grip.film != nil, !reduceMotion {
                PauseMotionButton().padding(.top, 16)
            }
            media.padding(.top, 28)
            VStack(spacing: 14) {
                lane("Photo-supported grip cue") { relaxed(grip.visibleCue, size: 13.5, ink: PitchAtlasTheme.bone2) }
                lane("Pitcher's own words", confidence: grip.claimTier) {
                    relaxed(grip.note, size: 13.5, ink: PitchAtlasTheme.bone2)
                    if let movement = grip.movement { relaxed(movement, size: 13.5, ink: PitchAtlasTheme.bone2) }
                }
                lane("Sourced public record") {
                    relaxed("The existing official and cited claims stay in the page below with their original confidence labels. This photo does not upgrade or replace those sources.",
                            size: 13.5, ink: PitchAtlasTheme.bone2)
                }
            }
            .padding(.top, 28)
            Text(grip.proofLimit.uppercased())
                .font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2))
                .tracking(em: 0.09, size: 9)
                .foregroundStyle(PitchAtlasTheme.ink3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Capsule().fill(Color.black.opacity(0.16)))
                .overlay(Capsule().strokeBorder(accent.opacity(0.24), lineWidth: 1))
                .padding(.top, 16)
            HStack(spacing: 0) {
                Text("See every grip in the ".uppercased()).foregroundStyle(PitchAtlasTheme.ink3)
                RouteButton(path: "grips") {
                    Text("Grip Library".uppercased()).foregroundStyle(PitchAtlasTheme.cyan)
                        .padding(.vertical, 14).contentShape(Rectangle()).padding(.vertical, -14)
                }
                .buttonStyle(.plain)
                Text(".").foregroundStyle(PitchAtlasTheme.ink3)
            }
            .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
            .tracking(em: 0.1, size: 10)
            .padding(.top, 16)
        }
        .chapterSection(flush: flush)
    }

    @ViewBuilder
    private var media: some View {
        let photos = includePhotos ? grip.photos : []
        if grip.film != nil || !photos.isEmpty {
            VStack(spacing: 16) {
                if let film = grip.film { GripMotionFigure(film: film) }
                ForEach(photos, id: \.src) { GripPhotoFigure(photo: $0) }
            }
        } else if !includePhotos, !grip.photos.isEmpty, let showBench {
            Button("Inspect the photographs at the grip bench ↑", action: showBench)
                .buttonStyle(StudyButtonStyle())
                .foregroundStyle(PitchAtlasTheme.bone)
        } else {
            let circle = grip.id == "circle-change"
            VStack(alignment: .leading, spacing: 8) {
                panelLabel(circle ? Self.circleChangeMarker : "Empty gallery", ink: ink)
                    .fixedSize(horizontal: false, vertical: true)
                relaxed(circle ? Self.circleChangeReason : "No Austin grip photo is attached to this pitch. The note below is intentionally text-only.",
                        size: 14, ink: PitchAtlasTheme.bone2)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(laneField))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(accent.opacity(0.32), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
        }
    }

    private var laneField: LinearGradient {
        LinearGradient(colors: [accent.opacity(0.08), Color.white.opacity(0.025)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func lane<Body: View>(_ label: String, confidence: ClaimConfidence? = nil,
                                  @ViewBuilder content: () -> Body) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            panelLabel(label, ink: ink)
            VStack(alignment: .leading, spacing: 8) { content() }.padding(.top, 8)
            if let confidence { ConfidenceDot(confidence: confidence).padding(.top, 12) }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(laneField))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(accent.opacity(0.24), lineWidth: 1))
    }
}

// MARK: - Release Room

struct ReleaseRoom: View {
    let entry: PitchAtlasEntry
    let accentRGB: UInt32

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChapterSectionHead(kicker: "Release Room", title: "Translate the hold into a release", accent: accentRGB,
                               lede: "Grip shape only matters if the release makes sense. Read pressure, thumb support, and ball depth before you read the pitch shape.")
            VStack(spacing: 14) {
                ForEach(Array(SpecimenReads.releaseSequence(entry).enumerated()), id: \.offset) { index, cue in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(String(format: "%02d", index + 1))
                            .font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .caption))
                            .monospacedDigit()
                            .foregroundStyle(PitchAccents.accentInk(accentRGB))
                        athletic(cue.label, size: 20, leading: 0.9).padding(.top, 8)
                        relaxed(cue.copy, size: 13.5, ink: PitchAtlasTheme.bone2).padding(.top, 10)
                    }
                    .modifier(PressPanel())
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.top, 28)
            RefractorClaimView(claim: entry.canonical.mechanics, ink: PitchAtlasTheme.bone).padding(.top, 32)
        }
        .chapterSection()
    }
}

// MARK: - Movement

struct MovementRead: View {
    let entry: PitchAtlasEntry
    let accentRGB: UInt32

    private var accent: Color { Color(rgb: accentRGB) }
    private var physics: PhysicsReference { entry.canonical.physics }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChapterSectionHead(kicker: "Movement", title: entry.display.foundationCaption, accent: accentRGB,
                               lede: "The read is shape, not a gauge. The spin words explain why it moves that way, and every prose claim still carries its source.")
            VStack(spacing: 14) {
                if let shape = physics.shape { shapeCard(shape) }
                VStack(alignment: .leading, spacing: 0) {
                    panelLabel("Spin words")
                    relaxed(physics.spinAxis.value, size: 13, ink: PitchAtlasTheme.bone).padding(.top, 8)
                    ClaimTierLine(claim: physics.spinAxis, ground: .panel).padding(.top, 10)
                }
                .modifier(PressPanel())
                VStack(alignment: .leading, spacing: 0) {
                    panelLabel("Craft read")
                    relaxed(entry.guide?.does.plain ?? physics.shape?.value ?? physics.spinAxis.value, size: 13, ink: PitchAtlasTheme.bone)
                        .padding(.top, 8)
                }
                .modifier(PressPanel())
            }
            .padding(.top, 28)
            teaching.padding(.top, 20)
        }
        .chapterSection()
    }

    private func shapeCard(_ shape: Claim) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            panelLabel("Shape")
            athletic(SpecimenReads.shapeLabel(entry), size: 24, leading: 1.02).padding(.top, 8)
            relaxed(shape.value, size: 13, ink: PitchAtlasTheme.bone2).padding(.top, 12)
            ClaimTierLine(claim: shape, ground: .panel).padding(.top, 12)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16).fill(PitchAtlasTheme.press)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(EllipticalGradient(stops: [.init(color: accent.opacity(0.16), location: 0), .init(color: .clear, location: 0.6)],
                                                 center: .topLeading, startRadiusFraction: 0, endRadiusFraction: 1.1))
                }
        }
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(accent.opacity(0.28), lineWidth: 1))
    }

    /// The one teaching sentence, in the athletic hand.
    private var teaching: some View {
        VStack(alignment: .leading, spacing: 0) {
            panelLabel("The one teaching sentence", ink: PitchAccents.accentInk(accentRGB), tracking: 0.16)
            athletic(physics.teaching.value, size: 18, leading: 1.05).padding(.top, 10)
            ClaimTierLine(claim: physics.teaching, ground: .panel).padding(.top, 12)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14).fill(PitchAtlasTheme.press)
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(EllipticalGradient(stops: [.init(color: accent.opacity(0.14), location: 0), .init(color: .clear, location: 0.6)],
                                                 center: .topTrailing, startRadiusFraction: 0, endRadiusFraction: 1.1))
                }
        }
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(accent.opacity(0.26), lineWidth: 1))
    }
}

// MARK: - Master Files

struct MasterFiles: View {
    let entry: PitchAtlasEntry
    let accentRGB: UInt32

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChapterSectionHead(kicker: "Master Files", title: "The master files", accent: accentRGB,
                               lede: entry.display.mastersIntro)
            Group {
                if entry.masterVariants.isEmpty {
                    empty
                } else {
                    VStack(spacing: 14) {
                        ForEach(entry.masterVariants, id: \.pitcher) { variant in
                            MasterFileCard(variant: variant, pitchSlug: entry.slug, accentRGB: accentRGB)
                        }
                    }
                }
            }
            .padding(.top, 28)
        }
        .chapterSection()
    }

    private var empty: some View {
        VStack(spacing: 16) {
            ArchiveSealMark(size: 56).opacity(0.8)
            Text("No master files for this pitch yet. A master is filed only when a named arm and a cited source both exist. Nothing is added to fill the page.")
                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 56)
        .frame(maxWidth: .infinity)
        .overlay(RoundedRectangle(cornerRadius: 16)
            .strokeBorder(PitchAtlasTheme.bone.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
    }
}

/// MasterCard: the arm, the way to their story when the hall has them, the
/// context, the written distinction, the accolades, and the quote — each with
/// its tier. The record's numbers stay off the page, as on the site.
private struct MasterFileCard: View {
    let variant: MasterVariantRecord
    let pitchSlug: String
    let accentRGB: UInt32
    @Environment(PitchStore.self) private var store

    private var accent: Color { Color(rgb: accentRGB) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            athletic(variant.pitcher, size: 24, leading: 0.9)
            if let person = store.master(named: variant.pitcher, forPitch: pitchSlug) {
                NavigationLink { CraftsmanDetailView(craftsman: person) } label: {
                    ArchiveLinkLabel(title: "The person behind this hold", ink: PitchAtlasTheme.bone)
                }
                .buttonStyle(.plain)
            }
            relaxed(variant.context, size: 12.5, ink: PitchAtlasTheme.bone2).padding(.top, 8)
            if let distinction = variant.distinction {
                RefractorClaimView(claim: distinction, size: 13, ink: PitchAtlasTheme.bone, ground: .panel)
                    .padding(.top, 16)
                    .overlay(alignment: .top) { rule }
                    .padding(.top, 16)
            }
            if let accolades = variant.accolades, !accolades.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(accolades, id: \.label) { accolade in accoladeRow(accolade) }
                }
                .padding(.top, 16)
            }
            if let quote = variant.quote, quote.source != nil { quoteFigure(quote) }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [ChapterInk.plateGround.mix(accent, 0.18), ChapterInk.plateFloor],
                                     startPoint: UnitPoint(x: 0.37, y: 0.02), endPoint: UnitPoint(x: 0.63, y: 0.98)))
        }
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(accent.opacity(0.24), lineWidth: 1))
    }

    private var rule: some View { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1) }

    private func accoladeRow(_ accolade: LabeledClaim) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            (Text("\(accolade.label) · ".uppercased())
                .font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2))
                .foregroundStyle(PitchAtlasTheme.bone3)
             + Text(accolade.claim.value)
                .font(PitchAtlasType.font(.hanken400, size: 12.5, relativeTo: .footnote))
                .foregroundStyle(PitchAtlasTheme.bone2))
                .cssLineHeight(1.625, face: .hanken400, size: 12.5, relativeTo: .footnote)
                .fixedSize(horizontal: false, vertical: true)
            ClaimTierLine(claim: accolade.claim, ground: .panel)
            if let note = accolade.claim.note { RefractorNoteView(text: note, ground: .panel) }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { rule }
    }

    private func quoteFigure(_ quote: Claim) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            athletic(quote.value, size: 15, leading: 1.375)
            ClaimTierLine(claim: quote, ground: .panel)
            if let note = quote.note { RefractorNoteView(text: note, ground: .panel) }
        }
        .padding(.top, 16)
        .overlay(alignment: .top) { rule }
        .padding(.top, 16)
    }
}

// MARK: - Colophon

struct Colophon: View {
    let entry: PitchAtlasEntry
    let accentRGB: UInt32

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChapterSectionHead(kicker: "The colophon", title: "Every claim, sourced", accent: accentRGB,
                               lede: "Follow a claim back to the person or record behind it. Confidence labels distinguish firsthand accounts, analysis, and secondhand attribution; the notes preserve what remains uncertain.")
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 30) {
                    ForEach(Array(SpecimenReads.colophonSources(entry).enumerated()), id: \.element.id) { index, source in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(String(format: "%02d", index + 1))
                                .font(PitchAtlasType.font(.martian400, size: 8, relativeTo: .caption2))
                                .foregroundStyle(PitchAtlasTheme.ink3)
                                .accessibilityHidden(true)
                            RefractorSourceLink(source: source)
                        }
                    }
                }
                FlowRow(spacing: 14, lineSpacing: 8, rowAlignment: .center) {
                    ForEach(SpecimenReads.colophonTiers, id: \.self) { tier in
                        HStack(spacing: 8) {
                            Circle().fill(PitchAtlasTheme.color(forConfidence: tier.rawValue)).frame(width: 8, height: 8)
                                .shadow(color: PitchAtlasTheme.color(forConfidence: tier.rawValue), radius: 4.5)
                            Text(tier.label.uppercased())
                                .font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2))
                                .tracking(em: 0.06, size: 9)
                                .foregroundStyle(PitchAtlasTheme.bone2)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.top, 16)
                .overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1) }
                .padding(.top, 20)
                Text("\(entry.seam.stitchCount.value) · \(entry.seam.accuracyLevel.rawValue) · as of the dates above".uppercased())
                    .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                    .tracking(em: 0.1, size: 10)
                    .foregroundStyle(PitchAtlasTheme.ink3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 16)
            }
            .modifier(PressPanel(radius: 16, padding: 22))
            .padding(.top, 28)
        }
        .chapterSection()
    }
}
