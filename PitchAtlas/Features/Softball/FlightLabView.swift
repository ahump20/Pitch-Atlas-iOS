import SwiftUI

// =============================================================================
// FlightLabView — your slow-pitch strike zone, at your height
// =============================================================================
// Web: pages/SoftballFlightLabPage.tsx at the site's phone width, in its order:
// the hero, the rulebook, the stage (the lob's name and verdict over the flat
// schematic), look-for and the dock (Throw, Slow), then the rail (You, Pitches,
// Tune, This pitch, the rulebook's lines and the legal-arc gauge), then every
// figure and its source. The app has no 3D scene yet, so the schematic is the
// stage and there are no camera buttons, as on the site without WebGL. The
// batter's settings stay on this device under the site's storage key. With
// Reduce Motion a throw lands at once. No spin, speed or break figure is shown.
// =============================================================================

struct FlightLabView: View {
    @Environment(PitchStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var rule: SlowpitchRuleKey
    @State private var settings: FlightLabSettings
    @State private var params: [String: SlowpitchLobParams] = [:]
    @State private var selectedKey = "belt"
    @State private var slow = false
    @State private var request: FlightLabThrowRequest?
    @State private var thrownT: Double?
    @State private var playing = false
    @State private var throwCount = 0
    @State private var announced: String?

    /// One store for the app's life, as the site keeps one in-memory copy.
    static let settingsStore = FlightLabSettingsStore(defaults: .standard)

    init(rule: SlowpitchRuleKey = .usssa) {
        _rule = State(initialValue: rule)
        _settings = State(initialValue: Self.settingsStore.read())
    }

    private func stance(_ content: FlightLabContent) -> SlowpitchStance {
        SlowpitchStance(heightIn: settings.heightIn, toesIn: settings.toesIn, box: settings.box,
                        batIn: content.measuredBatter.bat.value.lengthIn)
    }

    private func labModel(_ content: FlightLabContent) -> FlightLabModel? {
        FlightLab.buildLabModel(rule: rule, stance: stance(content), compareIn: settings.compareIn, params: params,
                                selected: selectedKey, lobs: content.lobs, rulebooks: content.rulebooks)
    }

    var body: some View {
        ZStack {
            FieldBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHero(eyebrow: FlightLabReads.eyebrow, title: Text(FlightLabReads.title),
                                sub: Text(FlightLabReads.heroSub),
                                trail: [Crumb(label: "The Atlas", path: "home"), Crumb(label: "Softball", path: "softball"),
                                        Crumb(label: "Slowpitch", path: "softball/slowpitch"), Crumb(label: "Flight lab")],
                                accent: .seam)
                    if let content = store.flightLab, let model = labModel(content) {
                        lab(content, model)
                        FlightLabSources(content: content)
                    } else {
                        unavailable
                    }
                    SiteFooter(path: "/softball/flight-lab")
                }
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                .emitsScrollProgress()
            }
        }
        .navigationTitle("Flight lab")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { BrandLockup(size: .sm) }
        }
        .onChange(of: settings) { _, next in Self.settingsStore.write(next) }
        .task(id: request) { await fly(request) }
        .task(id: statusLine) {
            // one quiet announcement once the controls settle, not one per tick
            guard let line = statusLine else { return }
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            if announced != nil, announced != line { AccessibilityNotification.Announcement(line).post() }
            announced = line
        }
    }

    private var statusLine: String? {
        store.flightLab.flatMap(labModel).map(FlightLabReads.statusText)
    }

    /// The error state: the reason, and the lab on the site.
    private var unavailable: some View {
        VStack(alignment: .leading, spacing: 16) {
            SoftballProse(text: "The Flight Lab’s rulebooks and example lobs did not load with this build, so there is nothing true to draw.",
                          size: 16, ink: PitchAtlasTheme.bone2)
            if let url = SoftballReads.flightLabURL {
                Link(destination: url) { Text("Open the lab on pitch-atlas.com ↗\u{FE0E}") }
                    .buttonStyle(.pitch(.ghost))
                    .accessibilityHint("Opens in Safari")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { PanelSurface() }
        .padding(.horizontal, 20)
        .padding(.vertical, 48)
    }

    // MARK: The throw

    /// The site's useSchematicThrow: elapsed flight time, slowed near the plate and
    /// by Slow, until the longest thrown lob is down. Reduce Motion lands it at once.
    private func fly(_ request: FlightLabThrowRequest?) async {
        thrownT = nil
        guard let request, let content = store.flightLab, let model = labModel(content) else { return }
        let flights = request.indices.compactMap { model.lobs.indices.contains($0) ? model.lobs[$0].flight : nil }
        guard let lead = flights.first else { return }
        let end = flights.map(\.duration).max() ?? 0
        if reduced {
            thrownT = end
            return
        }
        playing = true
        defer { playing = false }
        var t = 0.0
        var last = ContinuousClock.now
        while t < end {
            try? await Task.sleep(for: .milliseconds(16))
            guard !Task.isCancelled else { return }
            let now = ContinuousClock.now
            let elapsed = now - last
            last = now
            let dt = Swift.min(Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18, 0.05)
            let z = Slowpitch.positionAt(lead, Swift.min(t, lead.duration)).z
            t += dt * (slow ? FlightLab.SLOW_RATE : 1) * FlightLab.nearPlateTimeScale(z)
            thrownT = Swift.min(t, end)
        }
    }

    private func throwLobs(_ indices: [Int]) {
        throwCount += 1
        request = FlightLabThrowRequest(id: throwCount, indices: indices)
        Haptics.selection()
    }

    // MARK: The lab

    private func lab(_ content: FlightLabContent, _ model: FlightLabModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // the site's row wraps at phone width: the label over the toggle
            VStack(alignment: .leading, spacing: 8) {
                FlightLabMono(text: "Rulebook")
                SegmentToggle(selection: $rule, options: content.rulebooks.map { ($0.key, $0.name) })
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Rulebook")
            stage(model)
                .padding(.top, 20)
            lookFor(model)
                .padding(.top, 20)
            dock
                .padding(.top, 20)
            VStack(alignment: .leading, spacing: 32) {
                you(content, model)
                pitches(model)
                tune(content, model)
                thisPitch(model)
                rules(model)
            }
            .padding(.top, 32)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .background(FlightLabInk.stage.opacity(0.6))
        .overlay(alignment: .bottom) { PitchAtlasTheme.bone.opacity(0.12).frame(height: 1) }
    }

    private func stage(_ model: FlightLabModel) -> some View {
        let sel = model.selected
        let verdict = sel.reading.verdict
        return ZStack(alignment: .topLeading) {
            FlightLabInk.stage
            FlightLabSchematic(model: model, thrown: thrownT.map { ($0, request?.indices ?? []) }, insetTop: 92)
            LinearGradient(colors: [FlightLabInk.stage.opacity(0.85), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 112)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Circle().fill(FlightLabInk.lob(sel.color)).frame(width: 10, height: 10)
                    Text(sel.name.uppercased())
                        .font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .caption))
                        .tracking(em: 0.12, size: 12)
                        .foregroundStyle(PitchAtlasTheme.bone2)
                }
                Text(verdict.word)
                    .font(PitchAtlasType.font(.anton400, size: 36, relativeTo: .largeTitle))
                    .foregroundStyle(FlightLabTone.ink(verdict.tone))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .padding(16)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
        }
        .containerRelativeFrame(.vertical) { height, _ in Swift.min(600, Swift.max(420, height * 0.68)) }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(PitchAtlasTheme.bone.opacity(0.12), lineWidth: 1))
    }

    private func lookFor(_ model: FlightLabModel) -> some View {
        let range = FlightLab.lookForRange(model)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("LOOK FOR")
                    .font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .caption))
                    .tracking(em: 0.14, size: 12)
                    .foregroundStyle(FlightLabInk.amber)
                FlightLabModelMark(kind: .model)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(range ?? "Nothing")
                    .font(PitchAtlasType.font(.anton400, size: 52, relativeTo: .largeTitle))
                    .monospacedDigit()
                    .foregroundStyle(PitchAtlasTheme.bone)
                if range != nil {
                    Text("in")
                        .font(PitchAtlasType.font(.martian400, size: 20, relativeTo: .title3))
                        .foregroundStyle(PitchAtlasTheme.bone2)
                }
            }
            .padding(.top, 4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(range.map { "Look for \($0.replacingOccurrences(of: "–", with: " to ")) inches" } ?? "Look for nothing")
            FlightLabMono(text: range == nil ? "at this arc reaches your barrel" : "past the front of the plate", size: 12,
                          ink: PitchAtlasTheme.bone2)
                .padding(.top, 8)
            SoftballProse(text: FlightLabReads.lookForBody(model), size: 14, ink: PitchAtlasTheme.bone2, measure: 46)
                .padding(.top, 12)
        }
    }

    private var dock: some View {
        HStack(spacing: 12) {
            Button {
                if let content = store.flightLab, let model = labModel(content) { throwLobs([model.selectedIndex]) }
            } label: { Text("Throw →") }
                .buttonStyle(.pitch(.chrome))
                .disabled(playing)
            Button { slow.toggle() } label: {
                Text("SLOW")
                    .font(PitchAtlasType.segment).tracking(em: 0.06, size: 12)
                    .foregroundStyle(slow ? ComponentInk.onCyanInk : PitchAtlasTheme.bone)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 44)
                    .background { if slow { RoundedRectangle(cornerRadius: 8).fill(PitchAtlasTheme.cyan) } }
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(PitchAtlasTheme.bone.opacity(0.25), lineWidth: 1))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Slow")
            .accessibilityAddTraits(slow ? [.isButton, .isSelected] : .isButton)
        }
    }

    // MARK: The rail

    private func you(_ content: FlightLabContent, _ model: FlightLabModel) -> some View {
        let measured = content.measuredBatter.stance.value
        let isMeasured = settings.heightIn == measured.heightIn && settings.toesIn == measured.toesIn
            && settings.box == measured.box && settings.compareIn == FlightLab.DEFAULT_SETTINGS.compareIn
        return FlightLabRailSection(title: "You", first: true) {
            FlightLabLinkButton(title: "Reset", disabled: isMeasured) { settings = FlightLab.DEFAULT_SETTINGS }
        } content: {
            SoftballProse(text: isMeasured ? FlightLabReads.youMeasured : FlightLabReads.youTuned, size: 14, ink: PitchAtlasTheme.bone2)
            VStack(alignment: .leading, spacing: 24) {
                FlightLabSlider(label: "Height", value: $settings.heightIn, range: FlightLab.HEIGHT_RANGE.min...FlightLab.HEIGHT_RANGE.max,
                                step: 1, display: FlightLab.heightLabel(settings.heightIn),
                                spoken: FlightLab.heightLabel(settings.heightIn).replacingOccurrences(of: " ft ", with: " feet ")
                                    .replacingOccurrences(of: " in", with: " inches"))
                FlightLabSlider(label: "Toes to plate", value: $settings.toesIn, range: FlightLab.TOES_RANGE.min...FlightLab.TOES_RANGE.max,
                                step: 1, display: "\(SlowpitchJS.string(settings.toesIn)) in",
                                spoken: "\(SlowpitchJS.string(settings.toesIn)) inches")
                FlightLabField(label: "Box") {
                    SegmentToggle(selection: $settings.box, options: [(.front, "Front"), (.middle, "Middle"), (.back, "Back")])
                        .accessibilityLabel("Where you stand in the box")
                }
                FlightLabField(label: "Bat") {
                    Text(FlightLabReads.batLine(content.measuredBatter.bat.value))
                        .font(PitchAtlasType.font(.martian400, size: 16, relativeTo: .body))
                        .foregroundStyle(PitchAtlasTheme.bone)
                }
                FlightLabField(label: "Compare") {
                    SegmentToggle(selection: $settings.compareIn,
                                  options: FlightLab.COMPARE_OPTIONS.map { ($0, $0 == 0 ? "Off" : SlowpitchJS.string($0)) })
                        .accessibilityLabel("Compare with your old bat, inches")
                }
                if let c = model.comparison {
                    HStack(alignment: .top, spacing: 16) {
                        FlightLabReadout(label: "Barrel reach", value: FlightLab.signed(c.reachGapIn),
                                         unit: "in vs \(SlowpitchJS.string(model.compareIn))")
                        FlightLabReadout(label: "To match your \(SlowpitchJS.string(model.compareIn))",
                                         value: FlightLab.signed(c.matchShiftIn), unit: "in away")
                    }
                }
            }
            .padding(.top, 20)
        }
    }

    private func pitches(_ model: FlightLabModel) -> some View {
        FlightLabRailSection(title: "Pitches") {
            EmptyView()
        } content: {
            VStack(spacing: 6) {
                ForEach(Array(model.lobs.enumerated()), id: \.element.key) { i, lob in
                    let on = i == model.selectedIndex
                    let v = lob.reading.verdict
                    Button {
                        selectedKey = lob.key
                        request = nil
                        Haptics.selection()
                    } label: {
                        HStack(spacing: 12) {
                            Circle().fill(FlightLabInk.lob(lob.color)).frame(width: 10, height: 10)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lob.name)
                                    .font(PitchAtlasType.font(.anton400, size: 18, relativeTo: .headline))
                                    .foregroundStyle(PitchAtlasTheme.bone)
                                Text(FlightLabReads.lobRow(lob.params))
                                    .font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .caption))
                                    .foregroundStyle(PitchAtlasTheme.bone2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text(v.short.uppercased())
                                .font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .caption))
                                .tracking(em: 0.08, size: 12)
                                .foregroundStyle(FlightLabTone.ink(v.tone))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(minHeight: 52)
                        .background(RoundedRectangle(cornerRadius: 8).fill(on ? PitchAtlasTheme.cyan.opacity(0.07) : .clear))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(on ? PitchAtlasTheme.cyan.opacity(0.6) : .clear, lineWidth: 1))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(lob.name), \(FlightLabReads.lobRow(lob.params)), \(v.short)")
                    .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
                }
            }
            Button { throwLobs(model.lobs.indices.map { $0 }) } label: {
                Text("Throw all six").frame(maxWidth: .infinity)
            }
            .buttonStyle(.pitch(.ghost))
            .disabled(playing)
            .padding(.top, 16)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                FlightLabModelMark(kind: .example)
                Text(FlightLabReads.examplesNote)
                    .font(PitchAtlasType.font(.hanken400, size: 12, relativeTo: .caption))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 12)
        }
    }

    private func tune(_ content: FlightLabContent, _ model: FlightLabModel) -> some View {
        let key = model.selected.key
        let current = model.selected.params
        let defaults = content.lobs.first { $0.key == key }?.params.value
        func binding(_ field: WritableKeyPath<SlowpitchLobParams, Double>) -> Binding<Double> {
            Binding(get: { current[keyPath: field] }, set: { value in
                var next = current
                next[keyPath: field] = value
                params[key] = next
                request = nil
            })
        }
        return FlightLabRailSection(title: "Tune the \(model.selected.name.lowercased())") {
            FlightLabLinkButton(title: "Reset", disabled: defaults == nil || defaults == current) {
                params[key] = nil
                request = nil
            }
        } content: {
            VStack(alignment: .leading, spacing: 24) {
                // the solver lifts any peak under release + 0.4 m, so the slider starts there
                FlightLabSlider(label: "Arc peak", value: binding(\.apex), range: 4.2...13, step: 0.1,
                                display: "\(FlightLab.fixed(current.apex)) ft", spoken: "\(FlightLab.fixed(current.apex)) feet")
                FlightLabSlider(label: "Lands past front edge", value: binding(\.land), range: -30...150, step: 1,
                                display: "\(SlowpitchJS.string(current.land)) in",
                                spoken: "\(SlowpitchJS.string(current.land)) inches past the front of the plate")
                FlightLabSlider(label: "Across the plate", value: binding(\.side), range: -24...24, step: 1,
                                display: FlightLab.sideLabel(current.side),
                                spoken: FlightLab.sideLabel(current.side).replacingOccurrences(of: " in ", with: " inches "))
            }
        }
    }

    private func thisPitch(_ model: FlightLabModel) -> some View {
        FlightLabRailSection(title: "This pitch", mark: .model) {
            EmptyView()
        } content: {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16, alignment: .topLeading),
                                GridItem(.flexible(), spacing: 16, alignment: .topLeading)],
                      alignment: .leading, spacing: 16) {
                ForEach(FlightLabReads.thisPitchStats(model), id: \.self) { s in
                    FlightLabReadout(label: s.label, value: s.value, unit: s.unit, size: 20)
                }
            }
            Text(FlightLabReads.windowNote + (model.selected.reading.lookFor.hot == nil ? FlightLabReads.unreachedNote : ""))
                .font(PitchAtlasType.font(.hanken400, size: 12, relativeTo: .caption))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)
            if !model.selected.flight.converged {
                Text(FlightLabReads.unsolved)
                    .font(PitchAtlasType.font(.hanken400, size: 12, relativeTo: .caption))
                    .foregroundStyle(FlightLabInk.bad)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
            }
        }
    }

    @ViewBuilder
    private func rules(_ model: FlightLabModel) -> some View {
        if let book = model.rulebook {
            FlightLabRailSection(title: "\(book.name) rules") {
                EmptyView()
            } content: {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach([("Zone", book.zoneText), ("Arc", book.arcText), ("Illegal", book.illegalText)], id: \.0) { k, claim in
                        VStack(alignment: .leading, spacing: 8) {
                            FlightLabMono(text: k)
                            RefractorClaimView(claim: claim, ink: PitchAtlasTheme.bone)
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        FlightLabMono(text: "Legal arc, ft, with each lob’s peak")
                        FlightLabArcGauge(model: model)
                            .frame(maxWidth: 360)
                    }
                }
            }
        }
    }
}

