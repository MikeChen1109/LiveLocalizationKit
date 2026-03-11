import Foundation

public extension String {
    func localize() async -> String {
        await DebugLocalizer.shared.localize(self)
    }

    func localizeSync() -> String? {
        DebugLocalizer.shared.localizeSync(self)
    }

    func localize(using localizer: DebugLocalizer) async -> String {
        await localizer.localize(self)
    }

    func localizeSync(using localizer: DebugLocalizer) -> String? {
        localizer.localizeSync(self)
    }
}
