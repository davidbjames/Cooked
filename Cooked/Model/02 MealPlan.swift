//
//  MealPlan.swift
//  Cooked
//
//  Created by David James on 29/01/2026.
//

import Foundation
import SwiftData

extension SchemaV1 {
    
    /// Cooking timer in the broader sense of functionality.
    /// Ultimately, these are more "meal planners" that include
    /// as a core feature the timing of different meal parts.
    @Model
    final class MealPlan {
        
        
        /// Relationship to items (to-many, unordered by default)
        /// (this does not cascade delete to preserve original cooking items and their references)
        @Relationship(
            deleteRule: .nullify,
            minimumModelCount: 1,
            inverse: \CookingItem.mealPlans
        )
        var items: [CookingItem]? = []
        
        /// Optional user-provided name
        var customName: String?
        
        var createdAt: Date = Date()
        
        init(items: [CookingItem], customName: String?) {
            self.items = items
            self.customName = customName?.trimmingCharacters(in: .whitespacesAndNewlines)
            self.createdAt = Date()
        }
        
    }
}

extension MealPlan {
    
    /// Computed name when customName is nil or empty:
    /// 0 items: "Meal Plan"
    /// 1 item: "A"
    /// 2 items: "A & B"
    /// 3+ items: "A, B, ..., Y & Z"
    var name: String {
        if let customName, !customName.isEmpty {
            return customName
        } else {
            guard let items else {
                return "Missing data"
            }
            let names = items.compactMap {
                !$0.foodName.isEmpty ? $0.foodName : nil
            }
            if names.isEmpty {
                return "Meal Plan"
            } else if names.count == 1 {
                return names[0]
            } else if names.count == 2 {
                return "\(names[0]) & \(names[1])"
            } else {
                let head = names.dropLast().joined(separator: ", ")
                let tail = names.last!
                return "\(head) & \(tail)"
            }
        }
    }
    
    var summary: String? {
        guard let items, !items.isEmpty else {
            return nil
        }
        return items.compactMap { $0.foodItem?.name }.joined(separator: ", ")
    }
    
    var hasCookingItems: Bool {
        items != nil && items!.count > 0
    }
    
    func setCustomName(_ name: String?) {
        customName = name
    }
    func addCookingItem(_ item: CookingItem) {
        items?.append(item)
    }
}

extension MealPlan: TimedItem {
    
    /// Overall duration is the cooking item that takes the longest
    var timeInSeconds: Int {
        items?.max(by: { $0.timeInSeconds < $1.timeInSeconds })?.timeInSeconds ?? 0
    }
}

