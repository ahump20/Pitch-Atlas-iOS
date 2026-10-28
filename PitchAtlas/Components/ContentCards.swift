import SwiftUI
import UIKit

// =============================================================================
// Pitch Atlas — content cards
// =============================================================================
// The repeatable record surfaces: the bundled grip photo (with the seal fallback
// that the whole app copies), the pitch index card, the craftsman archive plate,
// and the lost-pitch tier card. All leather-press, all four-state aware.
// =============================================================================

// MARK: - Family / status color + label helpers (view layer)

extension PitchFamily {
    /// The web family inkwell (sections/family-accent.ts).
    var accent: Color { PitchAccents.familyColor(self) }
    var accentRGB: UInt32 { PitchAccents.familyRGB(self) }
    var label: String {
        switch self {
        case .fastball: return "Fastball"
        case .breaking: return "Breaking"
        case .offspeed: return "Offspeed"
        }
    }
}

extension RepertoireFamily {
    /// The web family inkwell (sections/family-accent.ts).
    var accent: Color { PitchAccents.familyColor(self) }
    var accentRGB: UInt32 { PitchAccents.familyRGB(self) }
    var label: String {
        switch self {
        case .fastball: return "Fastball"
        case .breaking: return "Breaking"
        case .offspeed: return "Offspeed"
        case .specialty: return "Specialty"
        case .banned: return "Banned"
        }
    }
}

extension RepertoireStatus {
    var displayLabel: String {
        switch self {
        case .standard: return "Standard"
        case .niche: return "Niche"
        case .rare: return "Rare"
        case .nearExtinct: return "Near-extinct"
        case .banned: return "Banned"
        case .alias: return "Alias"
        case .illusion: return "Illusion"
        case .notAPitch: return "Not a pitch"
        }
    }
    /// The Pitch Index row's status color (web sections/PitchIndex.tsx STATUS).
    var tone: Color { Color(rgb: toneRGB) }
    var toneRGB: UInt32 { (WebTokens.Status.indexColor[rawValue] ?? WebTokens.Palette.bone2).rgb }
    /// The status badge on a basic file (web index/StatusBadge.tsx): the honest
    /// edge cases take the seam, the live pitches read bone-2.
    var badgeTone: Color { Color(rgb: badgeToneRGB) }
    var badgeToneRGB: UInt32 {
        (WebTokens.Status.edge.contains(rawValue) ? WebTokens.Palette.seam : WebTokens.Palette.bone2).rgb
    }
}

extension DocumentationTier {
    /// The lost-pitch documentation tier color (web lost-pitches/EraTimeline.tsx TIER_COLOR).
    var tone: Color { Color(rgb: toneRGB) }
    var toneRGB: UInt32 { (WebTokens.LostTier.color[rawValue] ?? WebTokens.Tier.dot["unverified"] ?? WebTokens.Palette.seam).rgb }
}

// MARK: - Small chrome

/// A pitch-family accent dot.
struct FamilyDot: View {
    let color: Color
    var size: CGFloat = 7
    var body: some View {
        Circle().fill(color).frame(width: size, height: size).accessibilityHidden(true)
    }
}

/// A status / tier pill.
struct StatusPill: View {
    let text: String
    let tone: Color
    var body: some View {
        Text(text.uppercased())
            .font(PitchAtlasTheme.martian(9))
            .tracking(1)
            .foregroundStyle(tone)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .overlay(
                Capsule().strokeBorder(tone.opacity(0.5), lineWidth: 1)
            )
            .accessibilityLabel(text)
    }
}

// MARK: - Bundled grip image (loads webp from the app bundle, seal fallback)

/// Loads a bundled grip photo by its `/grips/<stem>.webp` src. A missing image
/// shows the seal + alt text, never a gray box — the model the app copies.
struct BundledImage: View {
    let src: String
    let alt: String
    var contentMode: ContentMode = .fill

    var body: some View {
        if let image = BundledImage.load(src) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: contentMode)
                .accessibilityLabel(alt)
        } else {
            ZStack {
                PitchAtlasTheme.paper2
                VStack(spacing: PitchAtlasSpacing.xs) {
                    BrandSealMark(size: 40, shadow: false)
                    Text(alt)
                        .font(PitchAtlasTheme.hanken(11))
                        .foregroundStyle(PitchAtlasTheme.text3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, PitchAtlasSpacing.sm)
                        .lineLimit(3)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Image unavailable. \(alt)")
        }
    }

    /// Decoded-image cache. `UIImage(contentsOfFile:)` re-reads and re-decodes the
    /// webp from disk on every call, and a SwiftUI view body can run many times per
    /// scroll. Bundled art is immutable, so a decode is cacheable forever — keyed by
    /// the resolved bundle path. NSCache sheds entries automatically under memory
    /// pressure, so this never becomes the thing that gets the app jetsammed.
    private static let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 80
        return c
    }()

    static func load(_ src: String) -> UIImage? {
        let file = (src as NSString).lastPathComponent
        let stem = (file as NSString).deletingPathExtension
        let ext = (file as NSString).pathExtension.isEmpty ? "webp" : (file as NSString).pathExtension
        guard let url = Bundle.main.url(forResource: stem, withExtension: ext) else { return nil }
        let key = url.path as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let image = UIImage(contentsOfFile: url.path) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }
}

/// A grip photo tile: the image (or seal fallback), the caption, and the
/// "not tracked data" honesty tag the Grip Library leans on.
struct GripPhotoTile: View {
    let photo: VisualReference

    /// Only real, loadable photography earns the tap-to-zoom affordance — never the
    /// seal fallback (there's nothing to get closer to).
    private var hasImage: Bool { BundledImage.load(photo.src) != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            BundledImage(src: photo.src, alt: photo.alt)
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous)
                        .strokeBorder(PitchAtlasTheme.machined, lineWidth: 1)
                )
                .overlay(alignment: .topTrailing) {
                    if hasImage {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(PitchAtlasTheme.bone)
                            .padding(6)
                            .background(.black.opacity(0.4), in: Circle())
                            .padding(PitchAtlasSpacing.xs)
                            .accessibilityHidden(true)
                    }
                }
                .modifier(OptionalZoom(enabled: hasImage, src: photo.src, alt: photo.alt, caption: photo.caption))

            Text(photo.caption)
                .font(PitchAtlasTheme.hanken(13))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: PitchAtlasSpacing.xs) {
                if let view = photo.view {
                    SectionLabel(text: view.rawValue, color: PitchAtlasTheme.cyanDeep, size: 8)
                }
                SectionLabel(text: "Not tracked data", color: PitchAtlasTheme.text3, size: 8)
            }
        }
    }
}
