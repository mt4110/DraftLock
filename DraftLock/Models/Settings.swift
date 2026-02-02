import Foundation

struct Settings: Codable {
    var apiKeyExists: Bool

    /// If true, store request bodies in local history.
    /// MVP: keep false.
    var shouldStoreBody: Bool

    var schemaVersion: Int

    static func `default`() -> Settings {
        Settings(apiKeyExists: false, shouldStoreBody: false, schemaVersion: 1)
    }
}
