import Foundation

public actor LiveLocalizer {
    private let provider: any LocalizationProvider
    private let cacheStore: any LocalizationCacheStore
    private let cachePolicy: LocalizationCachePolicy
    private let executionPolicy: LocalizationExecutionPolicy
    private let logger: (any LocalizationLogger)?
    private var inFlightLocalizations: [LocalizationRequest: Task<String, Never>] = [:]
    private let asyncRequestLimiter: AsyncRequestLimiter
    private let batchRequestCoordinator: BatchRequestCoordinator

    public init(
        provider: any LocalizationProvider,
        cacheStore: any LocalizationCacheStore = MemoryLocalizationCacheStore(),
        cachePolicy: LocalizationCachePolicy = LocalizationCachePolicy(),
        executionPolicy: LocalizationExecutionPolicy = LocalizationExecutionPolicy(),
        logger: (any LocalizationLogger)? = nil
    ) {
        self.provider = provider
        self.cacheStore = cacheStore
        self.cachePolicy = cachePolicy
        self.executionPolicy = executionPolicy
        self.logger = logger
        self.asyncRequestLimiter = AsyncRequestLimiter(
            maxConcurrentOperations: executionPolicy.maxConcurrentAsyncRequests
        )
        self.batchRequestCoordinator = BatchRequestCoordinator(
            batchWindow: executionPolicy.batchWindow,
            maxBatchSize: executionPolicy.maxBatchSize
        )
    }

    public var canLocalizeSynchronously: Bool {
        provider is any SyncLocalizationProvider
    }

    public func prepareForUse() async {
        await logger?.log(.cacheWarmupStarted)
        await cacheStore.prepareForUse()
        await logger?.log(.cacheWarmupFinished)
    }

    /// Returns a cached localized value for the given text if one is already available.
    public func cachedLocalization(for text: String) async -> String? {
        await cachedLocalization(for: LocalizationRequest(sourceText: text))
    }

    /// Returns a cached localized value for the given request if one is already available.
    public func cachedLocalization(for request: LocalizationRequest) async -> String? {
        await cacheStore.cacheEntry(forKey: cacheKey(for: request))?.localizedText
    }

    public func localize(_ text: String) async -> String {
        await localize(LocalizationRequest(sourceText: text))
    }

    public func localize(_ request: LocalizationRequest) async -> String {
        let cacheKey = cacheKey(for: request)
        if let cached = await cacheStore.cacheEntry(forKey: cacheKey)?.localizedText {
            await logger?.log(.cacheHit(key: cacheKey))
            return cached
        }

        if let inFlightTask = inFlightLocalizations[request] {
            return await inFlightTask.value
        }

        await logger?.log(.cacheMiss(key: cacheKey))
        let task = Task<String, Never> {
            if self.provider is any SyncLocalizationProvider {
                return await self.performLocalization(request, cacheKey: cacheKey)
            }

            if let batchProvider = self.provider as? any BatchLocalizationProvider {
                return await self.batchRequestCoordinator.translate(
                    request,
                    groupIdentifier: batchProvider.batchGroupIdentifier(for: request)
                ) { requests in
                    await self.performBatchLocalization(requests, using: batchProvider)
                }
            }

            return await self.asyncRequestLimiter.run {
                await self.performLocalization(request, cacheKey: cacheKey)
            }
        }
        inFlightLocalizations[request] = task

        let localizedText = await task.value
        inFlightLocalizations[request] = nil
        return localizedText
    }

    public func invalidateCachedLocalization(for text: String) async {
        await invalidateCachedLocalization(for: LocalizationRequest(sourceText: text))
    }

    public func invalidateCachedLocalization(for request: LocalizationRequest) async {
        let key = cacheKey(for: request)
        await cacheStore.removeLocalizedText(forKey: key)
        await logger?.log(.cacheInvalidated(key: key))
    }

    public func clearCache() async {
        await cacheStore.removeAllLocalizedText()
        await logger?.log(.cacheCleared)
    }

    private func cacheKey(for request: LocalizationRequest) -> String {
        let namespace = cachePolicy.namespace ?? ""
        let providerIdentifier = cachePolicy.providerIdentifier ?? ""
        let targetLanguageIdentifier = request.targetLanguageIdentifier ?? currentAppLanguageIdentifier()
        let sourceLanguageIdentifier = request.sourceLanguageIdentifier ?? ""
        let context = request.context ?? ""
        return "\(namespace)|\(providerIdentifier)|\(sourceLanguageIdentifier)|\(targetLanguageIdentifier)|\(context)|\(request.sourceText)"
    }

    private func cacheEntry(for localizedText: String) -> LocalizationCacheEntry {
        let expirationDate = cachePolicy.entryLifetime.map { Date().addingTimeInterval($0) }
        return LocalizationCacheEntry(
            localizedText: localizedText,
            expirationDate: expirationDate
        )
    }

    private func performLocalization(_ request: LocalizationRequest, cacheKey: String) async -> String {
        await logger?.log(.providerTranslationStarted(request: request))

        if let syncProvider = provider as? any SyncLocalizationProvider {
            do {
                let response = try syncProvider.translateSynchronously(request)
                await cacheStore.setCacheEntry(cacheEntry(for: response.localizedText), forKey: cacheKey)
                await logger?.log(.cacheStoreWrite(key: cacheKey))
                await logger?.log(.providerTranslationSucceeded(request: request, localizedText: response.localizedText))
                return response.localizedText
            } catch {
                await logger?.log(.providerTranslationFailed(request: request, fallbackText: request.sourceText))
                return request.sourceText
            }
        }

        do {
            let response = try await provider.translate(request)
            await cacheStore.setCacheEntry(cacheEntry(for: response.localizedText), forKey: cacheKey)
            await logger?.log(.cacheStoreWrite(key: cacheKey))
            await logger?.log(.providerTranslationSucceeded(request: request, localizedText: response.localizedText))
            return response.localizedText
        } catch {
            await logger?.log(.providerTranslationFailed(request: request, fallbackText: request.sourceText))
            return request.sourceText
        }
    }

    private func performBatchLocalization(
        _ requests: [LocalizationRequest],
        using provider: any BatchLocalizationProvider
    ) async -> [String] {
        for request in requests {
            await logger?.log(.providerTranslationStarted(request: request))
        }

        do {
            let responses = try await asyncRequestLimiter.runThrowing {
                try await provider.translateBatch(requests)
            }

            guard responses.count == requests.count else {
                for request in requests {
                    await logger?.log(.providerTranslationFailed(request: request, fallbackText: request.sourceText))
                }
                return requests.map(\.sourceText)
            }

            var localizedTexts: [String] = []
            localizedTexts.reserveCapacity(requests.count)

            for (request, response) in zip(requests, responses) {
                let cacheKey = cacheKey(for: request)
                await cacheStore.setCacheEntry(cacheEntry(for: response.localizedText), forKey: cacheKey)
                await logger?.log(.cacheStoreWrite(key: cacheKey))
                await logger?.log(.providerTranslationSucceeded(request: request, localizedText: response.localizedText))
                localizedTexts.append(response.localizedText)
            }

            return localizedTexts
        } catch {
            for request in requests {
                await logger?.log(.providerTranslationFailed(request: request, fallbackText: request.sourceText))
            }
            return requests.map(\.sourceText)
        }
    }
}

