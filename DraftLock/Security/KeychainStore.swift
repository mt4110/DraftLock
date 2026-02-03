import Foundation
import Security

/// SECURITY RULES (MUST NOT BREAK)
/// - Stored API key MUST NOT be displayed in UI.
/// - Do not log / print the key value.
/// - Keychain is the single source of truth for the secret.
///
/// NOTE:
/// - This store reads the key only for internal use (e.g. connectivity test),
///   but never exposes it to UI as a string to display.
final class KeychainStore {
    enum KeychainError: Error, LocalizedError {
        case unexpectedStatus(OSStatus)
        case decodeFailed

        var errorDescription: String? {
            switch self {
            case .unexpectedStatus(let status):
                return "Keychain error (status=\(status))"
            case .decodeFailed:
                return "Failed to decode key data."
            }
        }
    }

    private let service: String
    private let account: String

    /// service: defaults to bundle identifier (stable, app-scoped)
    /// account: logical slot name
    init(
        service: String = Bundle.main.bundleIdentifier ?? "DraftLock",
        account: String = "openai_api_key"
    ) {
        self.service = service
        self.account = account
    }

    /// Returns true if a key exists in Keychain.
    func hasKey() -> Bool {
        do {
            return try loadKey() != nil
        } catch {
            return false
        }
    }

    /// Loads the key for internal use. Do NOT display it in UI.
    func loadKey() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        guard let data = item as? Data else {
            throw KeychainError.decodeFailed
        }
        guard let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodeFailed
        }
        return key
    }

    /// Saves (upserts) the key.
    func saveKey(_ key: String) throws {
        let data = Data(key.utf8)

        // Try update first
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        // If not found, add.
        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(addStatus)
            }
            return
        }

        throw KeychainError.unexpectedStatus(updateStatus)
    }

    /// Deletes the key (if present).
    func deleteKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            return
        }
        throw KeychainError.unexpectedStatus(status)
    }
}
