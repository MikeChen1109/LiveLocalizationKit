import SwiftUI
import LiveLocalizationCore
import LiveLocalizationUI

struct ContentView: View {
    private let englishSourceText = "Payment successful"
    private let wrapperSourceText = "Continue"

    @State private var coreLocalizedText = "Payment successful"

    var body: some View {
        VStack(spacing: 24) {
            Text("SwiftUI Demo")
                .font(.headline)

            VStack(spacing: 8) {
                Text("Core API")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(coreLocalizedText)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 8) {
                Text("UI Wrapper")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LiveLocalizedText(
                    wrapperSourceText,
                    animationStyle: .softFade
                )
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
        }
        .padding()
        .task {
            coreLocalizedText = await englishSourceText.localize()
        }
    }
}

#Preview {
    ContentView()
}
