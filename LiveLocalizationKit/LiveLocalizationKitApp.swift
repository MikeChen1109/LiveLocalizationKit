import SwiftUI
import LiveLocalizationCore
import LiveLocalizationTranslationSupport

@main
struct LiveLocalizationKitApp: App {
    private let shouldPresentPreparationGate: Bool
    private let eventStore = DemoLocalizationEventStore()
    @State private var isConfigured = false

    init() {
        shouldPresentPreparationGate = true
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isConfigured {
                    TranslationPreparationGate(isEnabled: shouldPresentPreparationGate) {
                        MarketingLocalizationDemoView()
                    }
                } else {
                    ProgressView()
                }
            }
            .task {
                guard !isConfigured else { return }
                await LiveLocalization.configure(
                    provider: AppleTranslationProvider(),
//                    cacheStore: DiskLocalizationCacheStore(),
                    cachePolicy: LocalizationCachePolicy(
                        namespace: "demo",
                        providerIdentifier: "apple-translation"
                    ),
                    logger: ClosureLocalizationLogger { event in
                        await eventStore.record(event)
                    }
                )
                isConfigured = true
            }
        }
    }
}
