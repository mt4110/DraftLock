import Foundation

struct PricingSnapshot: Decodable {
    let schemaVersion: Int
    let pricingId: String
    let effectiveDate: String
    let currency: String
    let unit: String
    let source: String
    let models: [PricingModelPrice]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case pricingId = "pricing_id"
        case effectiveDate = "effective_date"
        case currency
        case unit
        case source
        case models
    }
}

struct PricingModelPrice: Decodable {
    let id: String
    let aliases: [String]
    let inputPer1MTokens: Decimal
    let cachedInputPer1MTokens: Decimal?
    let outputPer1MTokens: Decimal

    enum CodingKeys: String, CodingKey {
        case id
        case aliases
        case inputPer1MTokens = "input_per_1m_tokens"
        case cachedInputPer1MTokens = "cached_input_per_1m_tokens"
        case outputPer1MTokens = "output_per_1m_tokens"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        aliases = (try? c.decode([String].self, forKey: .aliases)) ?? []

        inputPer1MTokens = try c.decodeDecimal(forKey: .inputPer1MTokens)
        cachedInputPer1MTokens = try c.decodeDecimalIfPresent(forKey: .cachedInputPer1MTokens)
        outputPer1MTokens = try c.decodeDecimal(forKey: .outputPer1MTokens)
    }
}

// MARK: - Decimal decode helpers (deterministic; prefer string values in JSON)
private extension KeyedDecodingContainer {
    func decodeDecimal(forKey key: K) throws -> Decimal {
        if let s = try? decode(String.self, forKey: key),
           let d = Decimal(string: s, locale: Locale(identifier: "en_US_POSIX")) {
            return d
        }
        if let dbl = try? decode(Double.self, forKey: key),
           let d = Decimal(string: String(dbl), locale: Locale(identifier: "en_US_POSIX")) {
            return d
        }
        throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Invalid decimal value")
    }

    func decodeDecimalIfPresent(forKey key: K) throws -> Decimal? {
        if let s = try? decodeIfPresent(String.self, forKey: key) {
            if let s, let d = Decimal(string: s, locale: Locale(identifier: "en_US_POSIX")) { return d }
            if s == nil { return nil }
        }
        if let dbl = try? decodeIfPresent(Double.self, forKey: key) {
            if let dbl, let d = Decimal(string: String(dbl), locale: Locale(identifier: "en_US_POSIX")) { return d }
            if dbl == nil { return nil }
        }
        return nil
    }
}
