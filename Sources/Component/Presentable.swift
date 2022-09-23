//
//  Presentable.swift
//  GreycatsComponent
//
//  Created by Rex Sheng on 2022/9/23.
//

import Combine
import SwiftUI

extension AnyTransition {
    public static var pop: AnyTransition {
        .scale(scale: 0.8).combined(with: .opacity)
    }
}

public protocol Presentable {
    associatedtype Callout: View
    var isPresented: Binding<Bool> { get set }
    @ViewBuilder func body(context: PresentableContext) -> Self.Callout
}

public protocol AutoDismiss {
    var duration: DispatchTimeInterval { get set }
}

struct PresentableViewModifier<T: Presentable>: ViewModifier {
    let presentable: T

    public init(_ presentable: T) {
        self.presentable = presentable
    }

    public func body(content: Content) -> some View {
        let context = PresentableContext.shared
        content.onChange(of: presentable.isPresented.wrappedValue) {
            if $0 {
                context.open(presentable: presentable)
            } else {
                context.close()
            }
        }
    }
}

public final class PresentableContext: ObservableObject {
    @Published var isPresented = false

    static var shared = PresentableContext()

    var body: (() -> AnyView)?

    private init() {
    }

    private var workItem: DispatchWorkItem?
    var subscriber: AnyCancellable?

    func close() {
        isPresented = false
        cancel()
    }

    func cancel() {
        subscriber?.cancel()
        workItem?.cancel()
    }

    func open<T: Presentable>(presentable: T) {
        cancel()
        self.body = { AnyView(presentable.body(context: self)) }
        isPresented = true
        var subscriber: AnyCancellable?
        subscriber = $isPresented
            .map { !$0 }
            .sink { dismiss in
                if dismiss {
                    presentable.isPresented.wrappedValue = false
                    subscriber?.cancel()
                }
            }
        self.subscriber = subscriber

        if let autoDismiss = presentable as? AutoDismiss {
            workItem?.cancel()

            let task = DispatchWorkItem { [weak self] in
                withAnimation(.spring()) {
                    self?.isPresented = false
                }
            }
            workItem = task
            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismiss.duration, execute: task)
        }
    }
}

public struct PresentableContainer: View {
    @StateObject var context = PresentableContext.shared

    public init() {
    }

    public var body: some View {
        Group {
            if context.isPresented, let body = context.body {
                body()
            }
        }
        .edgesIgnoringSafeArea(.all)
        .transition(.pop)
    }
}

extension View {
    public func callout<T: Presentable>(_ presentable: T) -> some View {
        modifier(PresentableViewModifier(presentable))
    }
}
