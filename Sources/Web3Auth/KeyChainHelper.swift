import Foundation
import Security

final class KeychainHelper {

    static let shared = KeychainHelper()

    /// Isolates Web3Auth KeychainHelper items from the host app and from
    /// SessionManager / other libraries that also use generic passwords.
    static let service = "com.web3auth.swift-sdk.keychain"

    private init() {}

    // Save any Codable value
    func save<T: Codable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }

        // Remove any prior value (scoped + legacy account-only) before insert.
        delete(forKey: key)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemAdd(addQuery as CFDictionary, nil)
    }

    // Get any Codable value
    func get<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        if let value: T = read(forKey: key, as: type, includeService: true) {
            return value
        }
        // Legacy items written before service scoping (e.g. "isSFA" on 13.0.0).
        return read(forKey: key, as: type, includeService: false)
    }

    // Delete a single key (scoped + legacy account-only variants).
    func delete(forKey key: String) {
        SecItemDelete(query(account: key, includeService: true) as CFDictionary)
        SecItemDelete(query(account: key, includeService: false) as CFDictionary)
    }

    /// Removes only Web3Auth-owned KeychainHelper accounts.
    /// Does **not** delete the host app's (or SessionManager's) generic passwords.
    func clearAll() {
        for key in KeychainKeys.all {
            delete(forKey: key)
        }
    }

    private func read<T: Codable>(forKey key: String, as type: T.Type, includeService: Bool) -> T? {
        var query = query(account: key, includeService: includeService)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &item)

        guard let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func query(account: String, includeService: Bool) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        if includeService {
            query[kSecAttrService as String] = Self.service
        }
        return query
    }
}

struct KeychainKeys {
    static let isSFA = "isSFA"

    /// Every account KeychainHelper is allowed to create or wipe on logout.
    /// Add new SDK keys here — never rely on wiping the whole Keychain class.
    static let all: [String] = [isSFA]
}