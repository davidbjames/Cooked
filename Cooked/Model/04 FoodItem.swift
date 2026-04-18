//
//  FoodItem.swift
//  Cooked
//
//  Created by David James on 29/01/2026.
//

import Foundation
import SwiftData

extension SchemaV1 {
    
    /// User maintained food item, manually created or
    /// created from generated varieties (which can
    /// also be renamed here).
    @Model
    final class FoodItem {
        
        @Relationship(inverse: \FoodGroup.foodItems)
        var group: FoodGroup?
        
        // TBD: allow the user to select just an ingredient
        // In most cases, for cooking that is good enough,
        // without the variety (e.g. "potatoes" vs. "piper potatoes")
        
        @Relationship(inverse: \Ingredient.foodItems)
        var ingredient: Ingredient?
        
        @Relationship(inverse: \Variety.foodItems)
        var variety: Variety?
        
        var customName: String?
        
        var createdAt: Date = Date()
        
        /// Support querying cooking items that have a particular food item
        /// (e.g. all cooking items that use potatoes).
        /// These items are appended automatically by SwiftData every time
        /// a new CookingItem is created (with a FoodItem).
        @Relationship
        private(set) var cookingItems: [CookingItem]?
        
        init(group: FoodGroup, ingredient: Ingredient, variety: Variety?) {
            self.group = group
            self.ingredient = ingredient
            self.variety = variety
        }
    }
}

extension FoodItem {
    
    var name: String {
        if let customName {
            customName
        } else if let name = (variety?.name ?? ingredient?.name) {
            name.capitalized(with: Locale.current)
        } else {
            "Ingredient"
        }
    }
}
