enum DraftMode: String, CaseIterable, Identifiable {
    case chat = "Chat"
    case doc  = "Doc"
    case pr   = "PR"

    var id: String { rawValue }
}
