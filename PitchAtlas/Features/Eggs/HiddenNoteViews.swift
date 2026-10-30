import SwiftUI

// =============================================================================
// The hidden notes on screen: the spot, the reveal, the found index
// =============================================================================
// Web: components/eggs/EggButton.tsx (an element that already belongs on the page,
// quietly a real button with an aria-label; once found, a faint cyan underline),
// TidbitReveal.tsx and FoundIndex.tsx in EggDialog.tsx's panel. Each spot opens its
// own sheet, so a note found inside the bench's cover shows over the cover; the
// reveal's "Filed: n of 10 found" turns the same sheet into the index.
// =============================================================================

/// A hidden-in-plain-sight spot around content the page already shows.
struct EggButton<Label: View>: View {
    let note: HiddenNotePlacement
    @ViewBuilder var label: Label
    @Environment(\.hiddenNotes) private var notes
    @State private var open: HiddenNoteSheet.Mode?

    var body: some View {
        if let notes {
            Button {
                notes.discover(note.rawValue)
                open = .reveal(note.rawValue)
            } label: {
                label
                    .underline(notes.has(note.rawValue), color: PitchAtlasTheme.cyan.opacity(0.4))
                    // the site's coarse-pointer target: 44pt without moving the line
                    .padding(.vertical, 14)
                    .frame(minWidth: 44, alignment: .leading)
                    .contentShape(Rectangle())
                    .padding(.vertical, -14)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(note.label)
            .sheet(item: $open) { mode in HiddenNoteSheet(mode: mode, notes: notes) }
        } else {
            label
        }
    }
}

/// The footer's quiet on-ramp: "Hidden notes · n of 10 found", opening the index.
struct HiddenNotesCounter: View {
    @Environment(\.hiddenNotes) private var notes
    @State private var open: HiddenNoteSheet.Mode?

    var body: some View {
        if let notes {
            Button { open = .index } label: {
                Text(HiddenNotes.footerLine(count: notes.count, total: notes.total).uppercased())
                    .font(MonoLabel.font)
                    .tracking(MonoLabel.trackingEm * MonoLabel.size)
                    .foregroundStyle(PitchAtlasTheme.bone2.opacity(0.75))
                    .underline(color: PitchAtlasTheme.bone2.opacity(0.3))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(HiddenNotes.footerLine(count: notes.count, total: notes.total))
            .sheet(item: $open) { mode in HiddenNoteSheet(mode: mode, notes: notes) }
        }
    }
}

struct HiddenNoteSheet: View {
    enum Mode: Identifiable, Hashable {
        case reveal(String), index
        var id: Self { self }
    }

    @State var mode: Mode
    let notes: HiddenNotes
    @Environment(PitchStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            Group {
                switch mode {
                case .reveal(let id):
                    if let note = store.tidbit(id: id) { reveal(note) }
                case .index:
                    index
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(HiddenNoteInk.panel)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: TidbitReveal.tsx

    private func reveal(_ note: Tidbit) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            stageLabel(HiddenNotes.foundKick, ink: PitchAtlasTheme.cyan)
            Text(note.title)
                .font(PitchAtlasType.font(.newsreader400, size: 24, relativeTo: .title2))
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .accessibilityAddTraits(.isHeader)
            Text(note.claim.value)
                .font(PitchAtlasType.font(.hanken400, size: 16, relativeTo: .body))
                .lineSpacing(5)
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    sourceLink(note)
                    Button { mode = .index } label: {
                        stageLabel(HiddenNotes.filedLine(count: notes.count, total: notes.total),
                                   ink: PitchAtlasTheme.bone2.opacity(0.7))
                            .underline(color: PitchAtlasTheme.bone2.opacity(0.3))
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
                closeButton
            }
            .padding(.top, 16)
            .overlay(alignment: .top) { PitchAtlasTheme.bone.opacity(0.10).frame(height: 1) }
            .padding(.top, 20)
        }
    }

    // MARK: FoundIndex.tsx

    private var index: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    stageLabel(HiddenNotes.indexKick, ink: PitchAtlasTheme.cyan)
                    Text(HiddenNotes.indexTitle(count: notes.count, total: notes.total))
                        .font(PitchAtlasType.font(.newsreader400, size: 24, relativeTo: .title2))
                        .foregroundStyle(PitchAtlasTheme.bone)
                        .accessibilityAddTraits(.isHeader)
                }
                Spacer(minLength: 0)
                closeButton
            }
            Text(HiddenNotes.indexLede)
                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                .lineSpacing(4)
                .foregroundStyle(PitchAtlasTheme.bone2.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
            VStack(spacing: 12) {
                ForEach(store.tidbits) { note in row(note) }
            }
            .padding(.top, 20)
        }
    }

