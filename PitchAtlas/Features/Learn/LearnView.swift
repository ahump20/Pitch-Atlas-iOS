import SwiftUI

// =============================================================================
// LearnView — the field-manual hub (teaching layer)
// =============================================================================
// The knowledge-wings index. Not a tab — pushed from the Atlas home, but a
// standalone screen. Each wing is a sourced essay; this screen is the front
// door to them. Four states: a decode failure shows the error, an empty bundle
// explains itself, and the populated case is a stack of hub cards.
// =============================================================================

struct LearnView: View {
    @Environment(PitchStore.self) private var store

    var body: some View {
        ZStack {
            FieldBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: PitchAtlasSpacing.lg) {
                    masthead

                    content
                }
                .padding(.horizontal, PitchAtlasSpacing.md)
                .padding(.top, PitchAtlasSpacing.md)
                .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
            }
        }
        .navigationTitle("Learn")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: KnowledgeWing.self) { wing in
            KnowledgeWingView(wing: wing)
        }
    }

    // MARK: - Masthead

    private var masthead: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            SectionLabel(text: "ONE PITCH AT A TIME", color: PitchAtlasTheme.powder)
            Text("LEARN")
                .font(PitchAtlasTheme.anton(48))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
            Text("Command before stuff. Lower half, line to the plate, finish low, then trust the target.")
                .font(PitchAtlasTheme.newsreaderItalic(17))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("One pitch at a time. Learn. Command before stuff. Lower half, line to the plate, finish low, then trust the target.")
    }

    // MARK: - Content (four states)

    @ViewBuilder
    private var content: some View {
        if case .failed(let msg) = store.status {
            ErrorStateView(reason: msg)
        } else if store.knowledge.isEmpty {
            EmptyStateView(message: "The field manual couldn't load.")
        } else {
            VStack(spacing: PitchAtlasSpacing.sm) {
                ForEach(store.knowledge) { wing in
                    NavigationLink(value: wing) {
                        WingHubCard(wing: wing)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Hub card

private struct WingHubCard: View {
    let wing: KnowledgeWing

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            HStack(alignment: .top) {
                SectionLabel(text: wing.eyebrow)
                Spacer(minLength: PitchAtlasSpacing.xs)
                if wing.educational == true {
                    StatusPill(text: "Educational use", tone: PitchAtlasTheme.amberBright)
                }
            }

            Text(wing.title)
                .font(PitchAtlasTheme.newsreader(20))
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)

            Text(wing.summary)
                .font(PitchAtlasTheme.hanken(13))
                .foregroundStyle(PitchAtlasTheme.ink3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .leatherPress()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityText: String {
        var parts = [wing.eyebrow, wing.title, wing.summary]
        if wing.educational == true { parts.insert("Educational use", at: 1) }
        return parts.joined(separator: ". ")
    }
}
