//
//  SecureStorage.swift
//  Greycats
//
//  Created by Rex Sheng on 2021/12/30.
//

import Foundation

private class KeychainInterface {
    enum KeychainError: Error {
        // Attempted read for an item that does not exist.
        case itemNotFound

        // Attempted save to override an existing item.
        // Use update instead of save to update existing items
        case duplicateItem

        // A read of an item in any format other than Data
        case invalidItemFormat

        // Any operation result status than errSecSuccess
        case unexpectedStatus(OSStatus)
    }

    static func save(password: Data, service: String, account: String) throws {
        var query: [String: AnyObject] = [
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: account as AnyObject,
            kSecClass as String: kSecClassGenericPassword
        ]

        let attributes: [String: AnyObject] = [
            kSecValueData as String: password as AnyObject
        ]

        let status = SecItemUpdate(
            query as CFDictionary,
            attributes as CFDictionary
        )

        if status == errSecItemNotFound {
            query[kSecValueData as String] = password as AnyObject
            let status = SecItemAdd(
                query as CFDictionary,
                nil
            )
            guard status == errSecSuccess else {
                throw KeychainError.unexpectedStatus(status)
            }
        } else {
            guard status == errSecSuccess else {
                throw KeychainError.unexpectedStatus(status)
            }
        }
    }

    static func get(service: String, account: String) throws -> Data {
        let query: [String: AnyObject] = [
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: account as AnyObject,
            kSecClass as String: kSecClassGenericPassword,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: kCFBooleanTrue
        ]

        var itemCopy: AnyObject?
        let status = SecItemCopyMatching(
            query as CFDictionary,
            &itemCopy
        )

        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }

        guard let password = itemCopy as? Data else {
            throw KeychainError.invalidItemFormat
        }

        return password
    }
}

@propertyWrapper
public struct Keychain {
    private let key: String
    private let defaultValue: String

    public var wrappedValue: String {
        get { fatalError("Wrapped value should not be used.") }
        set { fatalError("Wrapped value should not be used. \(newValue)") }
    }

    public init(wrappedValue: String, _ key: String) {
        self.defaultValue = wrappedValue
        self.key = key
    }

    public static subscript<T: Preferences>(
        _enclosingInstance instance: T,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, String>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, Self>
    ) -> String {
        get {
            let key = instance[keyPath: storageKeyPath].key
            let defaultValue = instance[keyPath: storageKeyPath].defaultValue

            do {
                let data = try KeychainInterface.get(service: Bundle.main.bundleIdentifier ?? "GreycatsPreference", account: key)
                return String(data: data, encoding: .utf8) ?? defaultValue
            } catch {
                return defaultValue
            }
        }
        set {
            let key = instance[keyPath: storageKeyPath].key
            do {
                try KeychainInterface.save(password: newValue.data(using: .utf8) ?? Data(), service: Bundle.main.bundleIdentifier ?? "", account: key)
            } catch {
            }
            instance.preferencesChangedSubject.send(wrappedKeyPath)
        }
    }
}
