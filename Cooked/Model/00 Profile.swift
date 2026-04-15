//
//  00 Profile.swift
//  Cooked
//
//  Created by David James on 15/04/2026.
//

import SwiftData

@Model
final class Profile {
    
    struct Options: OptionSet {
        let rawValue: Int
        static let includeInternationalIngredients = Self(rawValue: 1 << 0)
    }
    
    private(set) var userOptions: Int = 0
    
    var options: Options {
        .init(rawValue: userOptions)
    }
    
    init(options: Options) {
        self.userOptions = options.rawValue
    }
}
