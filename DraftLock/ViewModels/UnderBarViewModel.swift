import Combine
import Foundation
import SwiftUI

@MainActor
final class UnderBarViewModel: ObservableObject {
    @Published var currentInputTokens: Int? = nil
    @Published var currentEstimatedCost: Double? = nil
    @Published var currentCurrency: String = "USD"

    @Published var totalInputTokens: Int = 0
    @Published var totalOutputTokens: Int = 0
    @Published var totalCost: Double = 0
    @Published var totalCurrency: String = "USD"

    func updateEstimate(inputTokens: Int?, estimatedCost: Double?, currency: String) {
        self.currentInputTokens = inputTokens
        self.currentEstimatedCost = estimatedCost
        self.currentCurrency = currency
    }

    func updateTotals(from ledger: UsageLedger) {
        self.totalInputTokens = ledger.totalInputTokens
        self.totalOutputTokens = ledger.totalOutputTokens
        self.totalCost = ledger.totalCost
        self.totalCurrency = ledger.currency
    }
}

