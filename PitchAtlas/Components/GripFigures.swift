import SwiftUI

// =============================================================================
// Grip figures — Austin's photographs and clips as the site frames them
// =============================================================================
// Web: sections/GripLibrary.tsx GripPhoto and GripMotion. Each is a 4:3 window on
// a dark ground under a 14pt corner: the photo (or the looping clip) cropped to
// fill, a small glass chip naming the view or the motion, then the caption and
// the credit with its cyan dot. A photo opens full frame to be read; a missing
// file shows the seal and its alt words, never a blank box.
// =============================================================================

extension VisualReference {
    /// KIND_LABEL · attribution · the capture year, as GripPhoto's credit line.
    var creditLine: String {
        let kindLabel: String = switch kind {
        case .firstParty: "Original"
        case .community: "Community"
        case .creativeCommons: "Creative Commons"
        case .publicDomain: "Public domain"
        case .licensed: "Licensed"
        }
        return [kindLabel, attribution, capturedAt.map { String($0.prefix(4)) }]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}

extension GripView {
    /// VIEW_LABEL: the thumb view is the underside.
    var photoLabel: String {
        switch self {
        case .top: "Top"
        case .side: "Side"
        case .thumb: "Underside"
        }
    }
}

/// The small glass chip on a figure: mono 9, upper case, on black at 55%.
private struct FigureChip: View {
    let text: String
    var dot = false

    var body: some View {
        HStack(spacing: 4) {
            if dot { Circle().fill(PitchAtlasTheme.cyan).frame(width: 6, height: 6) }
            Text(text.uppercased())
        }
        .font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2))
        .tracking(em: 0.1, size: 9)
        .foregroundStyle(PitchAtlasTheme.bone)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Capsule().fill(Color.black.opacity(0.55)))
        .padding(10)
        .accessibilityHidden(true)
    }
}

/// The figure's caption and its credit, 14pt in from the edges.
private struct FigureCaption: View {
    let caption: String
    let credit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(caption)
                .font(PitchAtlasType.font(.hanken400, size: 13, relativeTo: .footnote))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 13, relativeTo: .footnote)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                Circle().fill(PitchAtlasTheme.cyan).frame(width: 6, height: 6).accessibilityHidden(true)
                Text(credit.uppercased())
                    .font(PitchAtlasType.font(.martian400, size: 9, relativeTo: .caption2))
                    .tracking(em: 0.08, size: 9)
                    .foregroundStyle(PitchAtlasTheme.ink3)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// GripPhoto: one of Austin's grip photographs, cropped 4:3, its view named, its
/// caption and credit beneath; a tap opens it full frame.
struct GripPhotoFigure: View {
    let photo: VisualReference
    @State private var examining = false

    private var loaded: Bool { BundledImage.load(photo.src) != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .aspectRatio(4.0 / 3.0, contentMode: .fit)
                .overlay { BundledImage(src: photo.src, alt: photo.alt, contentMode: .fill) }
                .clipped()
                .overlay(alignment: .topLeading) {
                    if let view = photo.view { FigureChip(text: view.photoLabel) }
                }
                .contentShape(Rectangle())
                .onTapGesture { if loaded { examining = true } }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(photo.alt)
                .accessibilityAddTraits(loaded ? .isButton : .isImage)
                .accessibilityHint(loaded ? "Examine the grip photo full size" : "")
            FigureCaption(caption: photo.caption, credit: photo.creditLine)
        }
        .background(ChapterInk.plateGround)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(PitchAtlasTheme.bone.opacity(0.12), lineWidth: 1))
        .fullScreenCover(isPresented: $examining) {
            GripPhotoZoomViewer(src: photo.src, alt: photo.alt, caption: photo.caption)
        }
    }
}

/// GripMotion: the looping clip of Austin's hand, cropped 4:3 to its focus, the
/// MOTION chip, the clip's words and the credit. Held on its poster while motion
/// is paused or reduced. `large` is the library's theater: the clip at its own
/// 9:16 portrait, filled from the middle as the site's `object-cover` does.
struct GripMotionFigure: View {
    let film: GripFilm
    var large = false
    @AppStorage(MotionPreference.pausedKey) private var paused = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .aspectRatio(large ? 9.0 / 16.0 : 4.0 / 3.0, contentMode: .fit)
                .overlay {
                    FocusFill(aspect: BundledImage.load(film.poster).map { $0.size.width / max($0.size.height, 1) } ?? 9.0 / 16.0,
                              focus: large ? .center : FocusCrop.unitPoint(film.focus)) {
                        GripLoopFace(film: film, plays: !paused)
                    }
                }
                .clipped()
                .overlay(alignment: .topLeading) { FigureChip(text: "Motion", dot: true) }
                .accessibilityElement()
                .accessibilityLabel(film.clip.alt)
            FigureCaption(caption: film.clip.alt, credit: "Original · Austin H.")
        }
        .background(ChapterInk.plateGround)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(PitchAtlasTheme.cyan.opacity(0.25), lineWidth: 1))
    }
}
