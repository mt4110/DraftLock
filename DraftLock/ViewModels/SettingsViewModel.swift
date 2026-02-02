import Foundation
import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var hasAPIKey: Bool = false
    @Published var apiKeyInput: String = ""
    @Published var message: String? = nil

    @Published private(set) var settings: Settings

    init() {
        self.settings = LocalStorage.shared.loadOrCreateSettings()
        refresh()
    }

    func refresh() {
        switch KeychainHelper.loadAPIKey() {
        case .success(let key):
            let exists = (key != nil)
            hasAPIKey = exists
            settings.apiKeyExists = exists
            try? LocalStorage.shared.saveSettings(settings)
        case .failure(let err):
            // Keychainが読めないなら「無い扱い」にしつつ、理由を表示
            hasAPIKey = false
            settings.apiKeyExists = false
            try? LocalStorage.shared.saveSettings(settings)
            message = err.localizedDescription
        }
    }

    func saveAPIKey() {
        message = nil
        let key = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            message = "API Keyが空です"
            return
        }

        switch KeychainHelper.saveAPIKey(key) {
        case .success:
            apiKeyInput = ""          // メモリに残しにくくする
            message = "API Keyを保存しました"
            refresh()
        case .failure(let err):
            message = err.localizedDescription
            refresh()
        }
    }

    func deleteAPIKey() {
        message = nil
        switch KeychainHelper.deleteAPIKey() {
        case .success:
            message = "API Keyを削除しました"
            refresh()
        case .failure(let err):
            message = err.localizedDescription
            refresh()
        }
    }
}
