# Dark Vibrant UI Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign Light Table from a plain utility to a polished always-dark dashboard with custom data colors, neutral UI chrome, and subtle entrance animations.

**Architecture:** Restructure ContentView to replace GroupBox containers with custom dark surface containers. Define a theme namespace with color constants. Update chart to use Helvetia Blue / Citrine. Add `.animation(.default)` transitions.

**Tech Stack:** SwiftUI, Swift Charts, macOS 13+

**Spec:** `docs/superpowers/specs/2026-03-21-dark-vibrant-redesign-design.md`

---

### Task 1: Define theme colors and enforce dark mode

**Files:**
- Create: `LightTable/Theme.swift`
- Modify: `LightTable/LightTableApp.swift`

- [ ] **Step 1: Create `Theme.swift` with color constants**

```swift
import SwiftUI

enum Theme {
    // Data accent colors
    static let helvetiaBlue = Color(red: 0/255, green: 126/255, blue: 167/255)    // #007EA7
    static let dullCitrine  = Color(red: 155/255, green: 138/255, blue: 47/255)   // #9B8A2F

    // Neutrals
    static let bg          = Color(red: 17/255, green: 17/255, blue: 17/255)      // #111111
    static let bgElevated  = Color(red: 26/255, green: 26/255, blue: 26/255)      // #1A1A1A
    static let surface     = Color.white.opacity(0.035)
    static let border      = Color.white.opacity(0.07)
    static let text1       = Color(red: 242/255, green: 240/255, blue: 235/255)   // #F2F0EB
    static let text2       = Color.white.opacity(0.45)
    static let text3       = Color.white.opacity(0.25)
}
```

- [ ] **Step 2: Enforce always-dark in `LightTableApp.swift`**

Replace the WindowGroup content with:
```swift
WindowGroup {
    ContentView()
        .preferredColorScheme(.dark)
}
```

No other changes to LightTableApp.swift.

- [ ] **Step 3: Build to verify compiles**

Run: `xcodebuild -scheme LightTable -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add LightTable/Theme.swift LightTable/LightTableApp.swift
git commit -m "feat: add Theme color constants and enforce dark mode"
```

---

### Task 2: Redesign ContentView — hero stat and stat pills

**Files:**
- Modify: `LightTable/ContentView.swift:145-200` (summarySection and statItem)

- [ ] **Step 1: Replace `summarySection` with hero stat + stat pills**

Replace the entire `summarySection(_ result:)` method and `statItem` helper. Note: the `unknownSizeCount` message is intentionally dropped per the spec — the new design does not include it.

Replace with:

```swift
// MARK: - Hero Stat

private func heroSection(_ summary: ScanSummary) -> some View {
    let sizeString = formatBytes(summary.totalSize)
    let parts = sizeString.split(separator: " ", maxSplits: 1)
    let number = String(parts.first ?? "0")
    let unit = parts.count > 1 ? String(parts.last!) : ""

    return VStack(spacing: 4) {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(number)
                .font(.system(size: 52, weight: .heavy))
                .tracking(-2.5)
            Text(unit)
                .font(.system(size: 28, weight: .heavy))
        }
        .foregroundStyle(Theme.text1)
        .monospacedDigit()
        Text("LIBRARY SIZE")
            .font(.system(size: 11))
            .tracking(1.5)
            .foregroundStyle(Theme.text3)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 8)
}

// MARK: - Stat Pills

private func statPillsSection(_ summary: ScanSummary) -> some View {
    HStack(spacing: 12) {
        statPill(
            value: "\(summary.totalImages)",
            label: "PHOTOS",
            detail: summary.averageMegapixels > 0 ? "avg \(String(format: "%.1f", summary.averageMegapixels)) MP" : nil,
            accentColor: Theme.helvetiaBlue
        )
        statPill(
            value: "\(summary.totalVideos)",
            label: "VIDEOS",
            detail: summary.totalVideoDuration > 0 ? "\(formatDuration(summary.totalVideoDuration)) total" : nil,
            accentColor: Theme.dullCitrine
        )
    }
}

private func statPill(value: String, label: String, detail: String?, accentColor: Color) -> some View {
    VStack(alignment: .leading, spacing: 2) {
        Text(value)
            .font(.system(size: 26, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(Theme.text1)
        Text(label)
            .font(.system(size: 11))
            .tracking(0.5)
            .foregroundStyle(Theme.text2)
        if let detail {
            Text(detail)
                .font(.system(size: 11))
                .foregroundStyle(Theme.text3)
                .padding(.top, 2)
        }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(EdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18))
    .background(Theme.surface)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .overlay(alignment: .top) {
        accentColor.frame(height: 2)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14))
    }
    .overlay(
        RoundedRectangle(cornerRadius: 14)
            .strokeBorder(Theme.border, lineWidth: 1)
    )
}
```

