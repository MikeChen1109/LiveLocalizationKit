import Foundation

/// Animation styles used by the UI wrappers when committing localized text.
public enum LiveLocalizationTextAnimation: Sendable {
    /// Updates text without animation.
    case none

    /// Cross-fades from the current text to the localized text.
    case fade

    /// Softly replaces text with a brief fade, scale, and blur transition.
    case softFade
}
