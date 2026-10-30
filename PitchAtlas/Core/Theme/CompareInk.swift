import SwiftUI

/// The compare page and its bench. The site writes these as raw hex in its compare
/// styles (web src/styles/compare.css, bench.css, and inspector.css's
/// .specimen-seg), not as design-sync tokens, so they are ported here by hand; each
/// names the selector it comes from.
enum CompareInk {
    // MARK: The page (.archive-compare)
    /// .archive-back
    static let back = Color(hex: 0xC9BA9B)
    /// .archive-compare-header h1, and its span
    static let title = Color(hex: 0xF3EAD7)
    static let titleAccent = Color(hex: 0xBC9A62)
    /// .archive-compare-header p and .compare-next p
    static let lede = Color(hex: 0xC7BDA9)
    /// .compare-controls and .compare-next rules (#b99d6538)
    static let rule = Color(hex: 0xB99D65, opacity: 0x38 / 255.0)
    /// .compare-pickers label > span
    static let pickerLabel = Color(hex: 0xC9BDA5)
    /// .compare-pickers .rfx-select: its words, its well, its rim (the dark
    /// scene's --ctl-border, cyan at .4) and the lip across its top
    static let pickerInk = Color(hex: 0xF3EAD7)
    static let pickerWell = Color(hex: 0x191812)
    static let pickerRim = Color(hex: 0x5FE0EA, opacity: 0.4)
    static let pickerLip = Color(hex: 0xFFFFFF, opacity: 0.5)
    /// .archive-icon-action's rim (#f6f1e62b)
    static let iconRim = Color(hex: 0xF6F1E6, opacity: 0x2B / 255.0)
    /// .compare-tabs button, the pressed one, and its rule
    static let tab = Color(hex: 0xBCB19B)
    static let tabOn = Color(hex: 0xFFF0CE)
    static let tabRule = Color(hex: 0xC6A169)
    /// .compare-empty: the A / B behind it (#9e845850), its h2, its p
    static let emptyMark = Color(hex: 0x9E8458, opacity: 0x50 / 255.0)
    static let emptyTitle = Color(hex: 0xF0E5CF)
    static let emptyBody = Color(hex: 0xBFB39E)
    /// .compare-next .archive-eyebrow
    static let nextEyebrow = Color(hex: 0xC7A56B)
    /// .archive-text-link and .bench-study a: the underline (#a68a5966)
    static let linkRule = Color(hex: 0xA68A59, opacity: 0x66 / 255.0)
    /// .compare-replacement: the dialog's ground and words
    static let dialogFill = Color(hex: 0x191710)
    static let dialogInk = Color(hex: 0xF4E8D0)
    /// .archive-action--quiet's rim
    static let quietRim = Color(hex: 0x8A7A5E)

    // MARK: The tray (.compare-tray)
    /// Its ground, rim (#aa8b575c), words and open place (.compare-empty-slot),
    /// the lip of light inside its top edge (#f4e3b818) and its drop (#0009)
    static let trayFill = Color(hex: 0x171610)
    static let trayRim = Color(hex: 0xAA8B57, opacity: 0x5C / 255.0)
    static let trayInk = Color(hex: 0xEEE1C6)
    static let trayEmpty = Color(hex: 0xB6A98F)
    static let trayLip = Color(hex: 0xF4E3B8, opacity: 0x18 / 255.0)
    static let trayShadow = Color(hex: 0x000000, opacity: 0x99 / 255.0)

