# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project follows Semantic Versioning.

## [Unreleased]

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
