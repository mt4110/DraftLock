import Foundation

// MARK: - Requests

struct OpenAIResponsesRequest: Encodable {
    let model: String
    let input: String
    let instructions: String?
    let max_output_tokens: Int?

    init(model: String, input: String, instructions: String? = nil, max_output_tokens: Int? = nil) {
        self.model = model
        self.input = input
        self.instructions = instructions
        self.max_output_tokens = max_output_tokens
    }
}

struct OpenAIInputTokensResponse: Decodable {
    let input_tokens: Int
}

// MARK: - Responses

struct OpenAIResponse: Decodable {
    let id: String?
    let output: [OutputItem]?
    let usage: Usage?

    struct Usage: Decodable {
        let input_tokens: Int?
        let output_tokens: Int?
        let total_tokens: Int?
    }

    struct OutputItem: Decodable {
        let type: String
        let role: String?
        let content: [ContentItem]?
    }

    struct ContentItem: Decodable {
        let type: String
        let text: String?
    }
}

extension OpenAIResponse {
    var outputText: String {
        let chunks: [String] = (output ?? []).flatMap { item in
            (item.content ?? []).compactMap { c in
                guard c.type == "output_text" else { return nil }
                return c.text
            }
        }
        return chunks.joined(separator: "\n")
    }

    var inputTokens: Int { usage?.input_tokens ?? 0 }
    var outputTokens: Int { usage?.output_tokens ?? 0 }
}

struct OpenAIErrorEnvelope: Decodable {
    struct OpenAIError: Decodable {
        let message: String?
        let type: String?
        let code: String?
    }
    let error: OpenAIError
}
