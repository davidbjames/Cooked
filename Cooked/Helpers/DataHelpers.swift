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
    static func seedMockData(context: ModelContext, deferSave: Bool = false) async throws {
        
        try await IngredientGenerator(modelContext: context).generate()
        
        let foodGroups = try context.fetch(FetchDescriptor<FoodGroup>())

        // Create test data
        
        guard
            let proteinGroup = foodGroups.first(where: { $0.group == .protein }),
            let stapleGroup = foodGroups.first(where: { $0.group == .staple }),
            let vegetableGroup = foodGroups.first(where: { $0.group == .vegetable }),
            let firstProteinIngredient = proteinGroup.ingredients?.first,
            let firstStapleIngredient = stapleGroup.ingredients?.first,
            let lastStapleIngredient = stapleGroup.ingredients?.last,
            let firstVegetableIngredient = vegetableGroup.ingredients?.first
        else {
            return
        }
        let firstProteinVariety = firstProteinIngredient.varieties?.first
        let firstStapleVariety = firstStapleIngredient.varieties?.first
        let lastStapleVariety = lastStapleIngredient.varieties?.last
        let firstVegetableVariety = firstVegetableIngredient.varieties?.first

        // Seed food items using generated varieties
        let proteinFood1 = FoodItem(group: proteinGroup, ingredient: firstProteinIngredient, variety: firstProteinVariety)
        let stapleFood1 = FoodItem(group: stapleGroup, ingredient: firstStapleIngredient, variety: firstStapleVariety)
        let stapleFood2 = FoodItem(group: stapleGroup, ingredient: lastStapleIngredient, variety: lastStapleVariety)
        let vegetableFood1 = FoodItem(group: vegetableGroup, ingredient: firstVegetableIngredient, variety: firstVegetableVariety)
        
        let large = FoodVariable(name: "Large")
        let small = FoodVariable(name: "Small")
        
        // Create cooking items (some overlap in FoodItems across meal plans)
        let proteinItem1 = CookingItem(food: proteinFood1, variable: large, minutes: 45)
        let stapleItem1 = CookingItem(food: stapleFood1, variable: small, minutes: 30)
        let proteinItem2 = CookingItem(food: proteinFood1, minutes: 25) // same food as item1, different variable/duration
        let stapleItem2 = CookingItem(food: stapleFood2, minutes: 12)
        let vegetableItem2 = CookingItem(food: vegetableFood1, minutes: 20)
        
        // Two meal plans with variation and overlap
        let mealPlan1 = MealPlan(items: [proteinItem1, stapleItem1, vegetableItem2], customName: "Dinner")
        let mealPlan2 = MealPlan(items: [proteinItem2, stapleItem2], customName: "Quick Meal")
        let mealPlan3 = MealPlan(items: [proteinItem1, stapleItem2], customName: nil)
        
        // Insert food items, variables, cooking items, and meal plans
        context.insert(proteinFood1)
        context.insert(stapleFood1)
        context.insert(stapleFood2)
        context.insert(vegetableFood1)
        context.insert(large)
        context.insert(small)
        context.insert(proteinItem1)
        context.insert(stapleItem1)
        context.insert(proteinItem2)
        context.insert(stapleItem2)
        context.insert(vegetableItem2)
        context.insert(mealPlan1)
        context.insert(mealPlan2)
        context.insert(mealPlan3)
        
        if !deferSave {
            try context.save()
        }
    }
}

extension ModelContext {
    
    func hasData<T: PersistentModel>(for type: T.Type) -> Bool {
        guard let existing = try? fetch(FetchDescriptor<T>()) else {
            return false
        }
        return !existing.isEmpty
    }
    
    @MainActor
    func fetchAll<T: PersistentModel>(_: T.Type) -> [T] {
        let descriptor = FetchDescriptor<T>()
        return (try? fetch(descriptor)) ?? []
    }
    
    
    @MainActor
    func fetchUserProfile() -> Profile? {
        let descriptor = FetchDescriptor<Profile>()
        return try? fetch(descriptor).first
    }
}
