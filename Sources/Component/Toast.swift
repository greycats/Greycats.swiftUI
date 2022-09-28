//
//  Toast.swift
//  GreycatsComponent
//
//  Created by Rex Sheng on 2022/9/23.
//

import SwiftUI

struct Toast: View {
    @Binding var title: String
    @Binding var subtitle: String
    @Binding var isPresented: Bool

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .center) {
                Spacer()
                HStack(alignment: .center) {
                    VStack(spacing: 8) {
                        if !title.isEmpty {
                            Text(LocalizedStringKey(title))
                                .font(.system(.footnote).weight(.bold))
                        }
                        if !subtitle.isEmpty {
                            Text(LocalizedStringKey(subtitle))
                                .font(.system(.caption))
                                .opacity(0.7)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)

                    .frame(width: proxy.size.width - 60)
                    .frame(maxWidth: 327)
                    .padding()
                    .background(Color.black)
                    .shadow(radius: 15)
                    .cornerRadius(10)
                    .onTapGesture {
                        isPresented = false
                    }
                    .padding(.bottom, 64)
                }

            }
            .frame(width: proxy.size.width)
        }
        .transition(.move(edge: .bottom))
    }
}

struct ToastHolder: Presentable, AutoDismiss {
    var position: PresentingPosition = .bottom
    var isPresented: Binding<Bool>
    var duration: DispatchTimeInterval = .seconds(2)
    @Binding var title: String
    @Binding var subtitle: String

    var body: some View {
        Toast(title: $title, subtitle: $subtitle, isPresented: isPresented)
    }
}

extension View {
    public func toast(isPresented: Binding<Bool>, duration: DispatchTimeInterval = .seconds(2), title: Binding<String>, subtitle: Binding<String> = .constant("")) -> some View {
        callout(ToastHolder(isPresented: isPresented, duration: duration, title: title, subtitle: subtitle))
    }

    public func toast(duration: DispatchTimeInterval = .seconds(2), title: Binding<String>, subtitle: Binding<String> = .constant("")) -> some View {
        toast(isPresented: Binding<Bool>(get: {
            !title.wrappedValue.isEmpty }, set: { if !$0 { title.wrappedValue = "" } }), duration: duration, title: title, subtitle: subtitle)
    }
}

struct Toast_Previews: PreviewProvider {
    struct ToastDemo: View {
        @State var toastIsPresented = false
        @State var inputText: String = ""
        @State var toastMessage: String = ""
        @State var title = "Is this a good or bad idea?"
        @State var subtitle = "Is there a way to write this in a more generalized way?"

        var body: some View {
            VStack {
                Button("Toast \(toastMessage)") {
                    toastIsPresented.toggle()
                }
                .padding()
                TextField("Echo", text: $inputText)
                    .onSubmit {
                        toastMessage = inputText
                    }
                    .padding()
            }
            .toast(isPresented: $toastIsPresented, title: $title, subtitle: $subtitle)
            .toast(title: $toastMessage)

        }
    }
    static var previews: some View {
        ZStack {
            ToastDemo()
            PresentableContainer()
        }
    }
}
