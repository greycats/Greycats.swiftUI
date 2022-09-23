//
//  StringPicker.swift
//  GreycatsComponent
//
//  Created by Rex Sheng on 2022/9/23.
//

import SwiftUI

struct StringPicker<T, Label: View>: Presentable {
    private var title: String
    var isPresented: Binding<Bool>
    var label: (T) -> Label
    var choices: () -> [T]
    var onDone: (T) -> Void

    init(title: String, isPresented: Binding<Bool>, choices: @escaping () -> [T], label: @escaping (T) -> Label, onDone: @escaping (T) -> Void) {
        self.title = title
        self.isPresented = isPresented
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
                Button("Cancel") {
                    close()
                }
                Spacer()
                Text(title).font(.system(size: 18).weight(.medium))
                    .foregroundColor(.black)
                Spacer()
                Button("Done") {
                    close()
                    onDone(_choices[selection.wrappedValue])
                }
            }
            .padding()
            .background(Color(red: 0.93, green: 0.93, blue: 0.93))
            Picker(title, selection: selection) {
                ForEach(0..<_choices.count, id: \.self) { index in
                    label(_choices[index]).tag(index)
                }
            }
            .pickerStyle(.inline)
        }
        .background(Color.white)
    }

    func body(context: PresentableContext) -> some View {
        VStack {
            Spacer()
            picker(close: { context.isPresented = false })
                .foregroundColor(.accentColor)
        }
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
            content.callout(picker)
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
