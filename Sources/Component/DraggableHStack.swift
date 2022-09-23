//
//  DraggableHStack.swift
//  GreycatsComponent
//
//  Created by Rex Sheng on 2022/2/21.
//

import SwiftUI

public struct DraggableHStack<Content: View>: View {
    @ObservedObject private var viewModel: DraggableHStackModel
    private var content: (CGSize, Int) -> Content

    public init(index: Binding<Int>, total: Int, canMove: Bool, @ViewBuilder content: @escaping (CGSize, Int) -> Content) {
        viewModel = DraggableHStackModel(index: index, total: total, canMove: canMove)
        self.content = content
    }

    public var body: some View {
        GeometryReader { proxy -> AnyView in
            viewModel.viewSize = proxy.size
            return AnyView(
                HStack(alignment: .top, spacing: .zero) {
                    content(proxy.size, viewModel.activeIndex)
                }
                    .frame(width: proxy.size.width, alignment: .leading)
                    .offset(x: viewModel.offset)
                    .gesture(viewModel.dragGesture)
                    .animation(.linear, value: viewModel.offset)
            )
        }
    }
}

private final class DraggableHStackModel: ObservableObject {
    @Binding private var index: Int
    private var _total: Int
    private var _canMove: Bool
    @Published var dragOffset: CGFloat = .zero

    private var delayChangeIndexTask: Task<Void, Error>?

    @Published var activeIndex: Int = 0 {
        willSet {
            delayChangeIndexTask?.cancel()
            delayChangeIndexTask = Task {
                try? await Task.sleep(nanoseconds: 250_000_000)
                DispatchQueue.main.async {
                    self.index = newValue
                }
            }
        }
    }

    var viewSize: CGSize = UIScreen.main.bounds.size

    init(index: Binding<Int>, total: Int, canMove: Bool) {
        _index = index
        activeIndex = index.wrappedValue
        _canMove = canMove
        _total = total
    }

    var offset: CGFloat {
        let activeOffset = CGFloat(activeIndex) * viewSize.width
        return dragOffset - activeOffset
    }

    var dragGesture: some Gesture {
        DragGesture()
            .onChanged(dragChanged)
            .onEnded(dragEnded)
    }

    private func dragChanged(_ value: DragGesture.Value) {
        guard _canMove else { return }
        var offset = viewSize.width
        if value.translation.width > 0 {
            if activeIndex == 0 {
                offset = .zero
            } else {
                offset = min(offset, value.translation.width)
            }
        } else {
            offset = max(-offset, value.translation.width)
        }
        dragOffset = offset
    }

    private func dragEnded(_ value: DragGesture.Value) {
        guard _canMove else { return }
        dragOffset = .zero
        let dragThreshold = viewSize.width / 3
        var activeIndex = self.activeIndex
        if value.translation.width > dragThreshold {
            if activeIndex == 0 {
                return
            }
            activeIndex -= 1
        }
        if value.translation.width < -dragThreshold {
            activeIndex += 1
        }
        self.activeIndex = max(0, min(activeIndex, _total - 1))
    }
}

struct Slides_Previews: PreviewProvider {
    struct Slides: View {
        @State private var index = 0
        var body: some View {
            VStack {
                DraggableHStack(index: $index, total: 3, canMove: true) { size, _ in
                    Color.yellow.frame(width: size.width)
                    Color.blue.frame(width: size.width)
                    Color.green.frame(width: size.width)
                }
            }
        }
    }

    static var previews: some View {
        Slides()
    }
}
