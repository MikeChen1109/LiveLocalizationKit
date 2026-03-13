import Foundation

public enum LiveLocalization {
    private static let sharedStore = SharedLocalizerStore()

    public static func configure(
        provider: any LocalizationProvider,
        cacheStore: any LocalizationCacheStore = MemoryLocalizationCacheStore(),
        cachePolicy: LocalizationCachePolicy = LocalizationCachePolicy(),
        executionPolicy: LocalizationExecutionPolicy = LocalizationExecutionPolicy(),
        logger: (any LocalizationLogger)? = nil
    ) async {
        let localizer = LiveLocalizer(
            provider: provider,
            cacheStore: cacheStore,
            cachePolicy: cachePolicy,
            executionPolicy: executionPolicy,
            logger: logger
        )
        await logger?.log(.sharedConfigurationStarted)
        await localizer.prepareForUse()
        await sharedStore.setLocalizer(localizer)
        await logger?.log(.sharedConfigurationFinished)
    }

    public static func configure(localizer: LiveLocalizer) async {
        await sharedStore.setLocalizer(localizer)
    }

    public static var localizer: LiveLocalizer {
        get async {
            await sharedStore.localizer
        }
    }

    public static var canLocalizeSynchronously: Bool {
        get async {
            let localizer = await localizer
            return await localizer.canLocalizeSynchronously
        }
    }

    public static func clearCache() async {
        let localizer = await localizer
        await localizer.clearCache()
    }

    public static func reset() async {
        await configure(provider: PseudoLocalizationProvider())
    }
}

private actor SharedLocalizerStore {
    private var currentLocalizer = LiveLocalizer(provider: PseudoLocalizationProvider())

    var localizer: LiveLocalizer {
        return currentLocalizer
    }

    func setLocalizer(_ localizer: LiveLocalizer) {
        currentLocalizer = localizer
    }
}
