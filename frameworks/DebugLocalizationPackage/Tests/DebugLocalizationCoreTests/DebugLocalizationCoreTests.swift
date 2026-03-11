import Testing
@testable import DebugLocalizationCore

struct DebugLocalizationCoreTests {
    @Test
    func pseudoLocalizationExpandsText() async throws {
        let provider = PseudoLocalizationProvider()

        let localized = await provider.translate("Remove")

        #expect(localized.contains("["))
        #expect(localized.contains("⟪"))
        #expect(localized.count > "Remove".count)
    }

    @Test
    func stringExtensionUsesConfiguredSharedLocalizer() async {
        DebugTranslate.configure(provider: PassthroughLocalizationProvider())
        let passthrough = await "Settings".localize()

        DebugTranslate.configure(provider: PseudoLocalizationProvider())
        let pseudoLocalized = await "Settings".localize()

        #expect(passthrough == "Settings")
        #expect(pseudoLocalized != "Settings")
    }

    @Test
    func syncLocalizationUsesSyncCapableProvider() {
        DebugTranslate.configure(provider: MockTranslationProvider())

        let localized = "Settings".localizeSync()

        #expect(localized != nil)
        #expect(localized?.contains("Settings") == true)
    }

    @Test
    func syncLocalizationReturnsNilForAsyncOnlyProvider() {
        let localizer = DebugLocalizer(provider: AsyncOnlyProvider())

        #expect(localizer.localizeSync("Settings") == nil)
    }
}

private struct AsyncOnlyProvider: LocalizationProvider {
    func translate(_ text: String) async -> String {
        "[async] \(text)"
    }
}
