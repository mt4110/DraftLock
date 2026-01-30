import SwiftUI

struct ContentView: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var errorMessage: String?
    @State private var mode: DraftMode = .chat
    @State private var isProcessing: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Mode selector
            Picker("Mode", selection: $mode) {
                ForEach(DraftMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            // Input
            Text("Input")
                .font(.headline)

            TextEditor(text: $inputText)
                .frame(minHeight: 120)
                .border(Color.gray.opacity(0.3))

            // Transform button
            Button {
                transform()
            } label: {
                if isProcessing {
                    ProgressView()
                } else {
                    Text("Transform")
                }
            }
            .disabled(isProcessing || inputText.isEmpty)

            // Error
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Divider()

            // Output
            Text("Output")
                .font(.headline)

            TextEditor(text: $outputText)
                .frame(minHeight: 120)
                .border(Color.gray.opacity(0.3))

            // Copy
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(outputText, forType: .string)
            }
            .disabled(outputText.isEmpty)

            Spacer()
        }
        .padding()
        .frame(minWidth: 800, minHeight: 520)
    }

    // MARK: - Action

    private func transform() {
        isProcessing = true
        errorMessage = nil

        Task {
            do {
                let client = try OpenAIClient()
                let result = try await client.transform(
                    text: inputText,
                    mode: mode
                )
                outputText = result
            } catch {
                errorMessage = "OPENAI_API_KEY is not set"
            }
            isProcessing = false
        }
    }
}

#Preview {
    ContentView()
}
