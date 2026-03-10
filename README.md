# Debug Localization Preview Tool

This is a lightweight iOS debug tool for indie developers and small teams who want to preview localized UI faster, reduce manual translation setup during development, and validate how their app behaves across languages before a full production localization workflow is ready.

## Problem

For indie developers and small teams, localization often happens too late. The result is usually predictable:

- translated text is longer than expected
- layouts break in some languages
- screens still contain hard-coded strings
- testing real translated content takes too much manual effort

## Main Value

The main value of this tool is Apple Translation integration for faster localization preview.

Instead of manually preparing translated strings for every screen, you can use Apple Translation to generate preview content more quickly during development. This makes it easier to validate UI, compare language behavior, and reduce repetitive manual translation work.

Alongside that, the package also includes extra providers for testing different scenarios such as pseudo-localization, mock behavior, and passthrough mode.

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

- this depends on Apple platform availability
- supported languages depend on the system
- this is best treated as a debug preview aid, not a complete production translation pipeline

### Language Download Issue

When using Apple Translation, language package downloads may sometimes appear stuck or take a very long time.

If that happens, a practical workaround is:

1. Open the built-in `Translate` app on the device.
2. Go to the app's language management area.
3. Add or remove the language packs there first.
4. Return to your app and try again.

In practice, managing language packs through the `Translate` app can be more reliable than waiting for the download flow to recover inside your own testing flow.

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

## How To Think About The Two Products

### `DebugLocalizationCore`

This contains the shared debug localization foundation:

- `DebugLocalizer`
- provider abstraction
- pseudo-localization
- mock and passthrough providers
- configuration support

### `DebugLocalizationTranslationSupport`

This adds Apple Translation-based preview support on top of the core workflow.

The split keeps the core debug flow reusable, while translation-specific support stays separate.

## Open Source

This project is open source and intended for experimentation, learning, and internal debug workflows.

You can:

- use it in your own projects
- fork and customize it
- open issues or pull requests

## Repository Layout

- `Package.swift`: root manifest for Swift Package Manager
- `frameworks/DebugLocalizationPackage/`: package sources and tests
- `DebugLocalizationDemo/`: demo app for local development
