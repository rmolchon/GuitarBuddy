# GuitarBuddy

An iOS toolbox for guitar players. Native Swift/SwiftUI, iOS 17+.

## Features

- **Tuner** — real-time pitch detection (YIN algorithm) with standard tuning plus common alt tunings: Drop D, Open G, Open D, DADGAD, Half-Step Down.
- **Key Finder** — build a chord sequence by tapping a root note and quality onscreen (e.g. `C`, `Am`, `F`, `G`) and get a best-guess musical key with a confidence score, using diatonic chord matching.
- **Hum Mode** — hum a melody and see the sequence of detected notes as a scrollable chip history.
- **Transcribe** — strum chords and see the sequence of detected chords as a scrollable chip history (polyphonic detection via the Goertzel algorithm).
- **Dark Mode** — follows the system appearance by default, with a per-screen toolbar control to override to Light/Dark/System.

All four tools are fully on-device and offline — no network calls, no third-party dependencies. The first time a mic-based tool is used, the app requests microphone permission (`AVAudioApplication.requestRecordPermission`); if denied, each tool surfaces an in-app error message with instructions to enable it in Settings. Diagnostic logging uses Apple's native `os.Logger` (`Core/Logging/AppLogger`) rather than a third-party library — view logs in Console.app filtered by subsystem `com.guitarbuddy.app`.

## Requirements

- macOS with [Xcode](https://apps.apple.com/us/app/xcode/id497799835) 15+ installed (full Xcode.app, not just the Command Line Tools)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- iOS 17+ simulator or device

## Getting Started

```bash
# Generate the Xcode project from project.yml
xcodegen generate

# Open in Xcode
open GuitarBuddy.xcodeproj
```

Build and run the `GuitarBuddy` scheme on a simulator or device. A real guitar (or another audio source) is needed to exercise the Tuner beyond unit tests.

### Running tests

```bash
xcodebuild test -scheme GuitarBuddy -destination 'platform=iOS Simulator,name=iPhone 15'
```

Or use the Xcode Test navigator (⌘U).

For a full walkthrough of building and testing with either Xcode or VS Code — including running individual tests, reading coverage reports, and troubleshooting common setup issues — see **[BUILDING.md](BUILDING.md)**.

## Troubleshooting Audio in Xcode

Tuner, Hum Mode, and Transcribe all go through `AudioEngineController`, which needs a live microphone route. A few things commonly trip people up when testing audio from Xcode:

### "Microphone input isn't available" in the Simulator

Expected, not a bug. The iOS Simulator has no real microphone route by default — `AudioEngineController.start()` checks the input format before doing anything else and throws `AudioEngineControllerError.invalidInputFormat` when there isn't one, which is what surfaces this message in the UI.

To exercise the audio features with real input:
- **Run on a physical device** — the most reliable option. Plug in an iPhone/iPad, select it as the run destination, and trust the developer certificate if prompted.
- **Or enable Simulator audio passthrough** — with the Simulator focused, go to **I/O → Audio Input** in the menu bar and select your Mac's microphone. Availability depends on your Xcode/macOS combination, and even when it works, latency and gain behave differently from a real device — treat it as a rough check, not a substitute for on-device verification.

### Microphone permission

The app requests access the first time a mic-based tool is started (`AVAudioApplication.requestRecordPermission`, backed by `NSMicrophoneUsageDescription` in `Info.plist`). If you previously denied it:
- **In Settings** (device or Simulator): Settings → Privacy & Security → Microphone → GuitarBuddy → toggle on.
- **From the command line**, for a specific simulator:
  ```bash
  xcrun simctl privacy booted grant microphone com.guitarbuddy.app
  ```
  If GuitarBuddy is already running, relaunch it — a permission change doesn't retroactively unstick a session that already failed.

When permission is denied, the UI shows `AudioEngineControllerError.permissionDenied`'s message directly rather than failing silently.

### A change to `AudioEngineController` makes a test hang or crash

`start()` depends on live system permission state and the real audio session, both of which are non-deterministic in a headless XCTest run: an undetermined permission hangs the test awaiting a system prompt that never appears, and reaching `AVAudioSession`/`engine.start()` with no real input route crashes the process (`SIGKILL`) instead of throwing. Inject `FakeRecordPermissionProvider` (see `AudioEngineControllerTests`/`HumTranscriptionServiceTests`) rather than letting a test touch the real `AVAudioApplication`/`AVAudioSession` APIs, and keep any cheap guard that can fail deterministically (like the input-format check) running *before* anything that touches the live session.

For broader, non-audio build/test troubleshooting, see **[BUILDING.md's Troubleshooting section](BUILDING.md#troubleshooting)**.

## Project Structure

```
GuitarBuddy/
  App/                 # App entry point, root tab navigation
  Features/
    Tuner/              # Tuner screen and view model
    KeyFinder/           # Key Finder screen and view model
    HumMode/             # Hum Mode screen and view model
    Transcribe/          # Transcribe screen and view model
  Core/
    Audio/               # Pitch detection (YIN), audio capture, chroma extraction, frequency/note math
    MusicTheory/          # Chord parsing, tunings, key-matching engine
    Logging/              # Centralized os.Logger instances, one per feature
  Resources/            # Assets, Info.plist
GuitarBuddyTests/       # Unit tests for Core/
GuitarBuddyUITests/     # UI flow tests
project.yml             # XcodeGen project spec (source of truth for the Xcode project)
```

`Core/` is pure, UI-independent logic (no SwiftUI/AVFoundation view code), so it's exhaustively unit-testable. `Features/` holds the SwiftUI screens that consume `Core/`.

The `.xcodeproj` is generated by XcodeGen and is not committed — run `xcodegen generate` any time `project.yml` or the file layout changes.

## Status

All four tools (Tuner, Key Finder, Hum Mode, Transcribe), plus Dark Mode, are code-complete: `Core/`, the audio capture pipeline, all four feature UIs, and navigation/interaction UI tests are all in and passing, verified via `xcodebuild test` with full Xcode. The only remaining item is manual on-device verification of pitch/chord-detection accuracy against a real guitar and a known reference, which can't be automated. See `CLAUDE.md` for the detailed build order and architecture notes.
