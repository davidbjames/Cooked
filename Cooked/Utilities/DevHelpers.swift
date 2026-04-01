//
//  DevHelpers.swift
//  Cooked
//
//  Created by David James on 29/01/2026.
//

import SwiftData

func wipeAllData(context: ModelContext) throws {
    // Delete CookingTimer first to break relationships to items
    let timerDescriptor = FetchDescriptor<CookingTimer>()
    let timers = try context.fetch(timerDescriptor)
    timers.forEach { context.delete($0) }
    
    // Then delete CookingItem (some might be left if they were not attached to a timer)
    let itemDescriptor = FetchDescriptor<CookingItem>()
    let items = try context.fetch(itemDescriptor)
    items.forEach { context.delete($0) }
    
    // Finally delete lookup tables
    let foodDescriptor = FetchDescriptor<FoodItem>()
    let foods = try context.fetch(foodDescriptor)
    foods.forEach { context.delete($0) }
    
    let varDescriptor = FetchDescriptor<FoodVariable>()
    let vars = try context.fetch(varDescriptor)
    vars.forEach { context.delete($0) }
    
    try context.save()
}
