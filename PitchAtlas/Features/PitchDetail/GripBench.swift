import SwiftUI

// =============================================================================
// GripBench — "01 / At the grip bench"
// =============================================================================
// Web: components/study/GripStudy.tsx, grip/GripViewer.tsx, grip/GripUnfiledState
// .tsx and study/GripInspection.tsx, styled by study.css. Two panels: the
// reference model (the seam ball with the filed finger contacts, turned to Top,
// Side or Thumb, either hand, the hand lifted to show the seam beneath) and the
// reading — four steps through the same specimen, a master file kept beside the
// hold, Austin's photographs, and the complete grip notes. The site's 3D hand
// stands here as the drawn ball and its numbered pips; the hand is a named
// fast-follow. An unfiled grip (the eephus) draws no fingers and says so.
// =============================================================================

struct GripBench: View {
    let entry: PitchAtlasEntry
    let grip: GripEntry?
    let accentRGB: UInt32

    @State private var step = 0
    @State private var contact: String?
    @Environment(\.compareSelection) private var comparison

    /// The master kept beside the hold lives in the compare session, so the
    /// same file rides into Compare when the reader sets two grips side by side.
    private var selectedMaster: MasterVariantRecord? {
        let index = comparison.variantIndex(for: entry)
        return entry.masterVariants.indices.contains(index) ? entry.masterVariants[index] : nil
    }

    private var masterName: Binding<String> {
        Binding(get: { selectedMaster?.pitcher ?? "" },
                set: { name in comparison.selectVariant(entry.masterVariants.firstIndex { $0.pitcher == name } ?? -1, for: entry) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading.padding(.bottom, 28)
            SpecimenPanel(entry: entry, accentRGB: accentRGB, master: selectedMaster, highlighted: highlightedFinger)
            StudyReading(entry: entry, photos: grip?.photos ?? [], master: selectedMaster,
                         step: $step, contact: $contact, masterName: masterName)
                .padding(.top, 24)
        }
        .padding(.top, 36)
        .padding(.bottom, 64)
    }

    /// The finger behind the contact a reader picked in step 02, if any.
    private var highlightedFinger: Finger? {
        guard let contact else { return nil }
        return entry.canonical.gripModel.contacts.first { $0.label == contact }?.finger
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 0) {
            StudyEyebrow(text: "01 / At the grip bench")
            Text("Get to know the hold.")
                .font(PitchAtlasType.font(.newsreader400, size: 38, relativeTo: .largeTitle))
                .foregroundStyle(PitchAtlasTheme.bone)
                .cssLineHeight(1.07, face: .newsreader400, size: 38, relativeTo: .largeTitle)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 12)
                .accessibilityAddTraits(.isHeader)
            Text("Four ways into the same specimen. Take them in order, or go straight to the detail you came for.")
                .font(PitchAtlasType.font(.hanken400, size: 16, relativeTo: .body))
                .foregroundStyle(ChapterInk.benchLede)
                .cssLineHeight(1.7, face: .hanken400, size: 16, relativeTo: .body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - The bench's small parts (study.css)

/// `.study-eyebrow`: mono 500 10, upper case, tracked .12em, in the panel's ink.
struct StudyEyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(PitchAtlasType.font(.martian500, size: 10, relativeTo: .caption2))
            .tracking(em: 0.12, size: 10)
            .cssLineHeight(1.6, face: .martian500, size: 10, relativeTo: .caption2)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// `.study-material-note`: 11 on 1.6 at 80%, what the drawing can and cannot say.
struct StudyNote: View {
    let text: String
    var body: some View {
        Text(text)
            .font(PitchAtlasType.font(.hanken400, size: 11, relativeTo: .caption))
            .cssLineHeight(1.6, face: .hanken400, size: 11, relativeTo: .caption)
            .opacity(0.8)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 14)
    }
}

/// `.study-button`: a bordered mono control in the panel's own ink; pressed it
/// takes a leather wash and a 2pt rim, disabled it fades to 40%.
struct StudyButtonStyle: ButtonStyle {
    var on = false
    func makeBody(configuration: Configuration) -> some View { StudyButtonBody(configuration: configuration, on: on) }

    private struct StudyButtonBody: View {
        let configuration: Configuration
        let on: Bool
        @Environment(\.isEnabled) private var isEnabled
        var body: some View {
            configuration.label
                .font(PitchAtlasType.font(.martian500, size: 12, relativeTo: .caption))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 4).fill(on ? ChapterInk.buttonOnFill : .clear))
                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(.foreground, lineWidth: on ? 2 : 1))
                .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)
                .contentShape(Rectangle())
        }
    }
}