// MARK: - The rail's small parts (web components/flightlab/controls.tsx)

enum FlightLabTone {
    static func ink(_ tone: SlowpitchVerdict.Tone) -> Color {
        switch tone {
        case .good: FlightLabInk.amber
        case .warn: FlightLabInk.warn
        case .dim: PitchAtlasTheme.bone2
        case .bad: FlightLabInk.bad
        }
    }
}

/// `.mono-label-stage`: mono 12, upper case, tracked, bone-2.
struct FlightLabMono: View {
    let text: String
    var size: CGFloat = 12
    var ink: Color = PitchAtlasTheme.bone2

    var body: some View {
        Text(text.uppercased())
            .font(PitchAtlasType.font(.martian400, size: size, relativeTo: .caption))
            .tracking(em: 0.12, size: size)
            .foregroundStyle(ink)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Marks a figure the lab models or sets by hand, so it never reads as measured.
struct FlightLabModelMark: View {
    enum Kind { case model, example }
    let kind: Kind

    var body: some View {
        Text(kind == .model ? "MODEL" : "EXAMPLE")
            .font(PitchAtlasType.font(.martian400, size: 11, relativeTo: .caption2))
            .tracking(em: 0.08, size: 11)
            .foregroundStyle(PitchAtlasTheme.bone2)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(PitchAtlasTheme.bone3.opacity(0.6), lineWidth: 1))
            .accessibilityLabel(kind == .model ? "Model" : "Example")
            .accessibilityHint(kind == .model ? FlightLabReads.modelTitle : FlightLabReads.exampleTitle)
    }
}

/// A rail section: the kicker (and its mark) with an action at the right, a rule above all but the first.
struct FlightLabRailSection<Action: View, Content: View>: View {
    let title: String
    var mark: FlightLabModelMark.Kind? = nil
    var first = false
    @ViewBuilder var action: Action
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    SectionKick(text: title).accessibilityAddTraits(.isHeader)
                    if let mark { FlightLabModelMark(kind: mark) }
                }
                Spacer(minLength: 0)
                action
            }
            .padding(.bottom, 20)
            content
        }
        .padding(.top, first ? 0 : 24)
        .overlay(alignment: .top) { if !first { PitchAtlasTheme.bone.opacity(0.12).frame(height: 1) } }
    }
}

