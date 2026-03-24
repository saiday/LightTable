# Album Photos Compressed with Shortcut Lose Original "Date Taken"

## Problem

When running the bundled `LightTableCompress` Shortcut on photos selected from a **user-created album** (e.g., a Light Table album), the compressed output photo gets **today's date** as its "Date Taken" in the Photos timeline. However, running the exact same Shortcut on the same photos selected from **Recents / All Photos** preserves the original "Date Taken" date.

This means users who follow the intended workflow (open a Light Table album → select photos → run Shortcut) will have their compressed photos appear at the wrong position in their timeline.

## Observed Behavior

| Source of selection | Date Taken on compressed photo |
|---------------------|-------------------------------|
| Recents / All Photos | Original date preserved |
| User-created album (Light Table album) | Today's date |

## Current Shortcut Actions (simplified)

1. Receive Images from Share Sheet / Quick Actions
2. Get images from Shortcut Input
3. Resize Image (Longest Edge 6000)
4. Convert Image to HEIF
5. Save to Photo Album (Recents)
6. Delete Shortcut Input (originals)

The "Convert Image" action has "Preserve Metadata" available but may not solve this issue depending on the root cause.

## Hypotheses to Investigate

1. **Album reference vs. canonical asset**: When photos are selected from a user-created album, Shortcuts may receive album references (pointers) rather than direct photo assets. This indirection could cause EXIF metadata (including Date Taken) to be stripped during the Shortcut pipeline.

2. **"Get Details of Images → Date Taken" behavior**: The Date Taken value returned by this action may differ depending on whether the photo was selected from Recents vs. an album. Add a "Show Result" action after "Get Details of Images → Date Taken" and test from both contexts to confirm.

3. **"Preserve Metadata" on Convert Image**: Does enabling this toggle on the Convert Image action fix the issue when photos come from albums? It may preserve EXIF in the file but Photos.app may still assign today's date as the library creation date.

4. **Workaround with explicit date copy**: Add steps to (a) read Date Taken before conversion, (b) save the compressed photo, (c) use "Adjust Date & Time of Photos" to set the saved photo's date back to the original. Test whether this works for album-sourced photos (i.e., does "Get Details → Date Taken" even return the correct date from album context?).

5. **Photos framework / PhotoKit behavior**: Research whether this is a known Apple Shortcuts limitation when operating on photos via album context vs. library context. Check Apple Developer Forums and community discussions.

## Impact

This is the primary workflow for Light Table users: they create albums sorted by size, then compress from those albums. If the date is lost, compressed photos scatter to the end of the timeline, which degrades the user's photo library organization.

## Current Mitigation

A caveat is shown in `CompressionInfoView.swift`:
> "Note: Compressed photos in the album will appear at today's date as photo taken in your timeline."

## Desired Outcome

Compressed photos should retain their original Date Taken regardless of whether the Shortcut is invoked from Recents or a user-created album.
