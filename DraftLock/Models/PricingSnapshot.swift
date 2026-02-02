import Foundation

struct PricingSnapshot: Codable {
    var model: String

    /// USD per 1 token.
    var inputUnitPrice: Double

    /// USD per 1 token.
    var outputUnitPrice: Double

    var currency: String
    var takenAt: Date

    func estimateCost(inputTokens: Int, outputTokens: Int) -> Double {
        let input = Double(inputTokens) * inputUnitPrice
        let output = Double(outputTokens) * outputUnitPrice
        return input + output
    }
}

extension PricingSnapshot {
    /// Default pricing table (USD) based on OpenAI model docs.
    /// Keep this table in sync as pricing changes.
    static func defaultUSD(for model: ModelType, takenAt: Date = Date()) -> PricingSnapshot {
        // Prices below are "per 1M tokens" converted to "per 1 token".
        // gpt-4o:     $2.50 / $10.00
        // gpt-4o-mini:$0.15 / $0.60
        // gpt-5 chat: $1.25 / $10.00
        // codex-mini-latest: $1.50 / $6.00
        let perMillion = 1_000_000.0

        let (inPerM, outPerM): (Double, Double) = {
            switch model {
            case .gpt4o: return (2.50, 10.00)
            case .gpt4oMini: return (0.15, 0.60)
            case .gpt5ChatLatest: return (1.25, 10.00)
            case .codexMiniLatest: return (1.50, 6.00)
            }
        }()

        return PricingSnapshot(
            model: model.rawValue,
            inputUnitPrice: inPerM / perMillion,
            outputUnitPrice: outPerM / perMillion,
            currency: "USD",
            takenAt: takenAt
        )
    }
}