/// The rail's quiet link button ("Reset").
struct FlightLabLinkButton: View {
    let title: String
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .caption))
                .tracking(em: 0.08, size: 12)
                .underline(!disabled, color: PitchAtlasTheme.cyan.opacity(0.4))
                .foregroundStyle(disabled ? PitchAtlasTheme.bone3 : PitchAtlasTheme.cyan)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

/// SliderRow: the label and its value over the slider; VoiceOver hears the value in words.
struct FlightLabSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let display: String
    let spoken: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                FlightLabMono(text: label)
                Spacer(minLength: 12)
                Text(display)
                    .font(PitchAtlasType.font(.martian400, size: 14, relativeTo: .subheadline))
                    .monospacedDigit()
                    .foregroundStyle(PitchAtlasTheme.bone)
            }
            .accessibilityHidden(true)
            Slider(value: Binding(get: { value }, set: { value = (($0 / step).rounded() * step * 10).rounded() / 10 }),
                   in: range, step: step)
                .tint(PitchAtlasTheme.cyan)
                .frame(minHeight: 44)
                .accessibilityLabel(label)
                .accessibilityValue(spoken)
        }
    }
}

/// FieldRow: the mono label left, the control right.
struct FlightLabField<Control: View>: View {
    let label: String
    @ViewBuilder var control: Control

