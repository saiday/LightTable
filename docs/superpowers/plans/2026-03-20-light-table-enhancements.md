# Light Table Enhancement Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enhance Light Table with richer metadata, a file size distribution chart, proper macOS UI patterns (toolbar, GroupBox, NavigationStack), better post-creation UX, and re-scan capability.

**Architecture:** Extend the existing model layer with new PHAsset metadata and size distribution analytics. Add a Swift Charts bar chart view. Redesign ContentView to follow macOS HIG: NavigationStack for toolbar integration, GroupBox for visual sections, ScrollView for overflow. Improve album creation feedback with explicit album names, location guidance, and an "Open Photos" button. Add re-scan via toolbar action.

**Tech Stack:** Swift, SwiftUI, Swift Charts, PhotoKit, macOS 13+

**Design context (from Apple HIG research):**
- macOS toolbar: leading (title/navigation), center (customizable), trailing (persistent actions/primary action). Every toolbar item must also be in the menu bar.
- macOS body text is 13pt. Use built-in text styles (Large Title 26pt, Title1 22pt, Headline 13pt bold).
- Use GroupBox or negative space for visual grouping. Don't put critical info at bottom.
- Charts: Bar marks for comparisons. Maximize plot area. Accessible by default.
- Support both light and dark mode via semantic colors.
- PhotoKit limitation: albums always appear at bottom of album list. No API to control position or create folders.

---

## File Structure

```
LightTable/
├── LightTableApp.swift              # Modify: window toolbar style
├── ContentView.swift                # Rewrite: NavigationStack, toolbar, GroupBox sections, ScrollView
├── Models/
│   ├── AssetInfo.swift              # Modify: add pixelWidth, pixelHeight, duration
│   └── ScanResult.swift             # Modify: add SizeBucket, sizeDistribution(), enhance summary
├── Views/
│   └── SizeDistributionChart.swift  # Create: Swift Charts bar chart with count/storage toggle
├── Services/
│   ├── PhotoLibraryService.swift    # No changes
│   └── AlbumService.swift           # No changes
LightTableTests/
└── ScanResultTests.swift            # Modify: add tests for new metadata, distribution, enhanced summary
```

---

### Task 1: Extend AssetInfo with Richer Metadata

**Files:**
- Modify: `LightTable/Models/AssetInfo.swift`
- Modify: `LightTableTests/ScanResultTests.swift`

- [ ] **Step 1: Write failing test for new metadata fields**

Add to `LightTableTests/ScanResultTests.swift`:
```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodegen generate && xcodebuild test -scheme LightTable -destination 'platform=macOS' -configuration Debug 2>&1 | tail -20`
Expected: FAIL — `pixelWidth`, `pixelHeight`, `duration`, `megapixels` not defined

- [ ] **Step 3: Add new fields to AssetInfo**

Modify `LightTable/Models/AssetInfo.swift` — add new stored properties with defaults after `creationDate`, and a computed `megapixels` property:

```swift
struct AssetInfo: Identifiable {
    let localIdentifier: String
    let mediaType: AssetMediaType
    let fileSize: Int64  // bytes, 0 means unknown
    let creationDate: Date?
    let pixelWidth: Int
    let pixelHeight: Int
    let duration: TimeInterval  // seconds, 0 for images

    var id: String { localIdentifier }

    var hasKnownSize: Bool { fileSize > 0 }

    var megapixels: Double {
        guard pixelWidth > 0 && pixelHeight > 0 else { return 0 }
        return Double(pixelWidth) * Double(pixelHeight) / 1_000_000.0
    }
    // ... from(asset:) stays below
}
```

**Important:** Since the default memberwise init changes, all existing call sites (tests) that create `AssetInfo` without the new parameters will fail. Update the `from(asset:)` factory to populate new fields, and provide an **explicit** initializer with defaults for the new parameters so existing test call sites continue to compile:

```swift
init(localIdentifier: String, mediaType: AssetMediaType, fileSize: Int64, creationDate: Date?, pixelWidth: Int = 0, pixelHeight: Int = 0, duration: TimeInterval = 0) {
    self.localIdentifier = localIdentifier
    self.mediaType = mediaType
    self.fileSize = fileSize
    self.creationDate = creationDate
    self.pixelWidth = pixelWidth
    self.pixelHeight = pixelHeight
    self.duration = duration
}
```

- [ ] **Step 4: Update `from(asset:)` to extract new fields**

In `AssetInfo.from(asset:)`, extract pixel dimensions and duration from the PHAsset:

```swift
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
        creationDate: asset.creationDate,
        pixelWidth: asset.pixelWidth,
        pixelHeight: asset.pixelHeight,
        duration: asset.duration
    )
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodegen generate && xcodebuild test -scheme LightTable -destination 'platform=macOS' -configuration Debug 2>&1 | tail -20`
Expected: All tests PASS (existing tests should still work since the init has default values for new params)

