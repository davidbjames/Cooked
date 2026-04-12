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
    
    static func seedMockData(context: ModelContext, deferSave: Bool = false) throws {
        
        let existing = try context.fetch(FetchDescriptor<MealPlan>())
        
        guard existing.isEmpty else {
            // already seeded
            return
        }
        
        // Seed food group hierarchy: FoodGroup → Ingredient → Variety
        let chickenBreastVariety = Variety(name: "Boneless Chicken Breast")
        let chickenIngredient = Ingredient(name: "Chicken", varieties: [chickenBreastVariety])
        
        let basmatiRiceVariety = Variety(name: "Basmati Rice")
        let riceIngredient = Ingredient(name: "Rice", varieties: [basmatiRiceVariety])
        
        let spaghettiVariety = Variety(name: "Spaghetti Pasta")
        let pastaIngredient = Ingredient(name: "Pasta", varieties: [spaghettiVariety])
        
        let orangeCarrotVariety = Variety(name: "Orange Carrots")
        let carrotIngredient = Ingredient(name: "Carrots", varieties: [orangeCarrotVariety])
        
        let stapleGroup = FoodGroup(kind: .staple, ingredients: [riceIngredient, pastaIngredient])
        let proteinGroup = FoodGroup(kind: .protein, ingredients: [chickenIngredient])
        let vegetableGroup = FoodGroup(kind: .vegetable, ingredients: [carrotIngredient])
        
        // Seed food items using varieties
        let chicken = FoodItem(variety: chickenBreastVariety)
        let rice = FoodItem(variety: basmatiRiceVariety)
        let pasta = FoodItem(variety: spaghettiVariety)
        let carrots = FoodItem(variety: orangeCarrotVariety)
        
        let large = FoodVariable(name: "Large")
        let basmati = FoodVariable(name: "Basmati")
        
        // Create cooking items (some overlap in FoodItems across meal plans)
        let item1 = CookingItem(food: chicken, variable: large, minutes: 45)
        let item2 = CookingItem(food: rice, variable: basmati, minutes: 30)
        let item3 = CookingItem(food: chicken, minutes: 25) // same food as item1, different variable/duration
        let item4 = CookingItem(food: pasta, minutes: 12)
        let item5 = CookingItem(food: carrots, minutes: 20)
        
        // Two meal plans with variation and overlap
        let mealPlan1 = MealPlan(items: [item1, item2, item5], customName: "Dinner")
        let mealPlan2 = MealPlan(items: [item3, item4], customName: "Quick Meal")
        let mealPlan3 = MealPlan(items: [item2, item4])
        
        // Insert food groups (cascades to ingredients and varieties)
        context.insert(stapleGroup)
        context.insert(proteinGroup)
        context.insert(vegetableGroup)
        
        // Insert food items, variables, cooking items, and meal plans
        context.insert(chicken)
        context.insert(rice)
        context.insert(pasta)
        context.insert(carrots)
        context.insert(large)
        context.insert(basmati)
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
    
    static func resetData(context: ModelContext, reseed: Bool = false) throws {
        try wipeAllData(context: context, deferSave: true)
        if reseed {
            try seedMockData(context: context, deferSave: true)
        }
        try context.save()
    }
}

