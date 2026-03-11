import Foundation

public struct DebugLocalizationConfiguration: Sendable {
    public enum ProviderMode: Sendable {
        case appleTranslation
        case pseudoLocalization
        case passthrough
        case mock
    }

    public let providerMode: ProviderMode
    public let shouldPresentPreparationGate: Bool

    public init(providerMode: ProviderMode, shouldPresentPreparationGate: Bool) {
        self.providerMode = providerMode
        self.shouldPresentPreparationGate = shouldPresentPreparationGate
    }

    public static var debugDefault: DebugLocalizationConfiguration {
#if DEBUG
        DebugLocalizationConfiguration(
            providerMode: .appleTranslation,
            shouldPresentPreparationGate: true
        )
#else
        releaseDefault
#endif
    }

    public static let releaseDefault = DebugLocalizationConfiguration(
        providerMode: .passthrough,
        shouldPresentPreparationGate: false
    )
}
