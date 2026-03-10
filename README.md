# Debug Localization Preview Tool

Preview localized UI faster during development.

`Debug Localization Preview Tool` is a lightweight iOS debug tool for indie developers and small teams who want to check multi-language UI earlier, before a full localization pipeline is in place.

## Problem

Localization usually gets delayed until late in development. By then, teams often discover:

- translated text is longer than expected
- layouts break in some languages
- some screens still rely on hard-coded strings

This tool is built to help you preview those issues earlier.

## What This Tool Does

- pseudo-localizes text to simulate translated UI
- expands strings so layout issues are easier to spot
- lets you swap localization providers in debug builds
- supports Apple Translation-based flows where available

## Important Note

This project is currently intended for **debugging and UI preview workflows**.

It is **not recommended as a direct production localization solution** yet.

Use it to:

- validate UI layout under localization stress
- preview translation impact before real content is ready
- test localization integration in development

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

## Built-in Providers

### `PseudoLocalizationProvider`

Best for early UI preview.

It:

- replaces some characters with accented versions
- pads text length to mimic longer translations
- adds a visible language marker around the output

### `MockTranslationProvider`

Useful when you want to simulate async translation behavior.

### `PassthroughLocalizationProvider`

Returns the original text unchanged.

### `AppleTranslationProvider`

Used for Apple Translation-based flows on supported platforms.

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

## Possible Next Steps

Potential areas to improve:

- easier SwiftUI integration
- better demo scenarios for layout edge cases
- more tests for fallback behavior
- clearer setup around Apple Translation preparation flow
