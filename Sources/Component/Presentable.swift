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

public enum PresentingPosition {
    case top
    case center
    case bottom
}

public protocol Presentable: View {
    var isPresented: Binding<Bool> { get set }
    var position: PresentingPosition { get set }
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
        let context = PresentableContext.shared[presentable.position]!
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

    @Published public var boolFlag = false

    static var shared: [PresentingPosition: PresentableContext] = [
        .top: PresentableContext(),
        .center: PresentableContext(),
        .bottom: PresentableContext()
    ]

    var body: (() -> AnyView)?

    private init() {
    }

    private var workItem: DispatchWorkItem?
    var subscriber: AnyCancellable?

    func close() {
        withAnimation {
            isPresented = false
        }
        cancel()
    }

    func cancel() {
        subscriber?.cancel()
        workItem?.cancel()
    }

    func open<T: Presentable>(presentable: T) {
        cancel()
        self.body = { AnyView(presentable.body) }
        withAnimation {
            isPresented = true
        }

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
    @StateObject var top = PresentableContext.shared[.top]!
    @StateObject var center = PresentableContext.shared[.center]!
    @StateObject var bottom = PresentableContext.shared[.bottom]!

    public init() {
    }

    public var body: some View {
        Group {
            if top.isPresented, let body = top.body {
                body()
            }
            if center.isPresented, let body = center.body {
                body()
            }
            if bottom.isPresented, let body = bottom.body {
                body()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

extension View {
    public func callout<T: Presentable>(_ presentable: T) -> some View {
        modifier(PresentableViewModifier(presentable))
    }
}
