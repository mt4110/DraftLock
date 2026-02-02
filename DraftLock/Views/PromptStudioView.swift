import SwiftUI

struct PromptStudioView: View {
    @ObservedObject var vm: PromptStudioViewModel

    @State private var editorTarget: PromptTemplate? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.templates) { t in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(t.name)
                                .font(.headline)
                            Spacer()
                            Text(t.mode.displayName)
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                        Text(t.body)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button("Edit") { editorTarget = t }
                        Button("Duplicate") { vm.duplicate(t) }
                        Button(role: .destructive) { vm.delete(t) } label: { Text("Delete") }
                    }
                    .onTapGesture {
                        editorTarget = t
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet {
                        if i < vm.templates.count {
                            vm.delete(vm.templates[i])
                        }
                    }
                }
            }
            .navigationTitle("Templates")
            .toolbar(content: {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        // Create a new blank template and present the editor via editorTarget
                        editorTarget = PromptTemplate(
                            id: UUID(),
                            name: "New Template",
                            mode: .chat,
                            body: "",
                            isDefault: false,
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                    }) {
                        Label("Add", systemImage: "plus")
                    }
                }
            })
            .sheet(item: $editorTarget) { t in
                PromptEditorView(
                    initial: t,
                    modeLocked: false,
                    onSave: { updated in
                        // Persist the updated or newly created template
                        vm.upsert(template: updated)
                        // Dismiss the sheet
                        editorTarget = nil
                    },
                    onCancel: {
                        // Dismiss the sheet without saving
                        editorTarget = nil
                    }
                )
            }
        }
    }
}