    @ViewBuilder
    private func row(_ note: Tidbit) -> some View {
        let found = notes.has(note.id)
        VStack(alignment: .leading, spacing: 6) {
            if found {
                Text(note.title)
                    .font(PitchAtlasType.font(.newsreader400, size: 18, relativeTo: .headline))
                    .foregroundStyle(PitchAtlasTheme.bone)
                    .fixedSize(horizontal: false, vertical: true)
                Text(note.claim.value)
                    .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                    .lineSpacing(4)
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
                sourceLink(note)
            } else {
                HStack(spacing: 12) {
                    Text("·").foregroundStyle(PitchAtlasTheme.bone2.opacity(0.4)).accessibilityHidden(true)
                    stageLabel(HiddenNotes.lockedLine(note.eggLocation), ink: PitchAtlasTheme.bone2.opacity(0.55))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(found ? PitchAtlasTheme.bone.opacity(0.03) : Color.clear)
        .overlay(RoundedRectangle(cornerRadius: 2)
            .strokeBorder(PitchAtlasTheme.bone.opacity(found ? 0.15 : 0.08), lineWidth: 1))
    }

    // MARK: Pieces

    @ViewBuilder
    private func sourceLink(_ note: Tidbit) -> some View {
        if let source = note.claim.source, let url = URL(string: source.url) {
            Link(destination: url) {
                stageLabel(source.label, ink: PitchAtlasTheme.bone2)
                    .underline(color: PitchAtlasTheme.bone2.opacity(0.4))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityHint("Opens in Safari")
        }
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
            Text("CLOSE")
                .font(PitchAtlasType.font(.martian400, size: 11, relativeTo: .caption2))
                .tracking(em: 0.14, size: 11)
                .foregroundStyle(PitchAtlasTheme.bone)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(PitchAtlasTheme.bone.opacity(0.3), lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }

    /// `.mono-label-stage`: mono 11, capitals, tracked.
    private func stageLabel(_ text: String, ink: Color) -> some View {
        Text(text.uppercased())
            .font(MonoLabel.font)
            .tracking(MonoLabel.trackingEm * MonoLabel.size)
            .foregroundStyle(ink)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - A note inside a line of text

extension HiddenNotePlacement {
    /// The in-text link a spot inside running copy carries (the Sources as-of date).
    var url: URL? { URL(string: "pitchatlas-note://\(rawValue)") }
}

/// Opens the reveal for a `pitchatlas-note://<id>` link tapped inside this view's
/// text, and offers the same reveal as a VoiceOver action.
struct HiddenNoteLinks: ViewModifier {
    let note: HiddenNotePlacement
    @Environment(\.hiddenNotes) private var notes
    @State private var open: HiddenNoteSheet.Mode?

    func body(content: Content) -> some View {
        if let notes {
            content
                .environment(\.openURL, OpenURLAction { url in
                    guard url.scheme == "pitchatlas-note", let host = url.host(), host == note.rawValue else {
                        return .systemAction
                    }
                    reveal(notes)
                    return .handled
                })
                .accessibilityAction(named: Text(note.label)) { reveal(notes) }
                .sheet(item: $open) { mode in HiddenNoteSheet(mode: mode, notes: notes) }
        } else {
            content
        }
    }

    private func reveal(_ notes: HiddenNotes) {
        notes.discover(note.rawValue)
        open = .reveal(note.rawValue)
    }
}

extension View {
    func hiddenNoteLinks(_ note: HiddenNotePlacement) -> some View { modifier(HiddenNoteLinks(note: note)) }
}
