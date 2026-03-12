import Foundation

public actor LiveLocalizer {
    private let provider: any LocalizationProvider
    private let cacheStore: any LocalizationCacheStore

    public init(
        provider: any LocalizationProvider,
        cacheStore: any LocalizationCacheStore = MemoryLocalizationCacheStore()
    ) {
        self.provider = provider
        self.cacheStore = cacheStore
    }

    public var canLocalizeSynchronously: Bool {
        provider is any SyncLocalizationProvider
    }

    /// Returns a cached localized value for the given text if one is already available.
    public func cachedLocalization(for text: String) async -> String? {
        await cacheStore.localizedText(forKey: cacheKey(for: LocalizationRequest(sourceText: text)))
    }

    /// Returns a cached localized value for the given request if one is already available.
    public func cachedLocalization(for request: LocalizationRequest) async -> String? {
        await cacheStore.localizedText(forKey: cacheKey(for: request))
    }

    public func localize(_ text: String) async -> String {
        await localize(LocalizationRequest(sourceText: text))
    }

    public func localize(_ request: LocalizationRequest) async -> String {
        let cacheKey = cacheKey(for: request)
        if let cached = await cacheStore.localizedText(forKey: cacheKey) {
            return cached
        }

        if let syncProvider = provider as? any SyncLocalizationProvider {
            do {
                let response = try syncProvider.translateSynchronously(request)
                await cacheStore.setLocalizedText(response.localizedText, forKey: cacheKey)
                return response.localizedText
            } catch {
                return request.sourceText
            }
        }

        do {
            let response = try await provider.translate(request)
            await cacheStore.setLocalizedText(response.localizedText, forKey: cacheKey)
            return response.localizedText
        } catch {
            return request.sourceText
        }
    }

    public func clearCache() async {
        await cacheStore.removeAllLocalizedText()
    }

    private func cacheKey(for request: LocalizationRequest) -> String {
        let targetLanguageIdentifier = request.targetLanguageIdentifier ?? currentAppLanguageIdentifier()
        let sourceLanguageIdentifier = request.sourceLanguageIdentifier ?? ""
        let context = request.context ?? ""
        return "\(sourceLanguageIdentifier)|\(targetLanguageIdentifier)|\(context)|\(request.sourceText)"
    }
}
