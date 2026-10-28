import SwiftUI

// =============================================================================
// NearScreen — a picture drawn only near the reader
// =============================================================================
// A long page built all at once (the Grip Library) would decode every
// photograph the moment it opens. NearScreen draws its content only while it
// sits within a screen of the visible one, and the frame it fills is its
// parent's, so nothing on the page moves when the picture comes and goes.
// =============================================================================

enum ScreenReach {
    /// Within one screen above or below the visible one; a frame with no size
    /// is never near.
    static func isNear(_ frame: CGRect, in screen: CGRect) -> Bool {
        guard frame.width > 0, frame.height > 0 else { return false }
        return frame.intersects(screen.insetBy(dx: 0, dy: -screen.height))
    }
}

struct NearScreen<Content: View>: View {
    @ViewBuilder var content: Content
    @State private var near = false

    var body: some View {
        Color.clear
            .overlay { if near { content } }
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onAppear { track(geo.frame(in: .global)) }
                        .onChange(of: geo.frame(in: .global)) { _, frame in track(frame) }
                }
            }
            .onDisappear { near = false }
    }

    private func track(_ frame: CGRect) {
        let next = ScreenReach.isNear(frame, in: UIScreen.main.bounds)
        if next != near { near = next }
    }
}
