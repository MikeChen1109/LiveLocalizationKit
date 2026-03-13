import Foundation
import LiveLocalizationCore
#if canImport(Translation)
import Translation
#endif

/// A translation provider that wraps Apple Translation behind the shared localization API.
public struct AppleTranslationProvider: BatchLocalizationProvider, Sendable {
    typealias AppLanguageIdentifierProvider = @Sendable () -> String
    typealias EnglishLanguageIdentifierChecker = @Sendable (String) -> Bool
    typealias PreparationResolver = @Sendable (String) async -> Preparation?
    typealias BatchTranslationExecutor = @Sendable ([BatchTranslationRequest], Preparation) async throws -> [BatchTranslationResult]
    private static let preferredBatchChunkSize = 6

    private let appLanguageIdentifier: AppLanguageIdentifierProvider
    private let englishLanguageIdentifierChecker: EnglishLanguageIdentifierChecker
    private let preparationResolver: PreparationResolver
    private let batchTranslationExecutor: BatchTranslationExecutor

    @available(iOS 26.0, macOS 26.0, *)
    public init() {
        self.appLanguageIdentifier = currentAppLanguageIdentifier
        self.englishLanguageIdentifierChecker = isEnglishLanguageIdentifier
        self.preparationResolver = Self.preparation
        self.batchTranslationExecutor = Self.defaultBatchTranslationExecutor()
    }

    init(
        appLanguageIdentifier: @escaping AppLanguageIdentifierProvider,
        englishLanguageIdentifierChecker: @escaping EnglishLanguageIdentifierChecker,
        preparationResolver: @escaping PreparationResolver,
        batchTranslationExecutor: @escaping BatchTranslationExecutor
    ) {
        self.appLanguageIdentifier = appLanguageIdentifier
        self.englishLanguageIdentifierChecker = englishLanguageIdentifierChecker
        self.preparationResolver = preparationResolver
        self.batchTranslationExecutor = batchTranslationExecutor
    }

    private static func defaultBatchTranslationExecutor() -> BatchTranslationExecutor {
#if canImport(Translation)
        if #available(iOS 26.0, macOS 26.0, *) {
            return Self.translateBatchUsingInstalledSession
        }
#endif
        return { _, _ in
            throw LiveLocalizationError.notSupportedOnPlatform
        }
    }

    public func translate(_ request: LocalizationRequest) async throws -> LocalizationResponse {
        let languageIdentifier = request.targetLanguageIdentifier ?? appLanguageIdentifier()

        guard !englishLanguageIdentifierChecker(languageIdentifier) else {
            return LocalizationResponse(localizedText: request.sourceText)
        }

        let localizedText = try await translate(request.sourceText, into: languageIdentifier)
        return LocalizationResponse(localizedText: localizedText)
    }

    public func batchGroupIdentifier(for request: LocalizationRequest) -> String {
        let targetLanguageIdentifier = request.targetLanguageIdentifier ?? appLanguageIdentifier()
        let sourceLanguageIdentifier = request.sourceLanguageIdentifier ?? "en"
        return "\(sourceLanguageIdentifier)|\(targetLanguageIdentifier)"
    }

    public func translateBatch(_ requests: [LocalizationRequest]) async throws -> [LocalizationResponse] {
        guard let firstRequest = requests.first else {
            return []
        }

        let languageIdentifier = firstRequest.targetLanguageIdentifier ?? appLanguageIdentifier()
        guard !englishLanguageIdentifierChecker(languageIdentifier) else {
            return requests.map { request in
                LocalizationResponse(localizedText: request.sourceText)
            }
        }

#if canImport(Translation)
        if #available(iOS 18.0, *) {
            guard let preparation = await preparationResolver(languageIdentifier) else {
                throw LiveLocalizationError.unsupportedTargetLanguage
            }

            let batchRequests = requests.enumerated().map { index, request in
                BatchTranslationRequest(id: "\(index)", text: request.sourceText)
            }
            let results = try await batchTranslationExecutor(batchRequests, preparation)
            let resultMap = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0.text) })

            return requests.enumerated().map { index, request in
                let localizedText = resultMap["\(index)"] ?? request.sourceText
                return LocalizationResponse(localizedText: localizedText)
            }
        } else {
            throw LiveLocalizationError.notSupportedOnPlatform
        }
