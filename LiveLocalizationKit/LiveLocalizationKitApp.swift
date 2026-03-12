import SwiftUI
import LiveLocalizationCore
import LiveLocalizationTranslationSupport

@main
struct LiveLocalizationKitApp: App {
    private let shouldPresentPreparationGate: Bool
    @State private var isConfigured = false

    init() {
        shouldPresentPreparationGate = true
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isConfigured {
                    RootDemoView(shouldPresentPreparationGate: shouldPresentPreparationGate)
                } else {
                    ProgressView()
                }
            }
            .task {
                guard !isConfigured else { return }
                await LiveLocalization.configure(
                    provider: AppleTranslationProvider(),
                    cacheStore: DiskLocalizationCacheStore(),
                    cachePolicy: LocalizationCachePolicy(
                        namespace: "demo",
                        providerIdentifier: "apple-translation"
                    )
                )
                isConfigured = true
            }
        }
    }
}
