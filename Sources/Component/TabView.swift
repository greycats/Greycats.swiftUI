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

struct TabItem<Tab>: View where Tab: IconTab {
    var tab: Tab
    @Binding var tabIdx: Tab


    var body: some View {
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
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(tabIdx == tab ? Color(hue: 240 / 360.0, saturation: 0.05, brightness: 0.12) : .black.opacity(0))
                    .padding(.vertical, -5)
                    .padding(.horizontal, -9)
            )
        })
    }
}

public protocol TabItemStyle {
    associatedtype Body: Shape
    @ViewBuilder func backgroundShape(selected: Bool) -> Self.Body
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

public final class TabBarModel: ObservableObject {
    @Published public var hidden: Bool = false
}

private struct TabBarPreferences<Tab: IconTab>: PreferenceKey {
    typealias Value = [Tab: CGPoint]

    static var defaultValue: Value { [:] }

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue()) { $1 }
    }
}

public struct TabView<Tab: IconTab, Content, FlyOut, S>: View where Content: View, FlyOut: View, S: View {
    @Binding private var selection: Tab
    @Binding private var tabBarHidden: Bool
    private var content: (Tab) -> Content
    private var flyOuts: ([Tab: CGPoint]) -> FlyOut
    private var tabItemBackground: (Bool) -> S

    @State private var preferences: [Tab: CGPoint] = [:]

    init(selection: Binding<Tab>, tabBarHidden: Binding<Bool>, @ViewBuilder content: @escaping (Tab) -> Content, @ViewBuilder flyOuts: @escaping ([Tab: CGPoint]) -> FlyOut, @ViewBuilder tabItemBackground: @escaping (Bool) -> S) {
        _selection = selection
        _tabBarHidden = tabBarHidden
        self.content = content
        self.flyOuts = flyOuts
        self.tabItemBackground = tabItemBackground
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
                                Button(action: {
                                    withAnimation(.easeIn) {
                                        selection = tab
                                    }
                                }, label: {
                                    HStack(alignment: .center) {
                                        tab.icon

                                        if selection == tab {
                                            tab.label
                                                .transition(.fly.combined(with: .opacity))
                                        }
                                    }
                                    .background(
                                        tabItemBackground(selection == tab)
                                    )
                                })
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
                    .animation(.easeInOut(duration: 0.3), value: tabBarHidden)
                    .padding(.bottom, tabBarHidden ? -100 : 0)
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
    init(selection: Binding<Tab>, tabBarHidden: Binding<Bool>, @ViewBuilder content: @escaping (Tab) -> Content, @ViewBuilder tabItemBackground: @escaping (Bool) -> S) {
        self.init(selection: selection, tabBarHidden: tabBarHidden, content: content, flyOuts: { _ in EmptyView() }, tabItemBackground: tabItemBackground)
    }
}

struct TabView_Previews: PreviewProvider {

    enum Tab: String, IconTab {
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
            .foregroundColor(.white)
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

    struct TabViewContainer_Previews: View {
        @State var selection: Tab = .cash
        @State var hidden = false

        @State var scrollOffset: CGFloat = 0
        @State var flyOutVisible = true


        var body: some View {
            TabView(selection: $selection, tabBarHidden: $hidden, content: { tab in
                Color.yellow
                VStack(spacing: 50) {
                    Button("\(hidden ? "show" : "hide") tabs") {
                        hidden.toggle()
                    }
                    Button("\(flyOutVisible ? "hide" : "show") flyOut") {
                        flyOutVisible.toggle()
                    }
                    Text(tab.rawValue)
                }

            }, flyOuts: { preferences in
                if flyOutVisible {
                    FlyOutImage()
                        .position(x: preferences[.points, default: .zero].x + 21, y: preferences[.points, default: .zero].y - 25)
                }
            }, tabItemBackground: { selected in
                RoundedRectangle(cornerRadius: 8)
                    .fill(selected ? Color(hue: 240 / 360.0, saturation: 0.05, brightness: 0.12) : .black.opacity(0))
                    .padding(.vertical, -5)
                    .padding(.horizontal, -9)
            })
            .preferredColorScheme(.dark)
        }
    }

    static var previews: some View {
        return TabViewContainer_Previews()
    }
}
