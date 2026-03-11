import SwiftUI
import DebugLocalizationCore

struct UIKitDemoView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = UIKitDemoViewController()
        return UINavigationController(rootViewController: controller)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
