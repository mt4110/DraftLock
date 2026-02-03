import SwiftUI

/// SECURITY RULE (UI):
/// - Never display the stored API key value.
/// - Only show status (present/missing/error states) and allow save/delete/test.
struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()

    var body: some View {
        Form {
            Section("APIキー") {
                HStack(spacing: 8) {
                    Text("状態")
                    Spacer()
                    statusPill
                }

                SecureField("APIキーを貼り付け（保存後は表示しません）", text: $vm.apiKeyInput)
                    .textContentType(.password)

                HStack {
                    Button("保存") { vm.saveKey() }
                        .keyboardShortcut(.defaultAction)
                    Button("削除") { vm.deleteKey() }
                    Spacer()
                    Button("接続テスト") { vm.testConnection() }
                        .disabled(!canTest)
                }

                if let msg = vm.lastActionMessage, !msg.isEmpty {
                    Text(msg)
                        .font(.callout)
                }

                testStatusView
            }

            Section("安全性") {
                Text("・保存済みのキーは画面に表示しません（復元表示もしません）。")
                Text("・キーはKeychainのみを“唯一の正”として扱います。")
                Text("・ログ出力やScheme/env/UserDefaultsへの保存は禁止。")
            }
        }
        .padding(16)
        .frame(minWidth: 520, minHeight: 360)
        .onAppear { vm.refreshStatus() }
    }

    private var canTest: Bool {
        switch vm.keyStatus {
        case .present: return true
        default: return false
        }
    }

    @ViewBuilder
    private var statusPill: some View {
        switch vm.keyStatus {
        case .unknown:
            Text("確認中")
                .foregroundStyle(.secondary)
        case .missing:
            Label("未設定", systemImage: "xmark.circle")
                .foregroundStyle(.secondary)
        case .present:
            Label("保存済み", systemImage: "checkmark.seal")
        case .error:
            Label("エラー", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var testStatusView: some View {
        switch vm.testStatus {
        case .idle:
            EmptyView()
        case .testing:
            HStack(spacing: 8) {
                ProgressView()
                Text("接続テスト中…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        case .ok:
            Label("接続OK", systemImage: "checkmark.circle.fill")
                .font(.callout)
        case .failed(let reason):
            VStack(alignment: .leading, spacing: 4) {
                Label("接続NG", systemImage: "xmark.octagon.fill")
                    .font(.callout)
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
