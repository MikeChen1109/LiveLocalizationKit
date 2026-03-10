# DebugLocalizationPreviewTool

`DebugLocalizationPreviewTool` is a lightweight iOS debug tool for previewing how localized UI may look before a full production localization workflow is ready.

## What Problem It Solves

This project is designed to help indie developers and small teams support multi-language UI faster.

In many side projects, localization is delayed because:

- production translation pipelines are expensive or incomplete
- it is hard to quickly preview how strings expand in different languages
- layout issues are often discovered too late

This tool focuses on one practical goal:

- quickly preview whether different languages can still fit and display correctly in the intended UI design

## Current Positioning

This project is currently aimed at **debugging and UI preview workflows**, not production-ready localization infrastructure.

Important note:

- it is **not currently recommended to use this directly in production**
- use it to validate layout, length expansion, and localization integration points during development
- production apps should still use a proper localization strategy, translation review process, and content management flow

## What It Can Do

- pseudo-localize strings to simulate translated UI
- preview text expansion and accented characters
- swap between different localization providers during development
- integrate with Apple's Translation framework where supported
- help surface missing localization handling in app screens earlier

## Package Products

This repository exposes two Swift Package products:

- `DebugLocalizationCore`
- `DebugLocalizationTranslationSupport`

## Install with Swift Package Manager

Add this repository in Xcode using:

```text
https://github.com/MikeChen1109/DebugLocalizationPreviewTool.git
```

Then import the module you need:

```swift
import DebugLocalizationCore
```

or

```swift
import DebugLocalizationTranslationSupport
```

## Basic Usage

Create a `DebugLocalizer` with one of the built-in providers:

```swift
import DebugLocalizationCore

let localizer = DebugLocalizer(provider: PseudoLocalizationProvider())
let text = await localizer.localize("Settings")
```

You can also create a configuration and generate a localizer from it:

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

Use this when you want to test UI layout quickly without real translation.

It:

- replaces some characters with accented versions
- expands string length to simulate real localized text
- wraps output with a language marker for easier visual inspection

This is the most useful provider for early UI validation.

### `MockTranslationProvider`

Use this when you want to simulate asynchronous translation behavior without relying on real services.

### `PassthroughLocalizationProvider`

Use this when you want debug localization wiring enabled, but still return the original string.

### `AppleTranslationProvider`

Use this when testing translation flows on supported Apple platforms.

Notes:

- this depends on Apple platform availability
- it should be treated as a debug/development aid for now

## Recommended Use Cases

- checking whether long strings break your layout
- previewing localization impact before real translations are ready
- spotting screens that still contain hard-coded or unhandled strings
- validating debug builds with multiple provider modes

## Not Yet a Full Production Localization Solution

This repository does **not** replace:

- `Localizable.strings` or string catalogs
- translator review
- terminology consistency checks
- production content workflows
- localization QA across all markets

If your app is shipping broadly, you should treat this tool as a companion to your localization process, not the final process itself.

## Open Source Usage

This project is open source and intended for learning, experimentation, and integration into internal debug workflows.

If you use it:

- feel free to fork and adapt it to your own app workflow
- open issues or pull requests if you find bugs or have ideas
- please evaluate platform compatibility and product risk before using any part of it in a shipped app

## Repository Layout

- `Package.swift`: root Swift Package manifest for SPM consumers
- `frameworks/DebugLocalizationPackage/`: package source code and tests
- `DebugLocalizationDemo/`: local demo app for development and experiments

## Future Direction

Areas worth expanding next:

- easier SwiftUI integration APIs
- sample integration with string catalogs
- better demo coverage for common UI edge cases
- clearer preparation flow for Apple Translation support
- more test coverage around language handling and fallback behavior
