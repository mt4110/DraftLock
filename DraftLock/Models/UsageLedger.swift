import Foundation

struct UsageLedger: Codable {
    var entries: [UsageEntry]

    var totalInputTokens: Int
    var totalOutputTokens: Int
    var totalCost: Double

    var currency: String
    var schemaVersion: Int

    static func empty(currency: String = "USD") -> UsageLedger {
        UsageLedger(
            entries: [],
            totalInputTokens: 0,
            totalOutputTokens: 0,
            totalCost: 0,
            currency: currency,
            schemaVersion: 1
        )
    }

    mutating func append(_ entry: UsageEntry) {
        entries.append(entry)
        rebuildTotals()
    }

    mutating func rebuildTotals() {
        totalInputTokens = entries.reduce(0) { $0 + $1.inputTokens }
        totalOutputTokens = entries.reduce(0) { $0 + $1.outputTokens }
        totalCost = entries.reduce(0) { $0 + $1.pricing.estimateCost(inputTokens: $1.inputTokens, outputTokens: $1.outputTokens) }
        currency = entries.last?.pricing.currency ?? currency
    }
}
