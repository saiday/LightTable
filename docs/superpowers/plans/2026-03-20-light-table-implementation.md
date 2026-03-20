# Light Table Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS SwiftUI app that scans the Photos library for large assets and creates size-ordered albums in Photos.app.

**Architecture:** Three-layer app: PhotoLibraryService (PhotoKit scanning + file size extraction), AlbumService (album CRUD in Photos.app), and SwiftUI views. Models hold scanned asset data and summary stats. Services are protocol-backed for testability.

**Tech Stack:** Swift, SwiftUI, PhotoKit (Photos.framework), macOS 13+, xcodegen for project generation

---

## File Structure

```
LightTable/
├── project.yml                          # xcodegen project spec
├── LightTable/
│   ├── LightTableApp.swift              # @main app entry point
│   ├── ContentView.swift                # Main single-window view
│   ├── Models/
│   │   ├── AssetInfo.swift              # Asset + file size model
│   │   └── ScanResult.swift             # Scan summary + categorized assets
│   ├── Services/
│   │   ├── PhotoLibraryService.swift    # PhotoKit scanning, authorization
│   │   └── AlbumService.swift           # Album create/find/clear/populate
│   ├── Resources/
│   │   └── Info.plist                   # NSPhotoLibraryReadWriteUsageDescription
│   └── LightTable.entitlements          # Hardened Runtime + Photos entitlement
├── LightTableTests/
│   └── ScanResultTests.swift            # Filtering, sorting, summary logic
```

---

### Task 1: Project Scaffolding

**Files:**
- Create: `project.yml`
- Create: `LightTable/LightTableApp.swift`
- Create: `LightTable/ContentView.swift`
- Create: `LightTable/Resources/Info.plist`
- Create: `LightTable/LightTable.entitlements`
- Create: `.gitignore`

- [ ] **Step 1: Install xcodegen if not present**

Run: `brew list xcodegen || brew install xcodegen`

- [ ] **Step 2: Create directory structure**

Run:
```bash
mkdir -p LightTable/Models LightTable/Services LightTable/Resources LightTableTests
```

- [ ] **Step 3: Create project.yml**

```yaml
name: LightTable
options:
  bundleIdPrefix: com.saiday
  deploymentTarget:
    macOS: "13.0"
  xcodeVersion: "16.0"
  generateEmptyDirectories: true
settings:
  base:
    ENABLE_HARDENED_RUNTIME: YES
    CODE_SIGN_IDENTITY: "-"
    PRODUCT_NAME: "Light Table"
targets:
  LightTable:
    type: application
    platform: macOS
    sources:
      - LightTable
    settings:
      base:
        INFOPLIST_FILE: LightTable/Resources/Info.plist
        CODE_SIGN_ENTITLEMENTS: LightTable/LightTable.entitlements
        PRODUCT_BUNDLE_IDENTIFIER: com.saiday.light-table
    scheme:
      testTargets:
        - LightTableTests
  LightTableTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - LightTableTests
    dependencies:
      - target: LightTable
    settings:
      base:
        BUNDLE_LOADER: "$(TEST_HOST)"
        TEST_HOST: "$(BUILT_PRODUCTS_DIR)/Light Table.app/Contents/MacOS/Light Table"
```

- [ ] **Step 4: Create Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPhotoLibraryReadWriteUsageDescription</key>
    <string>Light Table needs access to your Photos library to find large files and create sorted albums.</string>
</dict>
</plist>
```

- [ ] **Step 5: Create entitlements file**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.personal-information.photos-library</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 6: Create minimal app entry point**

`LightTable/LightTableApp.swift`:
```swift
import SwiftUI

@main
struct LightTableApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

- [ ] **Step 7: Create placeholder ContentView**

`LightTable/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Light Table")
            .frame(width: 500, height: 400)
    }
}
```

- [ ] **Step 8: Create .gitignore**