// MARK: - The specimen panel

/// `.study-specimen`: the dark radial well with the reference model, its caveat,
/// the inspection, and the master file kept beside it.
private struct SpecimenPanel: View {
    let entry: PitchAtlasEntry
    let accentRGB: UInt32
    let master: MasterVariantRecord?
    let highlighted: Finger?

    private var filed: Bool { entry.canonical.gripModel.status != .unfiled }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StudyEyebrow(text: "\(entry.canonical.name) / Reference model")
            GripViewerPanel(entry: entry, accentRGB: accentRGB, highlighted: highlighted)
                .padding(.top, 4)
            StudyNote(text: entry.canonical.gripModel.visualCaveat)
            if filed {
                GripInspectionButton(label: "reference model") {
                    MasterContext(entry: entry, master: master)
                } content: {
                    SeamBall(motion: entry.motion, size: 300, contacts: entry.canonical.fingerPlacement,
                             orientation: entry.canonical.gripModel.defaultView, showMovement: false,
                             referenceContacts: entry.canonical.fingerPlacement)
                        .dynamicTypeSize(.large)
                        .frame(maxWidth: .infinity)
                }
            }
            if let master {
                VStack(alignment: .leading, spacing: 0) {
                    MasterContext(entry: entry, master: master)
                    StudyNote(text: "The model remains the reference hold. This master file supplies a written distinction.")
                }
                .padding(.top, 16)
                .overlay(alignment: .top) { Rectangle().fill(ChapterInk.selectedRule).frame(height: 1) }
                .padding(.top, 20)
            }
        }
        .foregroundStyle(ChapterInk.specimenText)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(EllipticalGradient(stops: [.init(color: ChapterInk.specimenGlow, location: 0),
                                                 .init(color: ChapterInk.specimenFloor, location: 0.7)],
                                         center: UnitPoint(x: 0.5, y: 0.25), startRadiusFraction: 0, endRadiusFraction: 0.75))
                .shadow(color: ChapterInk.specimenShadow, radius: 20, x: 0, y: 18)
        }
        .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(ChapterInk.specimenRim, lineWidth: 1) }
    }
}

/// The selected master beside the hold: who, their written distinction, and the
/// way to their story. With no master, the inspection names the reference grip.
private struct MasterContext: View {
    let entry: PitchAtlasEntry
    let master: MasterVariantRecord?
    @Environment(PitchStore.self) private var store

    var body: some View {
        if let master {
            VStack(alignment: .leading, spacing: 8) {
                StudyEyebrow(text: "Selected master · \(master.pitcher)")
                if let distinction = master.distinction { RefractorClaimView(claim: distinction, size: 13) }
                if let person = store.master(named: master.pitcher, forPitch: entry.slug) {
                    NavigationLink { CraftsmanDetailView(craftsman: person) } label: {
                        ArchiveLinkLabel(title: "Follow \(person.name)\u{2019}s story", ink: ChapterInk.specimenText)
                    }
                    .buttonStyle(.plain)
                }
            }
        } else {
            Text("Reference grip · \(entry.canonical.name)")
                .font(PitchAtlasType.font(.hanken400, size: 13, relativeTo: .footnote))
        }
    }
}

// MARK: - The reference model

