import Photos

@MainActor
final class AlbumService: ObservableObject {
    @Published var isCreating = false
    @Published var createdAlbumNames: [String] = []

    func createAlbums(categories: [AlbumCategory]) async throws {
        isCreating = true
        createdAlbumNames = []
        defer { isCreating = false }

        for category in categories where category.isSelected && !category.assets.isEmpty {
            try await createOrUpdateAlbum(name: category.name, assets: category.assets)
            createdAlbumNames.append(category.name)
        }
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
            try await clearAlbum(existing)
            // Populate with new assets
            try await populateAlbum(existing, with: phAssets)
        } else {
            // Create new album and populate
            let newAlbum = try await createAlbum(named: name)
            try await populateAlbum(newAlbum, with: phAssets)
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

    private func createAlbum(named title: String) async throws -> PHAssetCollection {
        var placeholder: PHObjectPlaceholder?
        try await PHPhotoLibrary.shared().performChanges {
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

    private func clearAlbum(_ album: PHAssetCollection) async throws {
        let assets = PHAsset.fetchAssets(in: album, options: nil)
        guard assets.count > 0 else { return }
        try await PHPhotoLibrary.shared().performChanges {
            guard let request = PHAssetCollectionChangeRequest(for: album) else { return }
            request.removeAssets(assets)
        }
    }

    private func populateAlbum(_ album: PHAssetCollection, with assets: [PHAsset]) async throws {
        guard !assets.isEmpty else { return }
        try await PHPhotoLibrary.shared().performChanges {
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
