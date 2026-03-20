import Photos

enum AssetMediaType {
    case image
    case video
    case other
}

struct AssetInfo: Identifiable {
    let localIdentifier: String
    let mediaType: AssetMediaType
    let fileSize: Int64  // bytes, 0 means unknown
    let creationDate: Date?

    var id: String { localIdentifier }

    var hasKnownSize: Bool { fileSize > 0 }

    static func from(asset: PHAsset) -> AssetInfo {
        let resources = PHAssetResource.assetResources(for: asset)

        let primaryResource: PHAssetResource?
        switch asset.mediaType {
        case .image:
            primaryResource = resources.first(where: { $0.type == .photo })
                ?? resources.first(where: { $0.type == .fullSizePhoto })
        case .video:
            primaryResource = resources.first(where: { $0.type == .video })
                ?? resources.first(where: { $0.type == .fullSizeVideo })
        default:
            primaryResource = nil
        }

        let fileSize = (primaryResource?.value(forKey: "fileSize") as? Int64) ?? 0

        let mediaType: AssetMediaType
        switch asset.mediaType {
        case .image: mediaType = .image
        case .video: mediaType = .video
        default: mediaType = .other
        }

        return AssetInfo(
            localIdentifier: asset.localIdentifier,
            mediaType: mediaType,
            fileSize: fileSize,
            creationDate: asset.creationDate
        )
    }
}
