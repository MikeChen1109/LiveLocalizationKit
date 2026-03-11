# Debug Localization Preview Tool

Debug Localization Preview Tool is a lightweight Swift Package for debug-time localization workflows. It is designed for developers who want to preview localized UI quickly, swap debug translation providers, and stress test layouts before production localization is in place.

## What This Tool Does

- uses Apple Translation for quicker translation preview in supported environments
- supports provider-swappable debug localization flows
- provides async and sync access for debug-time localization
- provides pseudo, mock, and passthrough providers for different scenarios
- helps catch layout problems caused by translated or expanded text

## Important Note

This project is currently intended for **debugging and UI preview workflows**.

It is **not recommended as a direct production localization solution** yet.

Use it to:

- preview multi-language UI faster
- validate layout under translated content
- test localization-related behavior in development

Do not treat it as a replacement for:

- string catalogs or `Localizable.strings`
- translator review
- localization QA
- a production translation workflow

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

DebugTranslate.configure(provider: MockTranslationProvider())

let localized = "Settings".localizeSync()
```

For Apple Translation-based preview:

```swift
import DebugLocalizationCore
import DebugLocalizationTranslationSupport

DebugTranslate.configure(provider: AppleTranslationProvider())
let localized = await "Settings".localize()
```

## Usage Notes

### Apple Translation Support

`AppleTranslationProvider` is intended to help you generate preview text faster with Apple's Translation framework on supported platforms.

Notes:

- minimum supported version is `iOS 18`
- this depends on Apple platform availability
- supported languages depend on the system
- this is best treated as a debug preview aid, not a complete production translation pipeline

### Language Packs

Before testing with `AppleTranslationProvider`, it is recommended to download the target language packs first in Apple's built-in `Translate` app.

Recommended setup:

1. Open the built-in `Translate` app on the device.
2. Go to the app's language management area.
3. Download the languages you want to test first.
4. Return to your app and run the preview flow.

This is currently the smoothest setup for developers using the package in their own projects.

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

### Sync API

`localizeSync()` is intentionally limited to providers conforming to `SyncLocalizationProvider`.

If the configured provider is async-only, `localizeSync()` returns `nil` instead of blocking.

### Example App

If you want to see how this package is used in practice, check the demo app in:

- `DebugLocalizationDemo/`

## Built-in Providers

### `AppleTranslationProvider`

Use it when you want preview output closer to real translated content and want to reduce manual translation work during development.

### `PseudoLocalizationProvider`

Use this when you want to stress test UI layout.

It:

- replaces some characters with accented versions
- pads text length to mimic longer translations
- adds a visible language marker around the output

### `MockTranslationProvider`

Useful when you want deterministic debug output without depending on external translation behavior.

### `PassthroughLocalizationProvider`

Returns the original text unchanged.

## License

MIT
