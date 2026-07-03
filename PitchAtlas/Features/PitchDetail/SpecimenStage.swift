import SwiftUI
import Metal

// =============================================================================
// SpecimenStage — the specimen surface that chooses its own medium
// =============================================================================
// One stage, two renditions of the same curve. On a capable device the filed
// specimen is the native 3D ball (SpecimenBallView) — drag to turn it, gyro
// parallax at rest, idle backspin about the authored axis. Under Reduce Motion,
// without Metal, or on any scene-build failure, the stage is the 2D SeamBall,
// silently — the schematic is the honest floor, never an apology.
//
// The routing is a pure function (`mode`), so the fallback ladder is testable
// without a renderer. Both renditions wear the SAME MotionCueOverlay, so the
// break language never forks between 2D and 3D. "Seam-informed schematic"
// stays on-surface in the card footer either way — the 3D sweep is finish,
// not new geometry.
//
// Power discipline: the render loop pauses when the stage scrolls fully
// off-screen (resuming at ≥20% visible — hysteresis so it never flickers at
// the edge), when the scene is backgrounded, and under Low Power Mode.
// =============================================================================

struct SpecimenStage: View {
    let entry: PitchAtlasEntry
    var size: CGFloat = 240

    enum Mode: Equatable {
        case schematic
        case dimensional
    }

    /// The fallback ladder, as a pure decision: 3D only when motion is welcome,
    /// Metal exists, and the scene actually built. Everything else is the 2D
    /// schematic — including the quiet wait while the leather maps bake.
    static func mode(reduceMotion: Bool, metalAvailable: Bool, sceneBuilt: Bool) -> Mode {
        if reduceMotion || !metalAvailable || !sceneBuilt { return .schematic }
        return .dimensional
    }

    /// Checked once per process; Metal never appears mid-session.
    static let metalAvailable = MTLCreateSystemDefaultDevice() != nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(MotionProvider.self) private var motion

    @State private var built: SpecimenSceneBuilder.Built?
    @State private var showAxis = false
    @State private var visibleFraction: Double = 1
    @State private var visibleEnough = true
    @State private var stagePlaying = true
    @State private var lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled

    var body: some View {
        let mode = Self.mode(
            reduceMotion: reduceMotion,
            metalAvailable: Self.metalAvailable,
            sceneBuilt: built != nil
        )

        VStack(spacing: PitchAtlasSpacing.xs) {
            switch mode {
            case .schematic:
                SeamBall(motion: entry.motion, size: size, contacts: entry.canonical.fingerPlacement)
            case .dimensional:
                dimensionalStage
            }
        }
        .task(id: entry.id) { await buildScene() }
        .background(visibilityReporter)
        .onChange(of: scenePhase) { _, _ in refreshPlaying() }
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
            lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
            refreshPlaying()
        }
    }

    // MARK: - The 3D stage

    @ViewBuilder
    private var dimensionalStage: some View {
        if let built {
            ZStack {
                SpecimenBallView(built: built, motion: motion, isPlaying: stagePlaying, showAxis: showAxis)
                    .frame(width: size, height: size)
                // the same screen-space break cue the 2D schematic wears
                MotionCueOverlay(motion: entry.motion, size: size)
                    .allowsHitTesting(false)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(dimensionalAccessibilityText)

            axisChip

            Text("On this device the same curve is swept in three dimensions — drag to turn the specimen.")
                .font(PitchAtlasTheme.hanken(12))
                .foregroundStyle(PitchAtlasTheme.ink3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, PitchAtlasSpacing.sm)
        }
    }

    /// Off by default: the axis is study apparatus, not the specimen.
    private var axisChip: some View {
        Button {
            showAxis.toggle()
        } label: {
            Text("AXIS")
                .font(PitchAtlasTheme.martian(8))
                .tracking(1.5)
                .foregroundStyle(showAxis ? PitchAtlasTheme.cyan : PitchAtlasTheme.ink3)
                .padding(.horizontal, PitchAtlasSpacing.sm)
                .padding(.vertical, PitchAtlasSpacing.xs2)
                .overlay(
                    Capsule().strokeBorder(
                        showAxis ? PitchAtlasTheme.cyan.opacity(0.6) : PitchAtlasTheme.machined,
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Spin axis overlay")
        .accessibilityValue(showAxis ? "on" : "off")
    }

    private var dimensionalAccessibilityText: String {
        "Three-dimensional specimen of the \(entry.canonical.name), swept from the same seam curve as the schematic. \(entry.motion.forceLabel). Drag to turn it."
    }

    // MARK: - Scene build

    private func buildScene() async {
        guard Self.metalAvailable else { return }
        let entry = entry
        let maps = await LeatherMaps.shared()
        let axis = showAxis
        // assemble off the main thread; SCNScene construction is safe pre-display
        let result = await Task.detached(priority: .userInitiated) {
            SpecimenSceneBuilder.build(entry: entry, maps: maps, showAxis: axis)
        }.value
        // any build failure leaves `built` nil → mode() keeps the 2D schematic
        built = result
        refreshPlaying()
    }

    // MARK: - Visibility pause

    /// Reports the stage's global frame so the render loop can stop the moment
    /// it scrolls fully off-screen — with hysteresis (resume at ≥20% visible)
    /// so the boundary never flickers.
    private var visibilityReporter: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear { updateVisibility(geo.frame(in: .global)) }
                .onChange(of: geo.frame(in: .global)) { _, frame in
                    updateVisibility(frame)
                }
        }
    }

    private func updateVisibility(_ frame: CGRect) {
        let screen = UIScreen.main.bounds
        let intersection = frame.intersection(screen)
        let area = frame.width * frame.height
        let fraction = area > 0 ? (intersection.width * intersection.height) / area : 0
        visibleFraction = fraction.isNaN ? 0 : fraction
        refreshPlaying()
    }

    private func refreshPlaying() {
        // hysteresis on visibility alone, so a backgrounded scene can't skew
        // the resume threshold
        if visibleEnough {
            visibleEnough = visibleFraction > 0 // pause only when fully gone
        } else {
            visibleEnough = visibleFraction >= 0.2 // resume once meaningfully back
        }
        stagePlaying = visibleEnough && scenePhase == .active && !lowPower
    }
}