```
# Xcode
*.xcodeproj/xcuserdata/
*.xcodeproj/project.xcworkspace/xcuserdata/
*.xcworkspace/xcuserdata/
DerivedData/
build/
*.pbxuser
*.mode1v3
*.mode2v3
*.perspectivev3
*.moved-aside

# macOS
.DS_Store

# SwiftPM
.build/
.swiftpm/
```

- [ ] **Step 9: Generate Xcode project and build**

Run:
```bash
xcodegen generate
xcodebuild -scheme LightTable -configuration Debug -destination 'platform=macOS' build
```
Expected: BUILD SUCCEEDED

- [ ] **Step 10: Commit**

```bash
git add .gitignore project.yml LightTable/ LightTableTests/ LightTable.xcodeproj/
git commit -m "feat: scaffold Xcode project with SwiftUI app, entitlements, and Info.plist"
```

---

### Task 2: AssetInfo and ScanResult Models

**Files:**
- Create: `LightTable/Models/AssetInfo.swift`
- Create: `LightTable/Models/ScanResult.swift`
- Create: `LightTableTests/ScanResultTests.swift`

- [ ] **Step 1: Write failing tests for ScanResult filtering and summary**

`LightTableTests/ScanResultTests.swift`:
```swift
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
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme LightTable -destination 'platform=macOS' -configuration Debug 2>&1 | tail -20`
Expected: FAIL — `AssetInfo` and `ScanResult` not defined

- [ ] **Step 3: Implement AssetInfo model**

`LightTable/Models/AssetInfo.swift`:
```swift
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
```

- [ ] **Step 4: Implement ScanResult model**

`LightTable/Models/ScanResult.swift`:
```swift
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
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild test -scheme LightTable -destination 'platform=macOS' -configuration Debug 2>&1 | tail -20`
Expected: All 4 tests PASS

- [ ] **Step 6: Commit**

```bash
git add LightTable/Models/ LightTableTests/ScanResultTests.swift
git commit -m "feat: add AssetInfo and ScanResult models with filtering and summary"
```

---

### Task 3: PhotoLibraryService — Authorization + Scanning

**Files:**
- Create: `LightTable/Services/PhotoLibraryService.swift`

- [ ] **Step 1: Implement PhotoLibraryService**

`LightTable/Services/PhotoLibraryService.swift`:
```swift
import Photos

enum PhotoLibraryError: Error, LocalizedError {
    case accessDenied
    case accessRestricted

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Photos access denied. Open System Settings → Privacy & Security → Photos to grant access."
        case .accessRestricted:
            return "Photos access is restricted on this device."
        }
    }
}

@MainActor
final class PhotoLibraryService: ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var scanProgress: ScanProgress?
    @Published var scanResult: ScanResult?
    @Published var isScanning = false

    struct ScanProgress {
        let completed: Int
        let total: Int
    }

    func requestAuthorization() async -> PHAuthorizationStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            authorizationStatus = newStatus
            return newStatus
        }
        authorizationStatus = status
        return status
    }

    func scan() async throws {
        let status = await requestAuthorization()
        guard status == .authorized else {
            if status == .restricted {
                throw PhotoLibraryError.accessRestricted
            }
            throw PhotoLibraryError.accessDenied
        }

        isScanning = true
        scanProgress = nil
        scanResult = nil

        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ScanResult, Error>) in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let fetchOptions = PHFetchOptions()
                fetchOptions.includeHiddenAssets = false
                let allAssets = PHAsset.fetchAssets(with: fetchOptions)
                let total = allAssets.count

                var assetInfos: [AssetInfo] = []
                assetInfos.reserveCapacity(total)

                allAssets.enumerateObjects { asset, index, _ in
                    let info = AssetInfo.from(asset: asset)
                    if info.mediaType != .other {
                        assetInfos.append(info)
                    }

                    if index % 500 == 0 {
                        let progress = ScanProgress(completed: index, total: total)
                        Task { @MainActor in
                            self?.scanProgress = progress
                        }
                    }
                }

                let finalProgress = ScanProgress(completed: total, total: total)
                Task { @MainActor in
                    self?.scanProgress = finalProgress
                }

                continuation.resume(returning: ScanResult(assets: assetInfos))
            }
        }

        scanResult = result
        isScanning = false
    }
}
```