    var body: some View {
        HStack(spacing: 16) {
            FlightLabMono(text: label).accessibilityHidden(true)
            Spacer(minLength: 0)
            control
        }
    }
}

/// Readout: a ruled label over a mono figure and its unit.
struct FlightLabReadout: View {
    let label: String
    let value: String
    var unit: String = ""
    var size: CGFloat = 24

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            FlightLabMono(text: label)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(PitchAtlasType.font(.martian400, size: size, relativeTo: .title2))
                    .monospacedDigit()
                    .foregroundStyle(PitchAtlasTheme.bone)
                if !unit.isEmpty {
                    Text(unit)
                        .font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .caption))
                        .foregroundStyle(PitchAtlasTheme.bone2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { PitchAtlasTheme.bone.opacity(0.12).frame(height: 1) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value) \(unit)")
    }
}

/// ArcGauge: the legal arc window as a band on a 0 to 14 ft rule, each lob's peak a dot.
struct FlightLabArcGauge: View {
    let model: FlightLabModel

    var body: some View {
        let window = Slowpitch.legalArcWindow(model.rule)
        Canvas { ctx, size in
            let k = Double(size.width) / 320
            func x(_ ft: Double) -> Double { (12 + (Swift.min(14, Swift.max(0, ft)) / 14) * 296) * k }
            let bone = PitchAtlasTheme.bone
            let band = Path(CGRect(x: x(window.0), y: 8 * k, width: x(window.1) - x(window.0), height: 20 * k))
            ctx.fill(band, with: .color(bone.opacity(0.12)))
            ctx.stroke(band, with: .color(bone.opacity(0.45)), lineWidth: 1)
            var rule = Path()
            rule.move(to: CGPoint(x: 12 * k, y: 28 * k))
            rule.addLine(to: CGPoint(x: 308 * k, y: 28 * k))
            for ft in stride(from: 0.0, through: 14, by: 2) {
                rule.move(to: CGPoint(x: x(ft), y: 28 * k))
                rule.addLine(to: CGPoint(x: x(ft), y: 32 * k))
                ctx.draw(Text(SlowpitchJS.string(ft)).font(.custom(PitchAtlasType.Face.martian400.postScriptName, fixedSize: 12))
                            .foregroundStyle(PitchAtlasTheme.bone2),
                         at: CGPoint(x: x(ft), y: 44 * k), anchor: .center)
            }
            ctx.stroke(rule, with: .color(bone.opacity(0.5)), lineWidth: 1)
            for (i, lob) in model.lobs.enumerated() {
                let on = i == model.selectedIndex
                let r = (on ? 6 : 3.6) * k
                let dot = Path(ellipseIn: CGRect(x: x(lob.flight.apex.y / 0.3048) - r, y: 18 * k - r, width: 2 * r, height: 2 * r))
                ctx.fill(dot, with: .color(FlightLabInk.lob(lob.color)))
                if on { ctx.stroke(dot, with: .color(bone), lineWidth: 1.5) }
            }
        }
        .aspectRatio(320 / 58, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel("Legal arc: \(FlightLab.fixed(window.0)) to \(FlightLab.fixed(window.1, 0)) ft above the ground. Peaks: "
            + model.lobs.map { "\($0.name) \(FlightLab.fixed($0.flight.apex.y / 0.3048)) ft" }.joined(separator: ", ") + ".")
        .accessibilityAddTraits(.isImage)
    }
}

// MARK: - Every figure, and where it comes from

/// The site's sources section: the rulebooks' three lines each, the notes on bat,
/// sweet spot and air, the measured batter, and the six example lobs, every one
/// tagged Model or Example where the lab, not a source, set it.
struct FlightLabSources: View {
    let content: FlightLabContent