- [ ] **Step 2: Update `scrollableContent` to use new sections**

In `scrollableContent`, replace the call to `summarySection(result)` with:
```swift
heroSection(result.summary())
statPillsSection(result.summary())
```

Also update the background of the entire `scrollableContent`:
```swift
.background(Theme.bg)
```

- [ ] **Step 3: Build to verify compiles**

Run: `xcodebuild -scheme LightTable -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add LightTable/ContentView.swift
git commit -m "feat: redesign summary as hero stat + stat pills"
```

---

### Task 3: Redesign album section with accent lines

**Files:**
- Modify: `LightTable/ContentView.swift:210-253` (albumSection)

- [ ] **Step 1: Replace `albumSection` with new design**

Replace the entire `albumSection` computed property:

```swift
private var albumSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("ALBUMS TO CREATE")
            .font(.system(size: 13, weight: .semibold))
            .tracking(0.5)
            .foregroundStyle(Theme.text2)

        VStack(spacing: 0) {
            ForEach($categories) { $category in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(category.name.contains("Video") ? Theme.dullCitrine : Theme.helvetiaBlue)
                        .frame(width: 3, height: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.text1)
                        Text("\(category.assets.count) items \u{00B7} \(formatBytes(category.totalSize))")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.text3)
                            .monospacedDigit()
                    }

                    Spacer()

                    Toggle("", isOn: $category.isSelected)
                        .labelsHidden()
                        .disabled(category.assets.isEmpty)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 18)

                if category.id != categories.last?.id {
                    Divider()
                        .background(Color.white.opacity(0.04))
                        .padding(.leading, 33)
                }
            }
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Theme.border, lineWidth: 1)
        )

        HStack {
            Spacer()
            Button {
                Task { await createAlbums() }
            } label: {
                if albumService.isCreating {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Create Albums")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(albumService.isCreating || !categories.contains(where: { $0.isSelected && !$0.assets.isEmpty }))
        }
    }
}
```

- [ ] **Step 2: Build to verify compiles**

Run: `xcodebuild -scheme LightTable -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add LightTable/ContentView.swift
git commit -m "feat: redesign album section with accent lines and surface containers"
```

---

### Task 4: Restyle SizeDistributionChart with custom colors

**Files:**
- Modify: `LightTable/Views/SizeDistributionChart.swift`

- [ ] **Step 1: Update chart colors, remove grid lines, add section header styling**

Replace the entire `SizeDistributionChart` body:

```swift
var body: some View {
    VStack(alignment: .leading, spacing: 12) {
        // Section header
        HStack {
            Text("SIZE DISTRIBUTION")
                .font(.system(size: 13, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Theme.text2)
            Spacer()
            Picker("Metric", selection: $chartMetric) {
                ForEach(ChartMetric.allCases, id: \.self) { metric in
                    Text(metric.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 160)
        }

        // Chart container
        Chart {
            ForEach(chartDataPoints) { point in
                BarMark(
                    x: .value("Size Range", point.bucket),
                    y: .value(chartMetric == .count ? "Assets" : "Size", point.value)
                )
                .foregroundStyle(by: .value("Type", point.mediaType))
            }
        }
        .chartForegroundStyleScale([
            "Photos": Theme.helvetiaBlue,
            "Videos": Theme.dullCitrine,
        ])
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if chartMetric == .storage {
                        if let bytes = value.as(Double.self) {
                            Text(formatBytes(Int64(bytes)))
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.text3)
                        }
                    } else {
                        if let count = value.as(Double.self) {
                            Text(formatCount(count))
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.text3)
                        }
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.text3)
            }
        }
        .chartLegend(position: .bottom, alignment: .leading, spacing: 12)
        .frame(height: 200)
        .padding(20)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
    }
}
```

