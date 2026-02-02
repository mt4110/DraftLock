import Foundation

enum OpenAIClientError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response"
        case .apiError(let message): return message
        }
    }
}

final class OpenAIClient {
    static let shared = OpenAIClient()
    private init() {}

    private let baseURL = URL(string: "https://api.openai.com/v1")!

    func createResponse(apiKey: String, request: OpenAIResponsesRequest) async throws -> OpenAIResponse {
        let url = baseURL.appendingPathComponent("responses")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        req.httpBody = try encoder.encode(request)
        print("Request URL:", req.url?.absoluteString ?? "nil")
        let (data, response) = try await URLSession.shared.data(for: req)
        try throwIfError(data: data, response: response)
        return try JSONDecoder().decode(OpenAIResponse.self, from: data)
    }

    /// Uses POST /v1/responses/input_tokens to get token count for the given request.
    func estimateInputTokens(apiKey: String, request: OpenAIResponsesRequest) async throws -> Int {
        let url = baseURL.appendingPathComponent("responses/input_tokens")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        req.httpBody = try encoder.encode(request)

        let (data, response) = try await URLSession.shared.data(for: req)
        try throwIfError(data: data, response: response)
        let decoded = try JSONDecoder().decode(OpenAIInputTokensResponse.self, from: data)
        return decoded.input_tokens
    }

    private func throwIfError(data: Data, response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw OpenAIClientError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            if let env = try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data),
               let message = env.error.message {
                throw OpenAIClientError.apiError(message: message)
            }
            throw OpenAIClientError.apiError(message: "HTTP \(http.statusCode)")
        }
    }
}
