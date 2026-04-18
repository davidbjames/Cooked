//
//  FoodItemView.swift
//  Cooked
//
//  Created by David James on 18/04/2026.
//

import SwiftUI
import SwiftData

struct FoodItemView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedFood: FoodItem?
    
    @State private var selectedGroupKind: FoodGroup.Kind?
    @State private var ingredientName: String = ""
    @State private var varietyName: String = ""
    
    var body: some View {
        Form {
            Section {
                Picker("Group", selection: $selectedGroupKind) {
                    ForEach(FoodGroup.Kind.allCases, id: \.self) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                
                if selectedGroupKind != nil {
                    TextField("Ingredient e.g. Potatoes", text: $ingredientName)
#if os(iOS)
                        .textInputAutocapitalization(.words)
#endif
                    if hasValidIngredient {
                        TextField("Variety (optional) e.g. Piper", text: $varietyName)
#if os(iOS)
                            .textInputAutocapitalization(.words)
#endif
                    }
                }
            }
            Section {
                Button {
                    save()
                } label: {
                    Label("Add Ingredient", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasValidIngredient)
            }
        }
        .navigationTitle("New Ingredient")
    }
    
    private var hasValidIngredient: Bool {
        !ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func save() {
        
        let trimmedIngredient = ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedIngredient.isEmpty else {
            return
        }
        let trimmedVariety = varietyName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // FoodGroup
        
        let groups = modelContext.fetchAll(FoodGroup.self)
        let foodGroup: FoodGroup
        if let group = groups.first(where: { $0.kind == selectedGroupKind }) {
            foodGroup = group
        } else if let selectedGroupKind {
            foodGroup = FoodGroup(kind: selectedGroupKind)
            modelContext.insert(foodGroup)
        } else {
            return
        }
        
        // Ingredient
        let ingredient: Ingredient
        if
            let existingIngredient = foodGroup.ingredients?.first(where: {
                $0.name.caseInsensitiveCompare(trimmedIngredient) == .orderedSame
            })
        {
            ingredient = existingIngredient
        } else {
            ingredient = Ingredient(name: trimmedIngredient, isRegional: true)
            // modelContext.insert(ingredient)
            foodGroup.addIngredient(ingredient)
        }
        
        // Variety
        
        let variety: Variety?
        if !trimmedVariety.isEmpty {
            // If the user typed just the variety type (e.g. "Piper"),
            // append the ingredient name to form the full variety name (e.g. "Piper Potatoes").
            let fullVarietyName: String
            if trimmedVariety.contains(trimmedIngredient) {
                fullVarietyName = trimmedVariety
            } else {
                fullVarietyName = "\(trimmedVariety) \(trimmedIngredient)"
            }
            if
                let existingVariety = ingredient.varieties?.first(where: {
                    $0.name.caseInsensitiveCompare(fullVarietyName) == .orderedSame
                })
            {
                variety = existingVariety
            } else {
                variety = Variety(name: fullVarietyName, isRegional: false)
                // modelContext.insert(new)
                ingredient.addVariety(variety!)
            }
        } else {
            variety = nil
        }
        
        // FoodItem
        
        let foodItem = FoodItem(group: foodGroup, ingredient: ingredient, variety: variety)
        modelContext.insert(foodItem)
        
        selectedFood = foodItem
        dismiss()
    }
}