- [ ] **Step 6: Commit**

```bash
git add LightTable/Models/AssetInfo.swift LightTableTests/ScanResultTests.swift LightTable.xcodeproj/
git commit -m "feat: extend AssetInfo with pixelWidth, pixelHeight, duration, megapixels"
```

---

### Task 2: Size Distribution Model + Enhanced Summary

**Files:**
- Modify: `LightTable/Models/ScanResult.swift`
- Modify: `LightTableTests/ScanResultTests.swift`

- [ ] **Step 1: Write failing tests for size distribution and enhanced summary**

Add to `LightTableTests/ScanResultTests.swift`:
```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodegen generate && xcodebuild test -scheme LightTable -destination 'platform=macOS' -configuration Debug 2>&1 | tail -20`
Expected: FAIL — `sizeDistribution()`, `SizeBucket`, `averageMegapixels`, `totalVideoDuration` not defined

- [ ] **Step 3: Add SizeBucket struct and sizeDistribution() to ScanResult.swift**

Add to `LightTable/Models/ScanResult.swift`, before the `ScanResult` struct:

```swift
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
```

Add `sizeDistribution()` method to `ScanResult`:

```swift
func sizeDistribution() -> [SizeBucket] {
    let ranges: [(id: String, label: String, lower: Int64, upper: Int64)] = [
        ("lt1mb",    "< 1 MB",       0,             1_000_000),
        ("1to5mb",   "1\u{2013}5 MB",   1_000_000,     5_000_000),
        ("5to10mb",  "5\u{2013}10 MB",  5_000_000,     10_000_000),
        ("10to50mb", "10\u{2013}50 MB", 10_000_000,    50_000_000),
        ("50to100mb","50\u{2013}100 MB",50_000_000,    100_000_000),
        ("gt100mb",  "100+ MB",      100_000_000,   Int64.max),
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
```

- [ ] **Step 4: Enhance ScanSummary with new fields**

Update `ScanSummary` in `LightTable/Models/ScanResult.swift`:

```swift
struct ScanSummary {
    let totalImages: Int
    let totalVideos: Int
    let unknownSizeCount: Int
    let totalSize: Int64
    let averageMegapixels: Double
    let totalVideoDuration: TimeInterval
}
```

Update `summary()` in `ScanResult`:

```swift
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
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodegen generate && xcodebuild test -scheme LightTable -destination 'platform=macOS' -configuration Debug 2>&1 | tail -20`
Expected: All tests PASS

- [ ] **Step 6: Commit**

```bash
git add LightTable/Models/ScanResult.swift LightTableTests/ScanResultTests.swift LightTable.xcodeproj/
git commit -m "feat: add size distribution bucketing and enhanced summary stats"
```

---

### Task 3: Size Distribution Chart View

**Files:**
- Create: `LightTable/Views/SizeDistributionChart.swift`

**Note:** This task requires `import Charts` (Swift Charts, available macOS 13+).

- [ ] **Step 1: Create the Views directory**

Run: `mkdir -p LightTable/Views`

- [ ] **Step 2: Create SizeDistributionChart.swift**

`LightTable/Views/SizeDistributionChart.swift`:
```swift
import SwiftUI
import Charts

enum ChartMetric: String, CaseIterable {
    case count = "Count"
    case storage = "Storage"
}

struct SizeDistributionChart: View {
    let buckets: [SizeBucket]
    @State private var chartMetric: ChartMetric = .count

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Size Distribution")
                    .font(.headline)
                Spacer()
                Picker("Metric", selection: $chartMetric) {
                    ForEach(ChartMetric.allCases, id: \.self) { metric in
                        Text(metric.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 160)
            }

            Chart {
                ForEach(chartDataPoints) { point in
                    BarMark(
                        x: .value("Size Range", point.bucket),
                        y: .value(chartMetric == .count ? "Assets" : "Size", point.value)
                    )
                    .foregroundStyle(by: .value("Type", point.mediaType))
                }
            }
            .chartForegroundStyleScale([
                "Photos": Color.blue,
                "Videos": Color.purple,
            ])
            .chartYAxis {
                if chartMetric == .storage {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let bytes = value.as(Double.self) {
                                Text(formatBytes(Int64(bytes)))
                            }
                        }
                    }
                } else {
                    AxisMarks()
                }
            }
            .frame(height: 200)
        }
    }

    private var chartDataPoints: [ChartDataPoint] {
        buckets.flatMap { bucket -> [ChartDataPoint] in
            let imageValue: Double
            let videoValue: Double
            switch chartMetric {
            case .count:
                imageValue = Double(bucket.imageCount)
                videoValue = Double(bucket.videoCount)
            case .storage:
                imageValue = Double(bucket.imageTotalSize)
                videoValue = Double(bucket.videoTotalSize)
            }
            return [
                ChartDataPoint(bucket: bucket.label, mediaType: "Photos", value: imageValue),
                ChartDataPoint(bucket: bucket.label, mediaType: "Videos", value: videoValue),
            ]
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

private struct ChartDataPoint: Identifiable {
    let id = UUID()
    let bucket: String
    let mediaType: String
    let value: Double
}
```

