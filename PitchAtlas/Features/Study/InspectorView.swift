import SwiftUI
import Observation

// =============================================================================
// InspectorView — the bench for one specimen
// =============================================================================
// Web: inspector/SpecimenInspector.tsx (the bench, minus its Card aspect),
// InspectorRail.tsx (InspectorHeader), useInspector.ts (what may open, what a
// partner may be), InspectButton.tsx, dressed by inspector.css and bench.css at the
// site's phone width. One pitch looked at three ways (the grip, the release, the
// flight), or two side by side once "Compare with" names a second. The stage and
// the rows are the table's own BenchBody. Opened from a specimen card's
// "Inspect card", as a full-screen cover like the table.
// =============================================================================

/// The bench's state: which pitch is open, its partner, and the aspect, view and
/// hand it is looked at with. The site keeps these in the address
/// (`?inspect=&with=&aspect=&orientation=&hand=`); here they live for the session.
@Observable final class SpecimenBench {
    struct Opened: Identifiable, Hashable {
        let slug: String
        var id: String { slug }
    }

    var opened: Opened?
    private(set) var partner: String?
    var mode: CompareSelection.Mode = .grips
    /// nil: each pitch's own default view (the site's `orientation: null`).
    var orientation: GripView?
    var hand: Handedness = .right

    /// useInspector's open: only a filed pitch opens. A new bench starts on the grip
    /// with no partner; the view carries over only while a bench is already open,
    /// and the hand always does.
    func open(_ slug: String, store: PitchStore) {
        guard store.pitch(slug: slug) != nil else { return }
        if opened == nil { orientation = nil }
        opened = Opened(slug: slug)
        partner = nil
        mode = .grips
    }

    /// "Compare with": a filed pitch that is not the open one, or none. A chosen pair
    /// is also the comparison tray's pair, so it is waiting after Close.
    func choosePartner(_ slug: String?, store: PitchStore, compare: CompareSelection) {
        guard let open = opened?.slug else { return }
        guard let slug, slug != open, store.pitch(slug: slug) != nil else {
            partner = nil
            return
        }
        partner = slug
        if compare.slug(in: .a) != open || compare.slug(in: .b) != slug {
            compare.set(.a, to: open, store: store)
            compare.set(.b, to: slug, store: store)
        }
    }

    func close() { opened = nil }

    /// BenchBody's `sharedView`: the reader's view, or the first pitch's own.
    func view(for entries: [PitchAtlasEntry]) -> GripView {
        orientation ?? entries.first?.canonical.gripModel.defaultView ?? .top
    }

    // MARK: What the bench says (the site's words)

    /// InspectButton.tsx
    static let inspectLabel = "Inspect card"
    /// InspectButton's sr-only tail: the slug in words.
    static func inspectAccessibility(_ slug: String) -> String {
        "\(inspectLabel) \(slug.replacingOccurrences(of: "-", with: " "))"
    }
    /// BenchControls' `.bench-with`
    static let withLabel = "Compare with"
    static let noPartner = "No second pitch"

    /// SpecimenInspector's ASPECT_NOTE, the dialog's description for each aspect.
    static func note(_ mode: CompareSelection.Mode) -> String {
        switch mode {
        case .grips: "Where each finger meets the seam, finger by finger."
        case .cues: "How the hold becomes the release."
        case .movement: "An illustrative flight drawn from the mound, beside the sourced shape words."
        }
    }

    /// InspectorHeader's h2: the full name, or both names joined by "and".
    static func title(_ entry: PitchAtlasEntry, partner: PitchAtlasEntry?) -> String {
        guard let partner else { return entry.canonical.name }
        return "\(entry.canonical.name) and \(partner.canonical.name)"
    }

    /// family.ts familyOverline: the family over one pitch's name, unless the name
    /// already says it. A pair carries no overline.
    static func overline(_ entry: PitchAtlasEntry) -> String? {
        let label = entry.canonical.family.label
        return entry.canonical.name.lowercased().contains(label.lowercased()) ? nil : label
    }

    /// BenchControls: every other pitch in the bundle.
    static func partnerOptions(for slug: String, store: PitchStore) -> [PitchAtlasEntry] {
        store.pitches.filter { $0.slug != slug }
    }
}

/// Where the bench lives, RootView supplies it. Where it does not (the table's cover,
/// a preview) "Inspect card" does not draw, so a card never offers an action that
/// does nothing — the site's InspectButton without a provider.
private struct SpecimenBenchKey: EnvironmentKey {
    static let defaultValue: SpecimenBench? = nil
}
extension EnvironmentValues {
    var specimenBench: SpecimenBench? {
        get { self[SpecimenBenchKey.self] }
        set { self[SpecimenBenchKey.self] = newValue }
    }
}

/// InspectButton.tsx: `.specimen-action`, the expand mark and "Inspect card".
struct InspectButton: View {
    let slug: String
    @Environment(\.specimenBench) private var bench
    @Environment(PitchStore.self) private var store

