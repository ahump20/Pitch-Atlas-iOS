import SwiftUI

// =============================================================================
// CompareTray — the pitches chosen to compare, above the tab bar
// =============================================================================
// Web: compare/CompareTray.tsx and CompareButton.tsx, dressed by compare.css at
// the site's phone width (under 600px). While a pitch is chosen and the table
// is shut, the tray sits above the tab bar on every page: the two places side
// by side, each a pitch with its Remove or the open place's prompt, then the
// action across the tray's width. The page beneath keeps room for it.
// =============================================================================

/// What the tray and the Compare button say, in the site's words.
enum CompareTrayReads {
    /// The tray's name (`aria-label="Selected pitches"`).
    static let name = "Selected pitches"
    /// `.compare-empty-slot`
    static let emptySlot = "Choose another pitch"

    /// The tray's status line (`role="status"`).
    static func status(chosen: Int) -> String { "\(chosen) of 2 pitches selected" }

    /// A pair opens the table on the pair; one pitch opens it to choose the second.
    static func action(chosen: Int) -> String { chosen >= 2 ? "Compare pair" : "Choose second pitch" }

    static func removeLabel(_ name: String) -> String { "Remove \(name)" }

    /// CompareButton's words: "Compare", or "Selected" once the pitch is chosen.
    static func buttonLabel(selected: Bool) -> String { selected ? "Selected" : "Compare" }

    /// CompareButton's `aria-label`: its words, then the pitch's slug in words.
    static func buttonAccessibility(selected: Bool, slug: String) -> String {
        "\(buttonLabel(selected: selected)) \(slug.replacingOccurrences(of: "-", with: " "))"
    }

    /// The tray shows while a pitch is chosen and the table is shut.
    static func shows(chosen: Int, tableUp: Bool) -> Bool { chosen > 0 && !tableUp }
}

struct CompareTray: View {
    @Environment(\.compareSelection) private var selection
    @Environment(PitchStore.self) private var store

    var body: some View {
        let chosen = selection.slugs.count
        if CompareTrayReads.shows(chosen: chosen, tableUp: selection.presented) {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    place(.a)
                    place(.b)
                }
                Button { selection.presented = true; Haptics.selection() } label: {
                    Text(CompareTrayReads.action(chosen: chosen)).frame(maxWidth: .infinity)
                }
                .buttonStyle(ArchiveActionStyle())
            }
            // padding 10 inside the 1pt rim
            .padding(11)
            .background(RoundedRectangle(cornerRadius: 12).fill(CompareInk.trayFill))
            // the inset lip of light along the top edge
            .overlay(alignment: .top) { CompareInk.trayLip.frame(height: 1).padding(.horizontal, 12).padding(.top, 1) }
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(CompareInk.trayRim, lineWidth: 1))
            .shadow(color: CompareInk.trayShadow, radius: 25, y: 12)
            // calc(100% - 28px), clear of the tab bar
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(CompareTrayReads.name)
        }
    }

    /// `.compare-tray-slot`: the pitch's short name, cut with an ellipsis, and its
    /// Remove; an open place says what it waits for.
    private func place(_ slot: CompareSelection.Slot) -> some View {
        HStack(spacing: 6) {
            if let entry = selection.slug(in: slot).flatMap(store.pitch(slug:)) {
                Text(entry.display.shortName)
                    .font(PitchAtlasType.font(.hanken400, size: 13, relativeTo: .footnote))
                    .foregroundStyle(CompareInk.trayInk)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Button { selection.set(slot, to: nil, store: store); Haptics.selection() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(CompareInk.trayInk)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(CompareTrayReads.removeLabel(entry.display.shortName))
            } else {
                Text(CompareTrayReads.emptySlot)
                    .font(PitchAtlasType.font(.hanken400i, size: 13, relativeTo: .footnote))
                    .foregroundStyle(CompareInk.trayEmpty)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(minHeight: 44)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    /// The tray above the tab bar, on every page a tab's stack shows.
    func compareTray() -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) { CompareTray() }
    }
}