/// GripViewer.tsx at its still branch: the seam ball with the solved contacts,
/// the source badge inside the panel, and the View / Hand / Lift controls. An
/// unfiled grip gets the honest empty state instead.
private struct GripViewerPanel: View {
    let entry: PitchAtlasEntry
    let accentRGB: UInt32
    let highlighted: Finger?

    @State private var view: GripView
    @State private var hand: Handedness = .right
    @State private var showHand = true

    init(entry: PitchAtlasEntry, accentRGB: UInt32, highlighted: Finger?) {
        self.entry = entry
        self.accentRGB = accentRGB
        self.highlighted = highlighted
        _view = State(initialValue: entry.canonical.gripModel.defaultView)
    }

    private var model: GripModel { entry.canonical.gripModel }

    var body: some View {
        if model.status == .unfiled {
            GripUnfiledPanel(entry: entry, accentRGB: accentRGB)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                stage
                controls.padding(.top, 20)
            }
        }
    }

    private var stage: some View {
        GeometryReader { geo in
            let side = geo.size.width
            ZStack(alignment: .bottomLeading) {
                Ellipse()
                    .fill(RadialGradient(colors: [ChapterInk.viewerShadow, .clear], center: .center,
                                         startRadius: 0, endRadius: side * 0.4))
                    .frame(width: side * 0.8, height: side * 0.16)
                    .position(x: side / 2, y: side * 0.89)
                SeamBall(motion: entry.motion, size: side, contacts: showHand ? entry.canonical.fingerPlacement : [],
                         orientation: view, hand: hand, showMovement: false,
                         referenceContacts: entry.canonical.fingerPlacement, highlightedFinger: highlighted)
                    .dynamicTypeSize(.large)
                    .accessibilityLabel("A \(entry.canonical.name) held \(hand.rawValue)-handed, \(view.rawValue) view: the filed finger contacts drawn on the seam."
                                        + (showHand ? "" : " The hand is lifted; the seam shows bare."))
                if let provenance = model.provenance {
                    GripSourceBadge(provenance: provenance).padding(12)
                }
            }
            .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 280)
        .frame(maxWidth: .infinity)
    }

    private var controls: some View {
        FlowRow(spacing: 16, lineSpacing: 12) {
            controlGroup("View") {
                ForEach([GripView.top, .side, .thumb], id: \.self) { option in
                    PitchChip(label: option.rawValue.capitalized, selected: view == option) { view = option; Haptics.selection() }
                }
            }
            controlGroup("Hand") {
                ForEach([Handedness.right, .left], id: \.self) { option in
                    PitchChip(label: option.rawValue.capitalized, selected: hand == option) { hand = option; Haptics.selection() }
                }
            }
            PitchChip(label: showHand ? "Lift the hand" : "Show the hand",
                      dot: showHand ? PitchAtlasTheme.cyan : PitchAtlasTheme.bone.opacity(0.35),
                      selected: !showHand) { showHand.toggle(); Haptics.selection() }
        }
    }

    private func controlGroup<Chips: View>(_ label: String, @ViewBuilder chips: () -> Chips) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                .tracking(em: 0.12, size: 10)
                .foregroundStyle(PitchAtlasTheme.bone2)
                .accessibilityHidden(true)
            HStack(spacing: 8) { chips() }
                .accessibilityElement(children: .contain)
                .accessibilityLabel(label == "View" ? "Grip view" : "Handedness")
        }
    }
}

/// GripUnfiledState.tsx: no canonical grip exists, so none is drawn. The ball,
/// its axis, the marker, the unverified badge, and what to read instead.
private struct GripUnfiledPanel: View {
    let entry: PitchAtlasEntry
    let accentRGB: UInt32

    private var accent: Color { Color(rgb: accentRGB) }

