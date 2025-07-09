import Foundation
import Security

final class KeychainHelper {

    static let shared = KeychainHelper()
    private init() {}

    // Save any Codable value
    func save<T: Codable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }

        let query: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrAccount as String:     key
        ]

        // Delete existing before adding new
        SecItemDelete(query as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrAccount as String:     key,
            kSecValueData as String:       data
        ]

        SecItemAdd(addQuery as CFDictionary, nil)
    }

    // Get any Codable value
    func get<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        let query: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrAccount as String:     key,
            kSecReturnData as String:      true,
            kSecMatchLimit as String:      kSecMatchLimitOne
        ]

        var item: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &item)

        guard let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    // Delete a single key
    func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    // Clear all in keychain
    func clearAll() {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword]
        SecItemDelete(query as CFDictionary)
    }
}

struct KeychainKeys {
    static let isSFA = "isSFA"
}

