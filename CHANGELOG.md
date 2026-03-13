# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project follows Semantic Versioning.

## [Unreleased]

## [0.7.0] - 2026-03-13

### Added
- Added `BatchLocalizationProvider` so compatible requests can be translated through a single backend batch call.
- Added `LocalizationExecutionPolicy` to control async request throttling, batch collection window, and batch size limits.
- Added batching and concurrency coverage in core tests, including grouped request validation for batch-capable providers.

### Changed
- Updated `LiveLocalizer` to throttle async provider work through a shared execution limiter.
- Updated `LiveLocalizer` to collect compatible requests into short-lived batches before calling batch-capable providers.
- Updated `AppleTranslationProvider` to participate in the new batch translation flow.
- Updated README guidance to document batch providers and execution policy tuning.

## [0.6.0] - 2026-03-13

### Added
- Added `LiveLocalizationPhase` as the shared UI-layer state model for loading and loaded text.
- Added `LiveLocalizationCompletion` for completion callbacks from SwiftUI and UIKit wrappers.
- Added SwiftUI `LiveLocalizedText.placeholder { ... }` for loading-time placeholder presentation.
- Added SwiftUI `LiveLocalizedText.onProgress(...)` and `LiveLocalizedText.onCompletion(...)`.
- Added UIKit `LiveLocalizedLabel` progress and completion handlers, including the current label instance in callbacks.

### Changed
- Simplified `LiveLocalizedText` to use a default text presentation and event-driven customization instead of custom content rendering.
- Updated `LiveLocalizedLabel` to stay blank while loading instead of showing the source string first.
- Updated the demo app to showcase multiline wrapper content, loading placeholders, and progress/completion-driven UI updates.
- Updated README examples to reflect the current UI wrapper customization model.

### Removed
- Removed `LiveLocalizationTextAnimation` and the public animation configuration surface from UI wrappers.
- Removed the previous SwiftUI and UIKit animation customization flow in favor of placeholder/progress/completion APIs.

## [0.5.0] - 2026-03-13

### Added
- Added pluggable cache store support with `MemoryLocalizationCacheStore` and `DiskLocalizationCacheStore`.
- Added `LocalizationCachePolicy` for namespacing, provider-aware cache segmentation, and TTL-based expiration.
- Added cache prewarming during shared configuration for persistent cache stores.
- Added `LocalizationEvent`, `LocalizationLogger`, and `ClosureLocalizationLogger` for runtime observability.
- Added a demo event log tab to inspect shared configuration, cache, and provider activity.
- Added provider documentation for custom backends, cache configuration, and observability hooks.

### Changed
- Expanded `LiveLocalization.configure(...)` to accept cache store, cache policy, and logger injection.
- Refined package platform support to `iOS 18` and `macOS 15` while keeping `AppleTranslationProvider` gated to `iOS 26` and `macOS 26`.
- Updated README and demo content to reflect runtime localization flows, configurable caching, and observability features.

## [0.4.0] - 2026-03-13

### Added
- Added the new `LiveLocalizationUI` product for UI-level localization wrappers.
- Added `LiveLocalizedText` for SwiftUI.
- Added `LiveLocalizedLabel` for UIKit.
- Added `LiveLocalizationTextAnimation` with `.none` and `.fade` styles.
- Added `LocalizationRequest` and `LocalizationResponse` to support richer custom provider implementations.
- Added `LocalizationCacheStore`, `MemoryLocalizationCacheStore`, and `DiskLocalizationCacheStore`.
- Added `LocalizationCachePolicy` for namespacing, provider-aware cache segmentation, and TTL-based expiration.
- Added UI-layer request coordination tests and demo coverage for the new wrappers.

### Changed
- Moved shared localization state to actor-based concurrency instead of relying on `@unchecked Sendable`.
- Updated `LiveLocalization` shared configuration flow to async usage.
- Updated the provider contract so custom backends can receive source language, target language, and context data.
- Updated `LiveLocalizer` to support injected cache stores and disk-backed persistence.
- Updated `LiveLocalizer` to support request-level cache invalidation and configurable cache expiration behavior.
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