    var body: some View {
        let model = entry.canonical.gripModel
        VStack(alignment: .leading, spacing: 16) {
            GeometryReader { geo in
                let side = geo.size.width
                ZStack {
                    SeamBall(motion: entry.motion, size: side * 0.8, showMovement: false)
                        .dynamicTypeSize(.large)
                        .opacity(0.6)
                        .accessibilityLabel("A \(entry.canonical.name) specimen with no canonical grip drawn. The seam and spin axis are shown; no finger placement is on file.")
                }
                .frame(width: side, height: side)
                .overlay(alignment: .topLeading) {
                    Text("No canonical grip on file".uppercased())
                        .font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2))
                        .tracking(em: 0.14, size: 9)
                        .foregroundStyle(PitchAccents.accentInk(accentRGB))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(web: WebTokens.Palette.stage)))
                        .overlay(Capsule().strokeBorder(accent.opacity(0.45), lineWidth: 1))
                        .padding(14)
                }
                .overlay(alignment: .bottomLeading) {
                    if let provenance = model.provenance { GripSourceBadge(provenance: provenance).padding(14) }
                }
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(PitchAtlasTheme.press)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(RadialGradient(colors: [accent.opacity(0.1), .clear], center: UnitPoint(x: 0.5, y: 0.18),
                                                     startRadius: 0, endRadius: side * 0.7))
                        }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(accent.opacity(0.34), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }
            }
            .aspectRatio(1, contentMode: .fit)
            if let provenance = model.provenance {
                VStack(alignment: .leading, spacing: 8) {
                    Text(provenance.value)
                        .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                        .foregroundStyle(PitchAtlasTheme.bone)
                        .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    if let note = provenance.note {
                        Text(note)
                            .font(PitchAtlasType.font(.hanken400, size: 12.5, relativeTo: .footnote))
                            .foregroundStyle(PitchAtlasTheme.bone2)
                            .cssLineHeight(1.625, face: .hanken400, size: 12.5, relativeTo: .footnote)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            (Text("Read this instead".uppercased())
                .font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2))
                .foregroundStyle(PitchAccents.accentInk(accentRGB))
             + Text("  ")
             + Text(model.releaseCue)
                .font(PitchAtlasType.font(.hanken400, size: 13, relativeTo: .footnote))
                .foregroundStyle(PitchAtlasTheme.bone2))
                .cssLineHeight(1.625, face: .hanken400, size: 13, relativeTo: .footnote)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 14)
                .overlay(alignment: .leading) { Rectangle().fill(accent.opacity(0.4)).frame(width: 2) }
        }
    }
}

// MARK: - The reading

