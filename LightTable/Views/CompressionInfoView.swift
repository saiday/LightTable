import SwiftUI

struct CompressionInfoView: View {
    @Environment(\.dismiss) private var dismiss
    let createdAlbumNames: [String]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    successSection
                    compressionSection
                    macOSSection
                    iOSSection
                    tipSection
                }
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minWidth: 480, minHeight: 360)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Success

    private var successSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Albums created", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.headline)

            if !createdAlbumNames.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(createdAlbumNames, id: \.self) { name in
                        Label(name, systemImage: "photo.on.rectangle")
                            .font(.callout)
                    }
                }
            }

            Text("Find them in Photos → Sidebar → My Albums.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Compression

    private var compressionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Don't want to delete? Compress instead.")
                .font(.headline)
            Text("Our Shortcut converts photos to HEIF at up to 24 MP — smaller files, nearly identical quality. Originals go to Recently Deleted for 30 days.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("Note: Compressed photos may appear at today's date in your timeline.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - macOS Instructions

    private var macOSSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Label("macOS", systemImage: "desktopcomputer")
                    .font(.headline)
                instructionRow(number: "1", text: "Install the Shortcut")
                installButton
                instructionRow(number: "2", text: "Open a Light Table album in Photos")
                instructionRow(number: "3", text: "Select photos → Right-click → Quick Actions → LightTableCompress")
            }
            .padding(8)
        }
    }

    // MARK: - iOS Instructions

    private var iOSSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Label("iOS", systemImage: "iphone")
                    .font(.headline)
                Text("The Shortcut syncs via iCloud after installing on Mac.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                instructionRow(number: "1", text: "Open a Light Table album in Photos")
                instructionRow(number: "2", text: "Select photos → Share → LightTableCompress")
            }
            .padding(8)
        }
    }

    // MARK: - Tip

    private var tipSection: some View {
        Text("Deleting a Light Table album only removes the album — your photos stay in your library.")
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    // MARK: - Helpers

    private var installButton: some View {
        Button {
            installShortcut()
        } label: {
            Label("Install Shortcut", systemImage: "square.and.arrow.down")
        }
        .buttonStyle(.bordered)
        .padding(.leading, 24)
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number + ".")
                .font(.body.bold())
                .monospacedDigit()
                .frame(width: 20, alignment: .trailing)
            Text(text)
        }
    }

    private func installShortcut() {
        guard let url = Bundle.main.url(forResource: "LightTableCompress", withExtension: "shortcut") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
