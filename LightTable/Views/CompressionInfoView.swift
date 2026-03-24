import SwiftUI

struct CompressionInfoView: View {
    @Environment(\.dismiss) private var dismiss
    let createdAlbumNames: [String]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                successSection
                Divider()
                compressionSection
            }
            .padding(32)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minWidth: 420)
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
        VStack(alignment: .leading, spacing: 10) {
            Text("Want to compress instead of delete?")
                .font(.headline)

            Text("Install our Shortcut here — it syncs to your iPhone via iCloud. We recommend compressing on iOS since the Photos experience there is much smoother.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Text("Tip: To keep the original date taken, use \"Show in All Photos\" and compress from there. Compressing directly in an album will reset the date to today.")
                .font(.caption)
                .foregroundStyle(.secondary)

            installButton
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
    }

    private func installShortcut() {
        guard let url = Bundle.main.url(forResource: "LightTableCompress", withExtension: "shortcut") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
