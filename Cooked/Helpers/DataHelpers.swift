//
//  DevHelpers.swift
//  Cooked
//
//  Created by David James on 29/01/2026.
//

import SwiftData

enum DataHelpers {
    
    static func wipeAllData(context: ModelContext, deferSave: Bool = false) throws {
        
        // Delete MealPlan first to break relationships to items
        let mealPlanDescriptor = FetchDescriptor<MealPlan>()
        let mealPlans = try context.fetch(mealPlanDescriptor)
        mealPlans.forEach { context.delete($0) }
        
        // Then delete CookingItem (some might be left if they were not attached to a meal plan)
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
        
        // Deleting FoodGroup cascades to Ingredient, which cascades to Variety
        let foodGroupDescriptor = FetchDescriptor<FoodGroup>()
        let foodGroups = try context.fetch(foodGroupDescriptor)
        foodGroups.forEach { context.delete($0) }
        
        if !deferSave {
            try context.save()
        }
    }
    
    @MainActor
    private static func seedMockData(context: ModelContext, deferSave: Bool = false) async throws {
        
        let existing = try context.fetch(FetchDescriptor<MealPlan>())
        
        guard existing.isEmpty else {
            // already seeded
            return
        }
        
        let generator = IngredientGenerator()
        await generator.generateIngredients()
        
        for foodGroup in generator.foodGroups {
            context.insert(foodGroup)
        }
        
        guard
            let proteinGroup = generator.foodGroups.first(where: { $0.kind == .protein }),
            let stapleGroup = generator.foodGroups.first(where: { $0.kind == .staple }),
            let vegetableGroup = generator.foodGroups.first(where: { $0.kind == .vegetable }),
            let firstProteinVariety = proteinGroup.ingredients?.first?.varieties?.first,
            let firstStapleVariety = stapleGroup.ingredients?.first?.varieties?.first,
            let lastStapleVariety = stapleGroup.ingredients?.last?.varieties?.last,
            let firstVegetableVariety = vegetableGroup.ingredients?.first?.varieties?.first
        else {
            return
        }
        
        // Seed food items using generated varieties
        let food1 = FoodItem(variety: firstProteinVariety)
        let food2 = FoodItem(variety: firstStapleVariety)
        let food3 = FoodItem(variety: lastStapleVariety)
        let food4 = FoodItem(variety: firstVegetableVariety)
        
        let large = FoodVariable(name: "Large")
        let small = FoodVariable(name: "Small")
        
        // Create cooking items (some overlap in FoodItems across meal plans)
        let item1 = CookingItem(food: food1, variable: large, minutes: 45)
        let item2 = CookingItem(food: food2, variable: small, minutes: 30)
        let item3 = CookingItem(food: food1, minutes: 25) // same food as item1, different variable/duration
        let item4 = CookingItem(food: food3, minutes: 12)
        let item5 = CookingItem(food: food4, minutes: 20)
        
        // Two meal plans with variation and overlap
        let mealPlan1 = MealPlan(items: [item1, item2, item5], customName: "Dinner")
        let mealPlan2 = MealPlan(items: [item3, item4], customName: "Quick Meal")
        let mealPlan3 = MealPlan(items: [item2, item4])
        
        // Insert food items, variables, cooking items, and meal plans
        context.insert(food1)
        context.insert(food2)
        context.insert(food3)
        context.insert(food4)
        context.insert(large)
        context.insert(small)
        context.insert(item1)
        context.insert(item2)
        context.insert(item3)
        context.insert(item4)
        context.insert(item5)
        context.insert(mealPlan1)
        context.insert(mealPlan2)
        context.insert(mealPlan3)
        
        if !deferSave {
            try context.save()
        }
    }
    
    @MainActor
    static func resetData(context: ModelContext, reseed: Bool = false, deferSave: Bool = false) async throws {
        try wipeAllData(context: context, deferSave: deferSave)
        if reseed {
            try await seedMockData(context: context, deferSave: deferSave)
        }
        try context.save()
    }
}