/// `.study-reading`: the four steps, the pager, the master picker, the
/// photographs, and the complete notes, on the leather panel.
private struct StudyReading: View {
    let entry: PitchAtlasEntry
    let photos: [VisualReference]
    let master: MasterVariantRecord?
    @Binding var step: Int
    @Binding var contact: String?
    @Binding var masterName: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepTabs
            StepContent(entry: entry, step: step, contact: $contact)
                .id(step)
                .transition(reduceMotion ? .identity : .opacity.combined(with: .offset(y: 6)))
                .padding(.top, 28)
                .padding(.bottom, 18)
            pager
            if !entry.masterVariants.isEmpty { masterPicker }
            if !photos.isEmpty { StudyPhotoFigure(entry: entry, photos: photos, master: master) }
            FullGripNotes(entry: entry)
        }
        .foregroundStyle(ChapterInk.readingText)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 4)
                .fill(ChapterInk.readingFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [ChapterInk.readingSheen, .clear],
                                             startPoint: UnitPoint(x: 0.03, y: 0.33), endPoint: UnitPoint(x: 0.97, y: 0.67)))
                }
        }
        .overlay { RoundedRectangle(cornerRadius: 4).strokeBorder(ChapterInk.readingRim, lineWidth: 1) }
    }

    private func go(_ next: Int) {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.22)) { step = next }
        contact = nil
        Haptics.selection()
    }

    /// `.study-steps`: four equal tabs on a rule; the open one takes the burnt foot.
    private var stepTabs: some View {
        HStack(spacing: 0) {
            ForEach(Array(SpecimenReads.studySteps.enumerated()), id: \.offset) { index, label in
                let on = step == index
                Button { go(index) } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(format: "%02d", index + 1))
                            .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                            .opacity(0.7)
                        Text(label)
                            .font(PitchAtlasType.font(.hanken400, size: 12, relativeTo: .caption))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, minHeight: 66, alignment: .topLeading)
                    .background(on ? ChapterInk.stepOnFill : .clear)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(on ? ChapterInk.stepOnRule : .clear).frame(height: 3)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(format: "%02d ", index + 1) + label)
                .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
            }
        }
        .overlay(alignment: .bottom) { Rectangle().fill(ChapterInk.stepsRule).frame(height: 1) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Grip study steps")
    }

    private var pager: some View {
        HStack {
            Button("Previous detail") { go(step - 1) }
                .buttonStyle(StudyButtonStyle())
                .disabled(step == 0)
            Spacer(minLength: 8)
            Button("Next detail") { go(step + 1) }
                .buttonStyle(StudyButtonStyle())
                .disabled(step == SpecimenReads.studySteps.count - 1)
        }
    }

    /// `.study-variant-picker`: keep one master's file beside the reference hold.
    private var masterPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Keep a master file beside the hold")
                .font(PitchAtlasType.font(.hanken400, size: 13, relativeTo: .footnote))
            Menu {
                Picker("Keep a master file beside the hold", selection: $masterName) {
                    Text("Reference hold").tag("")
                    ForEach(entry.masterVariants, id: \.pitcher) { variant in
                        Text(variant.pitcher).tag(variant.pitcher)
                    }
                }
            } label: {
                HStack {
                    Text(masterName.isEmpty ? "Reference hold" : masterName)
                        .font(PitchAtlasType.font(.hanken400, size: 16, relativeTo: .body))
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 12, weight: .semibold))
                        .accessibilityHidden(true)
                }
                .foregroundStyle(ChapterInk.selectInk)
                .padding(10)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Rectangle().fill(ChapterInk.selectFill))
                .overlay(Rectangle().strokeBorder(ChapterInk.selectRim, lineWidth: 1))
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Keep a master file beside the hold")
            .accessibilityValue(masterName.isEmpty ? "Reference hold" : masterName)
            .onChange(of: masterName) { _, _ in Haptics.selection() }
        }
        .padding(.top, 22)
        .overlay(alignment: .top) { Rectangle().fill(ChapterInk.readingRule).frame(height: 1) }
        .padding(.vertical, 26)
    }
}

/// One step's reading: its eyebrow and line, then the hold, the fingers (with
/// the filed contacts to light on the ball), the seam, or the one cue.
private struct StepContent: View {
    let entry: PitchAtlasEntry
    let step: Int
    @Binding var contact: String?

    private var canonical: CanonicalPitchRecord { entry.canonical }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StudyEyebrow(text: String(format: "%02d / ", step + 1) + SpecimenReads.studySteps[step])
            Text(SpecimenReads.studyTitles[step])
                .font(PitchAtlasType.font(.newsreader400, size: 30, relativeTo: .title))
                .cssLineHeight(1.13, face: .newsreader400, size: 30, relativeTo: .title)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
                .padding(.bottom, 22)
                .accessibilityAddTraits(.isHeader)
            reading
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var reading: some View {
        switch step {
        case 0:
            RefractorClaimView(claim: canonical.grip, ground: .reading)
        case 1:
            VStack(alignment: .leading, spacing: 22) {
                if canonical.gripDetails.isEmpty {
                    prose("Separate finger-placement details have not been filed. Read the sourced hold for the available account.")
                } else {
                    ForEach(Array(canonical.gripDetails.enumerated()), id: \.offset) { _, claim in
                        RefractorClaimView(claim: claim, ground: .reading)
                    }
                }
            }
            if canonical.gripModel.status != .unfiled { contacts.padding(.top, 20) }
        case 2:
            prose(SpecimenReads.seamStepLine(entry))
            RefractorClaimView(claim: entry.seam.accuracyNote, ground: .reading).padding(.top, 16)
            StudyNote(text: SpecimenReads.seamAccuracyLine(entry))
        default:
            RefractorClaimView(claim: SpecimenReads.sourcedCue(entry), ground: .reading)
        }
    }