    var body: some View {
        let mb = content.measuredBatter
        let stance = mb.stance.value
        VStack(alignment: .leading, spacing: 0) {
            StageTierMarker(index: "01", label: FlightLabReads.sourcesLabel)
            SoftballProse(text: FlightLabReads.sourcesLede, size: 16, ink: PitchAtlasTheme.ink2, measure: 68)
                .padding(.bottom, 32)
            group("Rulebooks", content.rulebooks.flatMap { r in
                [("\(r.name): arc", r.arcText, nil), ("\(r.name): strike zone", r.zoneText, nil), ("\(r.name): illegal pitch", r.illegalText, nil)]
            })
            group("Bat, sweet spot and air", content.notes.map { ($0.label, $0.claim, FlightLabReads.noteIsModel($0.label) ? .model : nil) })
            group("The batter", [
                ("Height, stance and box: one batter’s measured swing",
                 Self.claim(mb.stance, "\(FlightLab.heightLabel(stance.heightIn)), toes \(SlowpitchJS.string(stance.toesIn)) in off the plate, \(stance.box.rawValue) of the box."),
                 .model),
                ("Stride, reach and landmarks: the swing model",
                 Self.claim(mb.swing, "Knee, belt, chest and shoulder heights, the stride and the hands’ reach, as fractions of height."), .model),
                ("Bat", Self.claim(mb.bat, "\(SlowpitchJS.string(mb.bat.value.lengthIn)) in long, 2¼ in across."), nil),
                ("Barrel angle at contact", Self.claim(mb.barrelAngleDeg, "\(SlowpitchJS.string(mb.barrelAngleDeg.value))° below level."), .model),
            ])
            group("The example lobs", content.lobs.map { ($0.name, Self.claim($0.params, FlightLabReads.lobLine($0.params.value)), .example) },
                  last: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 64)
    }

    /// A non-string claim, worn as words with its own tier, source and note.
    static func claim<V>(_ c: SlowpitchClaim<V>, _ words: String) -> Claim {
        Claim(value: words, confidence: c.confidence, source: c.source, note: c.note, approximate: c.approximate)
    }

    private func group(_ title: String, _ rows: [(String, Claim, FlightLabModelMark.Kind?)], last: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            FlightLabMono(text: title, size: 12, ink: PitchAtlasTheme.ink2)
                .padding(.bottom, 8)
                .accessibilityAddTraits(.isHeader)
            ForEach(rows.indices, id: \.self) { i in
                let (label, claim, mark) = rows[i]
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(label)
                            .font(PitchAtlasType.font(.hanken400, size: 15, relativeTo: .body))
                            .foregroundStyle(PitchAtlasTheme.bone)
                            .fixedSize(horizontal: false, vertical: true)
                        if let mark { FlightLabModelMark(kind: mark) }
                    }
                    RefractorClaimView(claim: claim)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) { PitchAtlasTheme.bone.opacity(0.12).frame(height: 1) }
            }
        }
        .padding(.bottom, last ? 0 : 40)
    }
}
