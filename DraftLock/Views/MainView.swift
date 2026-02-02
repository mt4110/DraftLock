import SwiftUI

struct MainView: View {
    @ObservedObject var vm: MainViewModel
    @ObservedObject var promptStudio: PromptStudioViewModel
    @ObservedObject var underBar: UnderBarViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

            Divider()

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Input")
                        .font(.headline)
                    TextEditor(text: $vm.inputText)
                        .font(.body)
                        .onChange(of: vm.inputText) {
                            vm.onInputChanged()
                        }
                        .overlay(alignment: .topLeading) {
                            if vm.inputText.isEmpty {
                                Text("ここに文章を貼る")
                                    .foregroundStyle(.secondary)
                                    .padding(8)
                            }
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Output")
                        .font(.headline)
                    TextEditor(text: $vm.outputText)
                        .font(.body)
                        .disabled(true)
                        .overlay(alignment: .topLeading) {
                            if vm.outputText.isEmpty {
                                Text("結果がここに出る")
                                    .foregroundStyle(.secondary)
                                    .padding(8)
                            }
                        }
                }
            }
            .padding(12)

            Divider()

            UnderBarView(vm: underBar)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Picker("Mode", selection: $vm.selectedMode) {
                ForEach(DraftMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 320)

            Picker("Model", selection: $vm.selectedModel) {
                ForEach(ModelType.allCases) { model in
                    Text(model.displayName).tag(model)
                }
            }
            .pickerStyle(.menu)

            templateMenu

            Spacer()

            if let err = vm.lastError {
                Text(err)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            }

            Button {
                Task { vm.run() }
            } label: {
                if vm.isRunning {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Run")
                }
            }
            .disabled(vm.isRunning || vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button {
                vm.outputText = ""
                vm.lastError = nil
            } label: {
                Text("Clear")
            }
            .disabled(vm.isRunning)
        }
    }

    private var templateMenu: some View {
        let templates = promptStudio.templates(for: vm.selectedMode)
        let selectedTemplate = vm.selectedTemplate

        return Menu {
            if templates.isEmpty {
                Text("No templates")
            } else {
                ForEach(templates) { t in
                    Button {
                        vm.selectedTemplateID = t.id
                        vm.onInputChanged()
                    } label: {
                        if t.id == selectedTemplate?.id {
                            Label(t.name, systemImage: "checkmark")
                        } else {
                            Text(t.name)
                        }
                    }
                }
            }
        } label: {
            Label(selectedTemplate?.name ?? "Template", systemImage: "text.badge.plus")
        }
        .disabled(templates.isEmpty)
    }
}