private actor AsyncRequestLimiter {
    private let maxConcurrentOperations: Int
    private var runningOperations = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(maxConcurrentOperations: Int) {
        self.maxConcurrentOperations = max(1, maxConcurrentOperations)
    }

    func run<T: Sendable>(_ operation: @escaping @Sendable () async -> T) async -> T {
        await acquire()
        defer { release() }
        return await operation()
    }

    func runThrowing<T: Sendable>(_ operation: @escaping @Sendable () async throws -> T) async throws -> T {
        await acquire()
        defer { release() }
        return try await operation()
    }

    private func acquire() async {
        guard runningOperations < maxConcurrentOperations else {
            await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
            return
        }

        runningOperations += 1
    }

    private func release() {
        if let continuation = waiters.first {
            waiters.removeFirst()
            continuation.resume()
            return
        }

        runningOperations -= 1
    }
}

/// Collects compatible requests for a short window so batch-capable providers can translate them together.
private actor BatchRequestCoordinator {
    private struct BucketKey: Hashable {
        let groupIdentifier: String
    }

    private struct PendingRequest {
        let request: LocalizationRequest
        let continuation: CheckedContinuation<String, Never>
    }

    private struct Bucket {
        var requests: [PendingRequest]
    }

    private let batchWindow: Duration
    private let maxBatchSize: Int
    private var buckets: [BucketKey: Bucket] = [:]
    private var scheduledFlushes: Set<BucketKey> = []

    init(batchWindow: Duration, maxBatchSize: Int) {
        self.batchWindow = batchWindow
        self.maxBatchSize = max(1, maxBatchSize)
    }

    func translate(
        _ request: LocalizationRequest,
        groupIdentifier: String,
        executor: @escaping @Sendable ([LocalizationRequest]) async -> [String]
    ) async -> String {
        await withCheckedContinuation { continuation in
            let key = BucketKey(groupIdentifier: groupIdentifier)
            let pendingRequest = PendingRequest(request: request, continuation: continuation)

            if var bucket = buckets[key] {
                bucket.requests.append(pendingRequest)
                buckets[key] = bucket
            } else {
                buckets[key] = Bucket(requests: [pendingRequest])
            }

            if scheduledFlushes.insert(key).inserted {
                Task {
                    try? await Task.sleep(for: batchWindow)
                    await flush(for: key, executor: executor)
                }
            }

            if buckets[key]?.requests.count ?? 0 >= maxBatchSize {
                Task {
                    await flush(for: key, executor: executor)
                }
            }
        }
    }

    private func flush(
        for key: BucketKey,
        executor: @escaping @Sendable ([LocalizationRequest]) async -> [String]
    ) async {
        guard let bucket = buckets.removeValue(forKey: key) else {
            return
        }
        scheduledFlushes.remove(key)

        let requests = bucket.requests.map(\.request)
        let localizedTexts = await executor(requests)

        for (index, pendingRequest) in bucket.requests.enumerated() {
            let localizedText = index < localizedTexts.count ? localizedTexts[index] : pendingRequest.request.sourceText
            pendingRequest.continuation.resume(returning: localizedText)
        }
    }
}
