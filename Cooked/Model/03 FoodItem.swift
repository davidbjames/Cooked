//
//  FoodItem.swift
//  Cooked
//
//  Created by David James on 29/01/2026.
//

import Foundation
import SwiftData

@Model
final class FoodItem {
    
    var group: FoodGroup? {
        ingredient?.foodGroup
    }
    
    var ingredient: Ingredient? {
        variety?.ingredient
    }
    
    @Relationship(inverse: \Variety.foodItems)
    private(set) var variety: Variety?
    
    private(set) var createdAt: Date = Date()
    
    /// Support querying cooking items that have a particular food item
    /// (e.g. all cooking items that use potatoes).
    /// These items are appended automatically by SwiftData every time
    /// a new CookingItem is created (with a FoodItem).
    @Relationship
    private(set) var cookingItems: [CookingItem]?
    
    var name: String {
        variety?.name ?? "Missing Variety"
    }
    
    init(variety: Variety) {
        self.variety = variety
    }
    
    /// Used for testing only as it bypasses generated data source
    init(name: String) {
        self.variety = .init(name: "Some \(name)")
    }
}

