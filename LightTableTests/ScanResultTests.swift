import XCTest
@testable import LightTable

final class ScanResultTests: XCTestCase {

    func testFilterImagesAboveThreshold() {
        let assets = [
            AssetInfo(localIdentifier: "1", mediaType: .image, fileSize: 15_000_000, creationDate: nil),  // 15MB
            AssetInfo(localIdentifier: "2", mediaType: .image, fileSize: 3_000_000, creationDate: nil),   // 3MB
            AssetInfo(localIdentifier: "3", mediaType: .image, fileSize: 8_000_000, creationDate: nil),   // 8MB
            AssetInfo(localIdentifier: "4", mediaType: .video, fileSize: 50_000_000, creationDate: nil),  // 50MB video
        ]
        let result = ScanResult(assets: assets)

        let above10MB = result.images(above: 10_000_000)
        XCTAssertEqual(above10MB.count, 1)
        XCTAssertEqual(above10MB[0].localIdentifier, "1")

        let above5MB = result.images(above: 5_000_000)
        XCTAssertEqual(above5MB.count, 2)
        // Should be sorted by size descending
        XCTAssertEqual(above5MB[0].localIdentifier, "1")
        XCTAssertEqual(above5MB[1].localIdentifier, "3")
    }

    func testVideosSortedBySize() {
        let assets = [
            AssetInfo(localIdentifier: "1", mediaType: .video, fileSize: 10_000_000, creationDate: nil),
            AssetInfo(localIdentifier: "2", mediaType: .video, fileSize: 50_000_000, creationDate: nil),
            AssetInfo(localIdentifier: "3", mediaType: .image, fileSize: 20_000_000, creationDate: nil),
            AssetInfo(localIdentifier: "4", mediaType: .video, fileSize: 30_000_000, creationDate: nil),
        ]
        let result = ScanResult(assets: assets)
        let videos = result.videosBySize()

        XCTAssertEqual(videos.count, 3)
        XCTAssertEqual(videos[0].localIdentifier, "2")  // 50MB
        XCTAssertEqual(videos[1].localIdentifier, "4")  // 30MB
        XCTAssertEqual(videos[2].localIdentifier, "1")  // 10MB
    }

    func testSummary() {
        let assets = [
            AssetInfo(localIdentifier: "1", mediaType: .image, fileSize: 15_000_000, creationDate: nil),
            AssetInfo(localIdentifier: "2", mediaType: .image, fileSize: 3_000_000, creationDate: nil),
            AssetInfo(localIdentifier: "3", mediaType: .image, fileSize: 0, creationDate: nil),  // unknown size
            AssetInfo(localIdentifier: "4", mediaType: .video, fileSize: 50_000_000, creationDate: nil),
        ]
        let result = ScanResult(assets: assets)
        let summary = result.summary()

        XCTAssertEqual(summary.totalImages, 3)
        XCTAssertEqual(summary.totalVideos, 1)
        XCTAssertEqual(summary.unknownSizeCount, 1)
        XCTAssertEqual(summary.totalSize, 68_000_000)
    }

    func testImagesAboveThresholdExcludesUnknownSize() {
        let assets = [
            AssetInfo(localIdentifier: "1", mediaType: .image, fileSize: 15_000_000, creationDate: nil),
            AssetInfo(localIdentifier: "2", mediaType: .image, fileSize: 0, creationDate: nil),  // unknown
        ]
        let result = ScanResult(assets: assets)
        let above5MB = result.images(above: 5_000_000)
        XCTAssertEqual(above5MB.count, 1)
    }

    func testAssetInfoDefaultValues() {
        let info = AssetInfo(localIdentifier: "1", mediaType: .image, fileSize: 1000, creationDate: nil)
        XCTAssertEqual(info.pixelWidth, 0)
        XCTAssertEqual(info.pixelHeight, 0)
        XCTAssertEqual(info.duration, 0)
    }

    func testAssetInfoMegapixels() {
        let info = AssetInfo(localIdentifier: "1", mediaType: .image, fileSize: 5_000_000, creationDate: nil, pixelWidth: 4032, pixelHeight: 3024)
        XCTAssertEqual(info.megapixels, 12.2, accuracy: 0.1)
    }

