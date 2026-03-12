import Foundation

public actor LiveLocalizer {
    private let provider: any LocalizationProvider
    private let cacheStore: any LocalizationCacheStore
    private let cachePolicy: LocalizationCachePolicy
    private let logger: (any LocalizationLogger)?

    public init(
        provider: any LocalizationProvider,
        cacheStore: any LocalizationCacheStore = MemoryLocalizationCacheStore(),
        cachePolicy: LocalizationCachePolicy = LocalizationCachePolicy(),
        logger: (any LocalizationLogger)? = nil
    ) {
        self.provider = provider
        self.cacheStore = cacheStore
        self.cachePolicy = cachePolicy
        self.logger = logger
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

        await logger?.log(.cacheMiss(key: cacheKey))
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
}
