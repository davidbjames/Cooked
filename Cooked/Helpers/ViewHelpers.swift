//
//  ViewHelpers.swift
//  Cooked
//
//  Created by David James on 19/03/2026.
//

import SwiftUI

extension View {
    @ViewBuilder
    func `if`<Transformed: View>(_ condition: Bool, transform: (Self) -> Transformed) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        transform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            transform(self)
        } else {
            elseTransform(self)
        }
    }
}


extension Binding {
    /// Creates a read-only binding with only a getter.
    /// Use this if you need a dynamic Binding but you
    /// don't need the setter.
    init(get: @Sendable @escaping () -> Value) {
        self.init(get: get, set: { _ in })
    }
}
