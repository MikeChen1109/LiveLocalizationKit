import Foundation
import LiveLocalizationCore
#if canImport(Translation)
import Translation
#endif

/// A translation provider that wraps Apple Translation behind the shared localization API.
public struct AppleTranslationProvider: LocalizationProvider, Sendable {
    typealias AppLanguageIdentifierProvider = @Sendable () -> String
    typealias EnglishLanguageIdentifierChecker = @Sendable (String) -> Bool
    typealias PreparationResolver = @Sendable (String) async -> Preparation?
    typealias TranslationExecutor = @Sendable (String, Preparation) async throws -> String

    private let appLanguageIdentifier: AppLanguageIdentifierProvider
    private let englishLanguageIdentifierChecker: EnglishLanguageIdentifierChecker
    private let preparationResolver: PreparationResolver
    private let translationExecutor: TranslationExecutor

    @available(iOS 26.0, macOS 26.0, *)
    public init() {
        self.appLanguageIdentifier = currentAppLanguageIdentifier
        self.englishLanguageIdentifierChecker = isEnglishLanguageIdentifier
        self.preparationResolver = Self.preparation
        self.translationExecutor = Self.defaultTranslationExecutor()
    }

    init(
        appLanguageIdentifier: @escaping AppLanguageIdentifierProvider,
        englishLanguageIdentifierChecker: @escaping EnglishLanguageIdentifierChecker,
        preparationResolver: @escaping PreparationResolver,
        translationExecutor: @escaping TranslationExecutor
    ) {
        self.appLanguageIdentifier = appLanguageIdentifier
        self.englishLanguageIdentifierChecker = englishLanguageIdentifierChecker
        self.preparationResolver = preparationResolver
        self.translationExecutor = translationExecutor
    }

    private static func defaultTranslationExecutor() -> TranslationExecutor {
#if canImport(Translation)
        if #available(iOS 26.0, macOS 26.0, *) {
            return Self.translateUsingInstalledSession
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

    public func translate(_ text: String, into languageIdentifier: String) async throws -> String {
#if canImport(Translation)
        if #available(iOS 18.0, *) {
            guard let preparation = await preparationResolver(languageIdentifier) else {
                throw LiveLocalizationError.unsupportedTargetLanguage
            }

            return try await translationExecutor(text, preparation)
        } else {
            throw LiveLocalizationError.notSupportedOnPlatform
        }
#else
        throw LiveLocalizationError.notSupportedOnPlatform
#endif
    }

#if canImport(Translation)
    @available(iOS 18.0, *)
    /// The source and target language pair resolved for Apple Translation.
    public struct Preparation: Sendable {
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
    private static func translateUsingInstalledSession(_ text: String, preparation: Preparation) async throws -> String {
        let session = TranslationSession(
            installedSource: preparation.sourceLanguage,
            target: preparation.targetLanguage
        )
        do {
            let response = try await session.translate(text)
            return response.targetText
        } catch {
            throw LiveLocalizationError.translationFailed(underlying: error)
        }
    }
#endif
}
