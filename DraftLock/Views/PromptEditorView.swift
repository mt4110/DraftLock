import SwiftUI

struct PromptEditorView: View {
    let modeLocked: Bool
    let onSave: (PromptTemplate) -> Void
    let onCancel: () -> Void

    @State private var working: PromptTemplate

    init(initial: PromptTemplate, modeLocked: Bool, onSave: @escaping (PromptTemplate) -> Void, onCancel: @escaping () -> Void) {
        self.modeLocked = modeLocked
        self.onSave = onSave
        self.onCancel = onCancel
        _working = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Meta") {
                    TextField("Name", text: $working.name)
                    if modeLocked {
                        Text(working.mode.displayName)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Mode", selection: $working.mode) {
                            ForEach(DraftMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                    }
                }

                Section("Body") {
                    TextEditor(text: $working.body)
                        .frame(minHeight: 220)
                        .font(.body)
                    Text("Tip: use {{input}} if you want to embed the input inside this template.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Edit Template")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        working.updatedAt = Date()
                        working.version += 1
                        onSave(working)
                    }
                    .disabled(working.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
