import SwiftUI
import Observation

/// A session-long pair shared by all five tabs. Slugs always resolve against the bundle.
@Observable final class CompareSelection {
    enum Mode: String, CaseIterable { case grips, cues, movement }
    private(set) var slugs: [String] = []
    var mode: Mode = .grips
    var hand: Handedness = .right
    var orientation: GripView = .top
    var presented = false
    var pending: String?
    var error: String?

    func add(_ slug: String) {
        error = nil
        if slugs.contains(slug) { presented = true; return }
        if slugs.count < 2 { slugs.append(slug) } else { pending = slug }
        presented = true
    }
    func replace(_ index: Int) {
        guard slugs.indices.contains(index), let pending else { return }
        slugs[index] = pending
        self.pending = nil
    }
    func remove(_ slug: String) { slugs.removeAll { $0 == slug } }
    @discardableResult func handle(_ url: URL, store: PitchStore) -> Bool {
        guard url.scheme == "pitchatlas", url.host == "compare" else { return false }
        presented = true
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ key: String) -> String? { items.first { $0.name == key }?.value }
        guard let a = value("a"), let b = value("b"), a != b,
              store.pitch(slug: a) != nil, store.pitch(slug: b) != nil,
              let mode = Mode(rawValue: value("view") ?? "grips"),
              let hand = Handedness(rawValue: value("hand") ?? "right"),
              let orientation = GripView(rawValue: value("orientation") ?? "top"),
              Set(items.map(\.name)).count == items.count else {
            error = "This comparison link is invalid. Choose two different filed pitches and a supported view, hand, and orientation. Your existing pair is still here."
            return true
        }
        slugs = [a, b]; self.mode = mode; self.hand = hand; self.orientation = orientation
        pending = nil; error = nil
        return true
    }
}

struct CompareButton: View {
    let slug: String
    @Environment(\.compareSelection) private var selection
    var body: some View {
        Button { selection.add(slug); Haptics.selection() } label: {
            Label(selection.slugs.contains(slug) ? "In comparison" : "Compare", systemImage: "square.split.2x1")
        }.buttonStyle(.bordered).controlSize(.large)
    }
}

struct StudyTray: View {
    @Environment(\.compareSelection) private var selection
    @Environment(PitchStore.self) private var store
    var body: some View {
        Button { selection.presented = true; Haptics.selection() } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text("THE STUDY TABLE").font(PitchAtlasTheme.martian(11))
                Text(selection.slugs.isEmpty ? "Put two pitches within reach." : selection.slugs.compactMap { store.pitch(slug: $0)?.canonical.name }.joined(separator: " + "))
                    .font(PitchAtlasTheme.newsreader(24))
                Label("Compare grips, cues & movement · \(selection.slugs.count)/2", systemImage: "square.split.2x1")
                    .font(.subheadline)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
                .foregroundStyle(PitchAtlasTheme.cardbackInk)
                .background { ArchiveCoverSurface(radius: 12) }
        }.buttonStyle(.plain)
    }
}

