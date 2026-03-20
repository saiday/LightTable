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
}
