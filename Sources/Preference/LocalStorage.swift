//
//  AsyncStorage.swift
//  Greycats
//
//  Created by Rex Sheng on 2021/12/31.
//

import CryptoKit
import Foundation

private enum StorageError: Error {
    case invalidData
}

private class AsyncStorage {
    static let shared = AsyncStorage()

    private var manifest = [String: Any]()

    private let cache = NSCache<NSString, NSData>()

    private var storageDirectoryPath: URL = {
        guard let bundleID = Bundle.main.bundleIdentifier, let root = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            fatalError("AsyncStorage can't load app support directory")
        }

        let path = root.appendingPathComponent(bundleID).appendingPathComponent("RCTAsyncLocalStorage_V1")
        try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)

        return path
    }()

    private var manifestFilePath: URL {
        return storageDirectoryPath.appendingPathComponent("manifest.json", isDirectory: false)
    }

    private init() {
        readManifest()
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try? storageDirectoryPath.setResourceValues(resourceValues)
    }

    private func readManifest() {
        do {
            let data = try Data(contentsOf: manifestFilePath, options: .mappedIfSafe)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            if let jsonResult = jsonResult as? [String: Any] {
                manifest = jsonResult
            }
        } catch {
        }
    }

    private func writeManifest() {
        do {
            let data = try JSONSerialization.data(withJSONObject: manifest)
            try data.write(to: manifestFilePath, options: [.atomic])
        } catch {
            print("writeManifest \(error)")
        }
    }

    private func manifestClear() {
        manifest.removeAll()
        writeManifest()
    }

    private func filePathForKey(_ key: String) throws -> URL {
        guard let data = key.data(using: .utf8) else {
            throw StorageError.invalidData
        }

        let digest = Insecure.MD5.hash(data: data)
        let safeFileName = digest.map {
            String(format: "%02hhx", $0)
        }.joined()
        return storageDirectoryPath.appendingPathComponent(safeFileName)
    }

    func getKey(_ key: String) -> Data? {
        guard let value = manifest[key] else {
            return nil
        }
        if let value = value as? String {
            return value.data(using: .utf8)
        } else {
            if let value = cache.object(forKey: key as NSString) {
                return value as Data
            }
            if let value = try? Data(contentsOf: filePathForKey(key)) {
                cache.setObject(value as NSData, forKey: key as NSString, cost: value.count)
                return value
            } else {
                return nil
            }
        }
    }

    func setKey(_ key: String, value: Data) {
        if value.count > 1024 {
            cache.setObject(value as NSData, forKey: key as NSString, cost: value.count)
            try? value.write(to: filePathForKey(key))
            if !(manifest[key] is NSNull) {
                manifest[key] = NSNull()
                writeManifest()
            }
        } else {
            if manifest[key] is NSNull {
                try? FileManager.default.removeItem(at: filePathForKey(key))
                cache.removeObject(forKey: key as NSString)
            }
            manifest[key] = String(data: value, encoding: .utf8)
            writeManifest()
        }
    }
}

private struct StateValue<Value: Codable>: Codable {
    var state: Value
}

@propertyWrapper
public struct LocalStorage<Value: Codable> {
    let key: String
    let defaultValue: Value

    public init(wrappedValue: Value, _ key: String) {
        self.defaultValue = wrappedValue
        self.key = key
    }

    public static subscript<T: Preferences>(
        _enclosingInstance instance: T,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, Self>
    ) -> Value {
        get {
            let annotation = instance[keyPath: storageKeyPath]
            let key = annotation.key
            let defaultValue = annotation.defaultValue
            let container = AsyncStorage.shared
            if let data = container.getKey(key) {
                do {
                    if Value.self == String.self {
                        return try JSONDecoder().decode(Value.self, from: data)
                    } else {
                        return try JSONDecoder().decode(StateValue<Value>.self, from: data).state
                    }
                } catch {
                    print("failed to decode \(key) to type \(Value.self)")
                }
            }
            return defaultValue
        }
        set {
            let container = AsyncStorage.shared
            let key = instance[keyPath: storageKeyPath].key
            let data: Data
            do {
                if Value.self == String.self {
                    data = try JSONEncoder().encode(newValue)
                } else {
                    data = try JSONEncoder().encode(StateValue<Value>(state: newValue))
                }
                print("\(key) => \(String(data: data, encoding: .utf8) ?? "")")
            } catch {
                print("failed to encode \(key) value \(newValue)")
                return
            }
            container.setKey(key, value: data)
            instance.preferencesChangedSubject.send(wrappedKeyPath)
        }
    }

    @available(*, unavailable,
                message: "@LocalStorage can only be applied to classes"
    )
    public var wrappedValue: Value {
        get { fatalError("Wrapped value should not be used.") }
        set { fatalError("Wrapped value should not be used. \(newValue)") }
    }
}
