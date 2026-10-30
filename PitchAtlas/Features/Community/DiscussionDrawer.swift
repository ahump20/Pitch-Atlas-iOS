import SwiftUI

/// DiscussionPanel.tsx: the invitation, then the thread folded shut behind a
/// frosted bar inside a press panel. Nothing loads until a reader opens it, so a
/// page that is only being read never reaches the server.
struct DiscussionDrawer: View {
    let topic: CommunityTopic
    let topicName: String
    /// `compact` names the thread by the topic alone, as the site's compact variant does.
    var compact = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var open = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What did you notice? Ask about a detail, share a firsthand observation, or add a source to the conversation.")
                .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 14, relativeTo: .subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 60 * 0.56 * 14, alignment: .leading)
                .padding(.bottom, 20)
            VStack(spacing: 0) {
                bar
                if open {
                    CommunityPanel(topic: topic, topicName: topicName)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .overlay(alignment: .top) { Rectangle().fill(PitchAtlasTheme.bone.opacity(0.15)).frame(height: 1) }
                }
            }
            // .rfx-panel: the bar and the thread sit inside its hairline, over
            // the raking catch.
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .padding(1)
            .background { PanelSurface(radius: 12) }
            .inkContext(.object)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bar: some View {
        Button {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { open.toggle() }
            Haptics.selection()
        } label: {
            HStack(spacing: 12) {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 6) { label }
                } else {
                    HStack(spacing: 12) { label }
                }
                Spacer(minLength: 0)
                Text("›")
                    .font(MonoLabel.font)
                    .foregroundStyle(PitchAtlasTheme.bone3)
                    .rotationEffect(.degrees(open ? 90 : 0))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(reduceTransparency ? ArchiveInk.frostCoalSolid : ArchiveInk.frostCoal)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Discussion. \(title)")
        .accessibilityIdentifier("discussion-drawer")
        .accessibilityValue(open ? "Open" : "Closed")
        .accessibilityHint(open ? "Folds the discussion away" : "Opens the discussion")
    }

    private var title: String { compact ? topicName : "Talk through the \(topicName.lowercased())" }

    @ViewBuilder private var label: some View {
        KickerLabel(text: "Discussion").fixedSize()
        Text(title)
            .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
            .foregroundStyle(PitchAtlasTheme.bone2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}