struct CompareView: View {
    @Environment(\.compareSelection) private var selection
    @Environment(PitchStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var body: some View {
        @Bindable var selection = selection
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let error = selection.error { Text(error).accessibilityLabel("Invalid comparison. \(error)") }
                    if case .failed(let reason) = store.status { ErrorStateView(reason: reason) }
                    if let pending = selection.pending {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Replace a pitch with \(store.pitch(slug: pending)?.canonical.name ?? pending)?").font(.headline)
                            ForEach(Array(selection.slugs.enumerated()), id: \.offset) { index, slug in
                                Button("Replace \(store.pitch(slug: slug)?.canonical.name ?? slug)") { selection.replace(index); Haptics.selection() }.buttonStyle(.bordered)
                            }
                            Button("Keep current pair") { selection.pending = nil }
                        }.leatherPress()
                    }
                    studySurface
                    if selection.mode == .movement {
                        Text("Qualitative movement · not tracked flight data.")
                            .font(.subheadline).foregroundStyle(PitchAtlasTheme.bone2)
                    }
                    ForEach(selection.slugs, id: \.self) { slug in
                        if let entry = store.pitch(slug: slug) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(entry.canonical.name).font(PitchAtlasTheme.newsreader(24))
                                switch selection.mode {
                                case .grips: ClaimText(claim: entry.canonical.grip)
                                case .cues:
                                    ClaimText(claim: entry.canonical.mechanics)
                                    ForEach(Array(entry.canonical.gripDetails.enumerated()), id: \.offset) { _, claim in ClaimText(claim: claim) }
                                case .movement:
                                    if let shape = entry.canonical.physics.shape { ClaimText(claim: shape) }
                                    ClaimText(claim: entry.canonical.physics.teaching)
                                }
                                Button("Remove \(entry.display.shortName)") { selection.remove(slug) }
                                    .frame(minHeight: 44)
                            }.leatherPress()
                        }
                    }
                    Text("Choose a filed specimen").font(.headline)
                    ForEach(store.pitches) { entry in
                        Button(entry.canonical.name) { selection.add(entry.slug); Haptics.selection() }
                            .buttonStyle(.bordered).controlSize(.large)
                    }
                    if store.pitches.isEmpty { Text("No filed specimens are available in this bundle.") }
                }.padding(20)
            }.background(PitchAtlasTheme.void).foregroundStyle(PitchAtlasTheme.bone)
                .navigationTitle("Compare")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(PitchAtlasTheme.void, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
    private var studySurface: some View {
        @Bindable var selection = selection
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("THE STUDY TABLE").font(PitchAtlasTheme.martian(10))
                    .tracking(1.5)
                Spacer()
                Text("\(selection.slugs.count) / 2").font(PitchAtlasTheme.martian(10))
            }.foregroundStyle(PitchAtlasTheme.bone2)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            Text("Side by side").font(PitchAtlasTheme.newsreader(28))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            if dynamicTypeSize.isAccessibilitySize {
                Menu {
                    modePicker.pickerStyle(.menu)
                    inspectionPickers(hand: $selection.hand, orientation: $selection.orientation)
                } label: {
                    Label("View", systemImage: "slider.horizontal.3")
                        .frame(minHeight: 44)
                }
                Text("\(selection.mode.rawValue.capitalized) · \(selection.hand.rawValue.capitalized) · \(selection.orientation.rawValue.capitalized)")
                    .font(.caption).foregroundStyle(PitchAtlasTheme.bone2)
            } else {
                modePicker.pickerStyle(.segmented)
                inspectionControls(hand: $selection.hand, orientation: $selection.orientation)
            }
            Rectangle().fill(PitchAtlasTheme.sandBright.opacity(0.5)).frame(height: 1)
            if selection.slugs.count < 2 {
                Text(selection.slugs.isEmpty ? "Choose the first filed pitch below." : "Choose one more filed pitch below.")
                    .font(.subheadline)
            }
            if !selection.slugs.isEmpty {
                GeometryReader { geometry in
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(Array(selection.slugs.enumerated()), id: \.element) { index, slug in
                            if let entry = store.pitch(slug: slug) {
                                if index == 1 {
                                    Rectangle().fill(PitchAtlasTheme.sandBright.opacity(0.35))
                                        .frame(width: 1)
                                }
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("\(index == 0 ? "A" : "B")  /  \(entry.display.specimenNo)")
                                        .font(PitchAtlasTheme.martian(10))
                                        .foregroundStyle(PitchAtlasTheme.bone2)
                                    Text(entry.display.shortName)
                                        .font(PitchAtlasTheme.newsreader(22))
                                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
                                    if selection.mode == .grips {
                                        SeamBall(motion: entry.motion,
                                                 size: min(180, (geometry.size.width - 21) / 2 - 4),
                                                 contacts: entry.canonical.fingerPlacement,
                                                 orientation: selection.orientation, hand: selection.hand,
                                                 showMovement: false,
                                                 referenceContacts: selection.slugs.first.flatMap { store.pitch(slug: $0)?.canonical.fingerPlacement })
                                            .dynamicTypeSize(.large)
                                            .shadow(color: .black.opacity(0.45), radius: 9, x: 0, y: 8)
                                            .accessibilityLabel("Specimen \(index == 0 ? "A" : "B"), \(entry.canonical.name), \(selection.hand.rawValue) hand, \(selection.orientation.rawValue) seam-informed schematic")
                                    }
                                }
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }.frame(height: selection.mode == .grips ? (dynamicTypeSize.isAccessibilitySize ? 260 : 225) : (dynamicTypeSize.isAccessibilitySize ? 110 : 76))
            }
            if selection.mode == .grips {
                Text("Seam-informed schematics · same hand and view. Left hand is mirrored; these are not measured grip geometries.")
                    .font(.caption).foregroundStyle(PitchAtlasTheme.bone2)
            }
        }
        .padding(16)
        .tint(PitchAtlasTheme.bone)
        .background { ArchiveCoverSurface(radius: 18) }

    }

    private var modePicker: some View {
        @Bindable var selection = selection
        return Picker("Compare view", selection: $selection.mode) {
            ForEach(CompareSelection.Mode.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
        }
    }

}

