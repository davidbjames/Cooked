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


@main
struct CookedApp: App {
    
    // Shared ModelContainer configured for CloudKit sync and sharing
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FoodItem.self,
            FoodVariable.self,
            CookingItem.self,
            CookingTimer.self
        ])

        // Configure CloudKit with sharing at initialization time.
        // Replace the identifier below with your actual iCloud container ID.
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .automatic,
            cloudKitDatabase: .automatic
        )
        guard let modelContainer = try? ModelContainer(for: schema, configurations: [configuration]) else {
            preconditionFailure()
        }
        #if DEBUG
        CookedApp.seedMockData(modelContainer)
        #endif
        return modelContainer
    }()

    var body: some Scene {
        WindowGroup {
            TimerListView()
        }
        .modelContainer(sharedModelContainer)
    }

    private static func seedMockData(_ modelContainer: ModelContainer) {

        let context = modelContainer.mainContext

        do {
            let existing = try context.fetch(FetchDescriptor<CookingTimer>())
            if !existing.isEmpty {
                // already seeded
                return
            }
        } catch {
            print("Mock seeding: fetch failed: \(error)")
        }

        // Seed shared data
        let chicken = FoodItem(name: "Chicken")
        let rice = FoodItem(name: "Rice")
        let pasta = FoodItem(name: "Pasta")
        let large = FoodVariable(name: "Large")
        let basmati = FoodVariable(name: "Basmati")

        // Create cooking items (some overlap in FoodItems across timers)
        let item1 = CookingItem(foodItem: chicken, foodVariable: large, cookingTimeSeconds: 45 * 60)
        let item2 = CookingItem(foodItem: rice, foodVariable: basmati, cookingTimeSeconds: 30 * 60)
        let item3 = CookingItem(foodItem: chicken, cookingTimeSeconds: 25 * 60) // same food as item1, different variable/duration
        let item4 = CookingItem(foodItem: pasta, cookingTimeSeconds: 12 * 60)

        // Two timers with variation and overlap
        let timer1 = CookingTimer(items: [item1, item2], customName: "Dinner")
        let timer2 = CookingTimer(items: [item3, item4], customName: "Quick Meal")

        // Insert into context
        context.insert(chicken)
        context.insert(rice)
        context.insert(pasta)
        context.insert(large)
        context.insert(basmati)
        context.insert(item1)
        context.insert(item2)
        context.insert(item3)
        context.insert(item4)
        context.insert(timer1)
        context.insert(timer2)

        do {
            try context.save()
        } catch {
            print("Mock seeding: save failed: \(error)")
        }
    }
}

