import Foundation

final class LocalStorage {
    static let shared = LocalStorage()
    private init() {}

    private enum FileName {
        static let promptTemplates = "promptTemplates.json"
        static let usageLedger = "usageLedger.json"
        static let settings = "settings.json"
    }

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private func fileURL(_ name: String) throws -> URL {
        try AppDirectories.applicationSupportDirectory().appendingPathComponent(name)
    }

    // MARK: - Generic I/O

    private func load<T: Decodable>(_ type: T.Type, from file: String) throws -> T {
        let url = try fileURL(file)
        let data = try Data(contentsOf: url)
        return try decoder.decode(type, from: data)
    }

    private func save<T: Encodable>(_ value: T, to file: String) throws {
        let url = try fileURL(file)
        let data = try encoder.encode(value)
        try data.write(to: url, options: [.atomic])
    }

    // MARK: - Prompt Templates

    func loadOrCreatePromptTemplates() -> [PromptTemplate] {
        do {
            return try load([PromptTemplate].self, from: FileName.promptTemplates)
        } catch {
            let now = Date()
            let defaults = bundledPromptTemplateSeeds().enumerated().map { idx, seed in
                PromptTemplate(seed: seed, isDefault: idx == 0, now: now)
            }
            do { try save(defaults, to: FileName.promptTemplates) } catch { /* best-effort */ }
            return defaults
        }
    }

    func savePromptTemplates(_ templates: [PromptTemplate]) throws {
        try save(templates, to: FileName.promptTemplates)
    }

    // MARK: - Settings

    func loadOrCreateSettings() -> Settings {
        do {
            return try load(Settings.self, from: FileName.settings)
        } catch {
            let s = Settings.default()
            do { try save(s, to: FileName.settings) } catch { /* best-effort */ }
            return s
        }
    }

    func saveSettings(_ settings: Settings) throws {
        try save(settings, to: FileName.settings)
    }

    // MARK: - Usage Ledger

    func loadOrCreateUsageLedger() -> UsageLedger {
        do {
            var ledger = try load(UsageLedger.self, from: FileName.usageLedger)
            ledger.rebuildTotals()
            return ledger
        } catch {
            let ledger = UsageLedger.empty(currency: "USD")
            do { try save(ledger, to: FileName.usageLedger) } catch { /* best-effort */ }
            return ledger
        }
    }

    func saveUsageLedger(_ ledger: UsageLedger) throws {
        try save(ledger, to: FileName.usageLedger)
    }

    // MARK: - Defaults (bundled)

    private func bundledPromptTemplateSeeds() -> [PromptTemplateSeed] {
        // 1) Try bundle JSON.
        if let url = Bundle.main.url(forResource: "DefaultPromptTemplates", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let seeds = try? decoder.decode([PromptTemplateSeed].self, from: data),
           !seeds.isEmpty {
            return seeds
        }

        // 2) Fallback defaults (keeps app usable even if Resources aren't copied).
        return [
            PromptTemplateSeed(
                name: "Slack: 結論先・短文",
                mode: .chat,
                body: """
あなたはSlack投稿用の文章編集アシスタント。

ルール:
- 1行目に結論（最重要）
- 1文は40文字以内（目安）
- 背景説明は最大2文
- 感情語・自己弁護・過度な丁寧語は削る
- 読みやすさ優先で、必要なら箇条書き

出力は日本語。
"""
            ),
            PromptTemplateSeed(
                name: "Doc: 背景/課題/決定/次",
                mode: .doc,
                body: """
次の文章を、指定セクションに整理してまとめて。

セクション:
- Background（背景）
- Issue（課題）
- Decision（決定）
- Next Action（次のアクション）

ルール:
- 事実と意見を分離
- 曖昧表現を削る
- 可能なら箇条書き

出力は日本語。
"""
            ),
            PromptTemplateSeed(
                name: "PR: What/Why/How/Risk/Test",
                mode: .pr,
                body: """
次の変更内容をGitHub Pull Request本文（Markdown）に変換して。

必須セクション:
- What
- Why
- How
- Risk
- Test

ルール:
- 断定できないことは推測しない
- 差分が伝わる具体性
- 箇条書き中心

出力は日本語。
"""
            ),
            PromptTemplateSeed(
                name: "Notion: 整理して貼れる形",
                mode: .notion,
                body: """
次の文章をNotionに貼れる形（見出し＋箇条書き）で整理して。

ルール:
- 重要→詳細の順
- 用語は初出で短く補足
- 曖昧表現を削る

出力は日本語。
"""
            ),
            PromptTemplateSeed(
                name: "Mail: 件名＋本文",
                mode: .mail,
                body: """
次の要件を、ビジネスメール（日本語）として作成して。

出力フォーマット:
- 件名:
- 本文:

ルール:
- 用件は冒頭で明確に
- 1段落は短く
- 過度にへりくだらない（淡々と）
"""
            )
        ]
    }
}

