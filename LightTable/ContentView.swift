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
            VStack(spacing: 8) {
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
                if summary.unknownSizeCount > 0 {
                    Text("\(summary.unknownSizeCount) assets with unknown size (skipped)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
