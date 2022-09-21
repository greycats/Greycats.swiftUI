//
//  Preference.swift
//  Greycats
//
//  Created by Rex Sheng on 2021/12/30.
//

import Combine
import SwiftUI

open class Preferences {
    private(set) var preferencesChangedSubject = PassthroughSubject<AnyKeyPath, Never>()

    func publisher<Value>(to keyPath: ReferenceWritableKeyPath<Preferences, Value>) -> AnyPublisher<Value, Never> {
        return preferencesChangedSubject
            .filter { key in key == keyPath }
            .compactMap {[weak self] key in
                return self[keyPath: key] as? Value
            }
            .prepend(self[keyPath: keyPath])
            .eraseToAnyPublisher()
    }

    public init() {
    }
}

@propertyWrapper
public struct Preference<Value, T: Preferences>: DynamicProperty {
    @ObservedObject private var preferencesObserver: PublisherObservableObject
    private let keyPath: ReferenceWritableKeyPath<T, Value>
    private let preferences: T

    public init(_ keyPath: ReferenceWritableKeyPath<T, Value>, preferences: T) {
        self.keyPath = keyPath
        self.preferences = preferences
        let publisher = preferences
            .preferencesChangedSubject
            .filter { changedKeyPath in
                changedKeyPath == keyPath
            }.map { _ in () }
            .eraseToAnyPublisher()
        self.preferencesObserver = .init(publisher: publisher)
    }

    public var wrappedValue: Value {
        get { preferences[keyPath: keyPath] }
        nonmutating set { preferences[keyPath: keyPath] = newValue }
    }

    public var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}

public final class PublisherObservableObject: ObservableObject {
    var subscriber: AnyCancellable?

    init(publisher: AnyPublisher<Void, Never>) {
        subscriber = publisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                self?.objectWillChange.send()
            })
    }
}
