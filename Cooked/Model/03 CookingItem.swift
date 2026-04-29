//
//  CookingItem.swift
//  Cooked
//
//  Created by David James on 29/01/2026.
//

import Foundation
import SwiftData
import FoundationModels

extension SchemaV1 {
    /// Wrapper to anything that can be cooked for a prescribed time.
    ///
    /// This doesn't hold the actual name, that is on `FoodItem`.
    /// Also, the `FoodVariable` is an arbitrary variable.
    @Model
    final class CookingItem: TimedItem {
        
        @Relationship(deleteRule: .nullify, inverse: \FoodItem.cookingItems) // delete food item, make this reference nil
        private(set) var foodItem: FoodItem?
        
        @Relationship(deleteRule: .nullify)
        private(set) var foodVariable: FoodVariable?
        
        // @Attribute(originalName: "cookingTimeSeconds")
        private(set) var timeInSeconds: Int = 0
        
        private(set) var createdAt: Date = Date()
        
        // NOTE: this is the "other" side of the many-to-many relationship
        // between MealPlan and CookingItem.
        // SwiftData automatically detects the many-to-many relationship
        // and manages the data locally and on the backend, including
        // populating this array in the client.
        // (i.e. we can look up the associated meal plans from each food item)
        // SwiftData also infers the "inverse" relationship so we don't
        // need to mention it again here. I mention the minimum model count
        // just to be explicit (0 or more). See TBD.
        // @Attribute(originalName: "cookingTimers")
        // @Relationship(minimumModelCount: 0) (these macros cannot be composed)
        @Relationship
        private(set) var mealPlans: [MealPlan]? = []
        
        init(food: FoodItem, variable: FoodVariable? = nil, minutes: Double) {
            self.foodItem = food
            self.foodVariable = variable
            self.timeInSeconds = max(0, Int(minutes * 60))
        }
    }
}

extension CookingItem {
    
    var foodName: String {
        if let foodItem {
            foodItem.name
        } else {
            "Dish"
        }
    }
    var displayName: String {
        guard let foodItem else {
            return "Dish"
        }
        if let variable = foodVariable?.name, !variable.isEmpty {
            return "\(foodItem.name) (\(variable))"
        } else {
            return foodItem.name
        }
    }
}

