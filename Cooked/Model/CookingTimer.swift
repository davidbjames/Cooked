//
//  CookingTimer.swift
//  Cooked
//
//  Created by David James on 29/01/2026.
//

import Foundation
import SwiftData

@Model
final class CookingTimer {
    
    /// Relationship to items (to-many, unordered by default)
    /// (this does not cascade delete to preserve original cooking items and their references)
    @Relationship(deleteRule: .nullify, inverse: \CookingItem.cookingTimer)
    var items: [CookingItem]? = []

    /// Optional user-provided name
    var customName: String?
    
    var createdAt: Date = Date()

    init(items: [CookingItem] = [], customName: String? = nil) {
        self.items = items
        self.customName = customName?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = Date()
        for item in items {
            item.cookingTimer = self
        }
    }
    
    /// Computed name when customName is nil or empty:
    /// 0 items: "Cooking Timer"
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
            let names = items.compactMap { $0.foodItem?.name }.filter { !$0.isEmpty }
            
            if names.isEmpty {
                return "Cooking Timer"
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
}

extension CookingTimer: TimedItem {
    
    /// Overall duration is the cooking item that takes the longest
    var timeInSeconds: Int {
        items?.max(by: { $0.timeInSeconds < $1.timeInSeconds })?.timeInSeconds ?? 0
    }
}