#else
        throw LiveLocalizationError.notSupportedOnPlatform
#endif
    }

    public func translate(_ text: String, into languageIdentifier: String) async throws -> String {
        let response = try await translateBatch([
            LocalizationRequest(sourceText: text, targetLanguageIdentifier: languageIdentifier)
        ])
        return response.first?.localizedText ?? text
    }

#if canImport(Translation)
    struct BatchTranslationRequest: Sendable, Hashable {
        let id: String
        let text: String
    }

    struct BatchTranslationResult: Sendable, Hashable {
        let id: String
        let text: String
    }

    @available(iOS 18.0, *)
    /// The source and target language pair resolved for Apple Translation.
    public struct Preparation: Sendable, Hashable {
        public let sourceLanguage: Locale.Language
        public let targetLanguage: Locale.Language

        public init(sourceLanguage: Locale.Language, targetLanguage: Locale.Language) {
            self.sourceLanguage = sourceLanguage
            self.targetLanguage = targetLanguage
        }
    }

    @available(iOS 18.0, *)
    public static func preparation(for languageIdentifier: String) async -> Preparation? {
        guard !isEnglishLanguageIdentifier(languageIdentifier) else {
            return nil
        }

        let availability = LanguageAvailability()
        let supportedLanguages = await availability.supportedLanguages

        guard let sourceLanguage = supportedLanguages.first(where: { matches($0, candidateIdentifier: "en") }) else {
            return nil
        }

        for candidateIdentifier in candidateIdentifiers(from: languageIdentifier) {
            if let targetLanguage = supportedLanguages.first(where: { matches($0, candidateIdentifier: candidateIdentifier) }) {
                return Preparation(sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
            }
        }

        return nil
    }

    @available(iOS 18.0, *)
    private static func candidateIdentifiers(from languageIdentifier: String) -> [String] {
        var candidateIdentifiers: [String] = [languageIdentifier]

        let locale = Locale(identifier: languageIdentifier)
        if let languageCode = locale.language.languageCode?.identifier {
            candidateIdentifiers.append(languageCode)
        }

        var seen: Set<String> = []
        return candidateIdentifiers.filter { identifier in
            let normalized = identifier.replacingOccurrences(of: "_", with: "-").lowercased()
            return seen.insert(normalized).inserted
        }
    }

    @available(iOS 18.0, *)
    private static func matches(_ language: Locale.Language, candidateIdentifier: String) -> Bool {
        let candidateCode = Locale(identifier: candidateIdentifier).language.languageCode?.identifier.lowercased()
        let languageCode = language.languageCode?.identifier.lowercased()
        return candidateCode != nil && candidateCode == languageCode
    }

    @available(iOS 26.0, macOS 26.0, *)
    private static func translateBatchUsingInstalledSession(
        _ requests: [BatchTranslationRequest],
        preparation: Preparation
    ) async throws -> [BatchTranslationResult] {
        let session = TranslationSession(
            installedSource: preparation.sourceLanguage,
            target: preparation.targetLanguage
        )
        do {
            var results: [BatchTranslationResult] = []
            results.reserveCapacity(requests.count)

            for requestChunk in requests.chunked(into: preferredBatchChunkSize) {
                let batch = requestChunk.map { request in
                    TranslationSession.Request(
                        sourceText: request.text,
                        clientIdentifier: request.id
                    )
                }
                let responses = try await session.translations(from: batch)
                results.append(
                    contentsOf: responses.compactMap { response in
                        guard let id = response.clientIdentifier else { return nil }
                        return BatchTranslationResult(id: id, text: response.targetText)
                    }
                )
            }

            return results
        } catch {
            throw LiveLocalizationError.translationFailed(underlying: error)
        }
    }
#endif
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }

        var chunks: [[Element]] = []
        chunks.reserveCapacity((count + size - 1) / size)

        var index = startIndex
        while index < endIndex {
            let chunkEndIndex = self.index(index, offsetBy: size, limitedBy: endIndex) ?? endIndex
            chunks.append(Array(self[index..<chunkEndIndex]))
            index = chunkEndIndex
        }

        return chunks
    }
}
