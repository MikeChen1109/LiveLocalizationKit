#if canImport(SwiftUI)
import SwiftUI
import LiveLocalizationCore

/// A SwiftUI text view that resolves localized content through ``LiveLocalizer``.
public struct LiveLocalizedText: View {
    private enum AnimationConstants {
        static let fadeDuration = 0.2
        static let softFadeDuration = 0.28
        static let softFadeBlurRadius = 6.0
        static let softFadeOutgoingScale = 0.985
        static let softFadeIncomingScale = 1.015
    }

    private struct TaskKey: Equatable {
        let source: String
        let localizerIdentifier: ObjectIdentifier?
    }

    private let source: String
    private let localizer: LiveLocalizer?
    private let animationStyle: LiveLocalizationTextAnimation

    @State private var displayedText: String
    @State private var outgoingText: String?
    @State private var isSoftFadeAnimating = false
    @State private var requestCoordinator = LiveLocalizationTextRequestCoordinator()

    /// Creates a text view that localizes the provided source string.
    /// - Parameters:
    ///   - source: The original source string to localize.
    ///   - localizer: An optional localizer. When omitted, the shared package localizer is used.
    ///   - animationStyle: The animation used when committing the localized text.
    public init(
        _ source: String,
        localizer: LiveLocalizer? = nil,
        animationStyle: LiveLocalizationTextAnimation = .fade
    ) {
        self.source = source
        self.localizer = localizer
        self.animationStyle = animationStyle
        _displayedText = State(initialValue: source)
    }

    public var body: some View {
        Group {
            localizedTextView
        }
            .task(id: taskKey) {
                let resolvedLocalizer = if let localizer {
                    localizer
                } else {
                    await LiveLocalization.localizer
                }

                if let cachedText = await resolvedLocalizer.cachedLocalization(for: source) {
                    await MainActor.run {
                        displayedText = cachedText
                    }
                    return
                }

                let currentRequestVersion = await requestCoordinator.beginRequest()

                await MainActor.run {
                    displayedText = source
                }

                let localizedText = await resolvedLocalizer.localize(source)

                guard await requestCoordinator.isCurrent(currentRequestVersion) else {
                    return
                }

                await MainActor.run {
                    commitLocalizedText(localizedText)
                }
            }
    }

    @ViewBuilder
    private var localizedTextView: some View {
        switch animationStyle {
        case .none:
            Text(displayedText)
        case .fade:
            Text(displayedText)
                .contentTransition(.opacity)
        case .softFade:
            ZStack {
                if let outgoingText {
                    Text(outgoingText)
                        .opacity(isSoftFadeAnimating ? 0 : 1)
                        .scaleEffect(isSoftFadeAnimating ? AnimationConstants.softFadeOutgoingScale : 1)
                        .blur(radius: isSoftFadeAnimating ? AnimationConstants.softFadeBlurRadius : 0)
                }

                Text(displayedText)
                    .opacity(outgoingText == nil ? 1 : (isSoftFadeAnimating ? 1 : 0))
                    .scaleEffect(
                        outgoingText == nil
                            ? 1
                            : (isSoftFadeAnimating ? 1 : AnimationConstants.softFadeIncomingScale)
                    )
                    .blur(
                        radius: outgoingText == nil
                            ? 0
                            : (isSoftFadeAnimating ? 0 : AnimationConstants.softFadeBlurRadius)
                    )
            }
            .animation(.easeInOut(duration: AnimationConstants.softFadeDuration), value: isSoftFadeAnimating)
        }
    }

    private func commitLocalizedText(_ localizedText: String) {
        guard displayedText != localizedText else {
            outgoingText = nil
            isSoftFadeAnimating = false
            displayedText = localizedText
            return
        }

        switch animationStyle {
        case .none:
            displayedText = localizedText
        case .fade:
            withAnimation(.easeInOut(duration: AnimationConstants.fadeDuration)) {
                displayedText = localizedText
            }
        case .softFade:
            let previousText = displayedText
            outgoingText = previousText
            isSoftFadeAnimating = false
            displayedText = localizedText

            withAnimation(.easeInOut(duration: AnimationConstants.softFadeDuration)) {
                isSoftFadeAnimating = true
            }

            Task {
                try? await Task.sleep(for: .seconds(AnimationConstants.softFadeDuration))
                await MainActor.run {
                    if displayedText == localizedText {
                        outgoingText = nil
                        isSoftFadeAnimating = false
                    }
                }
            }
        }
    }

    private var taskKey: TaskKey {
        TaskKey(
            source: source,
            localizerIdentifier: localizer.map(ObjectIdentifier.init)
        )
    }
}
#endif
