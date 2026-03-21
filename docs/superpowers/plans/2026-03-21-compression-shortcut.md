# Compression Shortcut Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **IMPORTANT: Work in a separate worktree.** Before starting, create an isolated worktree using superpowers:using-git-worktrees. Branch name: `feature/compression-shortcut`. All implementation work must happen in that worktree — do not modify the main working directory.

**Goal:** Add a compression info view with bundled Apple Shortcut install to help users shrink large photos instead of deleting them.

**Architecture:** A new `CompressionInfoView` presented as a `.sheet` from an info button in the toolbar. The view contains copy explaining the feature, platform-specific usage instructions, and a button that opens a bundled `.shortcut` file for installation. The Shortcut itself is built manually in Shortcuts.app and exported as a `.shortcut` file.

**Tech Stack:** SwiftUI, NSWorkspace, Apple Shortcuts (.shortcut file)

**Spec:** `docs/superpowers/specs/2026-03-21-compression-shortcut-design.md`

**Note on XcodeGen:** The project uses `project.yml` with `sources: - LightTable` which auto-discovers all files under `LightTable/`. New `.swift` files and resources in `LightTable/Resources/` are included automatically. Run `xcodegen generate` after adding files to regenerate the project.

---

### Task 1: Create the CompressionInfoView

**Files:**
- Create: `LightTable/Views/CompressionInfoView.swift`

This is a SwiftUI view presented as a `.sheet`. It is a static informational view with no business logic to test — TDD is not applicable here.

The view must be wrapped in `NavigationStack` because `.toolbar` modifiers on a macOS sheet only render when there is a navigation container providing toolbar context. Without it, the "Done" button will not appear.

- [ ] **Step 1: Create `CompressionInfoView.swift`**

```swift
import SwiftUI

struct CompressionInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    bodySection
                    macOSSection
                    iOSSection
                }
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minWidth: 500, minHeight: 400)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Largest Photos Are Now Sorted by Size")
                .font(.title.bold())
            Text("Delete what you don't need. Compress what you want to keep.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Body

    private var bodySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Don't want to delete it? Shrink it.")
                .font(.headline)
            Text("Our Shortcut converts photos to HEIF and caps resolution at 24MP — smaller files, nearly indistinguishable quality.")
                .foregroundStyle(.secondary)
            Text("Originals go to Recently Deleted. You have 30 days to change your mind.")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - macOS Instructions

    private var macOSSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("macOS", systemImage: "desktopcomputer")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    instructionRow(number: "1", text: "Install the Shortcut")
                    installButton
                    instructionRow(number: "2", text: "Open a Light Table album in Photos")
                    instructionRow(number: "3", text: "Select photos → Right-click → Quick Actions → Light Table Compress")
                }
            }
            .padding(8)
        }
    }

    // MARK: - iOS Instructions

    private var iOSSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("iOS (via iCloud Sync)", systemImage: "iphone")
                    .font(.headline)

                Text("The Shortcut syncs to your iPhone/iPad via iCloud after installing on Mac.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    instructionRow(number: "1", text: "Open a Light Table album in Photos")
                    instructionRow(number: "2", text: "Select photos → Share → Light Table Compress")
                }
            }
            .padding(8)
        }
    }

    // MARK: - Helpers

    private var installButton: some View {
        Button {
            installShortcut()
        } label: {
            Label("Install Shortcut", systemImage: "square.and.arrow.down")
        }
        .buttonStyle(.bordered)
        .padding(.leading, 24)
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number + ".")
                .font(.body.bold())
                .monospacedDigit()
                .frame(width: 20, alignment: .trailing)
            Text(text)
        }
    }

    private func installShortcut() {
        // Silently no-ops if the .shortcut file is not yet bundled (see Task 4)
        guard let url = Bundle.main.url(forResource: "LightTableCompress", withExtension: "shortcut") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
```

- [ ] **Step 2: Regenerate project and verify it compiles**

```bash
xcodegen generate
xcodebuild build -project LightTable.xcodeproj -scheme LightTable -destination 'platform=macOS' 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add LightTable/Views/CompressionInfoView.swift LightTable.xcodeproj
git commit -m "feat: add CompressionInfoView with install and usage instructions"
```

---

### Task 2: Add info button to toolbar and wire up the sheet

**Files:**
- Modify: `LightTable/ContentView.swift`

**Design note:** The spec says the info button should be "visible when `scanResult != nil`." We use `.disabled(!hasResults)` instead of hiding/showing to keep the toolbar layout stable. The button is always present but only interactive after a scan.

- [ ] **Step 1: Add `@State` property for sheet presentation**

Add below the existing `@State private var showSuccess = false` line:

```swift
@State private var showCompressionInfo = false
```

- [ ] **Step 2: Add the info toolbar button**

Find the existing `.toolbar { }` block in `body`. Inside it, add a second `ToolbarItem` after the existing "Scan Again" `ToolbarItem`:

