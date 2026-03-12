import Foundation
import Testing
@testable import LiveLocalizationCore

@Suite(.serialized)
struct LiveLocalizationCoreTests {
    @Test
    func pseudoLocalizationExpandsText() async throws {
        let provider = PseudoLocalizationProvider()

        let localized = await provider.translate("Remove")

        #expect(localized.contains("["))
        #expect(localized.contains("⟪"))
        #expect(localized.count > "Remove".count)
    }

    @Test
    func stringExtensionUsesConfiguredSharedLocalizer() async {
        defer {
            Task {
                await LiveLocalization.reset()
            }
        }

        await LiveLocalization.configure(provider: PassthroughLocalizationProvider())
        let passthrough = await "Settings".localize()

        await LiveLocalization.configure(provider: PseudoLocalizationProvider())
        let pseudoLocalized = await "Settings".localize()

        #expect(passthrough == "Settings")
        #expect(pseudoLocalized != "Settings")
    }

    @Test
    func asyncLocalizationUsesSyncCapableProvider() async {
        defer {
            Task {
                await LiveLocalization.reset()
            }
        }

        await LiveLocalization.configure(provider: MockLocalizationProvider())

        let localized = await "Settings".localize()

        #expect(localized.contains("Settings"))
    }

    @Test
    func cachedLocalizationReturnsNilForUnknownValue() async {
        let localizer = LiveLocalizer(provider: AsyncOnlyProvider())

        #expect(await localizer.cachedLocalization(for: "Settings") == nil)
    }

    @Test
    func memoryCacheStoreCanBeInjected() async {
        let localizer = LiveLocalizer(
            provider: MockLocalizationProvider(),
            cacheStore: MemoryLocalizationCacheStore()
        )

        let localized = await localizer.localize("Settings")
        let cached = await localizer.cachedLocalization(for: "Settings")

        #expect(localized == cached)
    }

    @Test
    func asyncLocalizationUsesAsyncOnlyProvider() async {
        let localizer = LiveLocalizer(provider: AsyncOnlyProvider())

        let localized = await localizer.localize("Settings")

        #expect(localized == "[async] Settings")
    }

    @Test
    func asyncLocalizationCachesAsyncProviderResults() async {
        let counter = LockedCounter()
        let localizer = LiveLocalizer(provider: CountingAsyncProvider(counter: counter))

        let first = await localizer.localize("Settings")
        let second = await localizer.localize("Settings")

        #expect(first == "[async-1] Settings")
        #expect(second == first)
        #expect(await counter.value == 1)
    }

    @Test
    func localizationRequestAffectsCacheKey() async {
        let counter = LockedCounter()
        let localizer = LiveLocalizer(provider: CountingAsyncProvider(counter: counter))

        let first = await localizer.localize(
            LocalizationRequest(
                sourceText: "Settings",
                targetLanguageIdentifier: "ja",
                context: "settings.title"
            )
        )
        let second = await localizer.localize(
            LocalizationRequest(
                sourceText: "Settings",
                targetLanguageIdentifier: "ja",
                context: "settings.title"
            )
        )
        let third = await localizer.localize(
            LocalizationRequest(
                sourceText: "Settings",
                targetLanguageIdentifier: "fr",
                context: "settings.title"
            )
        )

        #expect(first == second)
        #expect(third != second)
        #expect(await counter.value == 2)
    }

    @Test
    func customProviderReceivesTargetLanguageAndContext() async {
        let localizer = LiveLocalizer(provider: RequestEchoProvider())
        let request = LocalizationRequest(
            sourceText: "Checkout",
            sourceLanguageIdentifier: "en",
            targetLanguageIdentifier: "ja",
            context: "paywall.primary_cta"
        )

        let localized = await localizer.localize(request)

        #expect(localized == "[ja|paywall.primary_cta] Checkout")
    }

    @Test
    func diskCacheStorePersistsAcrossLocalizerInstances() async {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("LiveLocalizationCache.json")
        let counter = LockedCounter()

        let firstLocalizer = LiveLocalizer(
            provider: CountingAsyncProvider(counter: counter),
            cacheStore: DiskLocalizationCacheStore(fileURL: fileURL)
        )
        let secondLocalizer = LiveLocalizer(
            provider: CountingAsyncProvider(counter: counter),
            cacheStore: DiskLocalizationCacheStore(fileURL: fileURL)
        )

        let first = await firstLocalizer.localize(
            LocalizationRequest(
                sourceText: "Settings",
                targetLanguageIdentifier: "ja",
                context: "settings.title"
            )
        )
        let second = await secondLocalizer.localize(
            LocalizationRequest(
                sourceText: "Settings",
                targetLanguageIdentifier: "ja",
                context: "settings.title"
            )
        )

        #expect(first == second)
        #expect(await counter.value == 1)
    }

    @Test
    func localizerReportsSyncCapability() async {
        let syncLocalizer = LiveLocalizer(provider: PseudoLocalizationProvider())
        let asyncLocalizer = LiveLocalizer(provider: AsyncOnlyProvider())

        #expect(await syncLocalizer.canLocalizeSynchronously)
        #expect(await !asyncLocalizer.canLocalizeSynchronously)
    }
}

private struct AsyncOnlyProvider: LocalizationProvider {
    func translate(_ request: LocalizationRequest) async throws -> LocalizationResponse {
        LocalizationResponse(localizedText: "[async] \(request.sourceText)")
    }
}

private actor LockedCounter {
    private var storage = 0

    var value: Int {
        return storage
    }

    func increment() -> Int {
        storage += 1
        return storage
    }
}

private struct CountingAsyncProvider: LocalizationProvider {
    let counter: LockedCounter

    func translate(_ request: LocalizationRequest) async throws -> LocalizationResponse {
        let callCount = await counter.increment()
        return LocalizationResponse(localizedText: "[async-\(callCount)] \(request.sourceText)")
    }
}

private struct RequestEchoProvider: LocalizationProvider {
    func translate(_ request: LocalizationRequest) async throws -> LocalizationResponse {
        let target = request.targetLanguageIdentifier ?? "nil"
        let context = request.context ?? "nil"
        return LocalizationResponse(localizedText: "[\(target)|\(context)] \(request.sourceText)")
    }
}
