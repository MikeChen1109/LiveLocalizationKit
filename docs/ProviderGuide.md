# Provider Guide

`LiveLocalizationKit` is designed so you can plug in your own translation backend without changing the UI layer or the shared localizer flow.

## Overview

Custom providers conform to `LocalizationProvider` and translate a `LocalizationRequest` into a `LocalizationResponse`.

```swift
import LiveLocalizationCore

struct MyTranslationProvider: LocalizationProvider {
    func translate(_ request: LocalizationRequest) async throws -> LocalizationResponse {
        let localizedText = request.sourceText
        return LocalizationResponse(localizedText: localizedText)
    }
}
```

Use it with the shared flow:

```swift
await LiveLocalization.configure(
    provider: MyTranslationProvider(),
    cacheStore: DiskLocalizationCacheStore(),
    cachePolicy: LocalizationCachePolicy(
        namespace: "preview",
        providerIdentifier: "my-provider"
    )
)
let localized = await "Settings".localize()
```

Or create an explicit localizer:

```swift
let localizer = LiveLocalizer(provider: MyTranslationProvider())
let localized = await "Checkout".localize(using: localizer)
```

## Request Model

`LocalizationRequest` contains:

- `sourceText`: the original text to translate
- `sourceLanguageIdentifier`: optional source language hint
- `targetLanguageIdentifier`: optional destination language hint
- `context`: optional domain or UI context

Example:

```swift
let localized = await "Checkout".localize(
    sourceLanguageIdentifier: "en",
    targetLanguageIdentifier: "ja",
    context: "paywall.primary_cta"
)
```

## Recommended Fallback Behavior

If your backend fails, the safest default is to fall back to `request.sourceText`.

```swift
struct SafeProvider: LocalizationProvider {
    func translate(_ request: LocalizationRequest) async throws -> LocalizationResponse {
        do {
            let localizedText = try await callBackend(with: request)
            return LocalizationResponse(localizedText: localizedText)
        } catch {
            return LocalizationResponse(localizedText: request.sourceText)
        }
    }

    private func callBackend(with request: LocalizationRequest) async throws -> String {
        request.sourceText
    }
}
```

## When To Use SyncLocalizationProvider

Use `SyncLocalizationProvider` if your provider can answer immediately and does not require async work.

Good examples:

- pseudo-localization
- passthrough behavior
- deterministic mock translations
- local dictionary lookups

```swift
struct DictionaryProvider: SyncLocalizationProvider {
    let values: [String: String]

    func translateSynchronously(_ request: LocalizationRequest) throws -> LocalizationResponse {
        let localizedText = values[request.sourceText] ?? request.sourceText
        return LocalizationResponse(localizedText: localizedText)
    }
}
```

## Using Context Well

`context` is useful when the same source string can mean different things in different screens or product areas.

Examples:

- `paywall.primary_cta`
- `settings.delete_button`
- `checkout.summary_title`

If your backend supports prompts, domains, or route selection, `context` is the right place to attach that information.

## Cache Behavior

`LiveLocalizer` caches results using:

- source text
- source language identifier
- target language identifier
- context

This means the same source string can safely produce different cached values when the language or UI context changes.

## Design Recommendations

- Keep providers stateless when possible.
- Treat `targetLanguageIdentifier` as the strongest routing signal.
- Use `context` for domain-specific prompts or glossary selection.
- Return the source text when you need a predictable fallback.
- Keep auth, retry, and rate-limit handling inside the provider implementation rather than pushing that complexity into the UI layer.
