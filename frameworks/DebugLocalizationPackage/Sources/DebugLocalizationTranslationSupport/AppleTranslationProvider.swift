import Foundation
import DebugLocalizationCore
#if canImport(Translation)
import Translation
#endif

public struct AppleTranslationProvider: LocalizationProvider {
    public init() {}

    public func translate(_ text: String) async -> String {
        let languageIdentifier = currentAppLanguageIdentifier()

        guard !isEnglishLanguageIdentifier(languageIdentifier) else {
            return text
        }

        do {
            return try await translate(text, into: languageIdentifier)
        } catch {
            print("Debug localization fallback. Error: \(error)")
            return text
        }
    }

    public func translate(_ text: String, into languageIdentifier: String) async throws -> String {
#if canImport(Translation)
        if #available(iOS 18.0, *) {
            guard let preparation = await Self.preparation(for: languageIdentifier) else {
                throw DebugLocalizationError.unsupportedTargetLanguage
            }

            return try await Self.translateUsingInstalledSession(text, preparation: preparation)
        } else {
            throw DebugLocalizationError.notSupportedOnPlatform
        }
#else
        throw DebugLocalizationError.notSupportedOnPlatform
#endif
    }

#if canImport(Translation)
    @available(iOS 18.0, *)
    public struct Preparation {
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

    @available(iOS 18.0, *)
    private static func translateUsingInstalledSession(_ text: String, preparation: Preparation) async throws -> String {
        if #available(iOS 26.0, *) {
            let session = TranslationSession(
                installedSource: preparation.sourceLanguage,
                target: preparation.targetLanguage
            )
            do {
                let response = try await session.translate(text)
                return response.targetText
            } catch {
                throw DebugLocalizationError.translationFailed(underlying: error)
            }
        } else {
            throw DebugLocalizationError.notSupportedOnPlatform
        }
    }
#endif
}
