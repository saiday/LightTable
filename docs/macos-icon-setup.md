# macOS App Icon Not Showing in Dock? Here's What to Check.

Your app builds fine but shows a blank icon in the Dock and Cmd+Tab. You've verified the PNG exists, the asset catalog is there — but no icon. Here's what's likely going on.

## The Setup That Works

A standard `Assets.xcassets/AppIcon.appiconset/` with 10 entries covering all macOS sizes. Generate them from a single 1024×1024 source:

```bash
sips -z 16 16     source.png --out icon_16x16.png
sips -z 32 32     source.png --out icon_16x16@2x.png
sips -z 32 32     source.png --out icon_32x32.png
sips -z 64 64     source.png --out icon_32x32@2x.png
sips -z 128 128   source.png --out icon_128x128.png
sips -z 256 256   source.png --out icon_128x128@2x.png
sips -z 256 256   source.png --out icon_256x256.png
sips -z 512 512   source.png --out icon_256x256@2x.png
sips -z 512 512   source.png --out icon_512x512.png
sips -z 1024 1024 source.png --out icon_512x512@2x.png
```

Every `Contents.json` entry must have all three fields — `idiom`, `size`, and `scale`:

```json
{
  "images": [
    { "filename": "icon_16x16.png",      "idiom": "mac", "scale": "1x", "size": "16x16" },
    { "filename": "icon_16x16@2x.png",   "idiom": "mac", "scale": "2x", "size": "16x16" },
    { "filename": "icon_32x32.png",      "idiom": "mac", "scale": "1x", "size": "32x32" },
    { "filename": "icon_32x32@2x.png",   "idiom": "mac", "scale": "2x", "size": "32x32" },
    { "filename": "icon_128x128.png",    "idiom": "mac", "scale": "1x", "size": "128x128" },
    { "filename": "icon_128x128@2x.png", "idiom": "mac", "scale": "2x", "size": "128x128" },
    { "filename": "icon_256x256.png",    "idiom": "mac", "scale": "1x", "size": "256x256" },
    { "filename": "icon_256x256@2x.png", "idiom": "mac", "scale": "2x", "size": "256x256" },
    { "filename": "icon_512x512.png",    "idiom": "mac", "scale": "1x", "size": "512x512" },
    { "filename": "icon_512x512@2x.png", "idiom": "mac", "scale": "2x", "size": "512x512" }
  ],
  "info": { "author": "xcode", "version": 1 }
}
```

Set `ASSETCATALOG_COMPILER_APPICON_NAME` to `AppIcon` in your build settings. No `CFBundleIconFile` in Info.plist needed — the asset catalog compiler injects it automatically.

## Common Mistakes That Cause Silent Failures

The asset catalog compiler (`actool`) never errors on bad icon input. It silently drops entries and produces whatever it can. Your build succeeds, but the icon is broken.

**Missing `scale` field.** Every entry needs `"scale": "1x"` or `"scale": "2x"`. Without it, the entry is ignored.

**Pixel dimensions don't match size × scale.** A `"size": "32x32", "scale": "2x"` entry requires a 64×64 pixel PNG. If your file is 32×32, the entry is silently dropped.

**Extra files in the appiconset.** Any PNG not referenced in `Contents.json` triggers "unassigned child" warnings and can interfere with compilation. Keep the directory clean.

**Both `ASSETCATALOG_COMPILER_APPICON_NAME` and `CFBundleIconFile` set.** The asset catalog compiler takes precedence and overwrites any manually-placed `.icns`. Use one or the other.

## Don't Be Misled by `iconutil` Verification

If you inspect the built `.icns` with `iconutil --convert iconset`, you might see only 4 sizes (16, 16@2x, 128, 128@2x) and think something is wrong. It's not.

The build runs `CompileAssetCatalogVariant thinned`, which produces a minimal `.icns` for legacy compatibility. The full icon set is stored in `Assets.car` alongside it and loaded at runtime. The icon displays correctly — `iconutil` just doesn't show you the whole picture.

## macOS Icon Cache

Even after fixing everything, the old blank icon may persist. Force a refresh:

```bash
# Re-register with LaunchServices and restart Dock
lsregister -f /path/to/Your.app
killall Dock
```

Where `lsregister` lives at:
```
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister
```
