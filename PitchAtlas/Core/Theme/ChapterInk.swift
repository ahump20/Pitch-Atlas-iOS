import SwiftUI

/// The specimen page's own inks. The site writes these as raw hex in
/// pages/PitchChapter.tsx and its study styles (web src/styles/study.css,
/// archive.css, world.css, compare.css), not as design-sync tokens, so they are
/// ported here by hand; each names where it comes from.
enum ChapterInk {
    // MARK: The hero stage and plates (PitchChapter.tsx)
    /// The gold 1/1's stage: a burnt wash over #2a1208 falling to #050309.
    static let goldStageWash = Color(hex: 0xBF5700, opacity: 0.22)
    static let goldStageCore = Color(hex: 0x2A1208)
    static let stageFloor = Color(hex: 0x050309)
    /// The read plate and master card ground: the accent mixed into #0B0805,
    /// falling to #070503.
    static let plateGround = Color(hex: 0x0B0805)
    static let plateFloor = Color(hex: 0x070503)
    /// The media bar's caption chip (bg-black/55).
    static let mediaChip = Color(hex: 0x000000, opacity: 0.55)

    // MARK: The chapter boxes (study.css .study-chapter-nav, archive.css)
    /// border-block #c8b99a44 around the row of boxes
    static let chapterRule = Color(hex: 0xC8B99A, opacity: 0x44 / 255.0)
    /// a[aria-current]: the box for the section in view
    static let chapterCurrentInk = Color(hex: 0xF2DDB9)
    static let chapterCurrentRule = Color(hex: 0xC3A16C)
    static let chapterCurrentFill = Color(hex: 0xD5B887, opacity: 0x14 / 255.0)

    // MARK: The grip bench (study.css)
    /// .study-heading > p:last-child
    static let benchLede = Color(hex: 0xC9BDAB)
    /// .study-specimen: radial #292522 → #100f0d 70%, rim #b8a48944, text #eee6d5
    static let specimenGlow = Color(hex: 0x292522)
    static let specimenFloor = Color(hex: 0x100F0D)
    static let specimenRim = Color(hex: 0xB8A489, opacity: 0x44 / 255.0)
    static let specimenText = Color(hex: 0xEEE6D5)
    static let specimenShadow = Color(hex: 0x000000, opacity: 0x44 / 255.0)
    /// .study-reading: #251d17 with a #fff2 sheen at 110°, rim #b58a4f44, text #eee7dc
    static let readingFill = Color(hex: 0x251D17)
    static let readingSheen = Color(hex: 0xFFFFFF, opacity: 0x22 / 255.0)
    static let readingRim = Color(hex: 0xB58A4F, opacity: 0x44 / 255.0)
    static let readingText = Color(hex: 0xEEE7DC)
    /// .study-reading .text-bone-2 and its links
    static let readingMuted = Color(hex: 0xD2BCA6)
    /// .study-steps' foot rule; the pressed step's burnt rule and wash
    static let stepsRule = Color(hex: 0x75664D, opacity: 0x66 / 255.0)
    static let stepOnRule = Color(hex: 0xBF5700)
    static let stepOnFill = Color(hex: 0xBF5700, opacity: 0x33 / 255.0)
    /// .study-button[aria-pressed=true]
    static let buttonOnFill = Color(hex: 0x8F714D, opacity: 0x33 / 255.0)
    /// the picker, photo and full-record rules (#76654b55)
    static let readingRule = Color(hex: 0x76654B, opacity: 0x55 / 255.0)
    /// .study-variant-picker select
    static let selectRim = Color(hex: 0x81715B)
    static let selectFill = Color(hex: 0x17130F)
    static let selectInk = Color(hex: 0xEEE4D7)
    /// .study-selected's top rule
    static let selectedRule = Color(hex: 0xC6B087, opacity: 0x55 / 255.0)
    /// .study-photo > img's well
    static let photoWell = Color(hex: 0x181510)
    /// .study-dialog and its viewport rim
    static let dialogFill = Color(hex: 0x151310)
    static let dialogInk = Color(hex: 0xEEE5D2)
    static let dialogRim = Color(hex: 0xAE9875)
    static let viewportRim = Color(hex: 0xB3A188, opacity: 0x44 / 255.0)
    /// the viewer's floor shadow (rgba(0,0,0,0.42))
    static let viewerShadow = Color(hex: 0x000000, opacity: 0.42)

    // MARK: The motion control (compare.css .specimen-action, .is-on-media)
    static let actionRim = Color(hex: 0x8A7A5E, opacity: 0x80 / 255.0)
    static let actionHeldFill = Color(hex: 0xF6F1E6, opacity: 0x0D / 255.0)
    static let actionOnMediaFill = Color(hex: 0x0B0805, opacity: 0xB8 / 255.0)
    static let actionOnMediaHeldFill = Color(hex: 0x0B0805, opacity: 0xE6 / 255.0)
    static let actionOnMediaRim = Color(hex: 0xF6F1E6, opacity: 0x3D / 255.0)
    static let actionHeldRim = Color(hex: 0xC8A35C)

    // MARK: Keep following (world.css .archive-companion)
    static let companionRim = Color(hex: 0xA0ABB3, opacity: 0x44 / 255.0)
    static let companionGlow = Color(hex: 0x3D454B, opacity: 0x66 / 255.0)
    static let companionFloor = Color(hex: 0x18191C)
}
