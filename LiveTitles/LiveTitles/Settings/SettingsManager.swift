import Foundation
import Security

final class SettingsManager {
    static let shared = SettingsManager()

    private let keychainService = "com.livetitles"

    // MARK: - API Keys (Keychain)

    var deepgramAPIKey: String {
        get { keychainRead(account: "deepgram") ?? "" }
        set { keychainSave(value: newValue, account: "deepgram") }
    }

    var anthropicAPIKey: String {
        get { keychainRead(account: "anthropic") ?? "" }
        set { keychainSave(value: newValue, account: "anthropic") }
    }

    var picovoiceAccessKey: String {
        get { keychainRead(account: "picovoice") ?? "" }
        set { keychainSave(value: newValue, account: "picovoice") }
    }

    // MARK: - Keychain Helpers

    private func keychainSave(value: String, account: String) {
        let data = Data(value.utf8)

        // Delete existing
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        guard !value.isEmpty else { return }

        // Add new
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private func keychainRead(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}
