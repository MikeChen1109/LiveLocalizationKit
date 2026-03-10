# Debug Localization Preview Tool

This is a lightweight iOS debug tool for indie developers and small teams who want to preview localized UI faster, reduce manual translation setup during development, and validate how their app behaves across languages before a full production localization workflow is ready.

## What This Tool Does

- uses Apple Translation for quicker translation preview in supported environments
- helps preview localization impact earlier in development
- reduces manual setup when testing multi-language UI
- provides pseudo, mock, and passthrough providers for different debug scenarios
- makes it easier to catch layout problems caused by translated text

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

For Apple Translation-based preview:

```swift
import DebugLocalizationCore
import DebugLocalizationTranslationSupport

let provider = AppleTranslationProvider()
let localizer = DebugLocalizer(provider: provider)
let localized = await localizer.localize("Settings")
```

For pseudo-localization preview:

```swift
import DebugLocalizationCore

let localizer = DebugLocalizer(provider: PseudoLocalizationProvider())
let localized = await localizer.localize("Settings")
```

You can also use a configuration:

```swift
import DebugLocalizationCore

let configuration = DebugLocalizationConfiguration(
    providerMode: .pseudoLocalization,
    shouldPresentPreparationGate: false
)

let localizer = configuration.makeLocalizer()
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

### Example App

If you want to see how this package is used in practice, check the demo app in:

- `DebugLocalizationDemo/`

## Built-in Providers

### `AppleTranslationProvider`

The main provider for this project. Use it when you want preview output closer to real translated content and want to reduce manual translation work during development.

### `PseudoLocalizationProvider`

Use this when you want to stress test UI layout.

It:

- replaces some characters with accented versions
- pads text length to mimic longer translations
- adds a visible language marker around the output

### `MockTranslationProvider`

Useful when you want to simulate async translation behavior.

### `PassthroughLocalizationProvider`

Returns the original text unchanged.

## License

MIT
