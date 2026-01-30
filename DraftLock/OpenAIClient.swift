import Foundation

enum OpenAIClientError: Error {
    case missingAPIKey
}

struct OpenAIClient {
    let apiKey: String

    init() throws {
        guard let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"],
              !key.isEmpty else {
            throw OpenAIClientError.missingAPIKey
        }
        self.apiKey = key
    }

    func transform(text: String, mode: DraftMode) async throws -> String {
        let prompt = DraftPrompt.forMode(mode, input: text)

        // TODO: OpenAI API call with `prompt`
        return "[\(mode.rawValue)] transformed"
    }
}
