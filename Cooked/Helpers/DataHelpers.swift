//
//  DevHelpers.swift
//  Cooked
//
//  Created by David James on 29/01/2026.
//

import SwiftData

enum DataHelpers {
    
    static func wipeAllData(context: ModelContext, deferSave: Bool = false) throws {
        
        // Delete CookingTimer first to break relationships to items
        let timerDescriptor = FetchDescriptor<CookingTimer>()
        let timers = try context.fetch(timerDescriptor)
        timers.forEach { context.delete($0) }
        
        // Then delete CookingItem (some might be left if they were not attached to a timer)
        let itemDescriptor = FetchDescriptor<CookingItem>()
        let items = try context.fetch(itemDescriptor)
        items.forEach { context.delete($0) }
        
        // Finally delete extended tables
        let foodDescriptor = FetchDescriptor<FoodItem>()
        let foods = try context.fetch(foodDescriptor)
        foods.forEach { context.delete($0) }
        
        let varDescriptor = FetchDescriptor<FoodVariable>()
        let vars = try context.fetch(varDescriptor)
        vars.forEach { context.delete($0) }
        
        if !deferSave {
            try context.save()
        }
    }
    
    static func seedMockData(context: ModelContext, deferSave: Bool = false) throws {
        
        let existing = try context.fetch(FetchDescriptor<CookingTimer>())
        
        guard existing.isEmpty else {
            // already seeded
            return
        }
        
        // Seed shared data
        let chicken = FoodItem(name: "Chicken")
        let rice = FoodItem(name: "Rice")
        let pasta = FoodItem(name: "Pasta")
        
        let large = FoodVariable(name: "Large")
        let basmati = FoodVariable(name: "Basmati")
        
        // Create cooking items (some overlap in FoodItems across timers)
        let item1 = CookingItem(food: chicken, variable: large, minutes: 45)
        let item2 = CookingItem(food: rice, variable: basmati, minutes: 30)
        let item3 = CookingItem(food: chicken, minutes: 25) // same food as item1, different variable/duration
        let item4 = CookingItem(food: pasta, minutes: 12)
        
        // Two timers with variation and overlap
        let timer1 = CookingTimer(items: [item1, item2], customName: "Dinner")
        // item1.cookingTimers = [timer1], item2.cookingTimers = [timer1]
        let timer2 = CookingTimer(items: [item3, item4], customName: "Quick Meal")
        // item3.cookingTimers = [timer2], item4.cookingTimers = [timer2]
        let timer3 = CookingTimer(items: [item2, item4])
        // item2.cookingTimers = [timer1, timer3], item4.cookingTimers = [timer2, timer3]
        
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
        context.insert(timer3)
        
        if !deferSave {
            try context.save()
        }
    }
    
    static func resetMockData(context: ModelContext) throws {
        try wipeAllData(context: context, deferSave: true)
        try seedMockData(context: context, deferSave: true)
        try context.save()
    }
}

