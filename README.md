# Debug Localization Preview Tool

A Swift Package for previewing multilingual UI during development.

Use it to quickly render SwiftUI or UIKit screens in other languages, catch truncation and layout issues early, and reduce the setup cost of using Apple Translation in debug builds.

## Best For

- debug-only localization preview
- UI layout validation across languages
- rapid iteration before formal localization QA

## Swift Package Manager

Add this repository in Xcode:

```text
https://github.com/MikeChen1109/DebugLocalizationPreviewTool.git
```

Available products:

- `DebugLocalizationCore`
- `DebugLocalizationTranslationSupport`

## Quick Start

Configure a provider once:

```swift
import DebugLocalizationCore

DebugTranslate.configure(provider: PseudoLocalizationProvider())
let localized = await "Settings".localize()
```

If you want Apple Translation-based preview:

```swift
import DebugLocalizationCore
import DebugLocalizationTranslationSupport

DebugTranslate.configure(provider: AppleTranslationProvider())
let localized = await "Settings".localize()
```

## Apple Translation Preview

If you want a debug flow that checks whether required language packs are available and guides preparation before showing the UI:

```swift
import SwiftUI
import DebugLocalizationTranslationSupport

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

See the example project in `DebugLocalizationDemo/` for a simple preview setup covering both SwiftUI and UIKit.

## License

MIT
