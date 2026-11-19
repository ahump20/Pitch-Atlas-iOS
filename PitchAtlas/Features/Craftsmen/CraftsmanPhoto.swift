import SwiftUI

/// Documentary photographs packaged separately from the publishers' film embeds.
struct CraftsmanPhoto: Decodable {
    let slug: String
    let alt: String
    let title: String
    let credit: String
    let source: URL
    let license: String
    let licenseURL: URL?

    static let catalog: [String: CraftsmanPhoto] = {
        guard let url = Bundle.main.url(forResource: "craftsmen-photo-credits", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let photos = try? JSONDecoder().decode([CraftsmanPhoto].self, from: data) else { return [:] }
        return Dictionary(photos.map { ($0.slug, $0) }, uniquingKeysWith: { first, _ in first })
    }()

    var image: UIImage? { BundledImage.load("craftsman-\(slug).webp") }
    var thumbnail: UIImage? { BundledImage.load("craftsman-\(slug)-thumbnail.webp") }
}

/// The photograph and its credit travel together in the pitcher's file.
struct CraftsmanPhotoFigure: View {
    let photo: CraftsmanPhoto

    var body: some View {
        if let image = photo.image {
            VStack(alignment: .leading, spacing: 6) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .accessibilityLabel(photo.alt)
                    .accessibilityIdentifier("craftsman-photo-\(photo.slug)")
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 8) {
                        Link(photo.title, destination: photo.source)
                        if let licenseURL = photo.licenseURL {
                            Link(photo.license, destination: licenseURL)
                        } else {
                            Text(photo.license)
                        }
                        Text("Cropped for display.")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                } label: {
                    Text("Photo credit · \(photo.credit)")
                }
                .font(PitchAtlasType.body(size: 13))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .tint(PitchAtlasTheme.cyan)
            }
        }
    }
}