Note: Grid lines are removed by not including `AxisGridLine()` in the `AxisMarks` closure.

- [ ] **Step 2: Build to verify compiles**

Run: `xcodebuild -scheme LightTable -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add LightTable/Views/SizeDistributionChart.swift
git commit -m "feat: restyle chart with custom palette and remove grid lines"
```

---

### Task 5: Restyle transient states (welcome, scanning, error, success, empty)

**Files:**
- Modify: `LightTable/ContentView.swift` (welcomeView, scanningSection, errorSection, successSection, emptyLibrarySection)

- [ ] **Step 1: Update `welcomeView` to use theme colors**

```swift
private var welcomeView: some View {
    VStack(spacing: 16) {
        Spacer(minLength: 100)
        Image(systemName: "photo.on.rectangle.angled")
            .font(.system(size: 48))
            .foregroundStyle(Theme.text3)
        Text("Sort your Photos library by size")
            .font(.title3)
            .foregroundStyle(Theme.text2)
        Button("Scan Library") {
            Task { await startScan() }
        }
        .keyboardShortcut(.defaultAction)
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        Spacer(minLength: 100)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.bg)
}
```

- [ ] **Step 2: Update `scanningSection` — replace GroupBox with surface container**

```swift
private var scanningSection: some View {
    VStack(spacing: 12) {
        ProgressView()
            .controlSize(.large)
        if let progress = photoService.scanProgress {
            Text("Scanning \(progress.completed) / \(progress.total)")
                .monospacedDigit()
                .foregroundStyle(Theme.text2)
        } else {
            Text("Starting scan...")
                .foregroundStyle(Theme.text2)
        }
    }
    .frame(maxWidth: .infinity)
    .padding(20)
    .background(Theme.surface)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
}
```

- [ ] **Step 3: Update `errorSection` — replace GroupBox**

```swift
private func errorSection(_ message: String) -> some View {
    VStack(spacing: 8) {
        Label(message, systemImage: "exclamationmark.triangle")
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
        Button("Dismiss") {
            errorMessage = nil
        }
        .buttonStyle(.borderless)
    }
    .frame(maxWidth: .infinity)
    .padding(20)
    .background(Theme.surface)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
}
```

- [ ] **Step 4: Update `emptyLibrarySection` — replace GroupBox**

```swift
private var emptyLibrarySection: some View {
    VStack(spacing: 12) {
        Text("No photos or videos found")
            .font(.headline)
            .foregroundStyle(Theme.text1)
        Text("Your Photos library appears to be empty.")
            .foregroundStyle(Theme.text2)
    }
    .frame(maxWidth: .infinity)
    .padding(20)
    .background(Theme.surface)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
}
```

- [ ] **Step 5: Update `successSection` — replace GroupBox**

```swift
private var successSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        Label("Albums created successfully!", systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green)
            .font(.headline)

        if !albumService.createdAlbumNames.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(albumService.createdAlbumNames, id: \.self) { name in
                    Label(name, systemImage: "photo.on.rectangle")
                        .foregroundStyle(Theme.text1)
                }
            }
        }

        Divider().background(Theme.border)

        HStack {
            Text("Find your albums in Photos \u{2192} Sidebar \u{2192} My Albums (scroll to bottom). You can drag to reorder.")
                .font(.caption)
                .foregroundStyle(Theme.text2)
            Spacer()
            Button("Open Photos") {
                NSWorkspace.shared.open(URL(string: "photos://")!)
            }
            .buttonStyle(.bordered)
        }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(20)
    .background(Theme.surface)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
}
```

- [ ] **Step 6: Build to verify compiles**