    private func prose(_ text: String) -> some View {
        Text(text)
            .font(PitchAtlasType.font(.hanken400, size: 16, relativeTo: .body))
            .cssLineHeight(1.7, face: .hanken400, size: 16, relativeTo: .body)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// `.study-contact-controls`: each filed contact and its job; pressing one
    /// lights that finger on the reference model.
    private var contacts: some View {
        FlowRow(spacing: 8, lineSpacing: 8) {
            ForEach(canonical.gripModel.contacts, id: \.label) { item in
                let on = contact == item.label
                Button("\(item.label) · \(item.pressureRole)") {
                    contact = on ? nil : item.label
                    Haptics.selection()
                }
                .buttonStyle(StudyButtonStyle(on: on))
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Filed finger contacts")
    }
}

// MARK: - Photographs

/// `.study-photo`: Austin's photographs of the hold, one at a time, with the
/// caption, the credit, the view buttons, and the inspection.
private struct StudyPhotoFigure: View {
    let entry: PitchAtlasEntry
    let photos: [VisualReference]
    let master: MasterVariantRecord?
    @State private var index = 0

    var body: some View {
        let photo = photos[min(index, photos.count - 1)]
        VStack(alignment: .leading, spacing: 0) {
            image(photo)
            VStack(alignment: .leading, spacing: 0) {
                Text(photo.caption)
                    .font(PitchAtlasType.font(.hanken400, size: 13, relativeTo: .footnote))
                    .cssLineHeight(1.6, face: .hanken400, size: 13, relativeTo: .footnote)
                    .fixedSize(horizontal: false, vertical: true)
                StudyNote(text: [photo.attribution, "Original photograph", photo.capturedAt].compactMap { $0 }.joined(separator: " · "))
            }
            .padding(.vertical, 14)
            FlowRow(spacing: 8, lineSpacing: 8) {
                ForEach(Array(photos.enumerated()), id: \.offset) { i, item in
                    Button("\(item.view?.rawValue ?? "view") \(i + 1)") { index = i; Haptics.selection() }
                        .buttonStyle(StudyButtonStyle(on: i == index))
                        .accessibilityAddTraits(i == index ? .isSelected : [])
                }
            }
            .padding(.bottom, 12)
            GripInspectionButton(label: "grip photograph") {
                VStack(alignment: .leading, spacing: 12) {
                    MasterContext(entry: entry, master: master)
                    Text("\(photo.caption) · \(photo.attribution ?? "Austin H.") · Original photograph")
                        .font(PitchAtlasType.font(.hanken400, size: 13, relativeTo: .footnote))
                        .fixedSize(horizontal: false, vertical: true)
                }
            } content: {
                BundledImage(src: photo.src, alt: photo.alt, contentMode: .fit)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 24)
        .overlay(alignment: .top) { Rectangle().fill(ChapterInk.readingRule).frame(height: 1) }
        .padding(.top, 28)
    }

    @ViewBuilder
    private func image(_ photo: VisualReference) -> some View {
        if BundledImage.load(photo.src) != nil {
            BundledImage(src: photo.src, alt: photo.alt, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .background(RoundedRectangle(cornerRadius: 4).fill(ChapterInk.photoWell))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            Text("The grip photograph could not load. Its caption and source remain available.")
                .font(PitchAtlasType.font(.hanken400, size: 13, relativeTo: .footnote))
                .fixedSize(horizontal: false, vertical: true)
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 4).fill(ChapterInk.photoWell))
        }
    }
}

// MARK: - The complete notes

/// `.study-full-record`: the guide's steps and feel, then the sourced hold and
/// its details, folded until asked for.
private struct FullGripNotes: View {
    let entry: PitchAtlasEntry
    @State private var open = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { open.toggle(); Haptics.selection() } label: {
                HStack(spacing: 8) {
                    Image(systemName: open ? "arrowtriangle.down.fill" : "arrowtriangle.right.fill")
                        .font(.system(size: 9))
                        .accessibilityHidden(true)
                    Text("The complete grip notes")
                        .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(open ? "Expanded" : "Collapsed")
            if open { notes }
        }
        .padding(.top, 18)
        .overlay(alignment: .top) { Rectangle().fill(ChapterInk.readingRule).frame(height: 1) }
        .padding(.top, 28)
    }

    private var notes: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let guide = entry.guide {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(guide.steps.enumerated()), id: \.offset) { i, step in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(i + 1).").frame(minWidth: 16, alignment: .trailing)
                            Text(step).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .font(PitchAtlasType.font(.hanken400, size: 16, relativeTo: .body))
                .cssLineHeight(1.7, face: .hanken400, size: 16, relativeTo: .body)
                Text(guide.feel)
                    .font(PitchAtlasType.font(.hanken400, size: 16, relativeTo: .body))
                    .fixedSize(horizontal: false, vertical: true)
            }
            RefractorClaimView(claim: entry.canonical.grip, ground: .reading)
            ForEach(Array(entry.canonical.gripDetails.enumerated()), id: \.offset) { _, claim in
                RefractorClaimView(claim: claim, ground: .reading)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Inspection

/// GripInspection.tsx: "Inspect {label}" opens the specimen large, with its
/// context, zoom steps of a quarter from 100% to 200%, and a viewport to pan.
struct GripInspectionButton<Context: View, Content: View>: View {
    let label: String
    @ViewBuilder var context: Context
    @ViewBuilder var content: Content
    @State private var open = false
    @State private var zoom = 1.0

    var body: some View {
        Button("Inspect \(label)") { zoom = 1; open = true; Haptics.selection() }
            .buttonStyle(StudyButtonStyle())
            .sheet(isPresented: $open) { sheet }
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                Text(label)
                    .font(PitchAtlasType.font(.newsreader400, size: 26, relativeTo: .title))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                Button("Close inspection") { open = false }.buttonStyle(StudyButtonStyle())
            }
            context
                .font(PitchAtlasType.font(.hanken400, size: 13, relativeTo: .footnote))
                .padding(.vertical, 16)
            HStack(spacing: 8) {
                Button("Zoom out") { zoom = max(1, zoom - 0.25) }.buttonStyle(StudyButtonStyle()).disabled(zoom <= 1)
                Text("\(Int((zoom * 100).rounded()))%")
                    .font(PitchAtlasType.font(.martian500, size: 12, relativeTo: .caption))
                    .accessibilityLabel("Zoom \(Int((zoom * 100).rounded())) percent")
                Button("Zoom in") { zoom = min(2, zoom + 0.25) }.buttonStyle(StudyButtonStyle()).disabled(zoom >= 2)
                Button("Reset zoom") { zoom = 1 }.buttonStyle(StudyButtonStyle())
            }
            .padding(.vertical, 12)
            GeometryReader { geo in
                ScrollView([.horizontal, .vertical]) {
                    content
                        .frame(width: geo.size.width * zoom)
                }
                .accessibilityLabel("Grip detail. Scroll to inspect the enlarged image.")
            }
            .overlay { Rectangle().strokeBorder(ChapterInk.viewportRim, lineWidth: 1) }
        }
        .foregroundStyle(ChapterInk.dialogInk)
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ChapterInk.dialogFill)
        .presentationBackground(ChapterInk.dialogFill)
        .presentationDragIndicator(.visible)
    }
}
