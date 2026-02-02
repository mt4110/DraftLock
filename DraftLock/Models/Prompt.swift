import Foundation

/// Seed file for bundled default templates (Resources/DefaultPromptTemplates.json).
struct PromptTemplateSeed: Codable {
    let name: String
    let mode: DraftMode
    let body: String
}