    var body: some View {
        if let bench {
            Button { bench.open(slug, store: store); Haptics.selection() } label: {
                Label(SpecimenBench.inspectLabel, systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(PitchAtlasType.font(.hanken600, size: 12, relativeTo: .caption))
                    .foregroundStyle(CompareInk.actionInk)
                    .padding(.horizontal, 12.8)
                    .frame(minHeight: 36)
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(CompareInk.actionRim, lineWidth: 1))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(SpecimenBench.inspectAccessibility(slug))
        }
    }
}

/// The room: the header (name, Close, the aspect switch and "Compare with"), then the
/// bench's stage and rows, inside one 14pt frame on the dimmed page.
struct InspectorView: View {
    let entry: PitchAtlasEntry
    let bench: SpecimenBench
    @Environment(\.compareSelection) private var compare
    @Environment(PitchStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var studying: PitchAtlasEntry?

    private var partner: PitchAtlasEntry? { bench.partner.flatMap(store.pitch(slug:)) }
    private var entries: [PitchAtlasEntry] { [entry] + (partner.map { [$0] } ?? []) }

    var body: some View {
        @Bindable var bench = bench
        let view = Binding<GripView>(get: { bench.view(for: entries) }, set: { bench.orientation = $0 })
        NavigationStack {
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 0) {
                        header
                        // `.specimen-inspector` sits 1rem in from each side
                        BenchBody(entries: entries, viewport: geo.size.width - 32,
                                  mode: $bench.mode, orientation: view, hand: $bench.hand,
                                  framed: false) { studying = $0 }
                    }
                    .background(CompareInk.benchGround)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(CompareInk.roomRim, lineWidth: 1))
                    .overlay(alignment: .top) { CompareInk.roomLip.frame(height: 1).padding(.horizontal, 14) }
                    .padding(16)
                }
                // the room scrolls inside the safe area: never under the clock and battery
                .clipped()
            }
            .background(CompareInk.roomOverlay)
            .toolbar(.hidden, for: .navigationBar)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(SpecimenBench.title(entry, partner: partner)): \(BenchReads.tabLabel(bench.mode).lowercased())")
            .accessibilityHint(SpecimenBench.note(bench.mode))
            // "Study" opens the file in the room, as the table's own Study does
            .navigationDestination(item: $studying) { target in
                PitchDetailView(entry: target, opensAt: .grip)
                    .toolbar(.visible, for: .navigationBar)
                    .toolbarBackground(PitchAtlasTheme.void, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
            }
        }
        .tint(PitchAtlasTheme.kicker)
        // the cover hides RootView's overlay, so the bench asks for room itself
        .overlay {
            if let pending = compare.pending, !compare.presented { MakeRoom(pending: pending) }
        }
    }

    // MARK: The header (.specimen-rail-head, phone width)

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    if partner == nil, let overline = SpecimenBench.overline(entry) {
                        Text(overline)
                            .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                            .tracking(em: 0.13, size: 10)
                            .textCase(.uppercase)
                            .foregroundStyle(CompareInk.key)
                    }
                    title
                        .accessibilityAddTraits(.isHeader)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button { bench.close(); dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(CompareInk.closeInk)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(CompareInk.closeDisc))
                        .overlay(Circle().strokeBorder(CompareInk.closeRing, lineWidth: 1))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            BenchSeg(label: "Aspect",
                     options: CompareSelection.Mode.allCases.map { ($0, BenchReads.tabLabel($0)) },
                     selected: bench.mode) { bench.mode = $0 }
            partnerPicker
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 4, trailing: 8))
    }

    /// The h2 at 26: a pair's "and" in the gold key at .7em.
    private var title: some View {
        let face = Text(entry.canonical.name)
        let line = partner.map {
            face + Text(" ") + Text("and").font(PitchAtlasType.font(.newsreader400, size: 26 * 0.7, relativeTo: .title2))
                .foregroundStyle(CompareInk.key) + Text(" ") + Text($0.canonical.name)
        } ?? face
        return line
            .font(PitchAtlasType.font(.newsreader400, size: 26, relativeTo: .title))
            .tracking(em: -0.02, size: 26)
            .foregroundStyle(CompareInk.specimenName)
            .cssLineHeight(1.05, face: .newsreader400, size: 26, relativeTo: .title)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// `.bench-with`: the mono key, then the select across the rest of the row.
    private var partnerPicker: some View {
        HStack(spacing: 12) {
            Text(SpecimenBench.withLabel)
                .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                .tracking(em: 0.13, size: 10)
                .textCase(.uppercase)
                .foregroundStyle(CompareInk.key)
                .fixedSize()
                .accessibilityHidden(true)
            Menu {
                Button(SpecimenBench.noPartner) { choose(nil) }
                ForEach(SpecimenBench.partnerOptions(for: entry.slug, store: store)) { option in
                    Button { choose(option.slug) } label: {
                        if option.slug == partner?.slug {
                            Label(option.display.shortName, systemImage: "checkmark")
                        } else {
                            Text(option.display.shortName)
                        }
                    }
                }
            } label: {
                HStack {
                    Text(partner?.display.shortName ?? SpecimenBench.noPartner)
                        .font(PitchAtlasType.font(.martian400, size: 12, relativeTo: .footnote))
                        .tracking(em: 0.02, size: 12)
                        .foregroundStyle(CompareInk.withInk)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(CompareInk.key)
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 10).fill(CompareInk.benchGround))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(CompareInk.withRim, lineWidth: 1))
                .contentShape(Rectangle())
            }
            .accessibilityLabel(SpecimenBench.withLabel)
            .accessibilityValue(partner?.display.shortName ?? SpecimenBench.noPartner)
        }
    }

    private func choose(_ slug: String?) {
        bench.choosePartner(slug, store: store, compare: compare)
        Haptics.selection()
    }
}
