# LiveLocalizationKit

A Swift Package that helps small teams and indie developers add multilingual support to SwiftUI and UIKit apps faster.

It provides a provider-based localization stack with built-in Apple Translation support, UI-ready wrappers, and configurable caching for runtime localization flows and custom translation backends.

## Features

- runtime localization for SwiftUI and UIKit apps
- provider-based architecture for custom translation backends
- built-in Apple Translation support
- SwiftUI `LiveLocalizedText` and UIKit `LiveLocalizedLabel`
- in-memory and disk-backed cache stores
- configurable cache policy with namespacing, provider segmentation, and TTL
- pseudo-localization, passthrough, and mock translation providers
- shared localizer configuration and explicit localizer injection

## Swift Package Manager

Add this repository in Xcode:

```text
https://github.com/MikeChen1109/LiveLocalizationKit.git
```

Available products:

- `LiveLocalizationCore`
- `LiveLocalizationUI`
- `LiveLocalizationTranslationSupport`

## Quick Start

Configure Apple Translation-based preview:

```swift
import LiveLocalizationCore
import LiveLocalizationTranslationSupport

await LiveLocalization.configure(
    provider: AppleTranslationProvider(),
    cacheStore: DiskLocalizationCacheStore(),
    cachePolicy: LocalizationCachePolicy(
        namespace: "preview",
        providerIdentifier: "apple-translation"
    )
)
let localized = await "Settings".localize()
```

`LiveLocalization.configure(...)` is async because shared configuration can prewarm injected cache stores such as `DiskLocalizationCacheStore` before your UI starts reading localized content.

For lightweight development flows, `LiveLocalizationCore` also includes providers such as `PseudoLocalizationProvider`, `MockLocalizationProvider`, and `PassthroughLocalizationProvider`.

## Create Your Own Provider

Custom providers implement `LocalizationProvider` and receive a `LocalizationRequest`.

```swift
import LiveLocalizationCore

struct MyTranslationProvider: LocalizationProvider {
    func translate(_ request: LocalizationRequest) async throws -> LocalizationResponse {
        let targetLanguage = request.targetLanguageIdentifier ?? "en"
        let localizedText = "[\(targetLanguage)] \(request.sourceText)"
        return LocalizationResponse(localizedText: localizedText)
    }
}
```

Use the shared package flow:

```swift
await LiveLocalization.configure(
    provider: MyTranslationProvider(),
    cacheStore: MemoryLocalizationCacheStore(),
    cachePolicy: LocalizationCachePolicy(providerIdentifier: "my-provider")
)
let text = await "Settings".localize()
```

Or create an explicit localizer with a custom cache store:

```swift
let localizer = LiveLocalizer(
    provider: MyTranslationProvider(),
    cacheStore: DiskLocalizationCacheStore(),
    cachePolicy: LocalizationCachePolicy(
        namespace: "preview",
        providerIdentifier: "my-provider",
        entryLifetime: 3600
    )
)
let text = await "Checkout".localize(using: localizer)
```

Or pass more request context when you need it:

```swift
let text = await "Checkout".localize(
    sourceLanguageIdentifier: "en",
    targetLanguageIdentifier: "ja",
    context: "paywall.primary_cta"
)
```

Provider guidance:

- Return `request.sourceText` when you want an explicit fallback.
- Use `targetLanguageIdentifier` and `context` if your backend needs routing or domain-specific prompts.
- If your provider can answer immediately, prefer `SyncLocalizationProvider`.

See [`docs/ProviderGuide.md`](docs/ProviderGuide.md) for a fuller guide to custom provider design.

## Cache Stores

`LiveLocalizationCore` supports pluggable cache stores.

- `MemoryLocalizationCacheStore` keeps results in memory for the current process.
- `DiskLocalizationCacheStore` persists localized text to disk across launches.
- `LocalizationCachePolicy` supports namespacing, provider-aware segmentation, and TTL-based expiration.
- Shared `LiveLocalization.configure(...)` can prewarm an injected cache store before the shared localizer is published.

```swift
let localizer = LiveLocalizer(
    provider: MyTranslationProvider(),
    cacheStore: DiskLocalizationCacheStore(),
    cachePolicy: LocalizationCachePolicy(
        namespace: "preview",
        providerIdentifier: "my-backend",
        entryLifetime: 3600
    )
)
```

## Observability

`LiveLocalizationCore` includes lightweight runtime event hooks for debugging and instrumentation.

You can observe:

- shared configuration start / finish
- cache warmup start / finish
- cache hit / miss / write / invalidation / clear
- provider translation start / success / failure fallback

```swift
let logger = ClosureLocalizationLogger { event in
    print("Localization event:", event)
}

await LiveLocalization.configure(
    provider: MyTranslationProvider(),
    cacheStore: DiskLocalizationCacheStore(),
    cachePolicy: LocalizationCachePolicy(providerIdentifier: "my-provider"),
    logger: logger
)
```

## UI Layer

`LiveLocalizationUI` adds simple view wrappers on top of the core localizer layer.

SwiftUI:

```swift
import SwiftUI
import LiveLocalizationUI

LiveLocalizedText("Continue")
```

UIKit:

```swift
import UIKit
import LiveLocalizationUI

let label = LiveLocalizedLabel()
label.setLocalizedText("Continue")
```

## Apple Translation Preview

If you want a debug flow that checks whether required language packs are available and guides preparation before showing the UI:

```swift
import SwiftUI
import LiveLocalizationTranslationSupport

TranslationPreparationGate {
    ContentView()
}
```

If you need custom presentation logic, use `TranslationPreparationCoordinator` directly.

Notes:

- package products support `iOS 18` and `macOS 15`
- `AppleTranslationProvider` requires `iOS 26` or `macOS 26`
- available languages depend on the system
- language packs may need to be downloaded on device first

If language pack download appears stuck in-app, managing the pack first in Apple's built-in `Translate` app is often more reliable during testing.

## Demo App

See `LiveLocalizationDemo.xcodeproj` for the bundled demo app. The demo sources live under `LiveLocalizationKit/` and cover both SwiftUI and UIKit preview flows.

## License

MIT
