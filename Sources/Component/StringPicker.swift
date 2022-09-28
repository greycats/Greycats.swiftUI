//
//  StringPicker.swift
//  GreycatsComponent
//
//  Created by Rex Sheng on 2022/9/23.
//

import SwiftUI

struct StringPicker<T, Label: View>: View {
    private var title: String
    @Binding var isPresented: Bool
    var label: (T) -> Label
    var choices: () -> [T]
    var onDone: (T) -> Void

    init(title: String, isPresented: Binding<Bool>, choices: @escaping () -> [T], label: @escaping (T) -> Label, onDone: @escaping (T) -> Void) {
        self.title = title
        _isPresented = isPresented
        self.choices = choices
        self.label = label
        self.onDone = onDone
    }

    @ViewBuilder func picker(close: @escaping () -> Void) -> some View {
        var _selection = 0
        let selection = Binding<Int>(get: { _selection }, set: { _selection = $0 })
        let _choices = choices()
        VStack {
            HStack {
                Button(LocalizedStringKey("Cancel")) {
                    close()
                }
                .font(.system(.body).weight(.bold))
                Spacer()
                Text(LocalizedStringKey(title)).font(.system(.callout).weight(.medium))
                    .foregroundColor(.black)
                Spacer()
                Button(LocalizedStringKey("Done")) {
                    close()
                    onDone(_choices[selection.wrappedValue])
                }
                .font(.system(.body).weight(.bold))
            }

            .padding()
            .background(Color(red: 0.93, green: 0.93, blue: 0.93).shadow(color: .black.opacity(0.02), radius: 2, y: -2))
            Picker(title, selection: selection) {
                ForEach(0..<_choices.count, id: \.self) { index in
                    label(_choices[index]).tag(index)
                }
            }
            .pickerStyle(.inline)
        }
        .background(Color.white)
    }

    var body: some View {
        Color.black.opacity(0.2)
            .transition(.opacity)
        VStack {
            Spacer()
            picker(close: { isPresented = false })
                .foregroundColor(.accentColor)
                .background {
                    Color.white
                }

        }
        .transition(.move(edge: .bottom))
    }
}

struct StringPickerPresentable<Content>: Presentable where Content: View {

    var position: PresentingPosition = .bottom
    var isPresented: Binding<Bool>

    var content: Content
    var body: some View {
        content
    }

    init(@ViewBuilder body: () -> Content, isPresented: Binding<Bool>, position: PresentingPosition) {
        self.content = body()
        self.isPresented = isPresented
        self.position = position
    }

}

struct StringPickerModifier<T, Label: View>: ViewModifier {
    let picker: StringPicker<T, Label>
    @Binding var isPresented: Bool

    init(title: String, isPresented: Binding<Bool>, choices: @escaping () -> [T], label: @escaping (T) -> Label, onDone: @escaping (T) -> Void) {
        _isPresented = isPresented
        picker = StringPicker(title: title, isPresented: isPresented, choices: choices, label: label, onDone: onDone)
    }

    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content.popover(isPresented: $isPresented, attachmentAnchor: .rect(.bounds)) {
                picker.picker(close: { isPresented = false })
            }
        } else {
            content.callout(StringPickerPresentable(body: { picker }, isPresented: $isPresented, position: .bottom))
        }
    }
}

extension View {
    public func stringPicker<T, Label: View>(title: String, isPresented: Binding<Bool>, choices: @escaping () -> [T], label: @escaping ((T) -> Label), onDone: @escaping ((T) -> Void) = { _ in }) -> some View {
        modifier(StringPickerModifier(title: title, isPresented: isPresented, choices: choices, label: label, onDone: onDone))
    }
}

struct StringPicker_Previews: PreviewProvider {
    struct StringPickerDemo: View {
        @State var pickerIsPresented = false

        @State var selected = 1

        var body: some View {
            VStack {
                Spacer()
                Button("Picker \(selected)") {
                    pickerIsPresented.toggle()
                }
                .padding()
                .stringPicker(title: "Pick a number", isPresented: $pickerIsPresented, choices: { [1, 2, 3, 4] }, label: { choice in
                    Text("\(choice)").foregroundColor(.black)
                }, onDone: { selected in
                    print(selected)
                    self.selected = selected
                })
            }
        }
    }
    static var previews: some View {
        ZStack {
            StringPickerDemo()
            PresentableContainer()
        }
    }
}
