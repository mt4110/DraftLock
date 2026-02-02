import Foundation

struct PromptTemplate: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var mode: DraftMode

    /// Template text (typically used as `instructions` for the Responses API).
    /// If you want to embed the user's text into the template, use the placeholder `{{input}}`.
    var body: String

    var isDefault: Bool
    var createdAt: Date
    var updatedAt: Date
    var version: Int

    func render(input: String) -> String {
        body.replacingOccurrences(of: "{{input}}", with: input)
    }

    init(
        id: UUID = UUID(),
        name: String,
        mode: DraftMode,
        body: String,
        isDefault: Bool,
        createdAt: Date,
        updatedAt: Date,
        version: Int = 1
    ) {
        self.id = id
        self.name = name
        self.mode = mode
        self.body = body
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.version = version
    }

    init(seed: PromptTemplateSeed, isDefault: Bool, now: Date) {
        self.init(
            id: UUID(),
            name: seed.name,
            mode: seed.mode,
            body: seed.body,
            isDefault: isDefault,
            createdAt: now,
            updatedAt: now,
            version: 1
        )
    }

    func refreshed(updatedAt now: Date) -> PromptTemplate {
        var copy = self
        copy.updatedAt = now
        copy.version += 1
        return copy
    }
}
