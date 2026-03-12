import Foundation
import Testing
@testable import LiveLocalizationCore
@testable import LiveLocalizationUI

struct LiveLocalizationUITests {
    @Test
    func requestCoordinatorInvalidatesOlderRequests() async {
        let coordinator = LiveLocalizationTextRequestCoordinator()

        let firstRequest = await coordinator.beginRequest()
        let secondRequest = await coordinator.beginRequest()

        #expect(await !coordinator.isCurrent(firstRequest))
        #expect(await coordinator.isCurrent(secondRequest))

        await coordinator.invalidateCurrentRequest()

        #expect(await !coordinator.isCurrent(secondRequest))
    }

    @Test
    func sharedLocalizerIsUsedWhenNoLocalizerIsInjected() async {
        defer {
            Task {
                await LiveLocalization.reset()
            }
        }

        await LiveLocalization.configure(
            provider: MockLocalizationProvider(),
            cacheStore: MemoryLocalizationCacheStore(),
            cachePolicy: LocalizationCachePolicy(providerIdentifier: "mock")
        )

        let localizer = await LiveLocalization.localizer
        let localized = await localizer.localize("Settings")

        #expect(localized.contains("Settings"))
    }
}

#if canImport(UIKit)
import UIKit

@Suite(.serialized)
struct LiveLocalizedLabelTests {
    @Test
    @MainActor
    func labelShowsSourceImmediatelyAndCommitsLatestLocalizedText() async throws {
        let localizer = LiveLocalizer(provider: DelayedProvider(delayNanoseconds: 50_000_000))
        let label = LiveLocalizedLabel()
        label.localizer = localizer
        label.animationStyle = .none

        label.setLocalizedText("Profile")

        #expect(label.text == "Profile")

        try await Task.sleep(nanoseconds: 120_000_000)

        #expect(label.text == "[localized] Profile")
    }

    @Test
    @MainActor
    func labelUsesCachedLocalizedValueWhenAvailable() async throws {
        let localizer = LiveLocalizer(provider: MockLocalizationProvider())
        _ = await localizer.localize("Profile")

        let label = LiveLocalizedLabel()
        label.localizer = localizer
        label.animationStyle = .none

        label.setLocalizedText("Profile")

        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(label.text?.contains("Profile") == true)
        #expect(label.text != "Profile")
    }

    @Test
    @MainActor
    func labelIgnoresStaleAsyncResults() async throws {
        let localizer = LiveLocalizer(provider: SequenceDelayedProvider())
        let label = LiveLocalizedLabel()
        label.localizer = localizer
        label.animationStyle = .none

        label.setLocalizedText("First")
        label.setLocalizedText("Second")

        try await Task.sleep(nanoseconds: 220_000_000)

        #expect(label.text == "[localized] Second")
    }
}

private struct DelayedProvider: LocalizationProvider {
    let delayNanoseconds: UInt64

    func translate(_ request: LocalizationRequest) async throws -> LocalizationResponse {
        try? await Task.sleep(nanoseconds: delayNanoseconds)
        return LocalizationResponse(localizedText: "[localized] \(request.sourceText)")
    }
}

private actor LockedDelayCounter {
    private var storage = 0

    func increment() -> Int {
        storage += 1
        return storage
    }
}

private struct SequenceDelayedProvider: LocalizationProvider {
    private let counter = LockedDelayCounter()

    func translate(_ request: LocalizationRequest) async throws -> LocalizationResponse {
        let callIndex = await counter.increment()
        let delayNanoseconds: UInt64 = callIndex == 1 ? 150_000_000 : 30_000_000
        try? await Task.sleep(nanoseconds: delayNanoseconds)
        return LocalizationResponse(localizedText: "[localized] \(request.sourceText)")
    }
}
#endif
