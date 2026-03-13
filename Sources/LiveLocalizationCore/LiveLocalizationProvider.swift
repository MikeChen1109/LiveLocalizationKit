import Foundation

/// A localization request passed into a provider implementation.
public struct LocalizationRequest: Sendable, Hashable {
    public let sourceText: String
    public let sourceLanguageIdentifier: String?
    public let targetLanguageIdentifier: String?
    public let context: String?

    public init(
        sourceText: String,
        sourceLanguageIdentifier: String? = nil,
        targetLanguageIdentifier: String? = nil,
        context: String? = nil
    ) {
        self.sourceText = sourceText
        self.sourceLanguageIdentifier = sourceLanguageIdentifier
        self.targetLanguageIdentifier = targetLanguageIdentifier
        self.context = context
    }
}

/// A localization response returned by a provider implementation.
public struct LocalizationResponse: Sendable, Hashable {
    public let localizedText: String

    public init(localizedText: String) {
        self.localizedText = localizedText
    }
}

/// A pluggable translation backend used by `LiveLocalizer` and `LiveLocalization`.
public protocol LocalizationProvider: Sendable {
    func translate(_ request: LocalizationRequest) async throws -> LocalizationResponse
}

/// A translation provider that can return results immediately without async work.
public protocol SyncLocalizationProvider: LocalizationProvider {
    func translateSynchronously(_ request: LocalizationRequest) throws -> LocalizationResponse
}

/// A translation provider that can batch compatible requests into a single backend call.
public protocol BatchLocalizationProvider: LocalizationProvider {
    /// Returns a stable key describing which requests can share the same batch.
    func batchGroupIdentifier(for request: LocalizationRequest) -> String

    /// Translates a batch of requests and returns responses in the same order as the input array.
    func translateBatch(_ requests: [LocalizationRequest]) async throws -> [LocalizationResponse]
}

public extension SyncLocalizationProvider {
    func translate(_ request: LocalizationRequest) async throws -> LocalizationResponse {
        try translateSynchronously(request)
    }
}

public extension LocalizationProvider {
    func translate(_ text: String) async -> String {
        let request = LocalizationRequest(sourceText: text)

        do {
            return try await translate(request).localizedText
        } catch {
            return text
        }
    }

    func translate(_ request: LocalizationRequest) async -> String {
        do {
            return try await translate(request).localizedText
        } catch {
            return request.sourceText
        }
    }
}

public extension SyncLocalizationProvider {
    func translateSynchronously(_ text: String) -> String {
        let request = LocalizationRequest(sourceText: text)

        do {
            return try translateSynchronously(request).localizedText
        } catch {
            return text
        }
    }
}

public enum LiveLocalizationError: Error {
    case emptyText
    case unsupportedTargetLanguage
    case notSupportedOnPlatform
    case translationFailed(underlying: Error)
}
