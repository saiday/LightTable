# Light Table (Sort by Size) — Design Spec

## Problem

Apple Photos offers no way to sort photos or videos by file size. Users with nearly-full iCloud storage have no efficient way to identify and remove their largest files.

## Solution

A macOS app that scans the user's Photos library via PhotoKit, identifies large assets, and creates size-ordered albums in Photos.app for the user to review and delete from.

## Core Flow

1. User launches app → system prompts for Photos library permission
2. App scans all `PHAsset` objects (photos + videos), reads file sizes from `PHAssetResource` metadata
3. App displays a summary: photo count, video count, total size per category
4. User selects which albums to create via checkboxes (checked by default):
   - `Light Table - Images >10MB`
   - `Light Table - Images >5MB`
   - `Light Table - Videos by Size` (all videos, no threshold — videos are inherently large and all are relevant for storage review)
5. User clicks "Create Albums" → app creates albums in Photos.app with assets inserted in size-descending order
6. User opens Photos.app, views albums (displayed in insertion order via "Custom Order"), reviews and deletes

## Architecture

### Tech Stack

- Swift, SwiftUI
- macOS 13 (Ventura) minimum target
- PhotoKit (`Photos.framework`)
- No external dependencies
- Bundle identifier: `com.saiday.light-table`

### App Layers

1. **PhotoLibraryService** — wraps PhotoKit. Enumerates all `PHAsset` objects, fetches file sizes via `PHAssetResource`, returns sorted results. Runs async on a background thread with progress reporting.

2. **AlbumService** — creates or updates albums in Photos.app. Takes filtered/sorted asset lists and writes them via `PHAssetCollectionChangeRequest`. Matches existing albums by name to avoid duplicates (replaces contents on re-run).

3. **UI (SwiftUI)** — single-window app:
   - Scan button + progress indicator
   - Summary stats (count and total size per category)
   - Checkboxes for each album category with item counts (categories with 0 items unchecked by default)
   - "Create Albums" button

### Key Technical Details

- **File size access:** `PHAsset` has no public `fileSize` property. We use `PHAssetResource.assetResources(for: asset)` and access file size via KVC: `resource.value(forKey: "fileSize")`. This is a **private/undocumented property** widely used in the community (including open-source libraries like TLPhotoPicker). It works reliably today but could break in future macOS updates. There is no public alternative — the only fallback would be `PHAssetResourceManager.requestData` to stream and measure the full file, which requires downloading iCloud originals and is prohibitively slow.

- **iCloud-only photos:** File size metadata is generally available via `value(forKey: "fileSize")` without downloading the original. However, this is observed behavior, not a documented guarantee. Some iCloud-optimized assets may return 0 or nil. The implementation must handle this gracefully — assets with unknown size should be excluded from album creation and optionally shown in a separate "Unknown Size" count in the summary.

- **Resource selection:** Each `PHAsset` can have multiple `PHAssetResource` objects (original, adjustments, paired video for Live Photos). We select the resource with type `.photo` or `.video` (the original asset data) to determine file size. For Live Photos, only the photo component size is used.

- **Album sort order:** We use `insertAssets(_:at:)` with explicit `IndexSet` positions (not `addAssets(_:)`) to guarantee deterministic size-descending order. Photos.app displays user-created albums in "Custom Order" which respects these positions.

- **Re-run behavior:** If albums with matching names already exist, the app removes all existing assets from the album and re-inserts the new sorted list. User modifications to the album (manual additions, reordering) will be lost on re-run.

### Performance

For large libraries (50,000–200,000+ assets):
- `PHAssetResource.assetResources(for:)` is not a batch API — it has per-asset overhead. Scanning a large library may take 30–60+ seconds.
- Scanning runs on a background thread. The UI shows a progress indicator with asset count progress (e.g., "Scanning 12,450 / 85,000").
- Results are computed all at once (not streamed) since we need the full sorted list before creating albums.
- No caching for v1 — each launch re-scans. Caching is a future optimization.

### Permissions

- `NSPhotoLibraryReadWriteUsageDescription` in Info.plist (read-write required for album creation)
- Hardened Runtime entitlement: `com.apple.security.personal-information.photos-library` (required for Photos library access on macOS 13+)

## Error Handling

- **Permission denied** — display message directing user to System Settings → Privacy & Security → Photos
- **Empty library** — display "No photos or videos found"
- **No assets match thresholds** — show "0 items" on the category, uncheck by default
- **Assets with unknown file size** — exclude from albums, show count in summary (e.g., "142 assets with unknown size skipped")
- **Album already exists** — clear and replace contents, do not create duplicate

## Distribution

- Open-source on GitHub (MIT license)
- Distributed as DMG via GitHub Releases
- Non-sandboxed, not notarized
- Users must right-click → Open on first launch to bypass Gatekeeper

## Future Considerations

- App Store distribution (add sandboxing + entitlements, requires paid Apple Developer account)
- Configurable size thresholds
- Serial/duplicate photo detection
- Scan result caching for faster re-runs
