# Debug Localization Preview Tool

Debug Localization Preview Tool is a Swift Package that wraps Apple Translation into a simpler integration flow for new iOS apps. It is designed for developers who want a more direct way to translate individual strings, reduce repetitive `translationTask` setup, and speed up localized UI preview during development.

## What This Tool Does

- wraps Apple Translation behind a simpler provider-based API
- reduces the need to repeatedly wire `translationTask` or manage translation sessions manually
- lets you translate individual strings through a shared localizer flow
- helps you preview localized UI faster and catch layout issues earlier
- includes preparation helpers for language pack download and readiness checks
- keeps the provider model open so other translation backends can be added later

## Important Note

This package is currently centered on **making Apple Translation easier to integrate** in modern iOS apps while also improving development-time localization preview workflows.

Its main value is not replacing Apple's framework, but providing a cleaner way to adopt it.

Use it to:

- integrate Apple Translate with less repeated setup code
- translate individual UI strings more directly in your app flow
- preview multi-language UI faster during development
- validate layout behavior under translated content
- prototype or ship app features built around Apple's on-device translation
- keep room for custom providers in future versions if you want to plug in your own translation API

Do not treat it as a replacement for:

- string catalogs or `Localizable.strings`
- translator review
- localization QA
- a full localization management workflow

## Swift Package Manager

Add this repository in Xcode:

```text
https://github.com/MikeChen1109/DebugLocalizationPreviewTool.git
```

Available products:

- `DebugLocalizationCore`
- `DebugLocalizationTranslationSupport`

## Quick Start

Configure a shared provider once at app startup:

```swift
import DebugLocalizationCore

DebugTranslate.configure(provider: PseudoLocalizationProvider())
```

Then localize directly from `String`:

```swift
import DebugLocalizationCore

let localized = await "Settings".localize()
```

If you want to bypass the shared instance, inject your own localizer:

```swift
import DebugLocalizationCore

let localizer = DebugLocalizer(provider: PseudoLocalizationProvider())
let localized = await "Settings".localize(using: localizer)
```

For providers that do not require async work:

```swift
import DebugLocalizationCore

DebugTranslate.configure(provider: MockLocalizationProvider())

let localized = "Settings".localizeSync()
```

For Apple Translation-based preview:

```swift
import DebugLocalizationCore
import DebugLocalizationTranslationSupport

DebugTranslate.configure(provider: AppleTranslationProvider())
let localized = await "Settings".localize()
```

If you want a fast in-app setup that checks whether language packs are installed and prompts the system download flow when needed:

```swift
import SwiftUI
import DebugLocalizationTranslationSupport

TranslationPreparationGate {
    ContentView()
}
```

If you need a custom UI, drive the flow yourself with `TranslationPreparationCoordinator`:

```swift
import DebugLocalizationTranslationSupport

@State private var coordinator = TranslationPreparationCoordinator()

.task {
    await coordinator.refresh()
}
```

## Usage Notes

### Apple Translation Support

`AppleTranslationProvider` is intended to give developers a more convenient integration layer on top of Apple's Translation framework.

Notes:

- minimum supported version is `iOS 26`
- this depends on Apple platform availability
- supported languages depend on the system
- this package focuses on simplifying Apple Translate integration rather than replacing a full localization pipeline

### Language Packs

For a quick setup, wrap your root debug UI with `TranslationPreparationGate`. It checks whether the required language pack is installed and can trigger Apple's in-app preparation flow before your localized preview content appears.

Example:

```swift
import DebugLocalizationTranslationSupport

TranslationPreparationGate {
    RootView()
}
```

If you want full control over the UI, use `TranslationPreparationCoordinator` directly and render your own loading or prompt states.

You can also query the current preparation state:

```swift
let needsPreparation = await coordinator.requiresPreparation()
let state = await coordinator.refreshPreparationStatus()
```

If you prefer not to use the in-app flow, you can still download language packs ahead of time in Apple's built-in `Translate` app.

### If Downloads Seem Stuck

When using Apple Translation, language package downloads may sometimes appear stuck or take a very long time inside the app flow.

If that happens, a practical workaround is:

1. Open the built-in `Translate` app on the device.
2. Go to the app's language management area.
3. Add or remove the language packs there first.
4. Return to your app and try again.

In practice, managing language packs through the `Translate` app can be more reliable than waiting for the download flow to recover inside your own testing flow.

### Shared Configuration

Use `DebugTranslate.configure(provider:)` during app startup to define the default provider used by `String.localize()`.

If needed, you can still create a custom `DebugLocalizer(provider:)` and pass it explicitly to `String.localize(using:)`.

You can also reset or clear the shared localizer state:

```swift
DebugTranslate.clearCache()
DebugTranslate.reset()
```

### Sync API

`localizeSync()` is intentionally limited to providers conforming to `SyncLocalizationProvider`.

If the configured provider is async-only, `localizeSync()` falls back to the original text instead of blocking.

Use sync APIs for:

- `PseudoLocalizationProvider`
- `PassthroughLocalizationProvider`
- `MockLocalizationProvider`

Use async APIs for:

- `AppleTranslationProvider`

### Example App

If you want to see how this package is used in practice, check the demo app in:

- `DebugLocalizationDemo/`

The demo app uses `TranslationPreparationGate` at the root and shows both SwiftUI and UIKit preview screens under the same preparation flow.

## Built-in Providers

### `AppleTranslationProvider`

Use it when you want a simpler way to integrate Apple Translate and translate strings without repeatedly wiring Apple Translation APIs yourself.

Pair it with `TranslationPreparationGate` for the quickest setup, or use `TranslationPreparationCoordinator` when you need a custom preparation UI.

### `PseudoLocalizationProvider`

Use this when you want to stress test UI layout.

It:

- replaces some characters with accented versions
- pads text length to mimic longer translations
- adds a visible language marker around the output

### `MockLocalizationProvider`

Useful when you want deterministic debug output without depending on external translation behavior.

### `PassthroughLocalizationProvider`

Returns the original text unchanged.

## License

MIT
