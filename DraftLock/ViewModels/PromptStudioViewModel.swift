import Foundation
import Combine
import SwiftUI

@MainActor
final class PromptStudioViewModel: ObservableObject {
    @Published private(set) var templates: [PromptTemplate] = []

    init() {
        reload()
    }

    func reload() {
        templates = LocalStorage.shared.loadOrCreatePromptTemplates()
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func templates(for mode: DraftMode) -> [PromptTemplate] {
        templates.filter { $0.mode == mode }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func defaultTemplate(for mode: DraftMode) -> PromptTemplate? {
        // Prefer default seed templates first, then most recently edited.
        let list = templates(for: mode)
        if let d = list.first(where: { $0.isDefault }) { return d }
        return list.first
    }

    func template(by id: UUID) -> PromptTemplate? {
        templates.first(where: { $0.id == id })
    }

    func addNew(name: String, mode: DraftMode, body: String) {
        let now = Date()
        let t = PromptTemplate(
            id: UUID(),
            name: name,
            mode: mode,
            body: body,
            isDefault: false,
            createdAt: now,
            updatedAt: now,
            version: 1
        )
        templates.insert(t, at: 0)
        persist()
    }

    func update(_ updated: PromptTemplate) {
        guard let idx = templates.firstIndex(where: { $0.id == updated.id }) else { return }
        templates[idx] = updated
        persist()
    }

    func delete(_ template: PromptTemplate) {
        templates.removeAll { $0.id == template.id }
        persist()
    }

    func duplicate(_ template: PromptTemplate) {
        let now = Date()
        let t = PromptTemplate(
            id: UUID(),
            name: template.name + " (copy)",
            mode: template.mode,
            body: template.body,
            isDefault: false,
            createdAt: now,
            updatedAt: now,
            version: 1
        )
        templates.insert(t, at: 0)
        persist()
    }

    func upsert(template: PromptTemplate) {
        if let idx = templates.firstIndex(where: { $0.id == template.id }) {
            templates[idx] = template
        } else {
            templates.insert(template, at: 0)
        }
        persist()
    }

    private func persist() {
        do {
            try LocalStorage.shared.savePromptTemplates(templates)
        } catch {
            // MVP: swallow. In future, surface error.
        }
    }
}

