//
//  Container.swift
//  Cooked
//
//  Created by David James on 15/04/2026.
//

import SwiftData

extension ModelContainer {
    
    
    // Shared ModelContainer configured for CloudKit sync and sharing
    static let sharedModelContainer: ModelContainer = {
        // Note: these are indented to reveal the hierarchy.
        let schema = Schema([
            Profile.self,
            MealPlan.self,
                CookingItem.self, // 1..*
                    FoodItem.self, // 1
                        FoodGroup.self,
                        Ingredient.self,
                        Variety.self,
                    FoodVariable.self, // 1
        ])
        // Configure CloudKit with sharing at initialization time.
        // Replace the identifier below with your actual iCloud container ID.
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false, // stored in SQLite locally
            allowsSave: true,
            groupContainer: .automatic,
            cloudKitDatabase: .automatic // connects model with CloudKit
            // no need for local persistent store URL (e.g. when syncing with CoreData)
        )
        guard
            let modelContainer = try? ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        else {
            preconditionFailure()
        }
        return modelContainer
    }()
    
}