```swift
ToolbarItem(placement: .primaryAction) {
    Button {
        showCompressionInfo = true
    } label: {
        Label("Compression Info", systemImage: "info.circle")
    }
    .help("Learn how to compress large photos")
    .disabled(!hasResults)
}
```

- [ ] **Step 3: Attach the `.sheet` modifier**

Find the `.toolbar { ... }` closing brace on the `Group` in `body`. Add the `.sheet` modifier directly after it (still chained on the `Group`):

```swift
.sheet(isPresented: $showCompressionInfo) {
    CompressionInfoView()
}
```

- [ ] **Step 4: Verify it compiles**

```bash
xcodebuild build -project LightTable.xcodeproj -scheme LightTable -destination 'platform=macOS' 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add LightTable/ContentView.swift
git commit -m "feat: add info button in toolbar to present CompressionInfoView"
```

---

### Task 3: Create and bundle the Shortcut file

> **MANUAL TASK — requires human intervention.** This task cannot be automated by an agent. It requires building a Shortcut in the Shortcuts.app GUI and exporting it. Tasks 1-2 compile and function without this file (the install button silently no-ops). This task must be completed before Tasks 4 and 5.

**Files:**
- Create: `LightTable/Resources/LightTableCompress.shortcut`

- [ ] **Step 1: Build the Shortcut in Shortcuts.app**

Open Shortcuts.app on macOS and create a new Shortcut named "Light Table Compress" with this action sequence:

1. **Receive** "Images" input from "Quick Actions" (macOS) and "Share Sheet" (iOS)
2. **Get Details of Images** — get "Width" and "Height"
3. **Calculate** — multiply width × height
4. **If** result > 24000000:
   - **Calculate** — target width = sqrt(24000000 × (width / height)), rounded
   - **Resize Image** — resize to calculated width, auto height
5. **End If**
6. **Convert Image** — convert to HEIF format
7. **Save to Photo Album** — save to Recents
8. **Delete Photos** — delete original input photos

- [ ] **Step 2: Export the Shortcut**

In Shortcuts.app: right-click the Shortcut → "Share" → "File" → save as `LightTableCompress.shortcut`

- [ ] **Step 3: Copy to project Resources and regenerate project**

```bash
cp ~/Downloads/LightTableCompress.shortcut LightTable/Resources/LightTableCompress.shortcut
xcodegen generate
```

- [ ] **Step 4: Verify the file is in the bundle**

```bash
xcodebuild build -project LightTable.xcodeproj -scheme LightTable -destination 'platform=macOS' 2>&1 | tail -5
find ~/Library/Developer/Xcode/DerivedData -name "LightTableCompress.shortcut" -path "*/Build/Products/*" 2>/dev/null | head -1
```

Expected: File found in the built product.

- [ ] **Step 5: Commit**

```bash
git add LightTable/Resources/LightTableCompress.shortcut LightTable.xcodeproj
git commit -m "feat: bundle Light Table Compress shortcut file"
```

---

### Task 4: Validate EXIF date preservation

> **Depends on Task 3.** The Shortcut must be built and working before this validation can run.

**Files:** None — this is a validation task (may result in a code change).

This addresses the open question from the spec: does the Shortcut preserve the photo's timeline position?

- [ ] **Step 1: Test the Shortcut manually**

1. Note a photo's date in Photos.app
2. Run the "Light Table Compress" Shortcut on it
3. Check if the compressed copy appears at the same date in the timeline

- [ ] **Step 2: Document the result**

If dates are **NOT** preserved, add a caveat to the body section in `CompressionInfoView.swift`, after the "30 days" text:

```swift
Text("Note: Compressed photos may appear at today's date in your timeline.")
    .font(.caption)
    .foregroundStyle(.secondary)
```

If dates **ARE** preserved, no change needed.

- [ ] **Step 3: Commit if changes were made**

```bash
git add LightTable/Views/CompressionInfoView.swift
git commit -m "docs: add date caveat to compression info view"
```

---

### Task 5: Final build and smoke test

**Files:** None — validation only.

- [ ] **Step 1: Clean build**

```bash
xcodebuild clean build -project LightTable.xcodeproj -scheme LightTable -destination 'platform=macOS' 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 2: Run existing tests**

```bash
xcodebuild test -project LightTable.xcodeproj -scheme LightTable -destination 'platform=macOS' 2>&1 | tail -10
```

Expected: All tests pass, no regressions.

- [ ] **Step 3: Manual smoke test**

1. Launch app → Scan library
2. Verify info button (`info.circle`) appears in toolbar after scan
3. Click info button → Verify sheet appears with correct copy and "Done" button
4. Click "Install Shortcut" → Verify Shortcuts.app opens with import prompt
5. Click "Done" → Verify sheet dismisses
6. Verify info button is disabled before scan

- [ ] **Step 4: Commit any final fixes**

Stage specific files only (avoid `git add -A` in worktrees):

```bash
git add LightTable/Views/CompressionInfoView.swift LightTable/ContentView.swift
git commit -m "fix: address issues found during smoke test"
```
