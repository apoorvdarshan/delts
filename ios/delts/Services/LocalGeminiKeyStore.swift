import Foundation
import Security

enum LocalGeminiKeyStore {
    private static let service = "com.apoorvdarshan.delts.gemini"
    private static let account = "gemini-api-key"
    private static let fallbackAccount = "ai-fallback-api-key"

    static var apiKey: String? {
        apiKey(for: account)
    }

    static var fallbackAPIKey: String? {
        apiKey(for: fallbackAccount)
    }

    @discardableResult
    static func save(_ apiKey: String) -> Bool {
        save(apiKey, for: account)
    }

    @discardableResult
    static func saveFallback(_ apiKey: String) -> Bool {
        save(apiKey, for: fallbackAccount)
    }

    @discardableResult
    static func clear() -> Bool {
        clear(for: account)
    }

    @discardableResult
    static func clearFallback() -> Bool {
        clear(for: fallbackAccount)
    }

    private static func apiKey(for account: String) -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }

        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    @discardableResult
    private static func save(_ apiKey: String, for account: String) -> Bool {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else {
            return clear(for: account)
        }

        var query = baseQuery(account: account)
        let attributes = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ] as [String: Any]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return true
        }

        query.merge(attributes) { _, new in new }
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    @discardableResult
    private static func clear(for account: String) -> Bool {
        let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    private static func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
