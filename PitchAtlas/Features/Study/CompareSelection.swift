import SwiftUI
import Observation

/// The pair at the table, shared by all five tabs: the site's compare/selection.ts
/// (a, b, view, hand, orientation) with CompareProvider's add and replace. Slugs
/// always resolve against the bundle, and a place nothing valid fills stays open.
@Observable final class CompareSelection {
    enum Mode: String, CaseIterable { case grips, cues, movement }
    enum Slot { case a, b }
    private(set) var a: String?
    private(set) var b: String?
    var mode: Mode = .grips
    var hand: Handedness = .right
    var orientation: GripView = .top
    var presented = false
    /// A third pitch, waiting for the reader to choose which place it takes.
    var pending: String?
    struct Inspection: Hashable { let slug: String }
    var inspection: Inspection?
    private var variants: [String: Int] = [:]

    /// The pair in place order, an open place left out.
    var slugs: [String] { [a, b].compactMap { $0 } }
    var canSwap: Bool { a != nil && b != nil }

    func slug(in slot: Slot) -> String? { slot == .a ? a : b }

    func inspect(_ slug: String, store: PitchStore) {
        guard slugs.contains(slug), store.pitch(slug: slug) != nil else { return }
        inspection = Inspection(slug: slug)
    }

    func variantIndex(for entry: PitchAtlasEntry) -> Int {
        let index = variants[entry.slug] ?? -1
        return entry.masterVariants.indices.contains(index) ? index : -1
    }

    func selectVariant(_ index: Int, for entry: PitchAtlasEntry) {
        guard index == -1 || entry.masterVariants.indices.contains(index) else { return }
        variants[entry.slug] = index
    }

    /// A picker fills one place (normalizeSelection): a pitch the bundle lacks
    /// leaves it open, and B never doubles A.
    func set(_ slot: Slot, to slug: String?, store: PitchStore) {
        let valid = slug.flatMap { store.pitch(slug: $0) == nil ? nil : $0 }
        switch slot {
        case .a:
            a = valid
            if a != nil, a == b { b = nil }
        case .b:
            b = valid == a ? nil : valid
        }
        if let inspection, !slugs.contains(inspection.slug) { self.inspection = nil }
        if let pending, slugs.contains(pending) { self.pending = nil }
    }

    /// Swap trades the two places; each pitch keeps the variant picked for it.
    func swap() {
        guard canSwap else { return }
        (a, b) = (b, a)
    }

    /// The site's "Clear comparison": the pair goes, the aspect, hand and view stay.
    func clear() {
        a = nil
        b = nil
        pending = nil
        inspection = nil
    }

    /// Compare fills A, then B; a third pitch waits for the reader to choose which
    /// place it takes. A pitch already at the table only opens the table.
    func add(_ slug: String) {
        inspection = nil
        presented = true
        if slugs.contains(slug) { return }
        if a == nil { a = slug } else if b == nil { b = slug } else { pending = slug; return }
        // a pitch that joined the pair is no longer waiting
        if pending == slug { pending = nil }
    }

    /// The waiting pitch takes this place; the other stays.
    func replace(_ slot: Slot) {
        guard let pending else { return }
        if !slugs.contains(pending) {
            switch slot {
            case .a: a = pending
            case .b: b = pending
            }
        }
        self.pending = nil
    }

    /// compare?a=…&b=…&view=…&hand=…&orientation=… opens the table on that pair,
    /// read the site's way (parseSelection): a pitch the bundle lacks leaves its
    /// place open, a doubled pitch keeps only A, and a bad view, hand or
    /// orientation falls back to the default — never a guessed pitch.
    @discardableResult func handle(_ url: URL, store: PitchStore) -> Bool {
        guard url.scheme == "pitchatlas", url.host == "compare" else { return false }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ key: String) -> String? { items.first { $0.name == key }?.value }
        func valid(_ slug: String?) -> String? { slug.flatMap { store.pitch(slug: $0) == nil ? nil : $0 } }
        let first = valid(value("a"))
        let second = valid(value("b"))
        a = first
        b = first == second ? nil : second
        mode = Mode(rawValue: value("view") ?? "") ?? .grips
        hand = value("hand") == Handedness.left.rawValue ? .left : .right
        orientation = GripView(rawValue: value("orientation") ?? "") ?? .top
        pending = nil
        inspection = nil
        presented = true
        return true
    }

    /// compareUrl: the table's own link, every choice in it.
    var link: URL {
        var components = URLComponents()
        components.scheme = "pitchatlas"
        components.host = "compare"
        components.queryItems = [
            URLQueryItem(name: "a", value: a ?? ""),
            URLQueryItem(name: "b", value: b ?? ""),
            URLQueryItem(name: "view", value: mode.rawValue),
            URLQueryItem(name: "hand", value: hand.rawValue),
            URLQueryItem(name: "orientation", value: orientation.rawValue),
        ]
        // a scheme, a host and plain query items always make a URL
        return components.url ?? URL(fileURLWithPath: "/")
    }
}

