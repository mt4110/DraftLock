import Foundation

enum ModelType: String, Codable, CaseIterable, Identifiable {
    /// GPT-4o
    case gpt4o = "gpt-4o"

    /// GPT-4o mini
    case gpt4oMini = "gpt-4o-mini"

    /// GPT-5 (chat)
    case gpt5ChatLatest = "gpt-5"

    /// Codex mini latest
    case codexMiniLatest = "codex-mini-latest"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gpt4o: return "GPT-4o"
        case .gpt4oMini: return "GPT-4o mini"
        case .gpt5ChatLatest: return "GPT-5"
        case .codexMiniLatest: return "Codex mini"
        }
    }
}
