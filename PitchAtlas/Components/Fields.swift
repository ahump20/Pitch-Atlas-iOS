import SwiftUI
import Observation

/// Search: 44pt, radius 14, cyan .40 rim, #1D1710 fill, Hanken 15, a 16pt icon,
/// clear button; focus adds a 3px cyan .5 ring.
struct PitchSearchField: View {
    static let height: CGFloat = 44
    static let radius: CGFloat = 14
    @Binding var text: String
    let prompt: String
    @FocusState private var focused: Bool
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").font(.system(size: 16)).foregroundStyle(ComponentInk.searchIcon).accessibilityHidden(true)
            TextField("", text: $text, prompt: Text(prompt).foregroundStyle(PitchAtlasTheme.placeholder))
                .font(PitchAtlasType.body(size: 15)).foregroundStyle(PitchAtlasTheme.bone)
                .focused($focused).submitLabel(.search).autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityLabel(prompt)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 16)).foregroundStyle(ComponentInk.searchIcon)
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityLabel("Clear search")
            }
        }
        .padding(.leading, 14)
        .frame(minHeight: Self.height)
        .background(RoundedRectangle(cornerRadius: Self.radius, style: .continuous).fill(ComponentInk.searchFill))
        .overlay(RoundedRectangle(cornerRadius: Self.radius, style: .continuous).strokeBorder(PitchAtlasTheme.cyan.opacity(focused ? 1 : 0.4), lineWidth: 1))
        .overlay { if focused { RoundedRectangle(cornerRadius: Self.radius + 3, style: .continuous).strokeBorder(PitchAtlasTheme.cyan.opacity(0.5), lineWidth: 3).padding(-3) } }
        .tint(PitchAtlasTheme.cyan)
    }
}

struct Toast: Identifiable, Equatable { let id = UUID(); let message: String }

/// One toast at a time, bottom-center, 4s — spoken to VoiceOver and felt as the success haptic.
@Observable final class ToastCenter {
    private(set) var current: Toast?
    func show(_ message: String, duration: TimeInterval = 4) {
        let toast = Toast(message: message)
        current = toast
        UIAccessibility.post(notification: .announcement, argument: message)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if self?.current?.id == toast.id { self?.current = nil }
        }
    }
}

struct ToastHost: ViewModifier {
    @Environment(ToastCenter.self) private var center
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let toast = center.current {
                Text(toast.message).font(PitchAtlasType.body(size: 14)).foregroundStyle(PitchAtlasTheme.bone)
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 10).fill(ComponentInk.dialogFill))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(PitchAtlasTheme.bone.opacity(0.12), lineWidth: 1))
                    .padding(.horizontal, 16).padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    .id(toast.id)
                    .accessibilityHidden(true) // already announced
            }
        }
        .animation(PitchAtlasMotion.animation(PitchAtlasMotion.short, reduceMotion: reduceMotion), value: center.current)
    }
}

extension View {
    func toastHost() -> some View { modifier(ToastHost()) }

    /// The web dialog: #0E0B15, radius 14, bone .10 ring, Anton 16 title, Hanken 14 description.
    func pitchDialog<C: View>(isPresented: Binding<Bool>, title: String, description: String, @ViewBuilder content: @escaping () -> C) -> some View {
        sheet(isPresented: isPresented) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title.uppercased()).font(PitchAtlasType.font(.anton400, size: 16, relativeTo: .headline)).foregroundStyle(PitchAtlasTheme.bone)
                    .accessibilityAddTraits(.isHeader)
                Text(description).font(PitchAtlasType.body(size: 14)).foregroundStyle(PitchAtlasTheme.ink2)
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .presentationDetents([.medium])
            .presentationBackground(ComponentInk.dialogFill)
            .presentationCornerRadius(14)
        }
    }
}
