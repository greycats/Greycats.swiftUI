//
//  FieldPlaceholder.swift
//  GreycatsComponent
//
//  Created by Rex Sheng on 2022/9/21.
//

import SwiftUI

struct FieldPlaceholder<Label: View>: ViewModifier {
    var showPlaceHolder: Bool
    var placeholder: () -> Label
    @Environment(\.multilineTextAlignment) var alignment

    func body(content: Content) -> some View {
        ZStack(alignment: alignment == .trailing ? .trailing : .leading) {
            if showPlaceHolder {
                placeholder()
            }
            content
        }
    }
}

extension View {
    public func placeholder<Label: View>(when showPlaceHolder: Bool, @ViewBuilder placeholder: @escaping () -> Label) -> some View {
        modifier(FieldPlaceholder(showPlaceHolder: showPlaceHolder, placeholder: placeholder))
    }

    public func placeholder(_ text: String, when showPlaceHolder: Bool) -> some View {
        modifier(FieldPlaceholder(showPlaceHolder: showPlaceHolder, placeholder: { Text(text).foregroundColor(.white.opacity(0.5)) }))
    }
}