Run: `xcodebuild -scheme LightTable -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 7: Commit**

```bash
git add LightTable/ContentView.swift
git commit -m "feat: restyle transient states with dark surface containers"
```

---

### Task 6: Add animations

**Files:**
- Modify: `LightTable/ContentView.swift` (scrollableContent, body)
- Modify: `LightTable/Views/SizeDistributionChart.swift`

- [ ] **Step 1: Add animated transition between welcome and results in `body`**

Update the `body` property to animate the view switch:

```swift
var body: some View {
    Group {
        if !hasResults && !photoService.isScanning && errorMessage == nil {
            welcomeView
        } else {
            scrollableContent
        }
    }
    .animation(.default, value: hasResults)
    .frame(minWidth: 700, minHeight: 600)
    .navigationTitle("Light Table")
    .toolbar {
        // ... (toolbar unchanged)
    }
}
```

- [ ] **Step 2: Add staggered section entrance in `scrollableContent`**

Add `@State private var showContent = false` to ContentView's state properties.

Update `scrollableContent` to stagger sections:

```swift
private var scrollableContent: some View {
    ScrollView {
        VStack(spacing: 24) {
            if let error = errorMessage {
                errorSection(error)
            }

            if photoService.isScanning {
                scanningSection
            }

            if let result = photoService.scanResult {
                if result.assets.isEmpty {
                    emptyLibrarySection
                } else {
                    let summary = result.summary()
                    heroSection(summary)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 10)
                        .animation(.default, value: showContent)

                    statPillsSection(summary)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 10)
                        .animation(.default.delay(0.05), value: showContent)

                    chartSection(result)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 10)
                        .animation(.default.delay(0.1), value: showContent)

                    albumSection
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 10)
                        .animation(.default.delay(0.15), value: showContent)
                }
            }

            if showSuccess {
                successSection
            }
        }
        .padding(EdgeInsets(top: 28, leading: 32, bottom: 32, trailing: 32))
    }
    .background(Theme.bg)
}
```

Update `startScan()` to trigger the stagger:

```swift
private func startScan() async {
    errorMessage = nil
    showSuccess = false
    showContent = false
    do {
        try await photoService.scan()
        if let result = photoService.scanResult {
            withAnimation(.default) {
                categories = result.albumCategories()
            }
            showContent = true
        }
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

- [ ] **Step 3: Add chart bar animation in `SizeDistributionChart.swift`**

Add `@State private var animateChart = false` to SizeDistributionChart.

Update `chartDataPoints` usage to animate from zero:

In the Chart, wrap the y value:
```swift
BarMark(
    x: .value("Size Range", point.bucket),
    y: .value(chartMetric == .count ? "Assets" : "Size", animateChart ? point.value : 0)
)
```

Add `.onAppear { animateChart = true }` and animate on metric change:
```swift
.animation(.default, value: chartMetric)
.animation(.default, value: animateChart)
.onAppear {
    withAnimation(.default) {
        animateChart = true
    }
}
```

- [ ] **Step 4: Build to verify compiles**

Run: `xcodebuild -scheme LightTable -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add LightTable/ContentView.swift LightTable/Views/SizeDistributionChart.swift
git commit -m "feat: add staggered entrance and chart bar animations"
```

---

### Task 7: Final verification

- [ ] **Step 1: Build and run**

Run: `xcodebuild -scheme LightTable -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 2: Verify against spec checklist**

Run the app and verify each item from the spec:
1. Always-dark appearance regardless of system setting
2. Chart uses Helvetia Blue / Citrine (not default blue/purple)
3. Toggles and CTA button use standard macOS styling
4. Hero stat shows unified color for number and unit
5. Stat pills have colored top accent lines
6. Album rows have colored left accent lines
7. No grid lines on chart
8. Chart bars animate from zero when results first appear
9. Sections stagger in on results page transition
10. Chart bars animate when toggling Count/Storage

- [ ] **Step 3: Commit any final fixes and tag**

```bash
git add -A
git commit -m "feat: complete dark vibrant UI redesign"
```
