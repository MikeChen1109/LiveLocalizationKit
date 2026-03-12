#if canImport(UIKit)
import UIKit
import LiveLocalizationCore

/// A UIKit label that resolves localized content through ``LiveLocalizer``.
@MainActor
public final class LiveLocalizedLabel: UILabel {
    private enum AnimationConstants {
        static let fadeDuration = 0.2
        static let softFadePhaseDuration = 0.14
        static let softFadeOutgoingScale = 0.985
        static let softFadeIncomingScale = 1.015
    }

    /// The localizer used by this label. When `nil`, the shared package localizer is used.
    public var localizer: LiveLocalizer?

    /// The animation applied when localized text replaces the current text.
    public var animationStyle: LiveLocalizationTextAnimation = .fade

    private var localizationTask: Task<Void, Never>?
    private let requestCoordinator = LiveLocalizationTextRequestCoordinator()

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    deinit {
        localizationTask?.cancel()
    }

    /// Starts localizing the provided source string and updates the label when the result arrives.
    /// - Parameter source: The original source string to localize.
    public func setLocalizedText(_ source: String) {
        localizationTask?.cancel()
        text = source

        localizationTask = Task { [weak self] in
            let resolvedLocalizer = if let localizer = self?.localizer {
                localizer
            } else {
                await LiveLocalization.localizer
            }

            if let cachedText = await resolvedLocalizer.cachedLocalization(for: source) {
                guard !Task.isCancelled else {
                    return
                }

                await MainActor.run {
                    self?.text = cachedText
                }
                return
            }

            let currentRequestVersion = await self?.requestCoordinator.beginRequest()
            guard let currentRequestVersion else {
                return
            }

            let localizedText = await resolvedLocalizer.localize(source)

            guard !Task.isCancelled else {
                return
            }

            await self?.commitLocalizedText(localizedText, requestVersion: currentRequestVersion)
        }
    }

    private func commitLocalizedText(_ localizedText: String, requestVersion: Int) async {
        guard await requestCoordinator.isCurrent(requestVersion) else {
            return
        }

        guard text != localizedText else {
            text = localizedText
            return
        }

        switch animationStyle {
        case .none:
            text = localizedText
        case .fade:
            UIView.transition(
                with: self,
                duration: AnimationConstants.fadeDuration,
                options: [.transitionCrossDissolve, .allowAnimatedContent]
            ) {
                self.text = localizedText
            }
        case .softFade:
            alpha = 1
            transform = .identity

            UIView.animate(
                withDuration: AnimationConstants.softFadePhaseDuration,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState]
            ) {
                self.alpha = 0
                self.transform = CGAffineTransform(
                    scaleX: AnimationConstants.softFadeOutgoingScale,
                    y: AnimationConstants.softFadeOutgoingScale
                )
            } completion: { _ in
                self.text = localizedText
                self.transform = CGAffineTransform(
                    scaleX: AnimationConstants.softFadeIncomingScale,
                    y: AnimationConstants.softFadeIncomingScale
                )

                UIView.animate(
                    withDuration: AnimationConstants.softFadePhaseDuration,
                    delay: 0,
                    options: [.curveEaseInOut, .beginFromCurrentState]
                ) {
                    self.alpha = 1
                    self.transform = .identity
                }
            }
        }
    }
}
#endif