@ViewBuilder func inspectionControls(hand: Binding<Handedness>, orientation: Binding<GripView>) -> some View {
    ViewThatFits(in: .horizontal) {
        HStack { inspectionPickers(hand: hand, orientation: orientation) }
        VStack(alignment: .leading) { inspectionPickers(hand: hand, orientation: orientation) }
    }
}

@ViewBuilder private func inspectionPickers(hand: Binding<Handedness>, orientation: Binding<GripView>) -> some View {
    Group {
        Picker("Hand", selection: hand) { ForEach(Handedness.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) } }.pickerStyle(.menu)
        Picker("Orientation", selection: orientation) { ForEach(GripView.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) } }.pickerStyle(.menu)
    }
}

struct StudyBall: View {
    let entry: PitchAtlasEntry
    var hand: Handedness
    var orientation: GripView
    @State private var zoom = 1.0
    var body: some View {
        VStack(spacing: 12) {
            SeamBall(motion: entry.motion, size: 220, contacts: entry.canonical.fingerPlacement,
                     orientation: orientation, hand: hand, showMovement: false)
                .dynamicTypeSize(.large)
                .scaleEffect(zoom).frame(maxWidth: .infinity).frame(height: 280).clipped()
                .accessibilityLabel("\(entry.canonical.name), \(hand.rawValue) hand, \(orientation.rawValue) seam-informed schematic")
            Slider(value: $zoom, in: 1...1.7) { Text("Inspection zoom") }
            Button("Reset inspection") { zoom = 1; Haptics.selection() }.buttonStyle(.bordered)
            Text("Seam-informed schematic · mirrored for left hand · orientation is a model view, not measured grip geometry.").font(.caption)
        }
    }
}

struct PitchStudy: View {
    let entry: PitchAtlasEntry
    @Environment(PitchStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var step = "Hold"
    @State private var variant = -1
    @State private var hand: Handedness = .right
    @State private var orientation: GripView = .top
    private let steps = ["Hold", "Fingers", "Seam", "Cue"]
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionLabel(text: "GRIP STUDY")
            if dynamicTypeSize.isAccessibilitySize {
                stepPicker.pickerStyle(.menu)
            } else {
                stepPicker.pickerStyle(.segmented)
            }
            inspectionControls(hand: $hand, orientation: $orientation)
            StudyBall(entry: entry, hand: hand, orientation: orientation)
            switch step {
            case "Fingers":
                if entry.canonical.gripDetails.isEmpty { Text("No additional sourced finger instructions are filed.") }
                ForEach(Array(entry.canonical.gripDetails.enumerated()), id: \.offset) { _, claim in ClaimText(claim: claim) }
            case "Seam":
                ClaimText(claim: entry.canonical.gripModel.provenance ?? entry.seam.accuracyNote)
            case "Cue": ClaimText(claim: entry.canonical.mechanics)
            default: ClaimText(claim: entry.canonical.grip)
            }
            Picker("Variant", selection: $variant) {
                Text("Canonical grip").tag(-1)
                ForEach(Array(entry.masterVariants.enumerated()), id: \.offset) { index, item in Text(item.pitcher).tag(index) }
            }.pickerStyle(.menu)
            if entry.masterVariants.indices.contains(variant) {
                let item = entry.masterVariants[variant]
                if let person = store.craftsmen.first(where: { $0.name == item.pitcher && $0.signaturePitchSlug == entry.slug }) {
                    NavigationLink { CraftsmanDetailView(craftsman: person) } label: {
                        Label("Meet \(person.name)", systemImage: "person.crop.rectangle")
                    }.frame(minHeight: 44)
                }
                Text(item.context).font(.subheadline)
                if let distinction = item.distinction { ClaimText(claim: distinction) }
                if let quote = item.quote { ClaimText(claim: quote) }
                Text("The model above remains the canonical schematic; this variant has no separately measured geometry.").font(.caption)
            }
            CompareButton(slug: entry.slug)
        }.leatherPress()
            .onChange(of: step) { _, _ in Haptics.selection() }
            .onChange(of: hand) { _, _ in Haptics.selection() }
            .onChange(of: orientation) { _, _ in Haptics.selection() }
            .onChange(of: variant) { _, _ in Haptics.selection() }
    }
    private var stepPicker: some View {
        Picker("Study step", selection: $step) {
            ForEach(steps, id: \.self) { Text($0).tag($0) }
        }
    }

}

// A default keeps isolated previews and independently hosted reference views usable.
// RootView supplies the actual session state for the full app.
private struct CompareSelectionKey: EnvironmentKey {
    static let defaultValue = CompareSelection()
}
extension EnvironmentValues {
    var compareSelection: CompareSelection {
        get { self[CompareSelectionKey.self] }
        set { self[CompareSelectionKey.self] = newValue }
    }
}