- [ ] **Step 3: Build to verify compilation**

Run: `xcodegen generate && xcodebuild -scheme LightTable -destination 'platform=macOS' -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Run existing tests to verify no regressions**

Run: `xcodebuild test -scheme LightTable -destination 'platform=macOS' -configuration Debug 2>&1 | tail -20`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add LightTable/Views/ LightTable.xcodeproj/
git commit -m "feat: add size distribution bar chart with count/storage toggle"
```

---

### Task 4: UI Redesign with macOS Patterns

**Files:**
- Modify: `LightTable/LightTableApp.swift`
- Rewrite: `LightTable/ContentView.swift`

**Context:** Current UI is a flat VStack with no toolbar, no visual grouping, and no scroll support. Redesign to follow macOS HIG: NavigationStack for toolbar integration, GroupBox for visual sections, ScrollView for content overflow. The summary section should display the new metadata (average megapixels, total video duration). The initial "Scan Library" state should be a centered welcome view. After scan, content shows in grouped sections.

**Reference:** Read `docs/official_documents_for_agents/swiftui-toolbar-features.md` for toolbar API patterns. Read `docs/official_documents_for_agents/swiftui-liquid-glass.md` for awareness of Liquid Glass (NOT for implementation — requires macOS 26, our target is 13).

- [ ] **Step 1: Update LightTableApp.swift**

Replace `LightTable/LightTableApp.swift`:
```swift
import SwiftUI

@main
struct LightTableApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 600, height: 700)
    }
}
```

**Note:** `.defaultSize` is macOS 13+. It sets the initial window size without constraining resizing.

- [ ] **Step 2: Rewrite ContentView.swift with NavigationStack, toolbar, and GroupBox sections**