- [ ] **Step 2: Build to verify compilation**

Run: `xcodebuild -scheme LightTable -destination 'platform=macOS' -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add LightTable/Services/PhotoLibraryService.swift
git commit -m "feat: add PhotoLibraryService with authorization and async scanning"
```

---

### Task 4: AlbumService — Create, Find, Clear, Populate Albums

**Files:**
- Create: `LightTable/Services/AlbumService.swift`

- [ ] **Step 1: Implement AlbumService**

`LightTable/Services/AlbumService.swift`:
```swift
import Photos

@MainActor
final class AlbumService: ObservableObject {
    @Published var isCreating = false
    @Published var createdAlbumNames: [String] = []

    func createAlbums(categories: [AlbumCategory]) async throws {
        isCreating = true
        createdAlbumNames = []

        for category in categories where category.isSelected && !category.assets.isEmpty {
            try await createOrUpdateAlbum(name: category.name, assets: category.assets)
            createdAlbumNames.append(category.name)
        }

        isCreating = false
    }

    private func createOrUpdateAlbum(name: String, assets: [AssetInfo]) async throws {
        // Fetch PHAsset objects from local identifiers
        let identifiers = assets.map { $0.localIdentifier }
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        var phAssets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            phAssets.append(asset)
        }

        // Re-sort by file size descending (fetchAssets doesn't preserve order)
        let sizeMap = Dictionary(uniqueKeysWithValues: assets.map { ($0.localIdentifier, $0.fileSize) })
        phAssets.sort { (sizeMap[$0.localIdentifier] ?? 0) > (sizeMap[$1.localIdentifier] ?? 0) }

        // Find or create album
        let album = findAlbum(named: name)

        if let existing = album {
            // Clear existing album contents
            try clearAlbum(existing)
            // Populate with new assets
            try populateAlbum(existing, with: phAssets)
        } else {
            // Create new album and populate
            let newAlbum = try createAlbum(named: name)
            try populateAlbum(newAlbum, with: phAssets)
        }
    }

    private func findAlbum(named title: String) -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title == %@", title)
        return PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: fetchOptions
        ).firstObject
    }

    private func createAlbum(named title: String) throws -> PHAssetCollection {
        var placeholder: PHObjectPlaceholder?
        try PHPhotoLibrary.shared().performChangesAndWait {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            placeholder = request.placeholderForCreatedAssetCollection
        }
        guard let localIdentifier = placeholder?.localIdentifier,
              let album = PHAssetCollection.fetchAssetCollections(
                  withLocalIdentifiers: [localIdentifier],
                  options: nil
              ).firstObject
        else {
            throw AlbumError.creationFailed
        }
        return album
    }

    private func clearAlbum(_ album: PHAssetCollection) throws {
        let assets = PHAsset.fetchAssets(in: album, options: nil)
        guard assets.count > 0 else { return }
        try PHPhotoLibrary.shared().performChangesAndWait {
            guard let request = PHAssetCollectionChangeRequest(for: album) else { return }
            request.removeAssets(assets)
        }
    }

    private func populateAlbum(_ album: PHAssetCollection, with assets: [PHAsset]) throws {
        guard !assets.isEmpty else { return }
        try PHPhotoLibrary.shared().performChangesAndWait {
            guard let request = PHAssetCollectionChangeRequest(for: album) else { return }
            request.insertAssets(
                assets as NSArray,
                at: IndexSet(integersIn: 0..<assets.count)
            )
        }
    }
}

enum AlbumError: Error, LocalizedError {
    case creationFailed

    var errorDescription: String? {
        switch self {
        case .creationFailed:
            return "Failed to create album in Photos."
        }
    }
}
```

- [ ] **Step 2: Build to verify compilation**

Run: `xcodebuild -scheme LightTable -destination 'platform=macOS' -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add LightTable/Services/AlbumService.swift
git commit -m "feat: add AlbumService with album create, find, clear, and populate"
```

