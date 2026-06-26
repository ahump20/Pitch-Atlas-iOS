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
    var accent: Color {
        switch self {
        case .fastball: return PitchAtlasTheme.cyan
        case .breaking: return PitchAtlasTheme.violet
        case .offspeed: return PitchAtlasTheme.lime
        }
    }
    var label: String {
        switch self {
        case .fastball: return "Fastball"
        case .breaking: return "Breaking"
        case .offspeed: return "Offspeed"
        }
    }
}

extension RepertoireFamily {
    var accent: Color {
        switch self {
        case .fastball: return PitchAtlasTheme.cyan
        case .breaking: return PitchAtlasTheme.violet
        case .offspeed: return PitchAtlasTheme.lime
        case .specialty: return PitchAtlasTheme.amberBright
        case .banned: return PitchAtlasTheme.seamBright
        }
    }
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
    var tone: Color {
        switch self {
        case .standard: return PitchAtlasTheme.cyan
        case .niche: return PitchAtlasTheme.bone2
        case .rare: return PitchAtlasTheme.amberBright
        case .nearExtinct: return PitchAtlasTheme.sandBright
        case .banned: return PitchAtlasTheme.seamBright
        case .alias: return PitchAtlasTheme.ink3
        case .illusion: return PitchAtlasTheme.violet
        case .notAPitch: return PitchAtlasTheme.ink3
        }
    }
}

extension DocumentationTier {
    var tone: Color {
        switch self {
        case .documented: return PitchAtlasTheme.okBright
        case .partial: return PitchAtlasTheme.amberBright
        case .legend: return PitchAtlasTheme.sandBright
        }
    }
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
                        .foregroundStyle(PitchAtlasTheme.ink3)
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
                SectionLabel(text: "Not tracked data", color: PitchAtlasTheme.ink3, size: 8)
            }
        }
    }
}

// MARK: - Pitch specimen card (foil front)

struct PitchSpecimenCard: View {
    enum Style {
        case hero
        case rail
    }

    let entry: PitchAtlasEntry
    var style: Style = .hero

    private var isHero: Bool { style == .hero }
    private var mediaHeight: CGFloat { isHero ? 176 : 118 }
    private var titleSize: CGFloat { isHero ? 29 : 17 }
    private var padding: CGFloat { isHero ? PitchAtlasSpacing.md : PitchAtlasSpacing.sm }
    private var cornerRadius: CGFloat { isHero ? PitchAtlasRadius.card : PitchAtlasRadius.tile }

