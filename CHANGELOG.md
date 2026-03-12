# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project follows Semantic Versioning.

## [Unreleased]

## [0.4.0] - 2026-03-13

### Added
- Added the new `LiveLocalizationUI` product for UI-level localization wrappers.
- Added `LiveLocalizedText` for SwiftUI.
- Added `LiveLocalizedLabel` for UIKit.
- Added `LiveLocalizationTextAnimation` with `.none` and `.fade` styles.
- Added `LocalizationRequest` and `LocalizationResponse` to support richer custom provider implementations.
- Added `LocalizationCacheStore`, `MemoryLocalizationCacheStore`, and `DiskLocalizationCacheStore`.
- Added UI-layer request coordination tests and demo coverage for the new wrappers.

### Changed
- Moved shared localization state to actor-based concurrency instead of relying on `@unchecked Sendable`.
- Updated `LiveLocalization` shared configuration flow to async usage.
- Updated the provider contract so custom backends can receive source language, target language, and context data.
- Updated `LiveLocalizer` to support injected cache stores and disk-backed persistence.
- Updated the demo app to show both direct core API usage and the new UI wrapper usage in SwiftUI and UIKit.
- Updated README examples to reflect the current package naming, install path, and UI-layer APIs.
- Continued the package rename from the previous `DebugLocalization*` surface to the `LiveLocalization*` naming now used across the repository.

## [0.3.0] - 2026-03-11

### Added
- Added `TranslationPreparationGate` as a quick in-app SwiftUI entry point for checking translation language pack availability and triggering the system preparation flow.
- Added `TranslationPreparationCoordinator.needsPreparation`, `refreshPreparationStatus(force:)`, `requiresPreparation(force:)`, and `currentPreparationRequest` to support custom preparation UIs.

### Changed
- Updated the demo app to use `TranslationPreparationGate` at the root instead of wiring the preparation flow directly in `RootDemoView`.
- Simplified the demo app startup flow to always configure `AppleTranslationProvider()` for the translation preparation example.
- Updated the README to document the in-app preparation flow, coordinator-based customization, and the new demo usage.

### Changed
- Moved package sources to the standard top-level `Sources/` and `Tests/` layout.
- Removed `DebugLocalizationConfiguration` from the public package surface and kept provider setup centered on `DebugTranslate.configure(provider:)`.
- Improved sync localization ergonomics so `localizeSync()` now falls back to the original text for async-only providers.
- Renamed the sync mock implementation to `MockLocalizationProvider`.

### Added
- Added `DebugLocalizer.canLocalizeSynchronously`.
- Added `DebugLocalizer.clearCache()`.
- Added `DebugTranslate.canLocalizeSynchronously`, `DebugTranslate.clearCache()`, and `DebugTranslate.reset()`.

## [0.2.0] - 2026-03-11

### Added
- Introduced `LocalizationProvider` as the primary public provider protocol.
- Added `DebugTranslate.configure(provider:)` as the global shared configuration entry point.
- Added `String.localize()`, `String.localize(using:)`, `String.localizeSync()`, and `String.localizeSync(using:)`.
- Added `SyncLocalizationProvider` for providers that can localize without async work.
- Added runtime package version access through `DebugLocalizationVersion.current`.

### Changed
- Simplified the default developer-facing API around shared configuration and string-based localization calls.
- Updated the demo app to use the new shared localization flow in both SwiftUI and UIKit.
- `PseudoLocalizationProvider`, `PassthroughLocalizationProvider`, and `MockTranslationProvider` now support sync localization paths.
- `DebugLocalizer` now supports both async and sync localization access while keeping shared usage thread-safe.

### Removed
- Removed the older provider alias and configuration helper APIs that were superseded by the new entry points.

## [0.1.0] - 2026-03-11

### Added
- Initial public baseline for the DebugLocalization package.
- `DebugLocalizationCore` with async localization provider abstractions and `DebugLocalizer`.
- Built-in provider modes for passthrough, pseudo-localization, and mock translation flows.
- `DebugLocalizationTranslationSupport` with Apple Translation integration for supported iOS configurations.
- Translation preparation coordination for checking and downloading language resources before translation.
- Public runtime version constant via `DebugLocalizationVersion.current`.
