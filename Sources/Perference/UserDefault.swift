//
//  UserDefault.swift
//  Greycats
//
//  Created by Rex Sheng on 2021/12/31.
//

import Combine
import Foundation

@propertyWrapper
public struct UserDefault<Value> {
    let key: String
    let defaultValue: Value

    public var wrappedValue: Value {
        get { fatalError("Wrapped value should not be used.") }
        set { fatalError("Wrapped value should not be used. \(newValue)") }
    }

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
            let container = UserDefaults.standard
            let key = instance[keyPath: storageKeyPath].key
            let defaultValue = instance[keyPath: storageKeyPath].defaultValue
            return container.object(forKey: key) as? Value ?? defaultValue
        }
        set {
            let container = UserDefaults.standard
            let key = instance[keyPath: storageKeyPath].key
            container.set(newValue, forKey: key)
            instance.preferencesChangedSubject.send(wrappedKeyPath)
        }
    }
}
