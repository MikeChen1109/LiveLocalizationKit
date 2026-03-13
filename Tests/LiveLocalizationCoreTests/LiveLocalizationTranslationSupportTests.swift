import Foundation
import Testing
@testable import LiveLocalizationTranslationSupport

struct LiveLocalizationTranslationSupportTests {
    @Test
    func appleTranslationProviderFallsBackToOriginalTextWhenTranslationFails() async {
        let provider = AppleTranslationProvider(
            appLanguageIdentifier: { "zh-Hant" },
            englishLanguageIdentifierChecker: { _ in false },
            preparationResolver: { _ in testPreparation },
            batchTranslationExecutor: { _, _ in throw LiveLocalizationTestError.expectedFailure }
        )

        let localized = await provider.translate("Settings")

        #expect(localized == "Settings")
    }

    @Test
    func appleTranslationProviderReturnsOriginalTextForEnglish() async {
        let provider = AppleTranslationProvider(
            appLanguageIdentifier: { "en" },
            englishLanguageIdentifierChecker: { _ in true },
            preparationResolver: { _ in
                Issue.record("Preparation should not be requested for English.")
                return nil
            },
            batchTranslationExecutor: { _, _ in
                Issue.record("Translation should not run for English.")
                return []
            }
        )

        let localized = await provider.translate("Settings")

        #expect(localized == "Settings")
    }

    @Test
    func appleTranslationProviderBatchesConcurrentRequests() async {
        let recorder = BatchRecorder()
        let provider = AppleTranslationProvider(
            appLanguageIdentifier: { "zh-Hant" },
            englishLanguageIdentifierChecker: { _ in false },
            preparationResolver: { _ in testPreparation },
            batchTranslationExecutor: { requests, _ in
                await recorder.record(requests.map(\.text))
                try? await Task.sleep(for: .milliseconds(50))
                return requests.map { request in
                    AppleTranslationProvider.BatchTranslationResult(
                        id: request.id,
                        text: "[translated] \(request.text)"
                    )
                }
            }
        )

        let results = await withTaskGroup(of: String.self, returning: [String].self) { group in
            group.addTask {
                await provider.translate("Settings")
            }
            group.addTask {
                await provider.translate("Delete")
            }

            var values: [String] = []
            for await value in group {
                values.append(value)
            }
            return values
        }

        #expect(Set(results) == ["[translated] Settings", "[translated] Delete"])
        #expect(await recorder.recordedBatches == [["Settings", "Delete"]])
    }

    @Test
    @MainActor
    func refreshTransitionsToNeedsDownloadWhenLanguagePackIsSupportedButMissing() async {
        let coordinator = TranslationPreparationCoordinator(
            appLanguageIdentifier: { "zh-Hant" },
            preparationResolver: { _ in testPreparation },
            availabilityStatusProvider: { _ in .supported },
            installationWaiter: { _ in false }
        )

        await coordinator.refresh()

        switch coordinator.state {
        case .needsDownload(let request):
            #expect(request.sourceLanguage == testPreparation.sourceLanguage)
            #expect(request.targetLanguage == testPreparation.targetLanguage)
        case .checking, .ready:
            Issue.record("Expected coordinator to require download.")
        }

        #expect(coordinator.downloadStatusMessage == "The language pack is not ready yet. Tap to start or resume the download.")
        #expect(coordinator.needsPreparation)
        #expect(await coordinator.requiresPreparation())
        #expect(coordinator.currentPreparationRequest?.targetLanguage == testPreparation.targetLanguage)
    }

    @Test
    @MainActor
    func prepareTranslationRetriesAndRestoresNeedsDownloadStateWhenInstallDoesNotComplete() async {
        let coordinator = TranslationPreparationCoordinator(
            appLanguageIdentifier: { "zh-Hant" },
            preparationResolver: { _ in testPreparation },
            availabilityStatusProvider: { _ in .supported },
            installationWaiter: { _ in false }
        )
        coordinator.startPreparation(for: testPreparation)

        await coordinator.completePreparation(with: .success(()))

        switch coordinator.state {
        case .needsDownload:
            break
        case .checking, .ready:
            Issue.record("Expected coordinator to remain in needsDownload state.")
        }

        #expect(coordinator.translationConfiguration == nil)
        #expect(!coordinator.isPreparingTranslation)
        #expect(coordinator.downloadStatusMessage == "The language pack is still downloading or waiting to start. You can tap again to check its status.")
    }
}

private enum LiveLocalizationTestError: Error {
    case expectedFailure
}

private actor BatchRecorder {
    private(set) var recordedBatches: [[String]] = []

    func record(_ batch: [String]) {
        recordedBatches.append(batch)
    }
}

@available(iOS 18.0, *)
private let testPreparation = AppleTranslationProvider.Preparation(
    sourceLanguage: Locale.Language(identifier: "en"),
    targetLanguage: Locale.Language(identifier: "zh-Hant")
)
