//
//  Toast.swift
//  GreycatsComponent
//
//  Created by Rex Sheng on 2022/9/23.
//

import SwiftUI

struct ToastHolder: Presentable, AutoDismiss {
    var isPresented: Binding<Bool>
    var duration: DispatchTimeInterval = .seconds(2)
    var title: String?
    var subtitle: String?

    @ViewBuilder func body(context: PresentableContext) -> some View {
        GeometryReader { proxy in
            VStack(alignment: .center) {
                Spacer()
                HStack(alignment: .center) {
                    VStack(spacing: 8) {
                        if let title = title {
                            Text(LocalizedStringKey(title))
                                .font(Font.body.bold())
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                        }
                        if let subtitle = subtitle {
                            Text(LocalizedStringKey(subtitle))
                                .font(Font.footnote)
                                .opacity(0.7)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: proxy.size.width - 60)
                    .frame(maxWidth: 327)
                    .padding()
                    .background(Color.black)
                    .shadow(radius: 15)
                    .cornerRadius(10)
                    .onTapGesture {
                        context.isPresented = false
                    }
                    .padding(.bottom, 40)
                }
            }
            .animation(.spring(), value: context.isPresented)
            .frame(width: proxy.size.width)
        }
    }
}

extension View {
    public func toast(isPresented: Binding<Bool>, duration: DispatchTimeInterval = .seconds(2), title: String?, subtitle: String?) -> some View {
        callout(ToastHolder(isPresented: isPresented, duration: duration, title: title, subtitle: subtitle))
    }
}

struct Toast_Previews: PreviewProvider {
    struct ToastDemo: View {
        @State var toastIsPresented = false

        var body: some View {
            VStack {
                Spacer()
                Button("Toast") {
                    toastIsPresented.toggle()
                }
                .padding()
            }
            .toast(isPresented: $toastIsPresented, title: "Hello", subtitle: "World")
        }
    }
    static var previews: some View {
        ZStack {
            ToastDemo()
            PresentableContainer()
        }
    }
}
