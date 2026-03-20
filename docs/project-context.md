# Light Table (Sort by Size)

## Problem

Apple Photos has no way to sort photos or videos by file size. Users with nearly-full iCloud storage can't easily find their largest files to free up space.

## What It Does

Scans your Photos library, groups assets by size, and creates albums in Photos.app with items inserted in size-descending order. Users review and delete directly in Photos.app.

## How It Works

- PhotoKit reads file sizes from `PHAssetResource` metadata — no need to download iCloud originals
- Creates albums in Photos.app that preserve insertion order as "Custom Order", achieving size sorting within native Photos.app
- Albums created:
  - `Light Table - Images >10MB`
  - `Light Table - Images >5MB`
  - `Light Table - Videos by Size`

## Distribution

- Open-source on GitHub, distributed as DMG via GitHub Releases
- Non-sandboxed, not notarized (users right-click → Open on first launch)
- Notarization requires a paid Apple Developer Program membership ($99/year)

## Key Technical Insights

- `PHAsset` has no `fileSize` property — must use `PHAssetResource`
- iCloud-only photo sizes are available from resource metadata without downloading the original
- Photos.app preserves insertion order as "Custom Order" in user-created albums — this is how we achieve size sorting in Photos.app
- No public Apple API exists for reading iCloud storage usage

## Reference

- [PhotoSort: Size & Quality Sort](https://apps.apple.com/us/app/photosort-size-quality-sort/id6739038077?mt=12) — prior art, similar album-based approach

## Future Considerations

- App Store distribution (add sandboxing + entitlements)
- Configurable size thresholds
- Serial/duplicate photo detection
