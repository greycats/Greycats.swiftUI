//
//  TabView.swift
//  GreycatsComponent
//
//  Created by Rex Sheng on 2022/1/28.
//

import SwiftUI

public protocol IconTab: Hashable {
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

private struct TabAnimationKey: EnvironmentKey {
    static let defaultValue: Animation = .easeIn(duration: 0.25)
}

public struct ShadowOptions: EnvironmentKey {
    public static let defaultValue: ShadowOptions = .drop(radius: 16)

    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    public static func drop(color: Color = .init(.sRGBLinear, white: 0, opacity: 0.33), radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) -> ShadowOptions {
        return ShadowOptions(color: color, radius: radius, x: x, y: y)
    }
}

private struct TabVerticalPadding: EnvironmentKey {
    static let defaultValue: CGFloat = 20
}

private struct TabHideTransition: EnvironmentKey {
    static let defaultValue: AnyTransition = .move(edge: .bottom).combined(with: .opacity)
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

    public var shadowOptions: ShadowOptions {
        get { self[ShadowOptions.self] }
        set { self[ShadowOptions.self] = newValue }
    }

    public var animation: Animation {
        get { self[TabAnimationKey.self] }
        set { self[TabAnimationKey.self] = newValue }
    }

    public var hideTransition: AnyTransition {
        get { self[TabHideTransition.self] }
        set { self[TabHideTransition.self] = newValue }
    }
}

public struct TabView<Tab: IconTab, Content, FlyOut>: View where Content: View, FlyOut: View {
    @Binding private var selection: Tab
    @Binding private var tabs: [Tab]
    @Binding private var tabBarHidden: Bool
    private var content: (Tab) -> Content
    private var flyOuts: ([Tab: CGPoint]) -> FlyOut

    @State private var preferences: [Tab: CGPoint] = [:]
    @Environment(\.tabBackgroundColor) var tabBackgroundColor
    @Environment(\.tabVerticalPadding) var verticalPadding
    @Environment(\.shadowOptions) var shadowOptions
    @Environment(\.animation) var animation
    @Environment(\.hideTransition) var hideTransition

    public init(selection: Binding<Tab>, tabs: Binding<[Tab]>, tabBarHidden: Binding<Bool>, @ViewBuilder content: @escaping (Tab) -> Content, @ViewBuilder flyOuts: @escaping ([Tab: CGPoint]) -> FlyOut) {
        _selection = selection
        _tabs = tabs
        _tabBarHidden = tabBarHidden
        self.content = content
        self.flyOuts = flyOuts
    }

    @ViewBuilder func tabItem(tab: Tab, geometry: GeometryProxy) -> some View {
        Button(action: {
            selection = tab
        }, label: {
            tab.tabItem(selected: selection == tab)
        })
        .animation(animation, value: selection)
        .anchorPreference(
            key: TabBarPreferences<Tab>.self,
            value: .bounds
        ) {
            [tab: geometry[$0].origin]
        }
    }

    public var body: some View {
        ZStack {
            content(selection)
                .ignoresSafeArea()
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    if !tabBarHidden {
                        HStack {
                            Spacer()
                            ForEach(tabs, id: \.self) { tab in
                                tabItem(tab: tab, geometry: geometry)
                                Spacer()
                            }
                        }
                        .padding(.vertical, verticalPadding)
                        .transition(hideTransition)
                        .background(
                            tabBackgroundColor
                                .edgesIgnoringSafeArea(.bottom)
                                .shadow(color: shadowOptions.color, radius: shadowOptions.radius, x: shadowOptions.x, y: shadowOptions.y)
                        )
                    }
                }
                .animation(.easeOut(duration: 0.25), value: tabBarHidden)
                flyOuts(preferences)
            }
            .onPreferenceChange(TabBarPreferences<Tab>.self) { sizes in
                self.preferences = sizes
            }
        }
    }
}

extension TabView where FlyOut == EmptyView {
    public init(selection: Binding<Tab>, tabs: Binding<[Tab]>, tabBarHidden: Binding<Bool>, @ViewBuilder content: @escaping (Tab) -> Content) {
        self.init(selection: selection, tabs: tabs, tabBarHidden: tabBarHidden, content: content, flyOuts: { _ in EmptyView() })
    }

    public init(selection: Binding<Tab>, tabs: [Tab], tabBarHidden: Binding<Bool>, @ViewBuilder content: @escaping (Tab) -> Content) {
        self.init(selection: selection, tabs: .constant(tabs), tabBarHidden: tabBarHidden, content: content, flyOuts: { _ in EmptyView() })
    }
}

extension TabView where Tab: CaseIterable {
    public init(selection: Binding<Tab>, tabBarHidden: Binding<Bool>, @ViewBuilder content: @escaping (Tab) -> Content, @ViewBuilder flyOuts: @escaping ([Tab: CGPoint]) -> FlyOut) {
        self.init(selection: selection, tabs: .constant(Tab.allCases as! [Tab]), tabBarHidden: tabBarHidden, content: content, flyOuts: flyOuts)
    }
}

extension TabView where Tab: CaseIterable, FlyOut == EmptyView {
    public init(selection: Binding<Tab>, tabBarHidden: Binding<Bool>, @ViewBuilder content: @escaping (Tab) -> Content) {
        self.init(selection: selection, tabs: Tab.allCases as! [Tab], tabBarHidden: tabBarHidden, content: content)
    }
}

struct TabView_Previews: PreviewProvider {

    enum Tab: String, IconTab, CaseIterable {
        case cash = "Cash"
        case points = "Points"
        case cards = "Cards"

        func tabItem(selected: Bool) -> some View {
            HStack(alignment: .center) {
                icon
                if selected {
                    label.transition(.fly.combined(with: .opacity))
                }
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 13)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(selected ? Color(red: 0.404, green: 0.420, blue: 0.529) : .clear)
            )
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
            Text("Invite friends ??? earn points")
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
                        if hidden {
                            flyOutVisible = false
                        }
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
            .environment(\.shadowOptions, .drop(color: .init(.sRGBLinear, white: 0, opacity: 0.05), radius: 16, x: 0, y: -4))
            .environment(\.animation, .spring(response: 0.2, dampingFraction: 0.5))
            .preferredColorScheme(.dark)
        }
    }

    static var previews: some View {
        return TabViewContainer_Previews()
    }
}
