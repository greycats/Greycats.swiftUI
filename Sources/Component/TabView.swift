//
//  TabView.swift
//  GreycatsComponent
//
//  Created by Rex Sheng on 2022/1/28.
//

import SwiftUI

public protocol IconTab: CaseIterable, Hashable where Self.AllCases: RandomAccessCollection {
    associatedtype TabItem: View
    @ViewBuilder func tabItem(selected: Bool) -> Self.TabItem
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

private struct TabBarPreferences<Tab: IconTab>: PreferenceKey {
    typealias Value = [Tab: CGPoint]

    static var defaultValue: Value { [:] }

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue()) { $1 }
    }
}

private struct TabBackgroundColorKey: EnvironmentKey {
    static let defaultValue = Color(.secondarySystemBackground)
}

private struct TabVerticalPadding: EnvironmentKey {
    static let defaultValue: CGFloat = 20
}

extension EnvironmentValues {
    public var tabBackgroundColor: Color {
        get { self[TabBackgroundColorKey.self] }
        set { self[TabBackgroundColorKey.self] = newValue }
    }

    public var tabVerticalPadding: CGFloat {
        get { self[TabVerticalPadding.self] }
        set { self[TabVerticalPadding.self] = newValue }
    }
}

public struct TabView<Tab: IconTab, Content, FlyOut>: View where Content: View, FlyOut: View {
    @Binding private var selection: Tab
    @Binding private var tabBarHidden: Bool
    private var content: (Tab) -> Content
    private var flyOuts: ([Tab: CGPoint]) -> FlyOut

    @State private var preferences: [Tab: CGPoint] = [:]
    @Environment(\.tabBackgroundColor) var tabBackgroundColor
    @Environment(\.tabVerticalPadding) var verticalPadding

    public init(selection: Binding<Tab>, tabBarHidden: Binding<Bool>, @ViewBuilder content: @escaping (Tab) -> Content, @ViewBuilder flyOuts: @escaping ([Tab: CGPoint]) -> FlyOut) {
        _selection = selection
        _tabBarHidden = tabBarHidden
        self.content = content
        self.flyOuts = flyOuts
    }

    public var body: some View {
        ZStack {
            content(selection)
                .ignoresSafeArea()
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
                                    tab.tabItem(selected: selection == tab)
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
                        .padding(.vertical, verticalPadding)
//                        .padding(.top, 20)
//                        .padding(.bottom, 20 + geometry.safeAreaInsets.bottom)
                    }

                    .animation(.easeIn(duration: 0.25), value: tabBarHidden)
                    .padding(.bottom, tabBarHidden ? -100 : 0)
                    .background(tabBackgroundColor)
                }
                flyOuts(preferences)
            }
            .onPreferenceChange(TabBarPreferences<Tab>.self) { sizes in
                self.preferences = sizes
            }
        }
    }
}

extension TabView where FlyOut == EmptyView {
    public init(selection: Binding<Tab>, tabBarHidden: Binding<Bool>, @ViewBuilder content: @escaping (Tab) -> Content) {
        self.init(selection: selection, tabBarHidden: tabBarHidden, content: content, flyOuts: { _ in EmptyView() })
    }
}

struct TabView_Previews: PreviewProvider {

    enum Tab: String, IconTab {
        case cash = "Cash"
        case points = "Points"
        case cards = "Cards"

        func tabItem(selected: Bool) -> some View {
            HStack(alignment: .center) {
                icon
                if selected {
                    label
                        .transition(.fly.combined(with: .opacity))

                }
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 13)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(selected ? Color(red: 0.404, green: 0.420, blue: 0.529) : .clear)

            )
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: selected)
        }

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
            })
            .environment(\.tabBackgroundColor, Color(red: 0.310, green: 0.322, blue: 0.408))
            .environment(\.tabVerticalPadding, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 12)
            .preferredColorScheme(.dark)
        }
    }

    static var previews: some View {
        return TabViewContainer_Previews()
    }
}
