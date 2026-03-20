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
   - `Light Table - Videos by Size`
5. User clicks "Create Albums" → app creates albums in Photos.app with assets inserted in size-descending order
6. User opens Photos.app, views albums (displayed in insertion order via "Custom Order"), reviews and deletes

## Architecture

### Tech Stack

- Swift, SwiftUI
- macOS 13 (Ventura) minimum target
- PhotoKit (`Photos.framework`)
- No external dependencies

### App Layers

1. **PhotoLibraryService** — wraps PhotoKit. Enumerates all `PHAsset` objects, fetches file sizes via `PHAssetResource.assetResources(for:)` and reads `fileSize` from resource properties. Returns sorted results. Runs async with progress reporting.

2. **AlbumService** — creates or updates albums in Photos.app. Takes filtered/sorted asset lists and writes them via `PHAssetCollectionChangeRequest`. Matches existing albums by name to avoid duplicates (replaces contents on re-run).

3. **UI (SwiftUI)** — single-window app:
   - Scan button + progress indicator
   - Summary stats (count and total size per category)
   - Checkboxes for each album category with item counts (categories with 0 items unchecked by default)
   - "Create Albums" button

### Key Technical Details

- **File size access:** `PHAsset` has no `fileSize` property. We use `PHAssetResource.assetResources(for: asset)` and read the `fileSize` value from the original resource (largest `PHAssetResourceType`).
- **iCloud-only photos:** File size metadata is available from `PHAssetResource` without downloading the original file.
- **Album sort order:** Photos.app preserves insertion order as "Custom Order" for user-created albums. By inserting assets in size-descending order, the album displays largest-first.
- **Re-run behavior:** If albums with matching names already exist, their contents are replaced rather than creating duplicate albums.

### Permissions

- `NSPhotoLibraryReadWriteUsageDescription` in Info.plist (read-write required for album creation)

## Error Handling

- **Permission denied** — display message directing user to System Settings → Privacy & Security → Photos
- **Empty library** — display "No photos or videos found"
- **No assets match thresholds** — show "0 items" on the category, uncheck by default
- **Album already exists** — replace contents, do not create duplicate

## Distribution

- Open-source on GitHub (MIT license)
- Distributed as DMG via GitHub Releases
- Non-sandboxed, not notarized
- Users must right-click → Open on first launch to bypass Gatekeeper

## Future Considerations

- App Store distribution (add sandboxing + entitlements, requires paid Apple Developer account)
- Configurable size thresholds
- Serial/duplicate photo detection
