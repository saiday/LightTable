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