    // MARK: The bench (.bench--page)
    /// .bench--page's rim (#a38a5e44) and ground
    static let benchRim = Color(hex: 0xA38A5E, opacity: 0x44 / 255.0)
    static let benchGround = Color(hex: 0x0B0A09)
    /// .bench-stage: radial-gradient(ellipse at 50% 38%, #1c1814 0%, #0b0a09 72%)
    static let stageGlow = Color(hex: 0x1C1814)
    /// .bench-stage::after, the rule under the stage (#a38a5e2e)
    static let stageRule = Color(hex: 0xA38A5E, opacity: 0x2E / 255.0)
    /// .specimen-seg: its rim (#a38a5e45), a button's wash (#f6f1e608) and ink;
    /// the pressed button's fill, ink and ring
    static let segRim = Color(hex: 0xA38A5E, opacity: 0x45 / 255.0)
    static let segWash = Color(hex: 0xF6F1E6, opacity: 0x08 / 255.0)
    static let segInk = Color(hex: 0xB7AB93)
    static let segOnFill = Color(hex: 0x3A3125)
    static let segOnInk = Color(hex: 0xFFF8EA)
    static let segOnRing = Color(hex: 0xC8A35C)
    /// .bench-specimen-name and .bench-col-head
    static let specimenName = Color(hex: 0xF3ECDD)
    /// The gold keys: .bench-specimen-name span and .bench-row-name
    static let key = Color(hex: 0xC4A777)
    /// .bench-ball's inner ring and .bench-row's top rule (#a38a5e1f)
    static let ballRing = Color(hex: 0xA38A5E, opacity: 0x1F / 255.0)
    /// .bench-chip: its rim (#a38a5e59), its ground (#0b0a09e0), its words
    static let chipRim = Color(hex: 0xA38A5E, opacity: 0x59 / 255.0)
    static let chipGround = Color(hex: 0x0B0A09, opacity: 0xE0 / 255.0)
    static let chipInk = Color(hex: 0xD9CCB3)
    /// .bench-flight-head
    static let flightHead = Color(hex: 0xCFC2A8)
    /// .bench-rail
    static let rail = Color(hex: 0x110F0D)
    /// .bench-cell, its strong, its quiet
    static let cell = Color(hex: 0xEFE6D6)
    static let cellStrong = Color(hex: 0xF6F1E6)
    static let cellQuiet = Color(hex: 0xA89C86)
    /// .bench-differs
    static let differs = Color(hex: 0xC8A35C)
    /// .bench-finger[aria-pressed=true]'s wash (#5fe0ea0f); its rule is --color-cyan
    static let fingerWash = Color(hex: 0x5FE0EA, opacity: 0x0F / 255.0)
    /// .bench-study a
    static let study = Color(hex: 0xDDA775)
    /// TunnelPlot's HALO, the ring around each endpoint and each name
    static let halo = Color(hex: 0x0B0A09)

    // MARK: The one-pitch bench (inspector.css, bench.css)
    /// .specimen-inspector-overlay: the page dimmed behind the room (#050403e0)
    static let roomOverlay = Color(hex: 0x050403, opacity: 0xE0 / 255.0)
    /// .specimen-inspector's 1px rim (#a38a5e66) and its top lip (inset 0 1px 0 #f6f1e614)
    static let roomRim = Color(hex: 0xA38A5E, opacity: 0x66 / 255.0)
    static let roomLip = Color(hex: 0xF6F1E6, opacity: 0x14 / 255.0)
    /// .specimen-close: its disc (#0b0a09cc), its ring (#a38a5e59), its X (#d9ccb3)
    static let closeDisc = Color(hex: 0x0B0A09, opacity: 0xCC / 255.0)
    static let closeRing = Color(hex: 0xA38A5E, opacity: 0x59 / 255.0)
    static let closeInk = Color(hex: 0xD9CCB3)
    /// .bench-with .rfx-select: the dark scene's --ctl-border (#a38a5e66) and words (#efe6d6)
    static let withRim = Color(hex: 0xA38A5E, opacity: 0x66 / 255.0)
    static let withInk = Color(hex: 0xEFE6D6)
    /// .specimen-action (compare.css): the Inspect card button's rim (#8a7a5e80) and words
    static let actionRim = Color(hex: 0x8A7A5E, opacity: 0x80 / 255.0)
    static let actionInk = Color(hex: 0xD9CCB3)
}
