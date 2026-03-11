import SwiftUI
import DebugLocalizationCore

struct ContentView: View {
    private let englishSourceText = "Payment successful"

    @State private var displayedText: String

    init() {
        _displayedText = State(initialValue: englishSourceText)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("SwiftUI Demo")
                .font(.headline)
            Text(displayedText)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .task {
            displayedText = await englishSourceText.localize()
        }
    }
}

#Preview {
    ContentView()
}
