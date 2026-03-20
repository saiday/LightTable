import Foundation

struct ScanSummary {
    let totalImages: Int
    let totalVideos: Int
    let unknownSizeCount: Int
    let totalSize: Int64
}

struct AlbumCategory: Identifiable {
    let id: String
    let name: String
    let assets: [AssetInfo]
    var isSelected: Bool

    var totalSize: Int64 {
        assets.reduce(0) { $0 + $1.fileSize }
    }
}

struct ScanResult {
    let assets: [AssetInfo]

    func images(above threshold: Int64) -> [AssetInfo] {
        assets
            .filter { $0.mediaType == .image && $0.hasKnownSize && $0.fileSize > threshold }
            .sorted { $0.fileSize > $1.fileSize }
    }

    func videosBySize() -> [AssetInfo] {
        assets
            .filter { $0.mediaType == .video && $0.hasKnownSize }
            .sorted { $0.fileSize > $1.fileSize }
    }

    func summary() -> ScanSummary {
        let images = assets.filter { $0.mediaType == .image }
        let videos = assets.filter { $0.mediaType == .video }
        let unknownSize = assets.filter { !$0.hasKnownSize }
        let totalSize = assets.reduce(Int64(0)) { $0 + $1.fileSize }

        return ScanSummary(
            totalImages: images.count,
            totalVideos: videos.count,
            unknownSizeCount: unknownSize.count,
            totalSize: totalSize
        )
    }

    func albumCategories() -> [AlbumCategory] {
        let imgs10 = images(above: 10_000_000)
        let imgs5 = images(above: 5_000_000)
        let vids = videosBySize()

        return [
            AlbumCategory(
                id: "images-10mb",
                name: "Light Table - Images >10MB",
                assets: imgs10,
                isSelected: !imgs10.isEmpty
            ),
            AlbumCategory(
                id: "images-5mb",
                name: "Light Table - Images >5MB",
                assets: imgs5,
                isSelected: !imgs5.isEmpty
            ),
            AlbumCategory(
                id: "videos-by-size",
                name: "Light Table - Videos by Size",
                assets: vids,
                isSelected: !vids.isEmpty
            ),
        ]
    }
}
