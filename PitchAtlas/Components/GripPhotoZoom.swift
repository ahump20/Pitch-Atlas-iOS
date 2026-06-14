import SwiftUI

// =============================================================================
// Pitch Atlas — grip photo zoom
// =============================================================================
// The core use of the manual is studying how a grip actually sits on the ball, so
// the first-party photography earns a real close look: a full-screen, pinch-and-pan
// viewer with double-tap to zoom. Still images only — there is no fabricated zoom
// of line art, and films keep their own looping treatment. A missing frame shows
// the seal + alt text here too, never a black void with nothing in it.
// =============================================================================

/// A full-screen, zoomable look at one grip photo.
struct GripPhotoZoomViewer: View {
    let src: String
    let alt: String
    let caption: String

    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let maxScale: CGFloat = 4

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = BundledImage.load(src) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(magnification)
                    .simultaneousGesture(pan)
                    .onTapGesture(count: 2) { toggleZoom() }
                    .accessibilityLabel(alt)
                    .accessibilityHint("Pinch to zoom, double tap to toggle, drag to pan.")
            } else {
                VStack(spacing: PitchAtlasSpacing.sm) {
                    SealMark(size: 64)
                    Text(alt)
                        .font(PitchAtlasTheme.hanken(14))
                        .foregroundStyle(PitchAtlasTheme.bone2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, PitchAtlasSpacing.xl)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Image unavailable. \(alt)")
            }

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.5), in: Circle())
                    }
                    .accessibilityLabel("Close")
                    .padding(PitchAtlasSpacing.md)
                }
                Spacer()
                if !caption.isEmpty {
                    Text(caption)
                        .font(PitchAtlasTheme.hanken(13))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(PitchAtlasSpacing.md)
                        .frame(maxWidth: .infinity)
                        .background(.black.opacity(0.45))
                }
            }
        }
    }

    private var magnification: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(maxScale, max(1, lastScale * value))
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= 1 { resetPan() }
            }
    }

    private var pan: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height)
            }
            .onEnded { _ in lastOffset = offset }
    }

    private func toggleZoom() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if scale > 1 {
                scale = 1; lastScale = 1; resetPan()
            } else {
                scale = 2.5; lastScale = 2.5
            }
        }
    }

    private func resetPan() {
        offset = .zero
        lastOffset = .zero
    }
}

// MARK: - Tap-to-zoom modifier

/// Makes a still grip photo open the full-screen zoom viewer on tap, but only when
/// `enabled` (real photography is on file — not the seal fallback) and only where
/// the tile is not already inside a NavigationLink that owns the tap.
struct OptionalZoom: ViewModifier {
    let enabled: Bool
    let src: String
    let alt: String
    let caption: String
    @State private var presented = false

    func body(content: Content) -> some View {
        if enabled {
            content
                .contentShape(Rectangle())
                .onTapGesture { presented = true }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Double tap to enlarge the photo")
                .fullScreenCover(isPresented: $presented) {
                    GripPhotoZoomViewer(src: src, alt: alt, caption: caption)
                }
        } else {
            content
        }
    }
}
