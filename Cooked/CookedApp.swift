//
//  CookedApp.swift
//  Cooked
//
//  Created by David James on 29/01/2026.
//

import SwiftUI
import SwiftData

// See this list for LLM gotchas that should be fixed: https://www.hackingwithswift.com/articles/281/what-to-fix-in-ai-generated-swift-code
// (some are already warnings)

// TODO: integrate Apple Intelligence into the app, learn it, it's AI integration.
// - tech note: https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window
// Get the app to a point of "working" correctly, including the timer display before integrating AI

// TODO: cooking *item* view which also shows *meal plans* they belong to
//       (i.e. since they have a many-to-many relationship)
// TBD:  should items always have at least 1 meal plan associated? 1..*
//       or can we have items with no meal plans? 0..*

// TODO: defensive logic if user is not logged in if necessary

@main
struct CookedApp: App {
    
    // Shared ModelContainer configured for CloudKit sync and sharing
    var sharedModelContainer: ModelContainer = {
        // Note: these are indented to reveal the hierarchy.
        let schema = Schema([
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

    var body: some Scene {
        WindowGroup {
            MealPlanListView()
        }
        .modelContainer(sharedModelContainer)
    }
}