struct CompareButton: View {
    let slug: String
    @Environment(\.compareSelection) private var selection
    var body: some View {
        let on = selection.slugs.contains(slug)
        Button { selection.add(slug); Haptics.selection() } label: {
            Label(on ? "In comparison" : "Compare", systemImage: "square.split.2x1")
                .font(PitchAtlasType.font(.hanken600, size: 12, relativeTo: .caption))
                .foregroundStyle(on ? ComponentInk.compareOnInk : ComponentInk.compareInk)
                .padding(.horizontal, 12.8)
                .frame(minHeight: 36)
                .background(RoundedRectangle(cornerRadius: 6).fill(on ? ComponentInk.compareOnFill : ComponentInk.compareFill))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(on ? ComponentInk.selectedOutline : ComponentInk.compareBorder, lineWidth: 1))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Aligned reading fields keep canonical claims separate from attributed variants.
enum CueComparisonField: String, CaseIterable, Identifiable {
    case grip = "Canonical grip"
    case fingers = "Canonical finger placement"
    case cue = "Canonical cue"
    case distinction = "Variant distinction"
    case voice = "In their words"
    var id: String { rawValue }

    func claims(in entry: PitchAtlasEntry, variantIndex: Int) -> [Claim] {
        let variant = entry.masterVariants.indices.contains(variantIndex) ? entry.masterVariants[variantIndex] : nil
        switch self {
        case .grip: return [entry.canonical.grip]
        case .fingers: return entry.canonical.gripDetails
        case .cue: return [entry.canonical.mechanics]
        case .distinction: return variant?.distinction.map { [$0] } ?? []
        case .voice:
            if let variant { return variant.quote.map { [$0] } ?? [] }
            return entry.canonical.voice.map { [$0] } ?? []
        }
    }
}

struct ArchiveChapter: Identifiable, Hashable {
    let id: String
    let title: String
}

enum SpecimenChapter: String, CaseIterable {
    case grip = "Grip", variants = "Variants", lessons = "Lessons", discussion = "Discussion", sources = "Sources"
    var chapter: ArchiveChapter { ArchiveChapter(id: "specimen-" + rawValue.lowercased(), title: rawValue) }
}

/// Native scrolling with direct chapter choices; no scroll takeover or inferred progress.
struct ArchiveChapterNavigation: View {
    let chapters: [ArchiveChapter]
    var compact = false
    let scroll: (String) -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if compact || dynamicTypeSize.isAccessibilitySize {
                Menu {
                    ForEach(chapters) { chapter in
                        Button(chapter.title) { scroll(chapter.id); Haptics.selection() }
                    }
                } label: {
                    Label("Chapters · \(chapters.count)", systemImage: "list.bullet")
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }.accessibilityLabel("Choose a chapter")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 18) {
                        ForEach(chapters) { chapter in
                            Button(chapter.title) { scroll(chapter.id); Haptics.selection() }
                                .frame(minHeight: 44)
                                .accessibilityLabel("Go to \(chapter.title)")
                        }
                    }
                }
            }
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, PitchAtlasSpacing.lg)
        .foregroundStyle(PitchAtlasTheme.bone)
        .background(PitchAtlasTheme.void)
        .overlay(alignment: .bottom) { Rectangle().fill(PitchAtlasTheme.machined).frame(height: 1) }
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
