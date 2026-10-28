import SwiftUI

// =============================================================================
// ChapterHero — the card, opened
// =============================================================================
// Web: pages/PitchChapter.tsx ChapterHero. The framed square stage in the
// pitch's accent world (the gold 1/1 for the four-seam), carrying the honest
// face: Austin's clip where he throws the pitch on game day, his photo where it
// is situational, the drawn seam schematic otherwise. Then the file line, the
// name in metal, the tell, the archive-drawer paragraph, the shape read, the
// grip, the family pills, and the two ways on.
// =============================================================================

struct ChapterHero: View {
    let entry: PitchAtlasEntry
    let grip: GripEntry?
    let openGripFile: () -> Void

    private var accentRGB: UInt32 { SpecimenReads.accentRGB(entry) }
    private var accent: Color { Color(rgb: accentRGB) }
    private var ink: Color { PitchAccents.accentInk(accentRGB) }
    private var isGold: Bool { entry.display.specimenNo == "00" }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HeroStage(entry: entry, grip: grip, accentRGB: accentRGB)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            meta
        }
        .padding(.top, 12)
        .padding(.bottom, 34)
        .background { HeroAtmosphere() }
    }

    private var meta: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Archive file · Specimen No. \(entry.display.specimenNo)".uppercased())
                .font(PitchAtlasTheme.anton(18, relativeTo: .headline))
                .tracking(em: 0.01, size: 18)
                .foregroundStyle(ink)
                .transformEffect(CardSkew.transform(degrees: -7))
            HoloWordmark(text: entry.canonical.name.uppercased(), size: 40, lineSpacing: -18)
                .padding(.vertical, -11)
                .padding(.top, 8)
            BalancedLines {
                Text((entry.guide?.tagline ?? entry.display.heroSub).uppercased())
                    .font(PitchAtlasTheme.anton(15, relativeTo: .subheadline))
                    .tracking(em: 0.01, size: 15)
                    .foregroundStyle(ink)
                    .cssLineHeight(1.18, face: .anton400, size: 15, relativeTo: .subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .transformEffect(CardSkew.transform(degrees: -7))
            .padding(.top, 10)
            // Verbatim, PitchChapter.tsx.
            Text("Open this like an archive drawer: grip first, source attached, shape in words, no invented spin or movement numbers. The file exists so the hold can keep moving forward.")
                .font(PitchAtlasType.font(.hanken400, size: 13.5, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 13.5, relativeTo: .subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 16)
                .overlay(alignment: .leading) { Rectangle().fill(accent.opacity(0.46)).frame(width: 2) }
                .padding(.top, 16)
            shapePlate.padding(.top, 18)
            Text(entry.canonical.grip.value)
                .font(PitchAtlasType.font(.hanken400, size: 14.5, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 14.5, relativeTo: .subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)
            pills.padding(.top, 16)
            tierTag("Grip", entry.canonical.grip.confidence).padding(.top, 14)
            actions.padding(.top, 28)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// .rfx-readplate: the shape in words, its sentence, and its tier.
    @ViewBuilder
    private var shapePlate: some View {
        if let shape = entry.canonical.physics.shape {
            VStack(alignment: .leading, spacing: 0) {
                Text("Shape read".uppercased())
                    .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                    .tracking(em: 0.14, size: 10)
                    .foregroundStyle(ink)
                Text(SpecimenReads.shapeLabel(entry).uppercased())
                    .font(PitchAtlasTheme.anton(22, relativeTo: .title2))
                    .tracking(em: 0.01, size: 22)
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .cssLineHeight(1.05, face: .anton400, size: 22, relativeTo: .title2)
                    .fixedSize(horizontal: false, vertical: true)
                    .transformEffect(CardSkew.transform(degrees: -7))
                    .padding(.top, 8)
                Text(shape.value)
                    .font(PitchAtlasType.font(.hanken400, size: 13, relativeTo: .footnote))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .cssLineHeight(1.625, face: .hanken400, size: 13, relativeTo: .footnote)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                tierTag("Shape", shape.confidence).padding(.top, 12)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [ChapterInk.plateGround.mix(accent, 0.18), ChapterInk.plateFloor],
                                         startPoint: UnitPoint(x: 0.21, y: 0.09), endPoint: UnitPoint(x: 0.79, y: 0.91)))
            }
            .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(accent.opacity(0.26), lineWidth: 1) }
            .overlay(alignment: .top) {
                Rectangle().fill(accent.opacity(0.22)).frame(height: 1).padding(.horizontal, 12).padding(.top, 1)
            }
        }
    }

    /// "Grip" / "Shape" and the tier's dot and words, in mono 9.
    private func tierTag(_ label: String, _ confidence: ClaimConfidence) -> some View {
        HStack(spacing: 8) {
            Text(label.uppercased())
                .font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2))
                .tracking(em: 0.08, size: 9)
                .foregroundStyle(PitchAtlasTheme.bone2)
            ConfidenceDot(confidence: confidence)
        }
        .accessibilityElement(children: .combine)
    }

    /// The family, the guide's family and the force, each once; the gold 1/1's
    /// first pill fills burnt.
    private var pills: some View {
        FlowRow(spacing: 8, lineSpacing: 8) {
            ForEach(Array(SpecimenReads.pills(entry).enumerated()), id: \.offset) { index, pill in
                let filled = index == 0 && isGold
                Text(pill.uppercased())
                    .font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2))
                    .tracking(em: 0.1, size: 9)
                    .foregroundStyle(filled ? PitchAtlasTheme.bone : PitchAtlasTheme.bone2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background { if filled { Capsule().fill(accent) } }
                    .overlay { if !filled { Capsule().strokeBorder(accent.opacity(0.4), lineWidth: 1) } }
            }
        }
    }

    private var actions: some View {
        let button = PitchAccents.accentButton(fill: accentRGB)
        return FlowRow(spacing: 12, lineSpacing: 12) {
            Button(action: openGripFile) {
                HStack(spacing: 8) {
                    Text("Open the grip file".uppercased())
                    Text("↓").accessibilityHidden(true)
                }
                .font(PitchAtlasType.font(.martian600, size: 14, relativeTo: .callout))
                .tracking(em: 0.025, size: 14)
                .foregroundStyle(Color(rgb: button.foreground))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(rgb: button.background)))
                .shadow(color: accent.opacity(0.55), radius: 10, x: 0, y: 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open the grip file")
            RouteButton(path: "repertoire") {
                HStack(spacing: 8) {
                    Text("All pitches".uppercased())
                    Text("→").accessibilityHidden(true)
                }
                .font(PitchAtlasType.font(.martian400, size: 14, relativeTo: .callout))
                .tracking(em: 0.025, size: 14)
                .foregroundStyle(PitchAtlasTheme.bone)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(minHeight: 44)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(PitchAtlasTheme.bone.opacity(0.3), lineWidth: 1))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("All pitches")
        }
    }
}

