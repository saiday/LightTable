import SwiftUI

struct CompressionInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    bodySection
                    macOSSection
                    iOSSection
                }
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minWidth: 500, minHeight: 400)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Largest Photos Are Now Sorted by Size")
                .font(.title.bold())
            Text("Delete what you don't need. Compress what you want to keep.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Body

    private var bodySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Don't want to delete it? Shrink it.")
                .font(.headline)
            Text("Our Shortcut converts photos to HEIF and caps resolution at 24MP — smaller files, nearly indistinguishable quality.")
                .foregroundStyle(.secondary)
            Text("Originals go to Recently Deleted. You have 30 days to change your mind.")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - macOS Instructions

    private var macOSSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("macOS", systemImage: "desktopcomputer")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    instructionRow(number: "1", text: "Install the Shortcut")
                    installButton
                    instructionRow(number: "2", text: "Open a Light Table album in Photos")
                    instructionRow(number: "3", text: "Select photos → Right-click → Quick Actions → Light Table Compress")
                }
            }
            .padding(8)
        }
    }

    // MARK: - iOS Instructions

    private var iOSSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("iOS (via iCloud Sync)", systemImage: "iphone")
                    .font(.headline)

                Text("The Shortcut syncs to your iPhone/iPad via iCloud after installing on Mac.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    instructionRow(number: "1", text: "Open a Light Table album in Photos")
                    instructionRow(number: "2", text: "Select photos → Share → Light Table Compress")
                }
            }
            .padding(8)
        }
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
        // Silently no-ops if the .shortcut file is not yet bundled (see Task 4)
        guard let url = Bundle.main.url(forResource: "LightTableCompress", withExtension: "shortcut") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
