import Foundation

public enum DebugTranslate {
    private static let sharedStore = SharedLocalizerStore()

    public static func configure(provider: any LocalizationProvider) {
        sharedStore.setLocalizer(DebugLocalizer(provider: provider))
    }

    public static func configure(localizer: DebugLocalizer) {
        sharedStore.setLocalizer(localizer)
    }

    public static var localizer: DebugLocalizer {
        sharedStore.localizer
    }
}

private final class SharedLocalizerStore: @unchecked Sendable {
    private let lock = NSLock()
    private var currentLocalizer = DebugLocalizer(provider: PseudoLocalizationProvider())

    var localizer: DebugLocalizer {
        lock.lock()
        defer { lock.unlock() }
        return currentLocalizer
    }

    func setLocalizer(_ localizer: DebugLocalizer) {
        lock.lock()
        currentLocalizer = localizer
        lock.unlock()
    }
}
