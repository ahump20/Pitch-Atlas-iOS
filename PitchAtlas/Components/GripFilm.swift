import AVFoundation
import SwiftUI

// =============================================================================
// GripFilm — first-party footage as the specimen face
// =============================================================================
// The owner's own grip clips, looping muted like the web's card faces. The film
// leads wherever it exists; the drawn SeamBall stays the face only where no real
// footage is on file — real footage > real photo > line art, never faked up a
// tier. Reduce Motion shows the poster with an explicit play control instead of
// autoplaying. Audio session stays ambient so a muted loop never ducks the
// listener's music.
// =============================================================================

struct GripFilmCard: View {
    let film: GripFilm
    var height: CGFloat = 420
    /// Off when the card sits inside a NavigationLink — Reduce Motion then gets
    /// the still poster with no nested play control fighting the tap target.
    var offersMotionControl: Bool = true
    /// Off for compact placements (the home masthead) — provenance tags stay.
    var showsCaption: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var motionApproved = false

    private var clipURL: URL? { Self.bundledURL(for: film.clip.src) }

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            face
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous)
                        .strokeBorder(PitchAtlasTheme.machined, lineWidth: 1)
                )

            if showsCaption {
                Text(film.clip.caption)
                    .font(PitchAtlasTheme.hanken(13))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: PitchAtlasSpacing.xs) {
                SectionLabel(text: "From the hand", color: PitchAtlasTheme.cyanDeep, size: 8)
                SectionLabel(text: "Not tracked data", color: PitchAtlasTheme.ink3, size: 8)
                if let attribution = film.clip.attribution {
                    SectionLabel(text: attribution, color: PitchAtlasTheme.ink3, size: 8)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Grip film. \(film.clip.alt) \(film.clip.caption)")
    }

    @ViewBuilder
    private var face: some View {
        if let clipURL, !reduceMotion || motionApproved {
            LoopingClipView(url: clipURL)
                .accessibilityLabel(film.clip.alt)
        } else if clipURL != nil, offersMotionControl {
            // Reduce Motion: the still leads; motion waits for an explicit ask.
            ZStack(alignment: .bottomLeading) {
                BundledImage(src: film.poster, alt: film.clip.alt)
                Button {
                    motionApproved = true
                } label: {
                    Label("Play grip film", systemImage: "play.fill")
                        .font(PitchAtlasTheme.hankenMedium(14))
                        .foregroundStyle(PitchAtlasTheme.bone)
                        .padding(.horizontal, PitchAtlasSpacing.md)
                        .frame(minHeight: 44)
                        .background(.black.opacity(0.6), in: Capsule())
                }
                .padding(PitchAtlasSpacing.sm)
            }
        } else {
            // Clip missing from the bundle: the honest poster, never a gray box.
            BundledImage(src: film.poster, alt: film.clip.alt)
        }
    }

    /// Resolves `/grips/<stem>.mp4` the same way BundledImage resolves stills:
    /// flat bundle lookup by stem + extension.
    static func bundledURL(for src: String) -> URL? {
        let file = (src as NSString).lastPathComponent
        let stem = (file as NSString).deletingPathExtension
        let ext = (file as NSString).pathExtension.isEmpty ? "mp4" : (file as NSString).pathExtension
        return Bundle.main.url(forResource: stem, withExtension: ext)
    }
}

// MARK: - Real photo as the specimen face

/// A real grip photo in the film card's chrome — the face wherever photography
/// is on file but no footage is. Same hierarchy, one rung down.
struct GripStillCard: View {
    let photo: VisualReference
    var height: CGFloat = 420
    var showsCaption: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            BundledImage(src: photo.src, alt: photo.alt)
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous)
                        .strokeBorder(PitchAtlasTheme.machined, lineWidth: 1)
                )

            if showsCaption {
                Text(photo.caption)
                    .font(PitchAtlasTheme.hanken(13))
                    .foregroundStyle(PitchAtlasTheme.bone2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: PitchAtlasSpacing.xs) {
                SectionLabel(text: "From the hand", color: PitchAtlasTheme.cyanDeep, size: 8)
                SectionLabel(text: "Not tracked data", color: PitchAtlasTheme.ink3, size: 8)
                if let attribution = photo.attribution {
                    SectionLabel(text: attribution, color: PitchAtlasTheme.ink3, size: 8)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Grip photo. \(photo.alt) \(photo.caption)")
    }
}

// MARK: - Looping player plumbing

private struct LoopingClipView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LoopingPlayerUIView {
        let view = LoopingPlayerUIView()
        view.load(url: url)
        return view
    }

    func updateUIView(_ uiView: LoopingPlayerUIView, context: Context) {}

    static func dismantleUIView(_ uiView: LoopingPlayerUIView, coordinator: ()) {
        uiView.teardown()
    }
}

final class LoopingPlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var queue: AVQueuePlayer?
    private var looper: AVPlayerLooper?

    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func load(url: URL) {
        // Muted ambient playback: never interrupts or ducks the user's audio.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        let player = AVQueuePlayer()
        player.isMuted = true
        player.preventsDisplaySleepDuringVideoPlayback = false
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        playerLayer.player = player
        queue = player
        player.play()
    }

    func teardown() {
        queue?.pause()
        looper = nil
        playerLayer.player = nil
        queue = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    // Pause offscreen, resume onscreen — four loops in one scroll stay cheap.
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            queue?.pause()
        } else {
            queue?.play()
        }
    }
}
