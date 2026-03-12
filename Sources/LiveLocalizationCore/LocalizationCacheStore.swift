import Foundation

/// A cached localization value and its optional expiration metadata.
public struct LocalizationCacheEntry: Sendable, Codable, Hashable {
    public let localizedText: String
    public let expirationDate: Date?

    public init(
        localizedText: String,
        expirationDate: Date? = nil
    ) {
        self.localizedText = localizedText
        self.expirationDate = expirationDate
    }

    public func isExpired(relativeTo date: Date = Date()) -> Bool {
        guard let expirationDate else {
            return false
        }

        return expirationDate <= date
    }
}

/// A pluggable cache store used by ``LiveLocalizer``.
public protocol LocalizationCacheStore: Sendable {
    func cacheEntry(forKey key: String) async -> LocalizationCacheEntry?
    func setCacheEntry(_ entry: LocalizationCacheEntry, forKey key: String) async
    func removeLocalizedText(forKey key: String) async
    func removeAllLocalizedText() async
}

/// Cache policy used by ``LiveLocalizer`` to segment and expire stored results.
public struct LocalizationCachePolicy: Sendable, Hashable {
    public let namespace: String?
    public let providerIdentifier: String?
    public let entryLifetime: TimeInterval?

    public init(
        namespace: String? = nil,
        providerIdentifier: String? = nil,
        entryLifetime: TimeInterval? = nil
    ) {
        self.namespace = namespace
        self.providerIdentifier = providerIdentifier
        self.entryLifetime = entryLifetime
    }
}
