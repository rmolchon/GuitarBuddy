# Building and Testing GuitarBuddy

This guide covers getting GuitarBuddy building, running, and testing locally, using either Xcode or Visual Studio Code. For architecture and design notes, see `CLAUDE.md`. For a project overview, see `README.md`.

## Prerequisites

- **macOS**, since this is a native iOS app — there is no cross-platform build path.
- **[Xcode](https://apps.apple.com/us/app/xcode/id497799835) 15+**, the **full app**, not just the Command Line Tools. `xcodebuild`, the iOS Simulator, and asset/Info.plist compilation all require the full Xcode toolchain. If you've only ever installed the Command Line Tools (e.g. via `xcode-select --install` or Homebrew pulling them in as a dependency), builds will fail — see [Troubleshooting](#troubleshooting) below.
- **[XcodeGen](https://github.com/yonaskolb/XcodeGen)** — `brew install xcodegen`. The `.xcodeproj` is generated from `project.yml` and is not committed to the repo.
- An **iOS 17+ Simulator runtime** installed (Xcode → Settings → Platforms → iOS, if not already present from your Xcode install).
- **(Optional, for editing in VS Code)** [Visual Studio Code](https://code.visualstudio.com/) with the official **Swift** extension. Search "Swift" in the Extensions view and install the one published by the Swift project / Swift Server Work Group — it provides SourceKit-LSP-backed autocomplete, jump-to-definition, and inline diagnostics for `.swift` files. It does not replace `xcodebuild` for actually building or testing an iOS app target (see below).

## Generating the Xcode project

The `.xcodeproj` is gitignored and regenerated from `project.yml`. Run this after cloning, and again any time you edit `project.yml` or add/move/remove source files:

```bash
xcodegen generate
```

This creates/updates `GuitarBuddy.xcodeproj` in the repo root.

## Building and running with Xcode

1. `xcodegen generate` (if you haven't already, or just changed `project.yml`)
2. `open GuitarBuddy.xcodeproj`
3. In the scheme selector, choose the **GuitarBuddy** scheme and an iOS Simulator destination (e.g. "iPhone 17")
4. **⌘B** to build, **⌘R** to build and run

The first time you launch the **Tuner** tab on a real device, iOS will prompt for microphone access (`NSMicrophoneUsageDescription` is already set in `Info.plist`). In the Simulator there is no real microphone route, so the Tuner will show a friendly "Microphone input isn't available" message instead of detecting pitch — that's expected simulator behavior, not a bug (see `AudioEngineControllerError` in `AudioEngineController.swift`).

## Building and running with VS Code

VS Code does not have its own iOS build/run pipeline — under the hood, building and testing GuitarBuddy from VS Code still goes through `xcodebuild`, the same tool Xcode itself uses. What VS Code adds is a good editing experience (via the Swift extension's SourceKit-LSP integration) plus a terminal you can drive that tool from without leaving the editor.

1. Install the Swift extension (see [Prerequisites](#prerequisites)) so you get autocomplete, diagnostics, and jump-to-definition across the project.
2. Open the repo root folder in VS Code (`code .`).
3. Open the integrated terminal (`` Ctrl+` ``) and run the same `xcodegen generate` / `xcodebuild` commands from the [Command-Line Reference](#command-line-reference) below.
4. To actually see the app running, either:
   - Open `GuitarBuddy.xcodeproj` in Xcode and run it there (fastest for interactive UI work), or
   - Build via `xcodebuild` from the VS Code terminal, then install and launch on a booted simulator manually:
     ```bash
     xcrun simctl boot "iPhone 17"   # skip if a simulator is already booted
     open -a Simulator
     xcodebuild -scheme GuitarBuddy -destination 'platform=iOS Simulator,name=iPhone 17' \
       -derivedDataPath .build/DerivedData build
     xcrun simctl install booted .build/DerivedData/Build/Products/Debug-iphonesimulator/GuitarBuddy.app
     xcrun simctl launch booted com.guitarbuddy.app
     ```

### Optional: a VS Code task for one-key builds

If you want **⇧⌘B** (Run Build Task) to work in VS Code, add a `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Generate Xcode project",
      "type": "shell",
      "command": "xcodegen generate"
    },
    {
      "label": "Build (Simulator)",
      "type": "shell",
      "command": "xcodebuild build -scheme GuitarBuddy -destination 'platform=iOS Simulator,name=iPhone 17'",
      "group": { "kind": "build", "isDefault": true },
      "problemMatcher": "$xcode"
    },
    {
      "label": "Test (all)",
      "type": "shell",
      "command": "xcodebuild test -scheme GuitarBuddy -destination 'platform=iOS Simulator,name=iPhone 17'",
      "group": { "kind": "test", "isDefault": true },
      "problemMatcher": "$xcode"
    }
  ]
}
```

Adjust the simulator name to one you actually have (`xcrun simctl list devices available`). The `$xcode` problem matcher surfaces `xcodebuild` errors/warnings in VS Code's Problems panel, same as Xcode's issue navigator.

## Command-line reference

These work identically from Xcode's terminal, VS Code's integrated terminal, or a plain Terminal window — they're just `xcodebuild`/`xcrun` invocations.

```bash
# List available simulators (grab a device name or UDID from here)
xcrun simctl list devices available

# Regenerate the Xcode project after editing project.yml or moving files
xcodegen generate

# Clean build artifacts
xcodebuild clean -scheme GuitarBuddy

# Build only
xcodebuild build -scheme GuitarBuddy -destination 'platform=iOS Simulator,name=iPhone 17'

# Build and run all tests (unit + UI)
xcodebuild test -scheme GuitarBuddy -destination 'platform=iOS Simulator,name=iPhone 17'
```

You can target a destination by UDID instead of name if you have multiple simulators with the same device type:

```bash
xcodebuild build -scheme GuitarBuddy -destination 'platform=iOS Simulator,id=<UDID>'
```

## Testing

GuitarBuddy has two test targets, with deliberately different scopes (see `CLAUDE.md`'s Testing section for the full rationale):

- **`GuitarBuddyTests`** (unit tests) — exhaustive coverage of `Core/` (music theory, audio math, tuning presets) plus `AudioEngineController`. These are fast (the whole suite runs in ~1.5 seconds) because DSP-heavy code (`PitchDetector`, `FrequencyToNote`) is tested against synthetic sine-wave buffers rather than live audio, and `AudioEngineController` is tested by calling its buffer-handling logic directly with synthetic `AVAudioPCMBuffer`s rather than starting the real audio engine.
- **`GuitarBuddyUITests`** (UI tests) — navigation and interaction flows only (tab switching, the tuning picker, adding/removing chord chips) via XCUITest, which drives the actual simulator UI. These are slower (~5–15 seconds per test, since each one launches or interacts with a real running app) and do not test DSP correctness — that's `GuitarBuddyTests`' job.

### Running tests

```bash
# Everything (unit + UI)
xcodebuild test -scheme GuitarBuddy -destination 'platform=iOS Simulator,name=iPhone 17'

# Unit tests only (fast — good for a tight edit/test loop)
xcodebuild test -scheme GuitarBuddy -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:GuitarBuddyTests

# UI tests only
xcodebuild test -scheme GuitarBuddy -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:GuitarBuddyUITests

# A single test class
xcodebuild test -scheme GuitarBuddy -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:GuitarBuddyTests/PitchDetectorTests

# A single test method
xcodebuild test -scheme GuitarBuddy -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:GuitarBuddyTests/PitchDetectorTests/test_detectsA4Frequency
```

In Xcode: **⌘U** runs the full test plan. The Test Navigator (**⌘6**) lists every test class/method and lets you run or debug individual ones; you can also click the diamond icon in the gutter next to any `func test_...()` to run just that test.

In VS Code: there's no native test runner UI for an Xcode-project test target (the Swift extension's built-in test runner targets SwiftPM's `swift test`, which doesn't apply here) — run tests via the terminal commands above, or wire up the `tasks.json` snippet from the previous section.

### Reading results

`xcodebuild test` writes a `.xcresult` bundle with full pass/fail details, logs, and (if enabled) coverage data:

```
~/Library/Developer/Xcode/DerivedData/GuitarBuddy-*/Logs/Test/Test-GuitarBuddy-*.xcresult
```

`xcodebuild`'s own stdout already prints a `Test Suite ... passed/failed` summary per class and an overall `** TEST SUCCEEDED **` / `** TEST FAILED **`, which is usually enough. To dig into a specific failure from the CLI without opening Xcode:

```bash
xcrun xcresulttool get test-results summary --path <path-to-.xcresult>
```

Or just open the `.xcresult` bundle in Finder (double-click) to view it in Xcode's Report Navigator UI.

### Code coverage

Enable coverage collection with `-enableCodeCoverage YES`:

```bash
xcodebuild test -scheme GuitarBuddy -destination 'platform=iOS Simulator,name=iPhone 17' \
  -enableCodeCoverage YES
```

View the report from the `.xcresult` bundle:

```bash
xcrun xccov view --report <path-to-.xcresult>
```

Or in Xcode: Report Navigator (**⌘9**) → select the test run → Coverage tab.

### Writing new tests

Follow the conventions already established in the codebase (see `CLAUDE.md` for the full testing philosophy):

- **Test-first**: write the failing test before the implementation.
- **AAA structure**: Arrange / Act / Assert, with the first test in a file commenting each section; subsequent tests in the same file can drop the comments once the pattern is established.
- **Naming**: `test_<behavior>()`, describing what's being verified, not the method under test (`test_returnsNilForEmptyString`, not `test_parse`).
- **Unit vs. UI**: if it's `Core/` logic or can be tested with synthetic data (sine waves, synthetic `AVAudioPCMBuffer`s), it belongs in `GuitarBuddyTests`. If it's a navigation/interaction flow that only makes sense against the real rendered UI, it belongs in `GuitarBuddyUITests` — and should target stable `accessibilityIdentifier`s (see the existing views for the pattern), not fragile visible text.

## Troubleshooting

**`xcode-select: error: tool 'xcodebuild' requires Xcode, but active developer directory '/Library/Developer/CommandLineTools' is a command line tools instance`**
Your system is pointed at the bare Command Line Tools instead of full Xcode.app, even though Xcode.app is installed. Fix:
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -version   # should now print an Xcode version, not just a CLT version
```

**`Cannot code sign because the target does not have an Info.plist file and one is not being generated automatically`**
A target's `settings.base` in `project.yml` needs `GENERATE_INFOPLIST_FILE: true` unless it has an explicit `info.properties` block (like the `GuitarBuddy` app target does). This bites you if you add a new test target or Swift Package without setting one or the other.

**`None of the input catalogs contained a matching stickers icon set, app icon set, or icon stack named "AppIcon"`**
`Assets.xcassets` needs an `AppIcon.appiconset` — Xcode's default build settings expect `ASSETCATALOG_COMPILER_APPICON_NAME=AppIcon` even without you setting it explicitly. GuitarBuddy already has one committed; this is here in case you ever regenerate the asset catalog from scratch.

**SourceKit/VS Code shows `No such module 'XCTest'` or "Cannot find type X in scope" in files that build fine via `xcodebuild`**
This is normal when an editor's live diagnostics engine type-checks a single file in isolation without the full project/SDK context loaded (common right after creating a new file, before the editor's index catches up). Trust `xcodebuild build`/`xcodebuild test` output over these transient single-file diagnostics — if the real build succeeds, the code is fine.

**Simulator won't boot, or a build seems stuck on stale state**
```bash
xcodebuild clean -scheme GuitarBuddy
rm -rf ~/Library/Developer/Xcode/DerivedData/GuitarBuddy-*
xcrun simctl shutdown all
```

**"Microphone input isn't available" in the Tuner tab**
Expected in the Simulator, which has no real microphone route — see [Building and running with Xcode](#building-and-running-with-xcode) above. Not a bug; `AudioEngineController` is designed to fail gracefully here rather than crash (it used to crash before this was fixed — see git history on `AudioEngineController.swift` if curious).
