//
//  ModelManagable.swift
//  Cooked
//
//  Created by David James on 03/04/2026.
//

import SwiftData

protocol ModelManagable: PersistentModel {
    
    func delete(in context: ModelContext)
}

extension ModelManagable {
    
    func delete(in context: ModelContext) {
        context.delete(self)
        try? modelContext?.save()
    }
}

extension CookingTimer: ModelManagable {}
extension CookingItem: ModelManagable {}
extension FoodItem: ModelManagable {}
extension FoodVariable: ModelManagable {}
