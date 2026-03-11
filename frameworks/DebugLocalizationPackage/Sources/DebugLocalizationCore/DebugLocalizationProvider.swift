import Foundation

public protocol LocalizationProvider: Sendable {
    func translate(_ text: String) async -> String
}

public protocol SyncLocalizationProvider: LocalizationProvider {
    func translateSync(_ text: String) -> String
}

public extension SyncLocalizationProvider {
    func translate(_ text: String) async -> String {
        translateSync(text)
    }
}

public enum DebugLocalizationError: Error {
    case emptyText
    case unsupportedTargetLanguage
    case notSupportedOnPlatform
    case translationFailed(underlying: Error)
}
