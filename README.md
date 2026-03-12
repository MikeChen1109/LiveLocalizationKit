# LiveLocalizationKit

A Swift Package that helps small teams and indie developers ship multilingual SwiftUI and UIKit apps faster.

It provides development-friendly localization workflows, including pseudo-localization and a built-in Apple Translation provider today, with a provider-based design that can be extended to support custom translation APIs.

## Best For

- development-time localization preview
- UI layout validation across languages
- pseudo-localization and mock translation flows
- Apple Translation preparation and live translation testing before formal localization QA

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

await LiveLocalization.configure(provider: AppleTranslationProvider())
let localized = await "Settings".localize()
```

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
await LiveLocalization.configure(provider: MyTranslationProvider())
let text = await "Settings".localize()
```

Or create an explicit localizer with a custom cache store:

```swift
let localizer = LiveLocalizer(
    provider: MyTranslationProvider(),
    cacheStore: DiskLocalizationCacheStore()
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

- `AppleTranslationProvider` requires `iOS 26`
- available languages depend on the system
- language packs may need to be downloaded on device first

If language pack download appears stuck in-app, managing the pack first in Apple's built-in `Translate` app is often more reliable during testing.

## Demo App

See `LiveLocalizationDemo.xcodeproj` for the bundled demo app. The demo sources live under `LiveLocalizationKit/` and cover both SwiftUI and UIKit preview flows.

## License

MIT
