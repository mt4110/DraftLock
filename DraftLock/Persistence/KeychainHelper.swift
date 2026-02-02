import Foundation
import Security

enum KeychainError: LocalizedError {
    case osStatus(OSStatus, String)

    var errorDescription: String? {
        switch self {
        case let .osStatus(_, message):
            return message
        }
    }

    static func message(for status: OSStatus, operation: String) -> KeychainError {
        let msg = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error"
        return .osStatus(status, "\(operation) failed: \(msg) (\(status))")
    }
}

final class KeychainHelper {
    // 既存の service/account を維持（互換性）
    static let service = "DraftLock.OpenAI"
    static let account = "apiKey"

    // 識別子だけのクエリ（検索・削除に使う）
    private static func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    /// 保存（存在すれば update / 無ければ add）
    static func saveAPIKey(_ key: String) -> Result<Void, KeychainError> {
        guard let data = key.data(using: .utf8), !data.isEmpty else {
            return .failure(.osStatus(errSecParam, "saveAPIKey failed: empty key"))
        }

        // まず update を試す
        let query = baseQuery()
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: data
        ]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

        if updateStatus == errSecSuccess {
            return .success(())
        }

        if updateStatus != errSecItemNotFound {
            return .failure(KeychainError.message(for: updateStatus, operation: "SecItemUpdate"))
        }

        // 無いなら add
        var addQuery = baseQuery()
        addQuery[kSecValueData as String] = data

        // “端末限定＆ロック解除中のみアクセス可”寄り（macOSでもOK）
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus == errSecSuccess {
            return .success(())
        }
        return .failure(KeychainError.message(for: addStatus, operation: "SecItemAdd"))
    }

    /// 読み出し
    static func loadAPIKey() -> Result<String?, KeychainError> {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return .success(nil)
        }
        guard status == errSecSuccess else {
            return .failure(KeychainError.message(for: status, operation: "SecItemCopyMatching"))
        }
        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8),
              !string.isEmpty else {
            return .success(nil)
        }
        return .success(string)
    }

    /// 削除
    static func deleteAPIKey() -> Result<Void, KeychainError> {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            return .success(())
        }
        return .failure(KeychainError.message(for: status, operation: "SecItemDelete"))
    }
}
