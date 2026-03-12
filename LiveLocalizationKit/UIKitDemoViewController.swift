import UIKit
import LiveLocalizationCore
import LiveLocalizationUI

final class UIKitDemoViewController: UIViewController {
    private let coreSourceText = "Delete"
    private let wrapperSourceText = "Continue"

    private let coreTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .headline)
        label.text = "Core API"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let coreLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .title2)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let wrapperTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .headline)
        label.text = "UI Wrapper"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let wrapperLabel: LiveLocalizedLabel = {
        let label = LiveLocalizedLabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .title2)
        label.animationStyle = .softFade
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        self.title = "UIKit Demo"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let stackView = UIStackView(arrangedSubviews: [
            coreTitleLabel,
            coreLabel,
            wrapperTitleLabel,
            wrapperLabel
        ])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        coreLabel.text = coreSourceText
        Task { [weak self] in
            guard let self else { return }
            let localized = await coreSourceText.localize()
            await MainActor.run {
                self.coreLabel.text = localized
            }
        }

        wrapperLabel.setLocalizedText(wrapperSourceText)
    }
}
