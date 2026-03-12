import Foundation

/// An event emitted by the localization runtime for debugging and instrumentation.
public enum LocalizationEvent: Sendable, Equatable {
    case sharedConfigurationStarted
    case sharedConfigurationFinished
    case cacheWarmupStarted
    case cacheWarmupFinished
    case cacheHit(key: String)
    case cacheMiss(key: String)
    case cacheStoreWrite(key: String)
    case cacheInvalidated(key: String)
    case cacheCleared
    case providerTranslationStarted(request: LocalizationRequest)
    case providerTranslationSucceeded(request: LocalizationRequest, localizedText: String)
    case providerTranslationFailed(request: LocalizationRequest, fallbackText: String)
}

/// A logging hook for localization runtime events.
public protocol LocalizationLogger: Sendable {
    func log(_ event: LocalizationEvent) async
}

public extension LocalizationLogger {
    func log(_ event: LocalizationEvent) async {}
}

/// A logger backed by an async closure.
public struct ClosureLocalizationLogger: LocalizationLogger {
    private let handler: @Sendable (LocalizationEvent) async -> Void

    public init(handler: @escaping @Sendable (LocalizationEvent) async -> Void) {
        self.handler = handler
    }

    public func log(_ event: LocalizationEvent) async {
        await handler(event)
    }
}
