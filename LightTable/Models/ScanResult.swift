import Foundation

struct ScanSummary {
    let totalImages: Int
    let totalVideos: Int
    let unknownSizeCount: Int
    let totalSize: Int64
    let averageMegapixels: Double
    let totalVideoDuration: TimeInterval
}

struct SizeBucket: Identifiable {
    let id: String
    let label: String
    let lowerBound: Int64
    let upperBound: Int64
    var imageCount: Int = 0
    var videoCount: Int = 0
    var imageTotalSize: Int64 = 0
    var videoTotalSize: Int64 = 0

    var totalCount: Int { imageCount + videoCount }
    var totalSize: Int64 { imageTotalSize + videoTotalSize }
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

        let imagesWithDimensions = images.filter { $0.pixelWidth > 0 && $0.pixelHeight > 0 }
        let avgMegapixels: Double
        if imagesWithDimensions.isEmpty {
            avgMegapixels = 0
        } else {
            let totalMegapixels = imagesWithDimensions.reduce(0.0) { $0 + $1.megapixels }
            avgMegapixels = totalMegapixels / Double(imagesWithDimensions.count)
        }

        let totalDuration = videos.reduce(0.0) { $0 + $1.duration }

        return ScanSummary(
            totalImages: images.count,
            totalVideos: videos.count,
            unknownSizeCount: unknownSize.count,
            totalSize: totalSize,
            averageMegapixels: avgMegapixels,
            totalVideoDuration: totalDuration
        )
    }

    func sizeDistribution() -> [SizeBucket] {
        let ranges: [(id: String, label: String, lower: Int64, upper: Int64)] = [
            ("lt1mb",    "< 1 MB",        0,           1_000_000),
            ("1to5mb",   "1\u{2013}5 MB",  1_000_000,   5_000_000),
            ("5to10mb",  "5\u{2013}10 MB", 5_000_000,   10_000_000),
            ("10to50mb", "10\u{2013}50 MB",10_000_000,  50_000_000),
            ("50to100mb","50\u{2013}100 MB",50_000_000, 100_000_000),
            ("gt100mb",  "100+ MB",       100_000_000, Int64.max),
        ]

        var buckets = ranges.map { SizeBucket(id: $0.id, label: $0.label, lowerBound: $0.lower, upperBound: $0.upper) }

        for asset in assets where asset.hasKnownSize {
            guard let index = buckets.firstIndex(where: { asset.fileSize >= $0.lowerBound && asset.fileSize < $0.upperBound }) else { continue }
            switch asset.mediaType {
            case .image:
                buckets[index].imageCount += 1
                buckets[index].imageTotalSize += asset.fileSize
            case .video:
                buckets[index].videoCount += 1
                buckets[index].videoTotalSize += asset.fileSize
            case .other:
                break
            }
        }

        return buckets
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
