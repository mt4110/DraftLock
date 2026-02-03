import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    enum KeyStatus: Equatable {
        case unknown
        case missing
        case present
        case error(String)
    }

    enum TestStatus: Equatable {
        case idle
        case testing
        case ok
        case failed(String)
    }

    // SECURITY NOTE:
    // - `apiKeyInput` is only for user input. It must be cleared after save.
    // - We never bind the stored Keychain value to UI.
    @Published var apiKeyInput: String = ""
    @Published var keyStatus: KeyStatus = .unknown
    @Published var testStatus: TestStatus = .idle
    @Published var lastActionMessage: String? = nil

    private let keychain: KeychainStore

    init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
    }

    func refreshStatus() {
        do {
            let has = keychain.hasKey()
            keyStatus = has ? .present : .missing
        } catch {
            keyStatus = .error(error.localizedDescription)
        }
    }

    func saveKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            lastActionMessage = "APIキーが空です。"
            return
        }

        do {
            try keychain.saveKey(trimmed)
            apiKeyInput = "" // important: clear input
            lastActionMessage = "保存しました。"
            refreshStatus()
        } catch {
            lastActionMessage = "保存に失敗: \(error.localizedDescription)"
            keyStatus = .error(error.localizedDescription)
        }
    }

    func deleteKey() {
        do {
            try keychain.deleteKey()
            lastActionMessage = "削除しました。"
            testStatus = .idle
            refreshStatus()
        } catch {
            lastActionMessage = "削除に失敗: \(error.localizedDescription)"
            keyStatus = .error(error.localizedDescription)
        }
    }

    func testConnection() {
        Task {
            await runConnectionTest()
        }
    }

    private func runConnectionTest() async {
        testStatus = .testing
        lastActionMessage = nil

        do {
            guard let key = try keychain.loadKey(), !key.isEmpty else {
                testStatus = .failed("APIキーが未設定です。")
                return
            }

            // Minimal, low-cost check: list models endpoint
            let url = URL(string: "https://api.openai.com/v1/models")!
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            req.timeoutInterval = 10

            let (_, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else {
                testStatus = .failed("HTTPレスポンスが不正です。")
                return
            }

            if (200..<300).contains(http.statusCode) {
                testStatus = .ok
                lastActionMessage = "接続OK（キー有効）"
                return
            }

            if http.statusCode == 401 {
                testStatus = .failed("認証失敗（401）: キーが無効か権限不足です。")
                return
            }

            testStatus = .failed("接続失敗（status=\(http.statusCode)）")
        } catch {
            testStatus = .failed("接続失敗: \(error.localizedDescription)")
        }
    }
}
