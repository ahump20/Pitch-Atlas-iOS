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
            .font(PitchAtlasTheme.martian(8))
            .tracking(1)
            .foregroundStyle(tone)
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
                    SealMark(size: 40)
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

    static func load(_ src: String) -> UIImage? {
        let file = (src as NSString).lastPathComponent
        let stem = (file as NSString).deletingPathExtension
        let ext = (file as NSString).pathExtension.isEmpty ? "webp" : (file as NSString).pathExtension
        guard let url = Bundle.main.url(forResource: stem, withExtension: ext) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}

/// A grip photo tile: the image (or seal fallback), the caption, and the
/// "not tracked data" honesty tag the Grip Library leans on.
struct GripPhotoTile: View {
    let photo: VisualReference

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

// MARK: - Pitch index card / repertoire row

/// One row in the searchable index. Family dot + name + status pill, with a chevron
/// when the entry links to a filed specimen.
struct RepertoireRow: View {
    let entry: RepertoireEntry

    var body: some View {
        HStack(spacing: PitchAtlasSpacing.sm) {
            FamilyDot(color: entry.family.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.name)
                    .font(PitchAtlasTheme.hankenMedium(16))
                    .foregroundStyle(PitchAtlasTheme.bone)
                if let aka = entry.aka, !aka.isEmpty {
                    Text(aka.joined(separator: " · "))
                        .font(PitchAtlasTheme.hanken(11))
                        .foregroundStyle(PitchAtlasTheme.ink3)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: PitchAtlasSpacing.xs)
            StatusPill(text: entry.status.displayLabel, tone: entry.status.tone)
            if entry.filedSlug != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PitchAtlasTheme.ink3)
            }
        }
        .padding(.vertical, PitchAtlasSpacing.sm)
        .padding(.horizontal, PitchAtlasSpacing.md)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.name), \(entry.status.displayLabel)\(entry.filedSlug != nil ? ", filed specimen" : "")")
    }
}

// MARK: - Craftsman card (archive plate)

/// A craftsman hall card: specimen plate, name in Anton, era + signature pitch.
/// A legend (the gyroball) is flagged, never shown as fact.
struct CraftsmanCard: View {
    let craftsman: Craftsman

    private var isLegend: Bool { craftsman.kind == .legend }

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
                    .font(PitchAtlasTheme.martian(9))
                    .foregroundStyle(PitchAtlasTheme.ink3)
            }
            .padding(.top, 2)
        }
        .leatherPress()
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
