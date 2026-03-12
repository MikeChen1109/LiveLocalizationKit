import Foundation

/// An in-memory cache store for localized text.
public actor MemoryLocalizationCacheStore: LocalizationCacheStore {
    private var storage: [String: LocalizationCacheEntry]

    public init(storage: [String: LocalizationCacheEntry] = [:]) {
        self.storage = storage
    }

    public func cacheEntry(forKey key: String) -> LocalizationCacheEntry? {
        guard let entry = storage[key] else {
            return nil
        }

        guard !entry.isExpired() else {
            storage.removeValue(forKey: key)
            return nil
        }

        return entry
    }

    public func setCacheEntry(_ entry: LocalizationCacheEntry, forKey key: String) {
        storage[key] = entry
    }

    public func removeLocalizedText(forKey key: String) {
        storage.removeValue(forKey: key)
    }

    public func removeAllLocalizedText() {
        storage.removeAll()
    }
}
