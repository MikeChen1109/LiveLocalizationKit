import SwiftUI
import DebugLocalizationCore
import DebugLocalizationTranslationSupport

@main
struct DebugLocalizationDemoApp: App {
    private let configuration: DebugLocalizationConfiguration

    init() {
        configuration = .debugDefault
        switch configuration.providerMode {
        case .appleTranslation:
            DebugTranslate.configure(provider: AppleTranslationProvider())
        case .pseudoLocalization:
            DebugTranslate.configure(provider: PseudoLocalizationProvider())
        case .passthrough:
            DebugTranslate.configure(provider: PassthroughLocalizationProvider())
        case .mock:
            DebugTranslate.configure(provider: MockTranslationProvider())
        }
    }

    var body: some Scene {
        WindowGroup {
            RootDemoView(configuration: configuration)
        }
    }
}
