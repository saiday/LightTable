# Compression Shortcut Feature Design

## Problem

Users discover large photos via Light Table's size-sorted albums but don't always want to delete them. There's no way to reduce file size while keeping the photo.

## Solution

Provide a bundled Apple Shortcut that compresses photos in-place. The app stays focused on discovery and analysis; compression is handled by the Shortcut via native system integration.

## The Shortcut

**What it does (per selected photo):**

1. If resolution > 24MP, resize to 24MP (maintaining aspect ratio)
2. Convert to HEIF format
3. Save compressed version to Photos library
4. Delete original (system shows native confirmation dialog)

**Shortcut action sequence:**

1. "Receive Photos input" — accepts selected photos
2. "Get Details of Images" — extract pixel width and height
3. "If" width × height > 24,000,000 — calculate target dimensions preserving aspect ratio
4. "Resize Image" — resize to calculated dimensions (only if above 24MP)
5. "Convert Image" — convert to HEIF format
6. "Save to Photo Album" — save to Recents
7. "Delete Photos" — delete the original input photos

Note: The "Resize Image" action takes width/height, not megapixels. The Shortcut must calculate target dimensions from the source aspect ratio to hit the 24MP cap.

**Distribution:** A `.shortcut` file for macOS bundled in the app's Resources. "Install Shortcut" button opens the file via `NSWorkspace.shared.open(fileURL)`, triggering system import.

**iOS distribution:** Since this is a macOS-only app, the iOS usage instructions reference the same Shortcut — users can find it in their Shortcuts library synced via iCloud if they install it on Mac. The app provides iOS usage instructions but not a separate iOS install mechanism.

**Metadata / timeline position:** Photos.app sorts by its own internal creation date metadata, not embedded EXIF. When "Save to Photo Album" creates a new asset, it may assign the current date rather than the original's date. **This is a feasibility risk that must be validated before implementation.** If the compressed photo does not maintain its timeline position, we should:
- Document this limitation clearly in the info view
- Or investigate whether Shortcuts can set the creation date on the saved photo

## App UI Changes

### Toolbar

Add an info button (`info.circle` SF Symbol) in the toolbar alongside "Scan Again." Visible when `scanResult != nil` (persists through re-scans).

### Info View

Presented as a `.sheet` over the main window. Dismissed via a "Done" button in the sheet toolbar.

**Title:** "Your Largest Photos Are Now Sorted by Size"
**Subtitle:** "Delete what you don't need. Compress what you want to keep."

**Body:**

> Don't want to delete it? Shrink it.
>
> Our Shortcut converts photos to HEIF and caps resolution at 24MP — smaller files, nearly indistinguishable quality.
>
> Originals go to Recently Deleted. You have 30 days to change your mind.

### Platform Sections

**macOS:**
1. Click "Install Shortcut" → `.bordered` button style
2. Open a Light Table album in Photos
3. Select photos → Right-click → Quick Actions → "Light Table Compress"

**iOS (if synced via iCloud):**
1. Open a Light Table album in Photos
2. Select photos → Share → "Light Table Compress"

### Dismiss

"Done" button positioned in the sheet's toolbar (trailing).

## Technical Notes

- `.shortcut` file opened via `NSWorkspace.shared.open(fileURL)` on macOS; may need to copy to a temp directory first if opening from inside the app bundle fails
- Fallback: iCloud Shortcut link if bundled file import doesn't work reliably
- The Shortcut is user-inspectable and editable in Shortcuts.app
- HEIF conversion typically yields 40-60% size reduction from JPEG
- 24MP cap primarily benefits 48MP iPhone Pro photos
- Lossy-to-lossy transcoding (JPEG → HEIF) has a minor quality reduction, but is visually imperceptible for photographic content

## Open Questions

- **EXIF/date preservation:** Does "Save to Photo Album" in Shortcuts preserve the original photo's date in Photos.app's timeline? Must be validated before implementation.
- **Bundled `.shortcut` import:** Does `NSWorkspace.shared.open()` on a file inside the app bundle reliably hand off to Shortcuts.app? May need temp file copy.

## Out of Scope

- In-app image processing or compression pipeline
- Triggering the Shortcut from within the app (URL scheme coupling)
- Per-photo compression preview or estimated savings
- Batch progress tracking from the app side
