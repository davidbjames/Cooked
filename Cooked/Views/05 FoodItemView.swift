//
//  FoodItemView.swift
//  Cooked
//
//  Created by David James on 18/04/2026.
//

import SwiftUI
import SwiftData

/// View for editing or create a food item.
/// This could also be used in case generation does not provide
/// the desired ingredient with which to create a food item from.
/// "New Ingredient"
struct FoodItemView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedFood: FoodItem?
    
    @State private var selectedGroupKind: FoodGroup.Group?
    @State private var ingredientName: String = ""
    @State private var varietyName: String = ""
    
    var body: some View {
        Form {
            Section {
                Picker("Group", selection: $selectedGroupKind) {
                    ForEach(FoodGroup.Group.allCases, id: \.self) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(hasValidIngredient)
                
                if selectedGroupKind != nil {
                    TextField("Ingredient e.g. \(exampleIngredient)", text: $ingredientName)
#if os(iOS)
                        .textInputAutocapitalization(.words)
#endif
                    if hasValidIngredient {
                        TextField("Variety (optional) e.g. \(exampleVariety)", text: $varietyName)
#if os(iOS)
                            .textInputAutocapitalization(.words)
#endif
                    }
                }
            }
        }
        .navigationTitle("New Ingredient")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    saveAndDismiss()
                } label: {
                    Image(systemName: "checkmark")
                }
                .disabled(!hasValidIngredient)
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private var hasValidIngredient: Bool {
        !ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var exampleIngredient: String {
        selectedGroupKind?.exampleIngredient ?? "Potatoes"
    }
    private var exampleVariety: String {
        selectedGroupKind?.exampleVariety ?? "Piper Potatoes"
    }
    
    private func saveAndDismiss() {
        
        let trimmedIngredient = ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedIngredient.isEmpty else {
            return
        }
        let trimmedVariety = varietyName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // FoodGroup
        
        let groups = modelContext.fetchAll(FoodGroup.self)
        let foodGroup: FoodGroup
        if let group = groups.first(where: { $0.group == selectedGroupKind }) {
            foodGroup = group
        } else if let selectedGroupKind {
            foodGroup = FoodGroup(selectedGroupKind)
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
            // TBD: this doesn't work for every case e.g. "Lamb Chops" (reverse order)
            // or "Shallots" (variety of "Onions", i.e. not "Shallot Onions")
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