    func testAssetInfoMegapixelsZeroWhenNoDimensions() {
        let info = AssetInfo(localIdentifier: "1", mediaType: .image, fileSize: 5_000_000, creationDate: nil)
        XCTAssertEqual(info.megapixels, 0)
    }

    func testSizeDistribution() {
        let assets = [
            AssetInfo(localIdentifier: "1", mediaType: .image, fileSize: 500_000, creationDate: nil),      // < 1MB
            AssetInfo(localIdentifier: "2", mediaType: .image, fileSize: 3_000_000, creationDate: nil),     // 1-5MB
            AssetInfo(localIdentifier: "3", mediaType: .image, fileSize: 8_000_000, creationDate: nil),     // 5-10MB
            AssetInfo(localIdentifier: "4", mediaType: .video, fileSize: 25_000_000, creationDate: nil),    // 10-50MB
            AssetInfo(localIdentifier: "5", mediaType: .video, fileSize: 75_000_000, creationDate: nil),    // 50-100MB
            AssetInfo(localIdentifier: "6", mediaType: .video, fileSize: 200_000_000, creationDate: nil),   // 100MB+
            AssetInfo(localIdentifier: "7", mediaType: .image, fileSize: 0, creationDate: nil),             // unknown - excluded
        ]
        let result = ScanResult(assets: assets)
        let buckets = result.sizeDistribution()

        XCTAssertEqual(buckets.count, 6)
        XCTAssertEqual(buckets[0].label, "< 1 MB")
        XCTAssertEqual(buckets[0].imageCount, 1)
        XCTAssertEqual(buckets[0].videoCount, 0)
        XCTAssertEqual(buckets[1].label, "1\u{2013}5 MB")  // en-dash
        XCTAssertEqual(buckets[1].imageCount, 1)
        XCTAssertEqual(buckets[2].label, "5\u{2013}10 MB")
        XCTAssertEqual(buckets[2].imageCount, 1)
        XCTAssertEqual(buckets[3].label, "10\u{2013}50 MB")
        XCTAssertEqual(buckets[3].videoCount, 1)
        XCTAssertEqual(buckets[4].label, "50\u{2013}100 MB")
        XCTAssertEqual(buckets[4].videoCount, 1)
        XCTAssertEqual(buckets[5].label, "100+ MB")
        XCTAssertEqual(buckets[5].videoCount, 1)
    }

    func testSizeDistributionTotalSize() {
        let assets = [
            AssetInfo(localIdentifier: "1", mediaType: .image, fileSize: 3_000_000, creationDate: nil),
            AssetInfo(localIdentifier: "2", mediaType: .video, fileSize: 4_000_000, creationDate: nil),
        ]
        let result = ScanResult(assets: assets)
        let buckets = result.sizeDistribution()
        let bucket1to5 = buckets.first(where: { $0.label == "1\u{2013}5 MB" })!
        XCTAssertEqual(bucket1to5.imageTotalSize, 3_000_000)
        XCTAssertEqual(bucket1to5.videoTotalSize, 4_000_000)
    }

    func testEnhancedSummary() {
        let assets = [
            AssetInfo(localIdentifier: "1", mediaType: .image, fileSize: 5_000_000, creationDate: nil, pixelWidth: 4032, pixelHeight: 3024),
            AssetInfo(localIdentifier: "2", mediaType: .image, fileSize: 3_000_000, creationDate: nil, pixelWidth: 3024, pixelHeight: 2016),
            AssetInfo(localIdentifier: "3", mediaType: .video, fileSize: 50_000_000, creationDate: nil, duration: 120),
            AssetInfo(localIdentifier: "4", mediaType: .video, fileSize: 30_000_000, creationDate: nil, duration: 60),
        ]
        let result = ScanResult(assets: assets)
        let summary = result.summary()

        // Average megapixels: (12.19 + 6.10) / 2 = 9.145
        XCTAssertEqual(summary.averageMegapixels, 9.1, accuracy: 0.2)
        XCTAssertEqual(summary.totalVideoDuration, 180)
    }

    func testEnhancedSummaryNoImages() {
        let assets = [
            AssetInfo(localIdentifier: "1", mediaType: .video, fileSize: 50_000_000, creationDate: nil, duration: 120),
        ]
        let result = ScanResult(assets: assets)
        let summary = result.summary()
        XCTAssertEqual(summary.averageMegapixels, 0)
        XCTAssertEqual(summary.totalVideoDuration, 120)
    }
}
