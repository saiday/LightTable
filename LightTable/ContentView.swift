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
        Group {
            if !hasResults && !photoService.isScanning && errorMessage == nil {
                welcomeView
            } else {
                scrollableContent
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .navigationTitle("Light Table")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await startScan() }
                } label: {
                    Label(hasResults ? "Scan Again" : "Scan Library", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(photoService.isScanning)
                .help(hasResults ? "Re-scan your Photos library" : "Scan your Photos library")
            }
        }
    }

    // MARK: - Welcome

    private var welcomeView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 100)
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(Theme.text3)
            Text("Sort your Photos library by size")
                .font(.title3)
                .foregroundStyle(Theme.text2)
            Button("Scan Library") {
                Task { await startScan() }
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Spacer(minLength: 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
    }

    // MARK: - Scrollable Content

    private var scrollableContent: some View {
        ScrollView {
            VStack(spacing: 24) {
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
                        heroSection(result.summary())
                        statPillsSection(result.summary())
                        chartSection(result)
                        albumSection
                    }
                }

                if showSuccess {
                    successSection
                }
            }
            .padding(24)
        }
        .background(Theme.bg)
    }

    // MARK: - Empty Library

    private var emptyLibrarySection: some View {
        VStack(spacing: 12) {
            Text("No photos or videos found")
                .font(.headline)
                .foregroundStyle(Theme.text1)
            Text("Your Photos library appears to be empty.")
                .foregroundStyle(Theme.text2)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
    }

    // MARK: - Error

    private func errorSection(_ message: String) -> some View {
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
        .padding(20)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
    }

    // MARK: - Scanning

    private var scanningSection: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            if let progress = photoService.scanProgress {
                Text("Scanning \(progress.completed) / \(progress.total)")
                    .monospacedDigit()
                    .foregroundStyle(Theme.text2)
            } else {
                Text("Starting scan...")
                    .foregroundStyle(Theme.text2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
    }

    // MARK: - Hero Stat

    private func heroSection(_ summary: ScanSummary) -> some View {
        let sizeString = formatBytes(summary.totalSize)
        let parts = sizeString.split(separator: " ", maxSplits: 1)
        let number = String(parts.first ?? "0")
        let unit = parts.count > 1 ? String(parts.last!) : ""

        return VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(number)
                    .font(.system(size: 52, weight: .heavy))
                    .tracking(-2.5)
                Text(unit)
                    .font(.system(size: 28, weight: .heavy))
            }
            .foregroundStyle(Theme.text1)
            .monospacedDigit()
            Text("LIBRARY SIZE")
                .font(.system(size: 11))
                .tracking(1.5)
                .foregroundStyle(Theme.text3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Stat Pills

    private func statPillsSection(_ summary: ScanSummary) -> some View {
        HStack(spacing: 12) {
            statPill(
                value: "\(summary.totalImages)",
                label: "PHOTOS",
                detail: summary.averageMegapixels > 0 ? "avg \(String(format: "%.1f", summary.averageMegapixels)) MP" : nil,
                accentColor: Theme.helvetiaBlue
            )
            statPill(
                value: "\(summary.totalVideos)",
                label: "VIDEOS",
                detail: summary.totalVideoDuration > 0 ? "\(formatDuration(summary.totalVideoDuration)) total" : nil,
                accentColor: Theme.dullCitrine
            )
        }
    }

    private func statPill(value: String, label: String, detail: String?, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Theme.text1)
            Text(label)
                .font(.system(size: 11))
                .tracking(0.5)
                .foregroundStyle(Theme.text2)
            if let detail {
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.text3)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18))
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .top) {
            accentColor.frame(height: 2)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
    }

    // MARK: - Chart

    private func chartSection(_ result: ScanResult) -> some View {
        SizeDistributionChart(buckets: result.sizeDistribution())
    }

    // MARK: - Album Selection

    private var albumSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ALBUMS TO CREATE")
                .font(.system(size: 13, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Theme.text2)

            VStack(spacing: 0) {
                ForEach($categories) { $category in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(category.name.contains("Video") ? Theme.dullCitrine : Theme.helvetiaBlue)
                            .frame(width: 3, height: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.text1)
                            Text("\(category.assets.count) items \u{00B7} \(formatBytes(category.totalSize))")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.text3)
                                .monospacedDigit()
                        }

                        Spacer()

                        Toggle("", isOn: $category.isSelected)
                            .labelsHidden()
                            .disabled(category.assets.isEmpty)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 18)

                    if category.id != categories.last?.id {
                        Divider()
                            .background(Color.white.opacity(0.04))
                            .padding(.leading, 33)
                    }
                }
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Theme.border, lineWidth: 1)
            )

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
    }

    // MARK: - Success

    private var successSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Albums created successfully!", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.headline)

            if !albumService.createdAlbumNames.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(albumService.createdAlbumNames, id: \.self) { name in
                        Label(name, systemImage: "photo.on.rectangle")
                            .foregroundStyle(Theme.text1)
                    }
                }
            }

            Divider().background(Theme.border)

            HStack {
                Text("Find your albums in Photos \u{2192} Sidebar \u{2192} My Albums (scroll to bottom). You can drag to reorder.")
                    .font(.caption)
                    .foregroundStyle(Theme.text2)
                Spacer()
                Button("Open Photos") {
                    NSWorkspace.shared.open(URL(string: "photos://")!)
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
    }

    // MARK: - Actions

    private func startScan() async {
        errorMessage = nil
        showSuccess = false
        do {
            try await photoService.scan()
            if let result = photoService.scanResult {
                withAnimation(.default) {
                    categories = result.albumCategories()
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createAlbums() async {
        showSuccess = false
        do {
            try await albumService.createAlbums(categories: categories)
            withAnimation(.default) {
                showSuccess = true
            }
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
