@testable import Web3Auth
import Security
import XCTest

/**
 Ensures logout Keychain cleanup cannot wipe the host app's generic passwords.
 */
final class KeychainHelperTests: XCTestCase {
    private var unrelatedAccount: String!

    override func setUp() {
        super.setUp()
        unrelatedAccount = "app.unrelated.test.\(UUID().uuidString)"
        deleteGenericPassword(account: unrelatedAccount, service: nil)
        KeychainHelper.shared.delete(forKey: KeychainKeys.isSFA)
    }

    override func tearDown() {
        deleteGenericPassword(account: unrelatedAccount, service: nil)
        KeychainHelper.shared.delete(forKey: KeychainKeys.isSFA)
        unrelatedAccount = nil
        super.tearDown()
    }

    func testAllKnownKeysAreExplicitAllowlist() {
        XCTAssertEqual(KeychainKeys.all, [KeychainKeys.isSFA])
        XCTAssertFalse(KeychainKeys.all.isEmpty)
        XCTAssertEqual(KeychainHelper.service, "com.web3auth.swift-sdk.keychain")
    }

    func testClearAllDoesNotDeleteUnrelatedGenericPasswords() throws {
        try requireKeychainAccess()

        let unrelatedValue = Data("host-app-secret".utf8)
        let addStatus = SecItemAdd(
            [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: unrelatedAccount!,
                kSecValueData as String: unrelatedValue
            ] as CFDictionary,
            nil
        )
        XCTAssertEqual(addStatus, errSecSuccess)

        KeychainHelper.shared.save(true, forKey: KeychainKeys.isSFA)
        XCTAssertEqual(KeychainHelper.shared.get(forKey: KeychainKeys.isSFA, as: Bool.self), true)

        // Simulates Web3Auth.logout() Keychain cleanup.
        KeychainHelper.shared.clearAll()

        XCTAssertNil(
            KeychainHelper.shared.get(forKey: KeychainKeys.isSFA, as: Bool.self),
            "Web3Auth isSFA flag should be removed on clearAll"
        )

        var item: AnyObject?
        let copyStatus = SecItemCopyMatching(
            [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: unrelatedAccount!,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ] as CFDictionary,
            &item
        )
        XCTAssertEqual(copyStatus, errSecSuccess, "Host-app Keychain item must survive clearAll")
        XCTAssertEqual(item as? Data, unrelatedValue)
    }

    func testClearAllRemovesLegacyIsSFAWithoutService() throws {
        try requireKeychainAccess()

        // 13.0.0 wrote isSFA without kSecAttrService.
        let encoded = try JSONEncoder().encode(true)
        let addStatus = SecItemAdd(
            [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: KeychainKeys.isSFA,
                kSecValueData as String: encoded
            ] as CFDictionary,
            nil
        )
        XCTAssertEqual(addStatus, errSecSuccess)

        XCTAssertEqual(
            KeychainHelper.shared.get(forKey: KeychainKeys.isSFA, as: Bool.self),
            true,
            "Legacy account-only isSFA should still be readable"
        )

        KeychainHelper.shared.clearAll()

        XCTAssertNil(KeychainHelper.shared.get(forKey: KeychainKeys.isSFA, as: Bool.self))
        var item: AnyObject?
        let copyStatus = SecItemCopyMatching(
            [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: KeychainKeys.isSFA,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ] as CFDictionary,
            &item
        )
        XCTAssertEqual(copyStatus, errSecItemNotFound)
    }

    /// SPM test hosts often lack Keychain entitlements (-34018). Skip instead of false-fail.
    private func requireKeychainAccess() throws {
        let probeAccount = "web3auth.keychain.probe.\(UUID().uuidString)"
        let status = SecItemAdd(
            [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: probeAccount,
                kSecValueData as String: Data("probe".utf8)
            ] as CFDictionary,
            nil
        )
        SecItemDelete(
            [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: probeAccount
            ] as CFDictionary
        )
        if status == errSecMissingEntitlement {
            throw XCTSkip("Keychain entitlements unavailable in this test host (errSecMissingEntitlement)")
        }
        guard status == errSecSuccess else {
            throw XCTSkip("Keychain unavailable in this test host (OSStatus \(status))")
        }
    }

    private func deleteGenericPassword(account: String, service: String?) {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        if let service {
            query[kSecAttrService as String] = service
        }
        SecItemDelete(query as CFDictionary)
    }
}
