import SwiftUI

// =============================================================================
// SiteKit — the site's own control kit, where a chapter wears it
// =============================================================================
// Web: components/ui (button, input-group, textarea, select, field, badge,
// separator, skeleton) on the dark theme, as sections/FieldNotes.tsx sets them.
// Buttons are rounded-lg (10) and keep the site's 44pt touch floor; a field is a
// label, the control on --card behind an --input hairline, and a description
// in muted-foreground.
// =============================================================================

enum SiteButtonKind: Equatable {
    /// variant default: the --primary fill, white words.
    case primary
    /// variant outline (dark): an --input hairline over --input at 30%.
    case outline
    /// variant destructive (dark): the seam at 20% under seam words. The site
    /// wears it on a "Tried this" or "Helpful" the reader has marked.
    case marked
    /// variant ghost: no ground; the words carry the ink their caller gives them.
    case ghost
}

struct SiteButtonStyle: ButtonStyle {
    var kind: SiteButtonKind = .primary

    func makeBody(configuration: Configuration) -> some View {
        SiteButtonBody(kind: kind, configuration: configuration)
    }
}

extension ButtonStyle where Self == SiteButtonStyle {
    static func site(_ kind: SiteButtonKind) -> SiteButtonStyle { SiteButtonStyle(kind: kind) }
}

private struct SiteButtonBody: View {
    let kind: SiteButtonKind
    let configuration: ButtonStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        configuration.label
            .foregroundStyle(ink)
            .padding(.horizontal, 10)
            .frame(minWidth: 44, minHeight: 44)
            .background(shape.fill(fill))
            .overlay(shape.strokeBorder(rim, lineWidth: 1))
            .contentShape(shape)
            // active:translate-y-px, and disabled:opacity-50
            .offset(y: configuration.isPressed ? 1 : 0)
            .opacity(isEnabled ? 1 : 0.5)
    }

    private var ink: Color {
        switch kind {
        case .primary: SiteKitInk.onPrimary
        case .marked: SiteKitInk.destructive
        case .outline, .ghost: PitchAtlasTheme.bone
        }
    }

    private var fill: Color {
        switch kind {
        case .primary: SiteKitInk.primary
        case .outline: SiteKitInk.input.opacity(0.3)
        case .marked: SiteKitInk.destructive.opacity(0.2)
        case .ghost: .clear
        }
    }

    private var rim: Color { kind == .outline ? SiteKitInk.input : .clear }
}

/// The mono words a button carries: Martian 500 at the caller's size, tracked
/// the way its className says (tracking-wide is .025em).
func siteButtonLabel(_ text: String, size: CGFloat, trackingEm: CGFloat = 0.025, uppercase: Bool = false) -> some View {
    Text(uppercase ? text.uppercased() : text)
        .font(PitchAtlasType.font(.martian500, size: size, relativeTo: size >= 14 ? .callout : .caption))
        .tracking(em: trackingEm, size: size)
        .lineLimit(1)
}

// MARK: - Fields

/// FieldLabel: Hanken 500, 14, leading-snug, bone (the destructive ink while
/// its field is invalid).
struct SiteFieldLabel: View {
    let text: String
    var invalid = false

