import Foundation

/// A pluggable cache store used by ``LiveLocalizer``.
public protocol LocalizationCacheStore: Sendable {
    func localizedText(forKey key: String) async -> String?
    func setLocalizedText(_ value: String, forKey key: String) async
    func removeAllLocalizedText() async
}