Replace `LightTable/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var photoService = PhotoLibraryService()
    @StateObject private var albumService = AlbumService()
    @State private var categories: [AlbumCategory] = []
    @State private var errorMessage: String?
    @State private var showSuccess = false

    private var hasResults: Bool {
        photoService.scanResult != nil
    }

    var body: some View {
        NavigationStack {
            Group {
                if !hasResults && !photoService.isScanning && errorMessage == nil {
                    welcomeView
                } else {
                    scrollableContent
                }
            }
            .navigationTitle("Light Table")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await startScan() }
                    } label: {
                        Label(hasResults ? "Scan Again" : "Scan Library", systemImage: "arrow.clockwise")
                    }
                    .disabled(photoService.isScanning)
                    .help(hasResults ? "Re-scan your Photos library" : "Scan your Photos library")
                }
            }
        }
    }

    // MARK: - Welcome

    private var welcomeView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Sort your Photos library by size")
                .font(.title3)
                .foregroundStyle(.secondary)
            Button("Scan Library") {
                Task { await startScan() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Scrollable Content

    private var scrollableContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let error = errorMessage {
                    errorSection(error)
                }

                if photoService.isScanning {
                    scanningSection
                }

                if let result = photoService.scanResult {
                    if result.assets.isEmpty {
                        emptyLibrarySection
                    } else {
                        summarySection(result)
                        chartSection(result)
                        albumSection
                    }
                }

                if showSuccess {
                    successSection
                }
            }
            .padding(20)
        }
    }

    // MARK: - Empty Library

    private var emptyLibrarySection: some View {
        GroupBox {
            VStack(spacing: 12) {
                Text("No photos or videos found")
                    .font(.headline)
                Text("Your Photos library appears to be empty.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(8)
        }
    }

    // MARK: - Error

    private func errorSection(_ message: String) -> some View {
        GroupBox {
            VStack(spacing: 8) {
                Label(message, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                Button("Dismiss") {
                    errorMessage = nil
                }
                .buttonStyle(.borderless)
            }
            .frame(maxWidth: .infinity)
            .padding(8)
        }
    }

    // MARK: - Scanning

    private var scanningSection: some View {
        GroupBox {
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                if let progress = photoService.scanProgress {
                    Text("Scanning \(progress.completed) / \(progress.total)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                } else {
                    Text("Starting scan...")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(8)
        }
    }

    // MARK: - Summary

    private func summarySection(_ result: ScanResult) -> some View {
        let summary = result.summary()
        return GroupBox("Library Summary") {
            HStack(spacing: 30) {
                statItem(
                    label: "Photos",
                    value: "\(summary.totalImages)",
                    detail: summary.averageMegapixels > 0 ? "avg \(String(format: "%.1f", summary.averageMegapixels)) MP" : nil
                )
                Divider().frame(height: 40)
                statItem(
                    label: "Videos",
                    value: "\(summary.totalVideos)",
                    detail: summary.totalVideoDuration > 0 ? formatDuration(summary.totalVideoDuration) : nil
                )
                Divider().frame(height: 40)
                statItem(
                    label: "Total Size",
                    value: formatBytes(summary.totalSize),
                    detail: nil
                )
            }
            .frame(maxWidth: .infinity)
            .padding(8)
        }
    }

    private func statItem(label: String, value: String, detail: String?) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let detail = detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Chart

    private func chartSection(_ result: ScanResult) -> some View {
        GroupBox {
            SizeDistributionChart(buckets: result.sizeDistribution())
                .padding(8)
        }
    }

    // MARK: - Album Selection

    private var albumSection: some View {
        GroupBox("Albums to Create") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach($categories) { $category in
                    HStack {
                        Toggle(isOn: $category.isSelected) {
                            Text(category.name)
                        }
                        .disabled(category.assets.isEmpty)
                        Spacer()
                        Text("\(category.assets.count) items (\(formatBytes(category.totalSize)))")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }

                HStack {
                    Spacer()
                    Button {
                        Task { await createAlbums() }
                    } label: {
                        if albumService.isCreating {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Create Albums")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(albumService.isCreating || !categories.contains(where: { $0.isSelected && !$0.assets.isEmpty }))
                }
            }
            .padding(8)
        }
    }

    // MARK: - Success

    private var successSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("Albums created successfully!", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)

                if !albumService.createdAlbumNames.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(albumService.createdAlbumNames, id: \.self) { name in
                            Label(name, systemImage: "photo.on.rectangle")
                                .foregroundStyle(.primary)
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Label("Where to find your albums:", systemImage: "info.circle")
                        .font(.subheadline.bold())

                    Text("macOS: Photos \u{2192} Sidebar \u{2192} My Albums \u{2192} scroll to bottom")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("iOS: Photos \u{2192} Albums tab \u{2192} My Albums \u{2192} scroll to bottom")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("You can drag albums to reorder them in Photos.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                HStack {
                    Spacer()
                    Button("Open Photos") {
                        NSWorkspace.shared.open(URL(string: "photos://")!)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        }
    }

    // MARK: - Actions

    private func startScan() async {
        errorMessage = nil
        showSuccess = false
        do {
            try await photoService.scan()
            if let result = photoService.scanResult {
                categories = result.albumCategories()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createAlbums() async {
        showSuccess = false
        do {
            try await albumService.createAlbums(categories: categories)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropLeading
        return formatter.string(from: seconds) ?? ""
    }
}
```

- [ ] **Step 3: Build to verify compilation**

Run: `xcodegen generate && xcodebuild clean build -scheme LightTable -destination 'platform=macOS' -configuration Debug 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Run tests to verify no regressions**

Run: `xcodebuild test -scheme LightTable -destination 'platform=macOS' -configuration Debug 2>&1 | tail -20`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add LightTable/LightTableApp.swift LightTable/ContentView.swift LightTable.xcodeproj/
git commit -m "feat: redesign UI with NavigationStack, toolbar, GroupBox sections, and enhanced summary"
```

---

### Task 5: Manual Verification

- [ ] **Step 1: Build and run the app**

Run:
```bash
xcodebuild -scheme LightTable -destination 'platform=macOS' -configuration Debug build 2>&1 | tail -5
open "$(xcodebuild -scheme LightTable -configuration Debug -showBuildSettings 2>/dev/null | grep ' BUILT_PRODUCTS_DIR' | awk '{print $3}')/Light Table.app"
```

- [ ] **Step 2: Verify the full flow**

1. App launches with welcome view (icon + "Scan Library" button)
2. Toolbar shows "Scan Library" button (also in toolbar for discoverability)
3. Click "Scan Library" → progress indicator in GroupBox
4. After scan: Library Summary GroupBox shows photos (with avg MP), videos (with total duration), total size
5. Size Distribution chart shows stacked bars. Toggle between Count and Storage.
6. Albums to Create section with toggles and "Create Albums" button
7. After creating albums: success section shows album names, location guidance for macOS and iOS, "Open Photos" button
8. "Scan Again" button in toolbar re-scans (resets results, categories, success state)
9. Window resizes gracefully, content scrolls when needed
10. Check dark mode appearance

- [ ] **Step 3: Commit any fixes discovered during testing**

```bash
git add -A
git commit -m "fix: address issues found during manual verification"
```