// MARK: - The stage

/// The framed square: the accent field, the hatch, the ring, the face, and the
/// media bar along its foot.
private struct HeroStage: View {
    let entry: PitchAtlasEntry
    let grip: GripEntry?
    let accentRGB: UInt32

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(MotionPreference.pausedKey) private var paused = false

    private var accent: Color { Color(rgb: accentRGB) }
    private var isGold: Bool { entry.display.specimenNo == "00" }
    private var film: GripFilm? { grip?.film }
    private var photo: VisualReference? { film == nil ? grip?.photos.first : nil }

    var body: some View {
        GeometryReader { geo in
            let side = geo.size.width
            ZStack {
                field(side: side)
                Hatch(angle: 45, spacing: 14).stroke(accent.opacity(0.5), lineWidth: 1.5)
                    .overlay { Hatch(angle: -45, spacing: 14).stroke(accent.opacity(0.5), lineWidth: 1.5) }
                    .blendMode(.screen)
                    .opacity(0.2)
                ring(side: side)
                face(side: side)
            }
            .frame(width: side, height: side)
            .overlay(alignment: .topLeading) { if isGold { emberChip } }
            .overlay(alignment: .bottom) { mediaBar(side: side) }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(accent.opacity(0.3), lineWidth: 1) }
            .background {
                RoundedRectangle(cornerRadius: 27, style: .continuous).fill(accent.opacity(0.18)).padding(-3)
            }
            .shadow(color: .black.opacity(0.8), radius: 22, x: 0, y: 26)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .contain)
    }

    /// Two radial washes: the accent's light at the top, then the deep floor.
    private func field(side: CGFloat) -> some View {
        let core = isGold ? ChapterInk.goldStageCore : Color.black.mix(Color(rgb: PitchAccents.triad(for: entry.slug).c2), 0.5)
        return ZStack {
            RadialGradient(stops: [.init(color: core, location: 0), .init(color: ChapterInk.stageFloor, location: 0.82)],
                           center: UnitPoint(x: 0.5, y: 0.3), startRadius: 0, endRadius: side * 1.05)
            RadialGradient(stops: [.init(color: isGold ? ChapterInk.goldStageWash : accent.opacity(0.18), location: 0),
                                   .init(color: .clear, location: 0.6)],
                           center: UnitPoint(x: 0.5, y: 0.18), startRadius: 0, endRadius: side * 1.1)
        }
    }

    /// The conic ring at 8% inset, masked to its outer fifth.
    private func ring(side: CGFloat) -> some View {
        let diameter = side * 0.84
        return Circle()
            .strokeBorder(AngularGradient(stops: [.init(color: .clear, location: 0),
                                                  .init(color: accent.opacity(0.4), location: 0.19),
                                                  .init(color: .clear, location: 0.38),
                                                  .init(color: .clear, location: 1)],
                                          center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)),
                          lineWidth: diameter * 0.1)
            .frame(width: diameter, height: diameter)
            .opacity(0.25)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func face(side: CGFloat) -> some View {
        if let film {
            FocusFill(aspect: BundledImage.load(film.poster).map { $0.size.width / max($0.size.height, 1) } ?? 9.0 / 16.0,
                      focus: FocusCrop.unitPoint(film.focus)) {
                GripLoopFace(film: film, plays: !paused)
            }
            .frame(width: side, height: side)
            .accessibilityElement()
            .accessibilityLabel(film.clip.alt)
        } else if let photo {
            FocusFill(aspect: BundledImage.load(photo.src).map { $0.size.width / max($0.size.height, 1) } ?? 3.0 / 4.0,
                      focus: .center) {
                BundledImage(src: photo.src, alt: photo.alt, contentMode: .fit)
            }
            .frame(width: side, height: side)
        } else {
            ZStack {
                Circle().fill(RadialGradient(colors: [accent.opacity(0.32), .clear], center: .center,
                                             startRadius: 0, endRadius: side * 0.46))
                SeamBall(motion: entry.motion, size: side * 0.78, showMovement: false)
            }
            .frame(width: side, height: side)
            .accessibilityElement()
            .accessibilityLabel("The \(entry.canonical.name) seam schematic, turned on its spin axis.")
        }
    }

    private var emberChip: some View {
        Text("Ember · 1 of 1 · Reference".uppercased())
            .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
            .tracking(em: 0.14, size: 10)
            .foregroundStyle(PitchAtlasTheme.bone)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(accent))
            .padding(14)
    }

    /// One bar along the foot: the chip on the left, Pause on the right. Under
    /// 380pt the control keeps only its icon so the chip keeps its words.
    @ViewBuilder
    private func mediaBar(side: CGFloat) -> some View {
        if film != nil || photo != nil {
            let plays = film != nil && !reduceMotion
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Circle().fill(PitchAtlasTheme.cyan).frame(width: 6, height: 6).accessibilityHidden(true)
                    Text(SpecimenReads.heroChip(hasClip: film != nil, reduced: reduceMotion, held: paused).uppercased())
                        .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                        .tracking(em: 0.14, size: 10)
                        .foregroundStyle(PitchAtlasTheme.bone)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(ChapterInk.mediaChip))
                Spacer(minLength: 0)
                if plays { PauseMotionButton(onMedia: true, iconOnly: side - 28 < 380) }
            }
            .padding(14)
        }
    }
}

/// The macro cut of Austin's own game ball behind the hero, a whisper at 18%,
/// fading out toward the edges (index.css .pa-atmo-specimen-stage).
private struct HeroAtmosphere: View {
    var body: some View {
        FocusFill(aspect: 1672.0 / 941.0, focus: UnitPoint(x: 0.58, y: 0.46)) {
            BundledImage(src: "/atmosphere/specimen-stage.webp", alt: "", contentMode: .fit)
        }
        .opacity(0.18)
        .mask {
            EllipticalGradient(stops: [.init(color: .black, location: 0.3), .init(color: .clear, location: 0.95)],
                               center: UnitPoint(x: 0.5, y: 0.4), startRadiusFraction: 0, endRadiusFraction: 1.0)
        }
        .padding(.horizontal, -20)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}
