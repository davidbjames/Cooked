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
        private(set) var group: FoodGroup?
        
        // TBD: allow the user to select just an ingredient
        // In most cases, for cooking that is good enough,
        // without the variety (e.g. "potatoes" vs. "piper potatoes")
        
        @Relationship(inverse: \Ingredient.foodItems)
        private(set) var ingredient: Ingredient?
        
        @Relationship(inverse: \Variety.foodItems)
        private(set) var variety: Variety?
        
        private(set) var customName: String?
        
        private(set) var createdAt: Date = Date()
        
        /// Support querying cooking items that have a particular food item
        /// (e.g. all cooking items that use potatoes).
        /// These items are appended automatically by SwiftData every time
        /// a new CookingItem is created (with a FoodItem).
        @Relationship
        private(set) var cookingItems: [CookingItem]?
        
        init(group: FoodGroup, ingredient: Ingredient, variety: Variety) {
            self.group = group
            self.ingredient = ingredient
            self.variety = variety
        }
    }
}

extension FoodItem {
    
    var name: String {
        customName ?? variety?.name ?? ingredient?.name ?? "Ingredient"
    }
}
