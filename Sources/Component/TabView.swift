//
//  TabView.swift
//  GreycatsComponent
//
//  Created by Rex Sheng on 2022/1/28.
//

import SwiftUI

public protocol IconTab: CaseIterable, Hashable where Self.AllCases: RandomAccessCollection {
    associatedtype Icon: View
    associatedtype Label: View

    var icon: Self.Icon { get }
    var label: Self.Label { get }
}

public struct TabItem<Tab>: View where Tab: IconTab {
    var tab: Tab
    @Binding var tabIdx: Tab

    public var body: some View {
        Button(action: {
            withAnimation(.easeIn) {
                tabIdx = tab
            }
        }, label: {
            HStack(alignment: .center) {
                tab.icon

                if tabIdx == tab {
                    tab.label
                        .transition(.fly.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(tabIdx == tab ? Color(hue: 240 / 360.0, saturation: 0.05, brightness: 0.12) : .black.opacity(0))
            )
        })
    }
}

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder public func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

final class TabBarModel: ObservableObject {
    @Published var hidden: Bool = false
}

private struct TabBarPreferences<Tab: IconTab>: PreferenceKey {
    typealias Value = [Tab: CGPoint]

    static var defaultValue: Value { [:] }

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue()) { $1 }
    }
}

public struct TabView<Tab: IconTab, Content, FlyOut>: View where Content: View, FlyOut: View {
    @Binding private var selection: Tab
    @EnvironmentObject private var model: TabBarModel
    private var content: (Tab) -> Content
    private var flyOuts: ([Tab: CGPoint]) -> FlyOut

    @State private var preferences: [Tab: CGPoint] = [:]

    init(selection: Binding<Tab>, @ViewBuilder content: @escaping (Tab) -> Content, @ViewBuilder flyOuts: @escaping ([Tab: CGPoint]) -> FlyOut) {
        _selection = selection
        self.content = content
        self.flyOuts = flyOuts
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            content(selection)
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    VStack {
                        HStack {
                            Spacer()
                            ForEach(Tab.allCases, id: \.self) { tab in
                                TabItem(tab: tab, tabIdx: $selection)
                                    .anchorPreference(
                                        key: TabBarPreferences<Tab>.self,
                                        value: .bounds
                                    ) {
                                        [tab: geometry[$0].origin]
                                    }
                                Spacer()
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 50)
                    }

                    .background(Color.black.opacity(0.3))
                    .transition(.move(edge: .bottom))
                    //                    .animation(.easeInOut(duration: 0.3))
                    .if(model.hidden) {
                        $0.hidden().frame(height: 0)
                    }
                }
                flyOuts(preferences)
            }
            .onPreferenceChange(TabBarPreferences<Tab>.self) { sizes in
                self.preferences = sizes
            }
        }
        .edgesIgnoringSafeArea(.vertical)
    }
}

extension TabView where FlyOut == EmptyView {
    init(selection: Binding<Tab>, @ViewBuilder content: @escaping (Tab) -> Content) {
        self.init(selection: selection, content: content, flyOuts: { _ in EmptyView() })
    }
}

enum Tab: String, Codable, CaseIterable, IconTab {
    case cash = "Cash"
    case points = "Points"
    case cards = "Cards"

    var icon: some View {
        Group {
            switch self {
                case .cash:
                    Image(systemName: "dollarsign.square")
                case .points:
                    Image(systemName: "giftcard")
                case .cards:
                    Image(systemName: "creditcard.and.123")
            }
        }
    }

    var label: some View {
        Text(self.rawValue)
            .textCase(.uppercase)
            .font(.system(size: 12).weight(.semibold))
            .foregroundColor(.white)
    }
}

struct FlyOutImage: View {
    var body: some View {
        Text("Invite friends — earn points")
            .font(.system(size: 12).weight(.semibold))
            .foregroundColor(.black)
            .background(RoundedRectangle(cornerRadius: 8)
                .frame(width: 178, height: 32, alignment: .center)
                .padding())
    }
}

struct TabView_Previews: PreviewProvider {
    struct TabViewContainer_Previews: View {
        @State var selection: Tab = .cash
        @State var scrollOffset: CGFloat = 0
        @State var flyOutVisible = true

        var body: some View {
            TabView(selection: $selection, content: { tab in
                Text(tab.rawValue)
            }, flyOuts: { preferences in
                if flyOutVisible {
                    FlyOutImage()
                        .position(x: preferences[.points, default: .zero].x + 21, y: preferences[.points, default: .zero].y - 25)
                }
            })
            .preferredColorScheme(.dark)
        }
    }

    static var previews: some View {
        return TabViewContainer_Previews().environmentObject(TabBarModel())
    }
}
