//
//  Loader.swift
//  GreycatsComponent
//
//  Created by Rex Sheng on 2022/9/23.
//

import SwiftUI

public enum LoaderStyle {
    case system(size: CGFloat = 80, backgroundColor: Color = .white, cornerRadius: CGFloat = 20, shadowRadius: CGFloat = 5)

    case twoDots(animation: Animation = .easeIn(duration: 1).repeatForever(autoreverses: false), foregroundColor: Color = .black)
}

struct SystemLoader: Presentable, AutoDismiss {
    var position: PresentingPosition = .center
    var isPresented: Binding<Bool>
    var duration: DispatchTimeInterval
    var size: CGFloat
    var backgroundColor: Color
    var cornerRadius: CGFloat
    var shadowRadius: CGFloat

    var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor).frame(width: size, height: size).shadow(radius: shadowRadius)
            )
            .transition(.pop)
    }
}

struct TwoDotsSpinner: View {
    var animation: Animation
    var foregroundColor: Color

    @State private var flag = false

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Circle()
                .frame(width: 8, height: 8)

            Circle()
                .frame(width: 8, height: 8)
        }
        .frame(width: 30, height: 10)
        .rotationEffect(Angle(degrees: flag ? 360 : 0))
        .transaction { view in
            view.animation = animation
        }
        .onAppear {
            flag = true
        }
        .onDisappear {
            flag = false
        }
        .foregroundColor(foregroundColor)
    }
}

struct TwoDotsSpinnerModifier: Presentable, AutoDismiss {
    var position: PresentingPosition = .center
    var isPresented: Binding<Bool>
    var duration: DispatchTimeInterval
    var animation: Animation
    var foregroundColor: Color

    var body: some View {
        TwoDotsSpinner(animation: animation, foregroundColor: foregroundColor)
    }
}

extension View {
    public func loader(isPresented: Binding<Bool>, duration: DispatchTimeInterval = .seconds(5), style: LoaderStyle) -> some View {
        Group {
            switch style {
                case .system(let size, let backgroundColor, let cornerRadius, let shadowRadius):
                    callout(SystemLoader(isPresented: isPresented, duration: duration, size: size, backgroundColor: backgroundColor, cornerRadius: cornerRadius, shadowRadius: shadowRadius))
                case .twoDots(animation: let animation, foregroundColor: let foregroundColor):
                    callout(TwoDotsSpinnerModifier(isPresented: isPresented,    duration: duration, animation: animation, foregroundColor: foregroundColor))
            }
        }

    }
}

struct Loader_Previews: PreviewProvider {
    struct LoaderDemo: View {
        @State var systemLoaderIsPresented = false
        @State var twoDotsLoaderIsPresented = false

        var body: some View {
            VStack {
                Spacer()
                Button("system") {
                    systemLoaderIsPresented.toggle()
                }
                Button("twoDots") {
                    twoDotsLoaderIsPresented.toggle()
                }
                .padding()
            }
            .loader(isPresented: $systemLoaderIsPresented, style: .system())
            .loader(isPresented: $twoDotsLoaderIsPresented, style: .twoDots(foregroundColor: .blue))
        }
    }

    static var previews: some View {
        ZStack {
            LoaderDemo()
            PresentableContainer()
        }
    }
}
