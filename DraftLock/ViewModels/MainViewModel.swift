import Foundation
import SwiftUI
import Combine

@MainActor
final class MainViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var outputText: String = ""

    @Published var selectedMode: DraftMode = .chat {
        didSet {
            // Mode changes -> select a reasonable template
            if let d = promptStudio.defaultTemplate(for: selectedMode) {
                selectedTemplateID = d.id
            }
            scheduleTokenEstimate()
        }
    }

    @Published var selectedModel: ModelType = .gpt4oMini {
        didSet { scheduleTokenEstimate() }
    }

    @Published var selectedTemplateID: UUID? {
        didSet { scheduleTokenEstimate() }
    }

    @Published var isRunning: Bool = false
    @Published var lastError: String? = nil

    private let promptStudio: PromptStudioViewModel
    private let settings: SettingsViewModel
    private let underBar: UnderBarViewModel

    private var usageLedger: UsageLedger
    private var estimateTask: Task<Void, Never>? = nil

    private var didBootstrap = false

    init(promptStudio: PromptStudioViewModel, settings: SettingsViewModel, underBar: UnderBarViewModel) {
        self.promptStudio = promptStudio
        self.settings = settings
        self.underBar = underBar
        self.usageLedger = .empty(currency:"USD")
        
    }
    
    func bootstrap() {
        guard !didBootstrap else { return }
        didBootstrap = true

        Task { @MainActor in
            await Task.yield()
            usageLedger = LocalStorage.shared.loadOrCreateUsageLedger()
            underBar.updateTotals(from: usageLedger)
            if selectedTemplateID == nil, let d = promptStudio.defaultTemplate(for: selectedMode) {
                selectedTemplateID = d.id
            }
            scheduleTokenEstimate()
        }
    }

    func onInputChanged() {
        scheduleTokenEstimate()
    }

    var selectedTemplate: PromptTemplate? {
        if let id = selectedTemplateID, let t = promptStudio.template(by: id) { return t }
        return promptStudio.defaultTemplate(for: selectedMode)
    }

    func run() {
        lastError = nil
        let apiKey: String
        switch KeychainHelper.loadAPIKey() {
        case .success(let value):
            guard let k = value, !k.isEmpty else {
                lastError = "API Keyが未設定です（Settingsで保存してね）"
                return
            }
            apiKey = k
        case .failure:
            lastError = "API Keyの読み込みに失敗しました"
            return
        }
        guard let template = selectedTemplate else {
            lastError = "テンプレートが見つかりません"
            return
        }
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            lastError = "入力が空です"
            return
        }

        isRunning = true

        Task {
            do {
                // Build request
                let instructions = template.instructions(for: trimmed)
                let request = OpenAIResponsesRequest(
                    model: selectedModel.rawValue,
                    input: "対象テキスト:\n\n" + trimmed,
                    instructions: instructions,
                    max_output_tokens: 800
                )

                let res = try await OpenAIClient.shared.createResponse(apiKey: apiKey, request: request)
                let text = res.outputText

                outputText = text.isEmpty ? "(no output)" : text

                // Ledger (actual usage)
                let pricing = LegacyPricingSnapshot(model: selectedModel.rawValue, inputUnitPrice: 0, outputUnitPrice: 0, currency: "USD", takenAt: Date())
                let entry = UsageEntry(
                    id: UUID(),
                    date: Date(),
                    promptTemplateID: template.id,
                    model: selectedModel.rawValue,
                    mode: selectedMode,
                    inputTokens: res.inputTokens,
                    outputTokens: res.outputTokens,
                    pricing: pricing
                )

                usageLedger.append(entry)
                try? LocalStorage.shared.saveUsageLedger(usageLedger)
                underBar.updateTotals(from: usageLedger)

                // Estimate panel: after run, show actual input tokens and cost as “current” as well.
                let actualCost = pricing.estimateCost(inputTokens: res.inputTokens, outputTokens: res.outputTokens)
                underBar.updateEstimate(inputTokens: res.inputTokens, estimatedCost: actualCost, currency: pricing.currency)

                isRunning = false
            } catch {
                lastError = error.localizedDescription
                isRunning = false
            }
        }
    }

    func clearOutput() {
        outputText = ""
    }

    func resetTotals() {
        usageLedger = UsageLedger.empty(currency: "USD")
        try? LocalStorage.shared.saveUsageLedger(usageLedger)
        underBar.updateTotals(from: usageLedger)
    }

    // MARK: - Token estimate

    private func scheduleTokenEstimate() {
        estimateTask?.cancel()

        // debounce
        estimateTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            await refreshTokenEstimate()
        }
    }

    private func refreshTokenEstimate() async {
        let apiKey: String
        switch KeychainHelper.loadAPIKey() {
        case .success(let value):
            guard let k = value, !k.isEmpty else {
                underBar.updateEstimate(inputTokens: nil, estimatedCost: nil, currency: "USD")
                return
            }
            apiKey = k
        case .failure:
            underBar.updateEstimate(inputTokens: nil, estimatedCost: nil, currency: "USD")
            return
        }
        guard let template = selectedTemplate else {
            underBar.updateEstimate(inputTokens: nil, estimatedCost: nil, currency: "USD")
            return
        }
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            underBar.updateEstimate(inputTokens: nil, estimatedCost: nil, currency: "USD")
            return
        }

        do {
            let instructions = template.instructions(for: trimmed)
            let request = OpenAIResponsesRequest(
                model: selectedModel.rawValue,
                input: "対象テキスト:\n\n" + trimmed,
                instructions: instructions,
                max_output_tokens: 800
            )
            let tokens = try await OpenAIClient.shared.estimateInputTokens(apiKey: apiKey, request: request)

            let pricing = LegacyPricingSnapshot(model: selectedModel.rawValue, inputUnitPrice: 0, outputUnitPrice: 0, currency: "USD", takenAt: Date())
            // prediction: input-only (output unknown)
            let estCost = pricing.estimateCost(inputTokens: tokens, outputTokens: 0)
            underBar.updateEstimate(inputTokens: tokens, estimatedCost: estCost, currency: pricing.currency)
        } catch {
            // MVP: hide estimate errors (e.g. network)
            underBar.updateEstimate(inputTokens: nil, estimatedCost: nil, currency: "USD")
        }
    }
}