---

### Task 5: SwiftUI UI — Scan, Summary, and Album Creation

**Files:**
- Modify: `LightTable/ContentView.swift`

- [ ] **Step 1: Implement ContentView with full UI flow**

`LightTable/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var photoService = PhotoLibraryService()
    @StateObject private var albumService = AlbumService()
    @State private var categories: [AlbumCategory] = []
    @State private var errorMessage: String?
    @State private var showSuccess = false

    var body: some View {
        VStack(spacing: 20) {
            headerView
            Divider()

            if let error = errorMessage {
                errorView(error)
            } else if photoService.isScanning {
                scanningView
            } else if let result = photoService.scanResult {
                if result.assets.isEmpty {
                    emptyLibraryView
                } else {
                    summaryView(result)
                    Divider()
                    albumSelectionView
                    Divider()
                    createAlbumsButton
                }
            } else {
                scanButton
            }

            if showSuccess {
                successView
            }
        }
        .padding(30)
        .frame(minWidth: 500, minHeight: 400)
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(spacing: 4) {
            Text("Light Table")
                .font(.largeTitle.bold())
            Text("Sort your Photos library by size")
                .foregroundStyle(.secondary)
        }
    }

    private var emptyLibraryView: some View {
        VStack(spacing: 12) {
            Text("No photos or videos found")
                .font(.headline)
            Text("Your Photos library appears to be empty.")
                .foregroundStyle(.secondary)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                errorMessage = nil
            }
        }
    }

    private var scanningView: some View {
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
    }

    private func summaryView(_ result: ScanResult) -> some View {
        let summary = result.summary()
        return VStack(spacing: 8) {
            Text("Library Summary")
                .font(.headline)
            HStack(spacing: 30) {
                statItem(label: "Photos", value: "\(summary.totalImages)")
                statItem(label: "Videos", value: "\(summary.totalVideos)")
                statItem(label: "Total Size", value: formatBytes(summary.totalSize))
            }
            if summary.unknownSizeCount > 0 {
                Text("\(summary.unknownSizeCount) assets with unknown size (skipped)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func statItem(label: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var albumSelectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Albums to Create")
                .font(.headline)
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
        }
    }

    private var createAlbumsButton: some View {
        VStack(spacing: 8) {
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

    private var scanButton: some View {
        Button("Scan Library") {
            Task { await startScan() }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private var successView: some View {
        VStack(spacing: 8) {
            Text("Albums created successfully!")
                .foregroundStyle(.green)
            Text("Open Photos.app to view them.")
                .font(.caption)
                .foregroundStyle(.secondary)
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
}
```

- [ ] **Step 2: Build to verify compilation**

Run: `xcodebuild -scheme LightTable -destination 'platform=macOS' -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add LightTable/ContentView.swift
git commit -m "feat: implement main UI with scan, summary, album selection, and creation"
```

---

### Task 6: Manual Integration Test

- [ ] **Step 1: Build and run the app**

Run: `xcodebuild -scheme LightTable -destination 'platform=macOS' -configuration Debug build 2>&1 | tail -5`
Then open: `open $(xcodebuild -scheme LightTable -configuration Debug -showBuildSettings 2>/dev/null | grep ' BUILT_PRODUCTS_DIR' | awk '{print $3}')/Light\ Table.app`

- [ ] **Step 2: Test the full flow manually**

1. App launches → click "Scan Library"
2. System prompts for Photos permission → grant
3. Scan runs with progress indicator
4. Summary shows photo/video counts and total size
5. Album checkboxes appear with item counts
6. Select desired albums → click "Create Albums"
7. Open Photos.app → verify albums exist with assets in size-descending order

- [ ] **Step 3: Test error states**

1. Deny Photos permission → verify error message appears
2. Re-run scan after albums exist → verify albums are updated (not duplicated)

- [ ] **Step 4: Commit any fixes discovered during testing**

```bash
git add -A
git commit -m "fix: address issues found during manual testing"
```

