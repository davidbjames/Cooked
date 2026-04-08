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
}
