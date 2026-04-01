//
//  CookingItem.swift
//  Cooked
//
//  Created by David James on 29/01/2026.
//

import Foundation
import SwiftData

@Model
final class CookingItem: TimedItem {
    
    @Relationship(deleteRule: .nullify)
    var foodItem: FoodItem? = FoodItem(name: "")

    @Relationship(deleteRule: .nullify)
    var foodVariable: FoodVariable?

    @Attribute(originalName: "cookingTimeSeconds")
    var timeInSeconds: Int = 0

    var createdAt: Date = Date()
    
    // Note: this inverse relationship causes a circular reference error
    // and is not needed since Swift infers the bi-directional relationship.
    // The convention is to put the relationship on the "to-many" side
    // as I did already on CookingTimer.items (vs. the "to-one" side here)
    // @Relationship(inverse: \CookingTimer.items)
    weak var cookingTimer: CookingTimer?

    init(foodItem: FoodItem, foodVariable: FoodVariable? = nil, cookingTimeSeconds: Int) {
        self.foodItem = foodItem
        self.foodVariable = foodVariable
        self.timeInSeconds = max(0, cookingTimeSeconds)
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

