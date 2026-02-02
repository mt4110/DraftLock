import SwiftUI

struct SettingsView: View {
    @ObservedObject var vm: SettingsViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("OpenAI API Key") {
                    if vm.hasAPIKey {
                        HStack {
                            Image(systemName: "checkmark.seal")
                            Text("API key saved in Keychain")
                        }
                        Button(role: .destructive) {
                            vm.deleteAPIKey()
                        } label: {
                            Text("Delete API key")
                        }
                    } else {
                        SecureField("sk-...", text: $vm.apiKeyInput)
                        Button("Save") { vm.saveAPIKey() }
                            .disabled(vm.apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    if let msg = vm.message {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Privacy") {
                    Text("MVPでは入力本文は保存しません（Usageはトークン/金額のみ記録）。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .task { vm.refresh() }
        }
    }
}