    var body: some View {
        VStack(alignment: .leading, spacing: isHero ? PitchAtlasSpacing.sm : PitchAtlasSpacing.xs) {
            HStack(alignment: .center, spacing: PitchAtlasSpacing.xs) {
                SectionLabel(text: entry.display.specimenNo, color: PitchAtlasTheme.cyanDeep, size: isHero ? 9 : 7)
                Spacer(minLength: PitchAtlasSpacing.xs)
                Text(entry.canonical.family.label.uppercased())
                    .font(PitchAtlasTheme.martian(isHero ? 8 : 7))
                    .tracking(1.2)
                    .foregroundStyle(entry.canonical.family.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            specimenMedia

            nameplate

            if isHero {
                HStack(alignment: .firstTextBaseline, spacing: PitchAtlasSpacing.xs) {
                    SectionLabel(text: entry.canonical.grip.confidence.label, color: PitchAtlasTheme.cyanDeep, size: 8)
                    Spacer(minLength: PitchAtlasSpacing.xs)
                    Text(entry.canonical.grip.source?.label ?? "Source gap visible")
                        .font(PitchAtlasTheme.hanken(11))
                        .foregroundStyle(PitchAtlasTheme.ink3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: max(cornerRadius - 5, 8), style: .continuous)
                .fill(PitchAtlasTheme.void)
        )
        .overlay(
            RoundedRectangle(cornerRadius: max(cornerRadius - 5, 8), style: .continuous)
                .strokeBorder(PitchAtlasTheme.bone.opacity(0.72), lineWidth: isHero ? 2 : 1.4)
        )
        .padding(isHero ? 6 : 4)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(PitchAtlasTheme.foil)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.black.opacity(0.55), lineWidth: 1)
        )
        .foilRake(radius: cornerRadius, intensity: isHero ? 0.9 : 0.55)
        .shadow(color: .black.opacity(isHero ? 0.42 : 0.28), radius: isHero ? 18 : 10, x: 0, y: isHero ? 14 : 7)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var specimenMedia: some View {
        Group {
            if isHero, let film = entry.canonical.gripFilm {
                GripFilmCard(film: film, height: mediaHeight, offersMotionControl: false, showsCaption: false)
            } else if let still = entry.canonical.realStill {
                BundledImage(src: still.src, alt: still.alt)
                    .frame(height: mediaHeight)
                    .frame(maxWidth: .infinity)
            } else {
                SeamBall(motion: entry.motion, size: isHero ? 210 : 96)
                    .frame(height: mediaHeight)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(
            LinearGradient(
                colors: [PitchAtlasTheme.paper3, PitchAtlasTheme.press],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PitchAtlasRadius.tile, style: .continuous)
                .strokeBorder(PitchAtlasTheme.machined, lineWidth: 1)
        )
    }

    private var nameplate: some View {
        HStack(spacing: PitchAtlasSpacing.xs) {
            FamilyDot(color: entry.canonical.family.accent, size: isHero ? 9 : 7)
            Text(entry.display.shortName.uppercased())
                .font(PitchAtlasTheme.anton(titleSize))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
                .lineLimit(isHero ? 2 : 1)
                .minimumScaleFactor(0.62)
            Spacer(minLength: PitchAtlasSpacing.xs)
            if isHero {
                BrandSealMark(size: 28, shadow: false)
            }
        }
        .padding(.horizontal, isHero ? PitchAtlasSpacing.sm : PitchAtlasSpacing.xs)
        .padding(.vertical, isHero ? PitchAtlasSpacing.xs : PitchAtlasSpacing.xs2)
        .background(
            RoundedRectangle(cornerRadius: PitchAtlasRadius.panel, style: .continuous)
                .fill(.black.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: PitchAtlasRadius.panel, style: .continuous)
                .strokeBorder(PitchAtlasTheme.bone.opacity(0.28), lineWidth: 1)
        )
    }

    private var accessibilityLabel: String {
        "\(entry.display.specimenNo). \(entry.display.shortName). \(entry.canonical.family.label). \(entry.canonical.grip.confidence.label)."
    }
}

// MARK: - Pitch index card / repertoire row

/// One row in the searchable index. Family dot + name + status pill, with a chevron
/// when the entry links to a filed specimen.
struct RepertoireRow: View {
    let entry: RepertoireEntry

    var body: some View {
        HStack(alignment: .top, spacing: PitchAtlasSpacing.sm) {
            FamilyDot(color: entry.family.accent)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs2) {
                Text(entry.name)
                    .font(PitchAtlasTheme.hankenMedium(16))
                    .foregroundStyle(PitchAtlasTheme.bone)
                if let aka = entry.aka, !aka.isEmpty {
                    Text(aka.joined(separator: " · "))
                        .font(PitchAtlasTheme.hanken(11))
                        .foregroundStyle(PitchAtlasTheme.ink3)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: PitchAtlasSpacing.xs) {
                    cardStrip(entry.family.label, color: entry.family.accent)
                    cardStrip(entry.filedSlug == nil ? "Basic file" : "Filed specimen",
                              color: entry.filedSlug == nil ? PitchAtlasTheme.ink3 : PitchAtlasTheme.cyanDeep)
                }
            }
            Spacer(minLength: PitchAtlasSpacing.xs)
            VStack(alignment: .trailing, spacing: PitchAtlasSpacing.xs) {
                StatusPill(text: entry.status.displayLabel, tone: entry.status.tone)
                if entry.filedSlug != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(PitchAtlasTheme.ink3)
                }
            }
        }
        .padding(.vertical, PitchAtlasSpacing.sm)
        .padding(.horizontal, PitchAtlasSpacing.md)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(entry.family.accent)
                .frame(width: 2)
                .padding(.vertical, PitchAtlasSpacing.sm)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private func cardStrip(_ text: String, color: Color) -> some View {
        Text(text.uppercased())
            .font(PitchAtlasTheme.martian(8))
            .tracking(0.8)
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(PitchAtlasTheme.paper3.opacity(0.8), in: Capsule())
    }

    /// The aliases are load-bearing for pitch identity but get truncated to one line
    /// on screen; VoiceOver announces the full list so they are never silently lost.
    private var accessibilityLabel: String {
        var parts = [
            entry.name,
            entry.family.label,
            entry.filedSlug == nil ? "Basic file" : "Filed specimen",
            entry.status.displayLabel,
        ]
        if let aka = entry.aka, !aka.isEmpty {
            parts.append("also known as \(aka.joined(separator: ", "))")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Craftsman card (insert card)

/// A craftsman hall card, struck as a chase-card insert: the set number
/// (C-01…) was already trading-card language, so the card finally dresses the
/// part — a gold edge down the left rail like the physical card's frame, and
/// the era worn as a rotated ink stamp, vintage side-rail style. The gyroball
/// legend keeps its sand flag and trades the gold edge for the may-not-exist
/// register: a dashed rail, never a solid one.
struct CraftsmanCard: View {
    let craftsman: Craftsman

    private var isLegend: Bool { craftsman.kind == .legend }
    private var railColor: Color { isLegend ? PitchAtlasTheme.sandBright : Color(hex: 0xCAA14A) }

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            HStack {
                SectionLabel(text: craftsman.specimenNo, color: PitchAtlasTheme.cyanDeep, size: 9)
                Spacer()
                if isLegend {
                    StatusPill(text: "Legend — flagged", tone: PitchAtlasTheme.sandBright)
                }
            }

            Text(craftsman.name.uppercased())
                .font(PitchAtlasTheme.anton(26))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
                .padding(.vertical, 2)

            Text(craftsman.tagline)
                .font(PitchAtlasTheme.newsreaderItalic(15))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: PitchAtlasSpacing.sm) {
                SectionLabel(text: craftsman.signaturePitch, color: PitchAtlasTheme.cyan, size: 9)
                Text(craftsman.era)
                    .font(PitchAtlasTheme.martian(8))
                    .tracking(1.2)
                    .foregroundStyle(PitchAtlasTheme.ink3)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(PitchAtlasTheme.ink3.opacity(0.7), lineWidth: 1)
                    )
                    .rotationEffect(.degrees(-1))
            }
            .padding(.top, 2)
        }
        .leatherPress()
        .overlay(alignment: .leading) {
            // the insert's gold rail (dashed for the legend that may not exist)
            RoundedRectangle(cornerRadius: 1.5)
                .fill(railColor)
                .frame(width: 3)
                .padding(.vertical, 6)
                .opacity(isLegend ? 0.65 : 0.9)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(craftsman.name), \(craftsman.signaturePitch), \(craftsman.era)\(isLegend ? ", legend, flagged" : "")")
    }
}

// MARK: - Lost pitch card (documentation tier)

/// A Lost Pitches card: the documentation tier is the feature, not a footnote.
struct LostPitchCard: View {
    let pitch: LostPitch

    var body: some View {
        VStack(alignment: .leading, spacing: PitchAtlasSpacing.xs) {
            HStack {
                SectionLabel(text: pitch.specimenNo, color: PitchAtlasTheme.cyanDeep, size: 9)
                Spacer()
                StatusPill(text: pitch.tier.label, tone: pitch.tier.tone)
            }

            Text(pitch.name.uppercased())
                .font(PitchAtlasTheme.anton(24))
                .foregroundStyle(PitchAtlasTheme.bone)
                .antonSkew()
                .padding(.vertical, 2)

            Text(pitch.tagline)
                .font(PitchAtlasTheme.newsreaderItalic(15))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)

            Text(pitch.era)
                .font(PitchAtlasTheme.martian(9))
                .foregroundStyle(PitchAtlasTheme.ink3)
                .padding(.top, 2)
        }
        .leatherPress()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pitch.name), \(pitch.tier.label), \(pitch.era)")
    }
}
