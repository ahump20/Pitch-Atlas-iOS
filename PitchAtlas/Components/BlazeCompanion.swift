import SwiftUI
import UIKit

enum BlazeMood: String, CaseIterable {
    case idle
    case chasing
    case caught
    case sniffing
    case napping
    case concerned
    case still
    case hidden
}

struct BlazeFrame: Equatable {
    let row: Int
    let column: Int
    let assetName: String
}

struct BlazeFrameSequence: Equatable {
    let label: String
    let frames: [BlazeFrame]
    let duration: TimeInterval
    let loops: Bool
}

enum BlazeCompanionPreference {
    static let key = "pitchAtlas.showBlazeCompanion"
    static let defaultValue = false
}

enum BlazeFrameManifest {
    static let frameWidth = 192
    static let frameHeight = 208
    static let sheetColumns = 8
    static let sheetRows = 9

    static let sourceSpriteSHA256 = "992ed0f946edd8ea694c04977f22de162f191fd5aa5e8abc910d816320fa0a7b"
    static let sourcePetSHA256 = "d5f6fc46f71fd672375e40263cf5fb08dda5d81bd66b505e3a32d63358af24d2"

    static let sequences: [BlazeMood: BlazeFrameSequence] = [
        .idle: sequence(label: "idle", mood: .idle, row: 0, columns: Array(0...5), duration: 7.6, loops: true),
        .chasing: sequence(label: "trot/chase", mood: .chasing, row: 1, columns: Array(0...7), duration: 0.98, loops: true),
        .caught: sequence(label: "catch", mood: .caught, row: 3, columns: Array(0...3), duration: 0.86, loops: false),
        .sniffing: sequence(label: "sniff", mood: .sniffing, row: 5, columns: Array(0...3), duration: 2.2, loops: false),
        .napping: sequence(label: "nap", mood: .napping, row: 7, columns: Array(0...5), duration: 5.6, loops: true),
        .concerned: sequence(label: "concerned", mood: .concerned, row: 8, columns: Array(0...3), duration: 1.1, loops: false),
        .still: sequence(label: "still", mood: .still, row: 0, columns: [0], duration: 0, loops: false),
    ]

    static func sequence(for mood: BlazeMood) -> BlazeFrameSequence {
        sequences[mood] ?? sequences[.still]!
    }

    private static func sequence(
        label: String,
        mood: BlazeMood,
        row: Int,
        columns: [Int],
        duration: TimeInterval,
        loops: Bool
    ) -> BlazeFrameSequence {
        BlazeFrameSequence(
            label: label,
            frames: columns.enumerated().map { index, column in
                BlazeFrame(row: row, column: column, assetName: "blaze_\(mood.rawValue)_\(String(format: "%02d", index))")
            },
            duration: duration,
            loops: loops
        )
    }
}

enum BlazeRouteMood {
    static func mood(for tab: AppTab, pathDepth: Int, isSeriousFlow: Bool = false) -> BlazeMood {
        if isSeriousFlow || tab == .sources { return .hidden }
        if pathDepth > 0 { return .chasing }

        switch tab {
        case .atlas, .index, .grips:
            return .sniffing
        case .craftsmen:
            return .idle
        case .sources:
            return .hidden
        }
    }

    static func reducedMotionMood(_ mood: BlazeMood, reduceMotion: Bool) -> BlazeMood {
        guard reduceMotion else { return mood }
        if mood == .hidden || mood == .concerned || mood == .still { return mood }
        return .still
    }
}

struct BlazeCompanion: View {
    let tab: AppTab
    let pathDepth: Int
    var isSeriousFlow = false

    @AppStorage(BlazeCompanionPreference.key) private var showBlazeCompanion = BlazeCompanionPreference.defaultValue
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var frameIndex = 0

    private var requestedMood: BlazeMood {
        BlazeRouteMood.mood(for: tab, pathDepth: pathDepth, isSeriousFlow: isSeriousFlow)
    }

    private var mood: BlazeMood {
        guard showBlazeCompanion else { return .hidden }
        return BlazeRouteMood.reducedMotionMood(requestedMood, reduceMotion: reduceMotion)
    }

    private var sequence: BlazeFrameSequence {
        BlazeFrameManifest.sequence(for: mood == .hidden ? .still : mood)
    }

    private var currentFrame: BlazeFrame {
        guard !sequence.frames.isEmpty else { return BlazeFrameManifest.sequence(for: .still).frames[0] }
        return sequence.frames[min(frameIndex, sequence.frames.count - 1)]
    }

    private var animationID: String {
        "\(mood.rawValue)-\(reduceMotion ? "reduced" : "motion")"
    }

    var body: some View {
        if mood != .hidden {
            HStack(alignment: .bottom, spacing: PitchAtlasSpacing.xs) {
                BlazeFrameImage(frame: currentFrame)
                    .frame(width: 70, height: 76)

                if showsBall {
                    BlazeBaseball()
                        .frame(width: 16, height: 16)
                        .offset(y: -11)
                }
            }
            .padding(.leading, PitchAtlasSpacing.sm)
            .padding(.bottom, PitchAtlasSpacing.xs)
            .opacity(0.82)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .task(id: animationID) { await animateCurrentMood() }
        }
    }

    private var showsBall: Bool {
        guard !reduceMotion else { return false }
        return mood == .chasing || mood == .caught || mood == .sniffing
    }

    private func animateCurrentMood() async {
        await MainActor.run { frameIndex = 0 }
        guard !reduceMotion, sequence.frames.count > 1, sequence.duration > 0 else { return }

        let secondsPerFrame = max(0.08, sequence.duration / Double(sequence.frames.count))
        let nanoseconds = UInt64(secondsPerFrame * 1_000_000_000)

        repeat {
            for index in sequence.frames.indices {
                if Task.isCancelled { return }
                await MainActor.run { frameIndex = index }
                try? await Task.sleep(nanoseconds: nanoseconds)
            }
        } while sequence.loops && !Task.isCancelled
    }
}

private struct BlazeFrameImage: View {
    let frame: BlazeFrame

    var body: some View {
        if let image = BlazeImageStore.image(named: frame.assetName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        }
    }
}

@MainActor
private enum BlazeImageStore {
    private static var cache: [String: UIImage] = [:]

    static func image(named name: String) -> UIImage? {
        if let cached = cache[name] { return cached }
        guard let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "blaze/frames")
                ?? Bundle.main.url(forResource: name, withExtension: "png"),
              let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        cache[name] = image
        return image
    }
}

private struct BlazeBaseball: View {
    var body: some View {
        Circle()
            .fill(PitchAtlasTheme.bone.opacity(0.92))
            .overlay(
                Circle()
                    .stroke(PitchAtlasTheme.seamBright.opacity(0.75), lineWidth: 1)
            )
            .overlay {
                SeamArc()
                    .stroke(PitchAtlasTheme.seamBright.opacity(0.78), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                    .padding(3)
            }
            .shadow(color: PitchAtlasTheme.seamBright.opacity(0.16), radius: 4)
    }
}
