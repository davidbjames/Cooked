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
    
    var name: String = ""
    
    var createdAt: Date = Date()
    
    @Relationship(inverse: \CookingItem.foodItem)
    var items: [CookingItem]?

    init(name: String) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = Date()
    }
}

