//
//  00 Profile.swift
//  Cooked
//
//  Created by David James on 15/04/2026.
//

import SwiftData

extension SchemaV1 {
    /// Separate and distinct from the actual device user
    /// we hold a "profile" with user settings.
    @Model
    final class Profile {
        
        private(set) var userOptions: Int = 0
        
        /// Keep this private.
        /// Use `Profile.current()` instead to get the single instance of the user's "profile".
        private init(options: Options = []) {
            self.userOptions = options.rawValue
        }
    }
}

extension Profile {
    
    struct Options: OptionSet {
        let rawValue: Int
        static let includeInternationalIngredients = Self(rawValue: 1 << 0)
    }
    
    private var options: Options {
        get {
            .init(rawValue: userOptions)
        }
        set {
            userOptions = newValue.rawValue
        }
    }
    
    var includeInternationalIngredients: Bool {
        get {
            options.contains(.includeInternationalIngredients)
        }
        set {
            if newValue {
                options.insert(.includeInternationalIngredients)
            } else {
                options.remove(.includeInternationalIngredients)
            }
        }
    }
    
    /// Fetches the existing Profile or creates a new one.
    /// Ensures only one Profile ever exists in the store.
    static func current(in modelContext: ModelContext) -> Profile {
        let descriptor = FetchDescriptor<Profile>()
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let profile = Profile()
        modelContext.insert(profile)
        return profile
    }
}
