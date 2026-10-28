import SwiftUI

/// The visitor's switch on ambient motion (web refractor/PauseMotionButton.tsx and
/// material/motionPref): kept on the device, so a Pause pressed on one screen
/// still holds the loops on the next, and every screen that shows a loop carries
/// one, so the way back is always there. The label names what the press will do.
/// Not offered under Reduce Motion, where nothing loops.
enum MotionPreference {
    static let pausedKey = "pa.motion.paused"
}

/// `.specimen-action`: a quiet bordered control; `.is-on-media` sits on a clip
/// in a dark glass and, on a narrow clip, keeps only its icon.
struct PauseMotionButton: View {
    var onMedia = false
    var iconOnly = false
    @AppStorage(MotionPreference.pausedKey) private var paused = false

    var body: some View {
        Button { paused.toggle(); Haptics.selection() } label: {
            HStack(spacing: 8) {
                Image(systemName: paused ? "play.fill" : "pause.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .accessibilityHidden(true)
                if !iconOnly { Text(paused ? "Resume motion" : "Pause motion") }
            }
            .font(PitchAtlasType.font(.hanken600, size: 12, relativeTo: .caption))
            .foregroundStyle(paused ? PitchAtlasTheme.bone : ComponentInk.compareInk)
            .padding(.horizontal, 12.8)
            .frame(minWidth: onMedia ? 44 : nil, minHeight: 44)
            .background(RoundedRectangle(cornerRadius: 6).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(rim, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(paused ? "Resume motion" : "Pause motion")
    }

    private var fill: Color {
        if onMedia { return paused ? ChapterInk.actionOnMediaHeldFill : ChapterInk.actionOnMediaFill }
        return paused ? ChapterInk.actionHeldFill : .clear
    }

    private var rim: Color {
        if paused { return ChapterInk.actionHeldRim }
        return onMedia ? ChapterInk.actionOnMediaRim : ChapterInk.actionRim
    }
}
