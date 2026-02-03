import Foundation

enum PricingError: Error, LocalizedError {
    case resourceMissing(String)
    case decodeFailed(String)
    case unsupportedSchema(Int)
    case invalidSnapshot(String)
    case modelNotFound(String)

    var errorDescription: String? {
        switch self {
        case .resourceMissing(let name): return "Pricing resource missing: \(name)"
        case .decodeFailed(let msg): return "Pricing decode failed: \(msg)"
        case .unsupportedSchema(let v): return "Unsupported pricing schema_version: \(v)"
        case .invalidSnapshot(let msg): return "Invalid pricing snapshot: \(msg)"
        case .modelNotFound(let model): return "Model not found in pricing snapshot: \(model)"
        }
    }
}

final class PricingStore {
    static let shared = PricingStore()

    private(set) var snapshot: PricingSnapshot?

    private init() {}

    /// Load pricing snapshot from app bundle.
    func loadFromBundle(resourceName: String = "pricing_snapshot_v1") throws -> PricingSnapshot {
        if let snap = snapshot { return snap }

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            throw PricingError.resourceMissing("\(resourceName).json")
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let snap = try decoder.decode(PricingSnapshot.self, from: data)

            guard snap.schemaVersion == 1 else { throw PricingError.unsupportedSchema(snap.schemaVersion) }
            guard snap.currency.uppercased() == "USD" else { throw PricingError.invalidSnapshot("currency must be USD") }
            guard snap.unit == "per_1m_tokens" else { throw PricingError.invalidSnapshot("unit must be per_1m_tokens") }

            // deterministic validation
            let ids = snap.models.map { $0.id }
            if Set(ids).count != ids.count {
                throw PricingError.invalidSnapshot("duplicate model ids")
            }

            snapshot = snap
            return snap
        } catch let e as PricingError {
            throw e
        } catch {
            throw PricingError.decodeFailed(error.localizedDescription)
        }
    }

    /// Resolve model price with deterministic normalization:
    /// - exact match on id or alias
    /// - else match by stripping "-YYYY-MM-DD" suffix (both sides)
    func resolve(modelName: String) throws -> PricingModelPrice {
        let snap = try loadFromBundle()

        // exact
        if let hit = snap.models.first(where: { $0.id == modelName || $0.aliases.contains(modelName) }) {
            return hit
        }

        let n = stripDateSuffix(modelName)
        if let hit = snap.models.first(where: { stripDateSuffix($0.id) == n || $0.aliases.map(stripDateSuffix).contains(n) }) {
            return hit
        }

        throw PricingError.modelNotFound(modelName)
    }

    /// Returns estimated cost in USD (Decimal) using per-1M token rates.
    func estimateCostUSD(modelName: String, inputTokens: Int, outputTokens: Int) throws -> Decimal {
        let p = try resolve(modelName: modelName)
        let oneM = Decimal(1_000_000)
        let inCost = (Decimal(inputTokens) / oneM) * p.inputPer1MTokens
        let outCost = (Decimal(outputTokens) / oneM) * p.outputPer1MTokens
        return inCost + outCost
    }

    private func stripDateSuffix(_ s: String) -> String {
        let parts = s.split(separator: "-")
        guard parts.count >= 4 else { return s }

        let y = parts[parts.count - 3]
        let m = parts[parts.count - 2]
        let d = parts[parts.count - 1]

        func isDigits(_ x: Substring, count: Int) -> Bool {
            x.count == count && x.allSatisfy { $0.isNumber }
        }

        if isDigits(y, count: 4) && isDigits(m, count: 2) && isDigits(d, count: 2) {
            return parts.dropLast(3).joined(separator: "-")
        }
        return s
    }
}
