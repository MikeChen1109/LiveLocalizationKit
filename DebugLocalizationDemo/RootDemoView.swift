import SwiftUI
import DebugLocalizationCore
import DebugLocalizationTranslationSupport
#if canImport(Translation)
import Translation
#endif

struct RootDemoView: View {
    let configuration: DebugLocalizationConfiguration

    @Environment(\.scenePhase) private var scenePhase
    @State private var preparationCoordinator = TranslationPreparationCoordinator()

    var body: some View {
        rootContent
            .task {
                await preparationCoordinator.refresh()
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                Task {
                    await preparationCoordinator.refresh(force: true)
                }
            }
    }

    private var tabContent: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("SwiftUI", systemImage: "swift")
                }

            UIKitDemoView()
                .tabItem {
                    Label("UIKit", systemImage: "square.stack.3d.up")
                }
        }
    }

    @ViewBuilder
    private var rootContent: some View {
#if canImport(Translation)
        if configuration.shouldPresentPreparationGate, #available(iOS 18.0, *) {
            switch preparationCoordinator.state {
            case .ready:
                tabContent
                    .translationTask(preparationCoordinator.translationConfiguration) { session in
                        guard preparationCoordinator.isPreparingTranslation else { return }
                        await preparationCoordinator.prepareTranslation(using: session)
                    }
            case .checking:
                ProgressView("Checking translation availability…")
            case .needsDownload(let request):
                preparationPrompt(for: request)
                    .translationTask(preparationCoordinator.translationConfiguration) { session in
                        guard preparationCoordinator.isPreparingTranslation else { return }
                        await preparationCoordinator.prepareTranslation(using: session)
                    }
            }
        } else {
            tabContent
        }
#else
        tabContent
#endif
    }

#if canImport(Translation)
    @available(iOS 18.0, *)
    @ViewBuilder
    private func preparationPrompt(for request: AppleTranslationProvider.Preparation) -> some View {
        VStack(spacing: 16) {
            Text("Translation Download Required")
                .font(.title3.weight(.semibold))

            Text("Download the translation model for \(preparationCoordinator.displayName(for: request.targetLanguage)) before showing localized text.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if let downloadStatusMessage = preparationCoordinator.downloadStatusMessage {
                Text(downloadStatusMessage)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            Button {
                preparationCoordinator.startPreparation(for: request)
            } label: {
                if preparationCoordinator.isPreparingTranslation {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Checking Download Status")
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Text(preparationCoordinator.downloadButtonTitle)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(preparationCoordinator.isPreparingTranslation)
        }
        .padding(24)
    }
#endif
}
