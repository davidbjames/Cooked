//
//  VarietyListView.swift
//  Cooked
//
//  Created by David James on 18/04/2026.
//

import SwiftUI
import SwiftData

struct VarietyListView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedFood: FoodItem?
    
    @State private var generator: VarietyGenerator

    init(selectedFood: Binding<FoodItem?>, generator: VarietyGenerator) {
        _selectedFood = selectedFood
        _generator = State(initialValue: generator)
    }
    
    var body: some View {
        List {
            Section(header: Text(generator.ingredient.name.capitalized(with: .current))) {
                ForEach(generator.ingredient.varieties?.sorted() ?? [], id: \.persistentModelID) { variety in
                    Button {
                        selectVariety(variety)
                    } label: {
                        Text(variety.name.capitalized(with: .current))
                    }
                }
            }
        }
        .navigationTitle("Varieties")
        .task {
            await generator.generate()
        }
    }
    
    private func selectVariety(_ variety: Variety) {
        let ingredient = generator.ingredient
        guard let group = ingredient.foodGroup else { return }
        let foodItem = FoodItem(group: group, ingredient: ingredient, variety: variety)
        modelContext.insert(foodItem)
        selectedFood = foodItem
        dismiss()
    }
}
