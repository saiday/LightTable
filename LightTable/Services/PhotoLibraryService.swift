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
        defer { isScanning = false }

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
    }
}
