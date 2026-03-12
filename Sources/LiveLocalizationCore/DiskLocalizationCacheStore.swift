import Foundation

/// A file-backed cache store for localized text persistence across launches.
public actor DiskLocalizationCacheStore: LocalizationCacheStore {
    private let fileURL: URL
    private let fileManager: FileManager
    private var storage: [String: String] = [:]
    private var hasLoaded = false

    public init(
        fileURL: URL,
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    public init(
        filename: String = "LiveLocalizationCache.json",
        directory: FileManager.SearchPathDirectory = .cachesDirectory,
        fileManager: FileManager = .default
    ) {
        let baseURL = fileManager.urls(for: directory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        self.fileURL = baseURL.appendingPathComponent(filename)
        self.fileManager = fileManager
    }

    public func localizedText(forKey key: String) async -> String? {
        await loadIfNeeded()
        return storage[key]
    }

    public func setLocalizedText(_ value: String, forKey key: String) async {
        await loadIfNeeded()
        storage[key] = value
        await persist()
    }

    public func removeAllLocalizedText() async {
        await loadIfNeeded()
        storage.removeAll()
        await persist()
    }

    private func loadIfNeeded() async {
        guard !hasLoaded else {
            return
        }

        defer { hasLoaded = true }

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            storage = try JSONDecoder().decode([String: String].self, from: data)
        } catch {
            storage = [:]
        }
    }

    private func persist() async {
        do {
            let directoryURL = fileURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(storage)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Ignore persistence errors and keep the runtime cache available in memory.
        }
    }
}