    var body: some View {
        Text(text)
            .font(PitchAtlasType.font(.hanken500, size: 14, relativeTo: .subheadline))
            .foregroundStyle(invalid ? SiteKitInk.destructive : PitchAtlasTheme.bone)
            .cssLineHeight(1.375, face: .hanken500, size: 14, relativeTo: .subheadline)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// FieldDescription: Hanken 14 on 1.5 in muted-foreground (destructive while
/// its field is invalid).
struct SiteFieldDescription: View {
    let text: String
    var invalid = false

    var body: some View {
        Text(text)
            .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
            .foregroundStyle(invalid ? SiteKitInk.destructive : SiteKitInk.mutedForeground)
            .cssLineHeight(1.5, face: .hanken400, size: 14, relativeTo: .subheadline)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// FieldError: Hanken 14 in the destructive ink.
struct SiteFieldError: View {
    let text: String

    var body: some View {
        Text(text)
            .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
            .foregroundStyle(SiteKitInk.destructive)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.updatesFrequently)
    }
}

/// Field: the label, the control, the description, eight apart. An invalid
/// field (data-invalid) turns its words the destructive ink.
struct SiteField<Control: View>: View {
    let label: String
    var description: String?
    var invalid = false
    @ViewBuilder let control: () -> Control

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SiteFieldLabel(text: label, invalid: invalid)
            control()
            if let description { SiteFieldDescription(text: description, invalid: invalid) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// InputGroup with its input or textarea: --card behind an --input hairline,
/// radius 10, Hanken 16 in bone, the placeholder in muted-foreground. A line is
/// 44 tall inside the hairline; the textarea opens two lines tall.
struct SiteTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var multiline = false
    var maxLength: Int?
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType?
    var capitalization: TextInputAutocapitalization = .sentences
    var autocorrect = true

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        TextField(label, text: $text,
                  prompt: Text(placeholder).foregroundStyle(SiteKitInk.mutedForeground),
                  axis: multiline ? .vertical : .horizontal)
            .lineLimit(multiline ? 2...10 : 1...1)
            .font(PitchAtlasType.font(.hanken400, size: 16, relativeTo: .body))
            .foregroundStyle(PitchAtlasTheme.bone)
            .tint(PitchAtlasTheme.cyan)
            .keyboardType(keyboard)
            .textContentType(contentType)
            .textInputAutocapitalization(capitalization)
            .autocorrectionDisabled(!autocorrect)
            .padding(.horizontal, 10)
            .padding(.vertical, multiline ? 8 : 4)
            .frame(minHeight: multiline ? 64 : 44, alignment: multiline ? .topLeading : .leading)
            .background(shape.fill(SiteKitInk.card))
            .overlay(shape.strokeBorder(SiteKitInk.input, lineWidth: 1))
            .onChange(of: text) { _, value in
                if let maxLength, value.count > maxLength { text = String(value.prefix(maxLength)) }
            }
    }
}

/// One choice in a select.
struct SiteOption<Value: Hashable>: Hashable {
    let value: Value
    let label: String
}

/// SelectField: the label, then the trigger (--card behind an --input
/// hairline, radius 10, 8/8/8/10, Hanken 14 on 20, the chevron in
/// muted-foreground) opening the system list of choices, then a hint.
struct SiteSelect<Value: Hashable>: View {
    let label: String
    let options: [SiteOption<Value>]
    @Binding var selection: Value
    var hint: String?

    private var current: String { options.first { $0.value == selection }?.label ?? "" }

    var body: some View {
        SiteField(label: label, description: hint) {
            let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
            Menu {
                Picker(label, selection: $selection) {
                    ForEach(options, id: \.self) { option in
                        Text(option.label).tag(option.value)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(current)
                        .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                        .foregroundStyle(PitchAtlasTheme.bone)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SiteKitInk.mutedForeground)
                        .accessibilityHidden(true)
                }
                .padding(.leading, 10)
                .padding(.trailing, 8)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .background(shape.fill(SiteKitInk.card))
                .overlay(shape.strokeBorder(SiteKitInk.input, lineWidth: 1))
                .contentShape(shape)
            }
            .accessibilityLabel(label)
            .accessibilityValue(current)
        }
    }
}

/// Badge, outline: a 20pt pill behind a --border hairline.
struct SiteOutlineBadge: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(PitchAtlasType.font(.martian500, size: 10, relativeTo: .caption2))
            .tracking(em: 0.14, size: 10)
            .foregroundStyle(PitchAtlasTheme.text3)
            .padding(.horizontal, 8)
            .frame(minHeight: 20)
            .overlay(Capsule().strokeBorder(SiteKitInk.border, lineWidth: 1))
    }
}

/// Separator: a --border hairline.
struct SiteSeparator: View {
    var body: some View {
        Rectangle().fill(SiteKitInk.border).frame(height: 1).accessibilityHidden(true)
    }
}

/// Skeleton: a --muted block that pulses unless Reduce Motion holds it still.
struct SiteSkeleton: View {
    var height: CGFloat
    var radius: CGFloat = 4
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dim = false

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(SiteKitInk.muted)
            .frame(height: height)
            .opacity(dim ? 0.5 : 1)
            .animation(reduceMotion ? nil : .easeInOut(duration: 1).repeatForever(autoreverses: true), value: dim)
            .onAppear { if !reduceMotion { dim = true } }
            .accessibilityHidden(true)
    }
}
