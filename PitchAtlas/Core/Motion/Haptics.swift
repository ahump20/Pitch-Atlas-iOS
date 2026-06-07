import UIKit

// =============================================================================
// Haptics — the restrained feedback map
// =============================================================================
// Deliberately sparse. A selection tick on grip-view / step changes; impact.soft
// on card focus; impact.rigid once on the dissolve lock; impact.light on a chip
// toggle. Never on the foil. Centralized so the map stays disciplined.
// =============================================================================

enum Haptics {
    static func selection() {
        let g = UISelectionFeedbackGenerator()
        g.selectionChanged()
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    /// Card focus / open.
    static func soft() { impact(.soft) }
    /// The 3D→2D dissolve lock — fires once.
    static func lock() { impact(.rigid) }
    /// A filter chip toggle.
    static func toggle() { impact(.light) }
}
