import Foundation

enum DraftMode: String, Codable, CaseIterable, Identifiable {
    case chat
    case doc
    case pr
    case notion
    case mail

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chat: return "Chat"
        case .doc: return "Doc"
        case .pr: return "PR"
        case .notion: return "Notion"
        case .mail: return "Mail"
        }
    }
}
