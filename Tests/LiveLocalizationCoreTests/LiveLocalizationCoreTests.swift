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

        await LiveLocalization.configure(
            provider: PassthroughLocalizationProvider(),
            cacheStore: MemoryLocalizationCacheStore(),
            cachePolicy: LocalizationCachePolicy(namespace: "passthrough")
        )
        let passthrough = await "Settings".localize()

        await LiveLocalization.configure(
            provider: PseudoLocalizationProvider(),
            cacheStore: MemoryLocalizationCacheStore(),
            cachePolicy: LocalizationCachePolicy(namespace: "pseudo")
        )
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

        await LiveLocalization.configure(
            provider: MockLocalizationProvider(),
            cacheStore: MemoryLocalizationCacheStore(),
            cachePolicy: LocalizationCachePolicy(providerIdentifier: "mock")
        )

        let localized = await "Settings".localize()

        #expect(localized.contains("Settings"))
    }

    @Test
    func sharedConfigureAcceptsCacheStoreAndPolicy() async {
        defer {
            Task {
                await LiveLocalization.reset()
            }
        }

        await LiveLocalization.configure(
            provider: MockLocalizationProvider(),
            cacheStore: MemoryLocalizationCacheStore(),
            cachePolicy: LocalizationCachePolicy(
                namespace: "shared",
                providerIdentifier: "mock"
            )
        )

        let first = await "Settings".localize(
            targetLanguageIdentifier: "ja",
            context: "settings.title"
        )
        let second = await "Settings".localize(
            targetLanguageIdentifier: "ja",
            context: "settings.title"
        )

        #expect(first == second)
    }

    @Test
    func sharedConfigurePrewarmsDiskCacheStore() async {
        defer {
            Task {
                await LiveLocalization.reset()
            }
        }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("LiveLocalizationCache.json")
        let request = LocalizationRequest(
            sourceText: "Settings",
            targetLanguageIdentifier: "ja",
            context: "settings.title"
        )
        let counter = LockedCounter()

        let seedLocalizer = LiveLocalizer(
            provider: CountingAsyncProvider(counter: counter),
            cacheStore: DiskLocalizationCacheStore(fileURL: fileURL),
            cachePolicy: LocalizationCachePolicy(
                namespace: "shared",
                providerIdentifier: "seed"
            )
        )
        _ = await seedLocalizer.localize(request)

        await LiveLocalization.configure(
            provider: CountingAsyncProvider(counter: counter),
            cacheStore: DiskLocalizationCacheStore(fileURL: fileURL),
            cachePolicy: LocalizationCachePolicy(
                namespace: "shared",
                providerIdentifier: "seed"
            )
        )

        let localized = await "Settings".localize(
            targetLanguageIdentifier: "ja",
            context: "settings.title"
        )

        #expect(localized == "[async-1] Settings")
        #expect(await counter.value == 1)
    }

    @Test
    func loggerCapturesSharedConfigurationAndCacheWarmup() async {
        defer {
            Task {
                await LiveLocalization.reset()
            }
        }

        let logger = EventRecorder()

        await LiveLocalization.configure(
            provider: MockLocalizationProvider(),
            cacheStore: MemoryLocalizationCacheStore(),
            cachePolicy: LocalizationCachePolicy(providerIdentifier: "mock"),
            logger: logger
        )

        let events = await logger.events

        #expect(events == [
            .sharedConfigurationStarted,
            .cacheWarmupStarted,
            .cacheWarmupFinished,
            .sharedConfigurationFinished
        ])
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
    func cachePolicySegmentsByNamespaceAndProviderIdentifier() async {
        let sharedCacheStore = MemoryLocalizationCacheStore()
        let counter = LockedCounter()

        let firstLocalizer = LiveLocalizer(
            provider: CountingAsyncProvider(counter: counter),
            cacheStore: sharedCacheStore,
            cachePolicy: LocalizationCachePolicy(
                namespace: "preview",
                providerIdentifier: "provider-a"
            )
        )
        let secondLocalizer = LiveLocalizer(
            provider: CountingAsyncProvider(counter: counter),
            cacheStore: sharedCacheStore,
            cachePolicy: LocalizationCachePolicy(
                namespace: "preview",
                providerIdentifier: "provider-b"
            )
        )

        let first = await firstLocalizer.localize("Settings")
        let second = await secondLocalizer.localize("Settings")

        #expect(first != second)
        #expect(await counter.value == 2)
    }

    @Test
    func cachePolicyEntryLifetimeExpiresEntries() async throws {
        let counter = LockedCounter()
        let localizer = LiveLocalizer(
            provider: CountingAsyncProvider(counter: counter),
            cacheStore: MemoryLocalizationCacheStore(),
            cachePolicy: LocalizationCachePolicy(entryLifetime: 0.05)
        )

        let first = await localizer.localize("Settings")
        try await Task.sleep(nanoseconds: 120_000_000)
        let second = await localizer.localize("Settings")

        #expect(first != second)
        #expect(await counter.value == 2)
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
    func concurrentLocalizationSharesInFlightWorkForIdenticalRequests() async {
        let counter = LockedCounter()
        let localizer = LiveLocalizer(provider: SlowCountingAsyncProvider(counter: counter))
        let request = LocalizationRequest(
            sourceText: "Settings",
            targetLanguageIdentifier: "ja",
            context: "settings.title"
        )

        await withTaskGroup(of: String.self) { group in
            for _ in 0..<8 {
                group.addTask {
                    await localizer.localize(request)
                }
            }

            var results: [String] = []
            for await result in group {
                results.append(result)
            }

            #expect(Set(results).count == 1)
        }

        #expect(await counter.value == 1)
    }

    @Test
    func loggerCapturesCacheMissSuccessWriteAndCacheHit() async {
        let counter = LockedCounter()
        let logger = EventRecorder()
        let localizer = LiveLocalizer(
            provider: CountingAsyncProvider(counter: counter),
            logger: logger
        )

        let request = LocalizationRequest(sourceText: "Settings")
        _ = await localizer.localize(request)
        _ = await localizer.localize(request)

        let events = await logger.events

        #expect(events.contains(where: {
            if case .cacheMiss = $0 { return true }
            return false
        }))
        #expect(events.contains(where: {
            if case .providerTranslationSucceeded = $0 { return true }
            return false
        }))
        #expect(events.contains(where: {
            if case .cacheStoreWrite = $0 { return true }
            return false
        }))
        #expect(events.contains(where: {
            if case .cacheHit = $0 { return true }
            return false
        }))
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
    func invalidateCachedLocalizationRemovesSingleRequest() async {
        let counter = LockedCounter()
        let logger = EventRecorder()
        let localizer = LiveLocalizer(
            provider: CountingAsyncProvider(counter: counter),
            logger: logger
        )
        let request = LocalizationRequest(
            sourceText: "Settings",
            targetLanguageIdentifier: "ja",
            context: "settings.title"
        )

        let first = await localizer.localize(request)
        await localizer.invalidateCachedLocalization(for: request)
        let second = await localizer.localize(request)

        #expect(first != second)
        #expect(await counter.value == 2)
        let events = await logger.events
        #expect(events.contains(where: {
            if case .cacheInvalidated = $0 { return true }
            return false
        }))
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

    @Test
    func loggerCapturesProviderFailureFallback() async {
        let logger = EventRecorder()
        let localizer = LiveLocalizer(
            provider: FailingProvider(),
            logger: logger
        )

        let localized = await localizer.localize("Settings")

        #expect(localized == "Settings")
        let events = await logger.events
        #expect(events.contains(where: {
            if case .providerTranslationFailed(_, let fallbackText) = $0 {
                return fallbackText == "Settings"
            }
            return false
        }))
    }

    @Test
    func executionPolicyLimitsConcurrentAsyncRequestsAcrossDifferentRequests() async {
        let tracker = ConcurrencyTracker()
        let localizer = LiveLocalizer(
            provider: TrackingAsyncProvider(tracker: tracker),
            executionPolicy: LocalizationExecutionPolicy(maxConcurrentAsyncRequests: 2)
        )

        await withTaskGroup(of: String.self) { group in
            for index in 0..<6 {
                group.addTask {
                    await localizer.localize("Item \(index)")
                }
            }

            for await _ in group {}
        }

        #expect(await tracker.maxConcurrentOperations == 2)
    }

    @Test
    func batchCapableCustomProviderCoalescesSiblingRequests() async {
        let recorder = BatchProviderRecorder()
        let localizer = LiveLocalizer(
            provider: RecordingBatchProvider(recorder: recorder),
            executionPolicy: LocalizationExecutionPolicy(
                maxConcurrentAsyncRequests: 4,
                batchWindow: .milliseconds(30),
                maxBatchSize: 16
            )
        )

        let results = await withTaskGroup(of: String.self, returning: [String].self) { group in
            group.addTask {
                await localizer.localize(
                    LocalizationRequest(sourceText: "Settings", targetLanguageIdentifier: "ja")
                )
            }
            group.addTask {
                await localizer.localize(
                    LocalizationRequest(sourceText: "Delete", targetLanguageIdentifier: "ja")
                )
            }

            var values: [String] = []
            for await value in group {
                values.append(value)
            }
            return values
        }

        #expect(Set(results) == ["[batch] Settings", "[batch] Delete"])
        #expect(await recorder.recordedBatches == [["Settings", "Delete"]])
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

private struct SlowCountingAsyncProvider: LocalizationProvider {
    let counter: LockedCounter

    func translate(_ request: LocalizationRequest) async throws -> LocalizationResponse {
        let callCount = await counter.increment()
        try? await Task.sleep(for: .milliseconds(50))
        return LocalizationResponse(localizedText: "[async-\(callCount)] \(request.sourceText)")
    }
}

private actor ConcurrencyTracker {
    private var currentOperations = 0
    private(set) var maxConcurrentOperations = 0

    func begin() {
        currentOperations += 1
        maxConcurrentOperations = max(maxConcurrentOperations, currentOperations)
    }

    func end() {
        currentOperations -= 1
    }
}

private actor BatchProviderRecorder {
    private(set) var recordedBatches: [[String]] = []

    func record(_ batch: [String]) {
        recordedBatches.append(batch)
    }
}

private struct TrackingAsyncProvider: LocalizationProvider {
    let tracker: ConcurrencyTracker

    func translate(_ request: LocalizationRequest) async throws -> LocalizationResponse {
        await tracker.begin()
        try? await Task.sleep(for: .milliseconds(50))
        await tracker.end()
        return LocalizationResponse(localizedText: "[tracked] \(request.sourceText)")
    }
}

private struct RecordingBatchProvider: BatchLocalizationProvider {
    let recorder: BatchProviderRecorder

    func batchGroupIdentifier(for request: LocalizationRequest) -> String {
        request.targetLanguageIdentifier ?? "default"
    }

    func translateBatch(_ requests: [LocalizationRequest]) async throws -> [LocalizationResponse] {
        await recorder.record(requests.map(\.sourceText))
        try? await Task.sleep(for: .milliseconds(50))
        return requests.map { request in
            LocalizationResponse(localizedText: "[batch] \(request.sourceText)")
        }
    }

    func translate(_ request: LocalizationRequest) async throws -> LocalizationResponse {
        LocalizationResponse(localizedText: "[single] \(request.sourceText)")
    }
}

private struct RequestEchoProvider: LocalizationProvider {
    func translate(_ request: LocalizationRequest) async throws -> LocalizationResponse {
        let target = request.targetLanguageIdentifier ?? "nil"
        let context = request.context ?? "nil"
        return LocalizationResponse(localizedText: "[\(target)|\(context)] \(request.sourceText)")
    }
}

private struct FailingProvider: LocalizationProvider {
    func translate(_ request: LocalizationRequest) async throws -> LocalizationResponse {
        throw LocalizationTestError.expectedFailure
    }
}

private enum LocalizationTestError: Error {
    case expectedFailure
}

private actor EventRecorder: LocalizationLogger {
    private(set) var events: [LocalizationEvent] = []

    func log(_ event: LocalizationEvent) async {
        events.append(event)
    }
}
