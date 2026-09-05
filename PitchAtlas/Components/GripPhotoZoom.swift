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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let maxScale: CGFloat = 4

    var body: some View {
        let image = BundledImage.load(src)
        ZStack {
            Color.black.ignoresSafeArea()

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(magnification)
                    .simultaneousGesture(pan)
                    .onTapGesture(count: 2) { toggleZoom() }
                    .accessibilityLabel(alt)
                    .accessibilityValue("\(Int(scale * 100)) percent zoom")
                    .accessibilityHint("Adjust the zoom or use the controls below. Drag to pan.")
                    .accessibilityAdjustableAction { direction in
                        switch direction {
                        case .increment: setZoom(scale + 0.5)
                        case .decrement: setZoom(scale - 0.5)
                        @unknown default: break
                        }
                    }
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
                if image != nil {
                    VStack(spacing: 8) {
                        Text("\(Int(scale * 100))% zoom").font(.subheadline.monospacedDigit())
                        ViewThatFits(in: .horizontal) {
                            HStack { zoomOut; zoomIn; resetZoom }
                            VStack { HStack { zoomOut; zoomIn }; resetZoom }
                        }
                    }
                    .padding(PitchAtlasSpacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(reduceTransparency ? 1 : 0.85))
                    .foregroundStyle(.white)
                }
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

    private var zoomOut: some View {
        Button("Zoom out") { setZoom(scale - 0.5) }
            .frame(minHeight: 44).buttonStyle(.bordered).disabled(scale <= 1)
    }

    private var zoomIn: some View {
        Button("Zoom in") { setZoom(scale + 0.5) }
            .frame(minHeight: 44).buttonStyle(.bordered).disabled(scale >= maxScale)
    }

    private var resetZoom: some View {
        Button("Reset") { setZoom(1) }
            .frame(minHeight: 44).buttonStyle(.bordered)
            .accessibilityLabel("Reset photo zoom and position")
    }

    private func setZoom(_ value: CGFloat) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            scale = min(maxScale, max(1, value))
            lastScale = scale
            if scale == 1 { resetPan() }
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
        setZoom(scale > 1 ? 1 : 2.5)
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
