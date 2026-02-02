import Foundation

struct UsageEntry: Identifiable, Codable {
    var id: UUID
    var date: Date

    /// If the request was made with a saved template, store the template ID.
    var promptTemplateID: UUID?

    /// OpenAI model string (e.g. "gpt-4o-mini").
    var model: String
    var mode: DraftMode

    var inputTokens: Int
    var outputTokens: Int

    /// Pricing at the time of the request (local estimate).
    var pricing: PricingSnapshot
}
