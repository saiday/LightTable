# Light Table — Dark Vibrant UI Redesign

## Problem

The current Light Table UI uses plain GroupBox containers, default system chart styling, and lacks visual hierarchy. The overall feel is utilitarian rather than polished.

## Design Direction

**Always-dark vibrant dashboard** with a custom 4-color accent palette on neutral dark surfaces. Platform-native controls for toggles and buttons. Custom palette reserved for data visualization only.

## Color Palette

| Name            | Hex       | Role                        |
|-----------------|-----------|-----------------------------|
| Helvetia Blue   | `#007EA7` | Photos data, chart bars, album accent lines |
| Dull Citrine    | `#9B8A2F` | Videos data, chart bars, album accent lines |
| Ecru            | `#C2B280` | _Reserved — not actively used in current design_ |
| Glaucous Green  | `#6B8F71` | _Reserved — not actively used in current design_ |

### Neutrals

| Token      | Value                        | Usage                  |
|------------|------------------------------|------------------------|
| `bg`       | `#111111`                    | Window background      |
| `bg-elevated` | `#1A1A1A`                 | Title bar background   |
| `surface`  | `rgba(255,255,255,0.035)`    | Card/container fill    |
| `border`   | `rgba(255,255,255,0.07)`     | Container borders      |
| `text-1`   | `#F2F0EB`                    | Primary text (warm white) |
| `text-2`   | `rgba(255,255,255,0.45)`     | Secondary text (labels, captions) |
| `text-3`   | `rgba(255,255,255,0.25)`     | Tertiary text (metadata) |

### Platform Defaults (not customized)

- **Toggle**: Standard macOS toggle (system green `#30D158`)
- **CTA Button**: Standard `.borderedProminent` (system blue `#0A84FF`)

## Layout Structure

### 1. Hero Stat (top, centered)
- Total library size: e.g., "11.98 GB"
- Number and unit are the same color and weight (`text-1`, 800 weight)
- Unit is smaller font size (28pt vs 52pt)
- Label below: "LIBRARY SIZE" in uppercase, tertiary color, letter-spaced

### 2. Stat Pills (row of 2)
- Two equal-width cards side by side
- Each has a 2px colored top accent line (Helvetia Blue for photos, Citrine for videos)
- Content: large value, uppercase label, detail line (e.g., "avg 13.5 MP")
- Surface background with subtle border
- Rounded corners (14pt radius)

### 3. Size Distribution Chart
- Section header: "SIZE DISTRIBUTION" label + segmented picker (Count/Storage)
- Segmented control: neutral background, white text for active segment
- Chart inside a surface container (14pt radius)
- Stacked bars: photos (Helvetia Blue gradient) on top, videos (Citrine gradient) below
- Count labels above each bar group
- Size range labels below each bar
- Legend at bottom with colored dots: Photos, Videos
- No grid lines

### 4. Albums to Create
- Section header: "ALBUMS TO CREATE"
- Surface container with rows
- Each row: thin colored accent line (3px, left side) + album name + metadata + toggle
- Accent line color matches data type (Helvetia Blue for image albums, Citrine for video albums)
- Rows separated by subtle dividers
- Standard macOS toggles (not custom styled)

### 5. CTA Button
- Right-aligned
- Standard macOS `.borderedProminent` style
- Text: "Create Albums"

## Theme Enforcement

- Always dark: use `.preferredColorScheme(.dark)` on the window
- Window background: custom dark color, not system default
- No light mode variant needed

## Typography

- Hero value: 52pt, weight 800, -2.5px tracking
- Hero unit: 28pt, weight 800
- Stat pill values: 26pt, weight 700
- Labels: 11pt uppercase, 0.5px letter-spacing
- Section titles: 13pt, weight 600, uppercase
- Album names: 13pt, weight 500
- Metadata: 11pt, tertiary color
- All numbers: `.monospacedDigit()`

## Spacing

- Main content padding: 28pt top, 32pt sides
- Section gap: 24pt
- Stat pill gap: 12pt
- Container corner radius: 14pt
- Album row padding: 14pt vertical, 18pt horizontal

## Animations

Use SwiftUI default animations (`.default`) throughout. No custom spring/timing curves.

- **Results page transition**: When scan results appear (replacing the welcome view), animate the transition with `.animation(.default)`
- **Chart bars**: Bars animate in from zero height when the chart first appears and when toggling between Count/Storage
- **Section stagger**: Hero, stat pills, chart, and albums sections fade/slide in with a subtle stagger using `.animation(.default.delay(...))`on each section

## Files to Modify

- `LightTable/ContentView.swift` — main layout restructure, color definitions, dark theme enforcement
- `LightTable/Views/SizeDistributionChart.swift` — chart colors, remove grid lines, add count labels
- `LightTable/LightTableApp.swift` — window background color, dark mode enforcement

## Verification

1. Build and run the app
2. Verify always-dark appearance regardless of system setting
3. Verify chart uses Helvetia Blue / Citrine (not default blue/purple)
4. Verify toggles and CTA button use standard macOS styling
5. Verify hero stat shows unified color for number and unit
6. Verify stat pills have colored top accent lines
7. Verify album rows have colored left accent lines
8. Verify no grid lines on chart
9. Verify chart bars animate from zero when results first appear
10. Verify sections stagger in on results page transition
11. Verify chart bars animate when toggling Count/Storage
