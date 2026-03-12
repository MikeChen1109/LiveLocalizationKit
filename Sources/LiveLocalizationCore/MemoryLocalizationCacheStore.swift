import Foundation

/// An in-memory cache store for localized text.
public actor MemoryLocalizationCacheStore: LocalizationCacheStore {
    private var storage: [String: String]

    public init(storage: [String: String] = [:]) {
        self.storage = storage
    }

    public func localizedText(forKey key: String) -> String? {
        storage[key]
    }

    public func setLocalizedText(_ value: String, forKey key: String) {
        storage[key] = value
    }

    public func removeAllLocalizedText() {
        storage.removeAll()
    }
}
