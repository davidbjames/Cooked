//
//  IngredientListView.swift
//  Cooked
//
//  Created by David James on 18/04/2026.
//

import SwiftUI
import SwiftData
import FoundationModels

// Bugs:
// - Ingredients are regenerated when going back from Varieties
// - FoodItemListView is showing duplicate ingredients
// - IngredientListView selecting ingredient does nothing
// - VarietyListView is displaying way too much, including dupes

struct IngredientListView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedFood: FoodItem?
    
    @State private var generator: IngredientGenerator

    init(selectedFood: Binding<FoodItem?>, generator: IngredientGenerator) {
        _selectedFood = selectedFood
        _generator = State(initialValue: generator)
    }
    
    @State private var generationState: SystemLanguageModel.Availability?
    @State private var varietyGenerator: VarietyGenerator?
    
    private var showVarieties: Binding<Bool> {
        let state = generationState
        return .init { state == .available }
    }
    private var showGeneratorError: Binding<Bool> {
        let state = generationState
        return .init { state?.isAvailable == false }
    }
    
    var body: some View {
        List {
            ForEach(generator.foodGroups, id: \.persistentModelID) { foodGroup in
                Section(header: Text(foodGroup.group.title)) {
                    ForEach(foodGroup.ingredients?.sorted() ?? [], id: \.persistentModelID) { ingredient in
                        HStack {
                            Button {
                                selectIngredient(ingredient, group: foodGroup)
                            } label: {
                                Text(ingredient.name.capitalized(with: .current))
                            }
                            .buttonStyle(.borderless) // restrict tap to button not row
                            Spacer()
                            Button {
                                drillIntoVarieties(for: ingredient)
                            } label: {
                                Image(systemName: "chevron.right")
                                    // .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless) // restrict tap to button not row
                        }
                    }
                }
            }
        }
        .navigationTitle("Ingredients")
        .navigationDestination(isPresented: showVarieties) {
            if let varietyGenerator {
                VarietyListView(selectedFood: $selectedFood, generator: varietyGenerator)
            }
        }
        .alert("Apple Intelligence", isPresented: showGeneratorError) {
            Button("OK", role: .cancel) { generationState = nil }
        } message: {
            if case let .unavailable(error) = generationState {
                switch error {
                case .appleIntelligenceNotEnabled:
                    Text("Apple Intelligence is not enabled. Please check it is enabled in Settings and try again.")
                case .deviceNotEligible:
                    Text("This device does not support Apple Intelligence. Varieties are not available.")
                case .modelNotReady:
                    Text("Apple Intelligence not ready. Please try again later.")
                @unknown default:
                    fatalError()
                }
            } else {
                Text("Please try again later.")
            }
        }
        .task {
            await generator.generateIngredients()
        }
    }
    
    private func selectIngredient(_ ingredient: Ingredient, group: FoodGroup) {
        let foodItem = FoodItem(group: group, ingredient: ingredient, variety: nil)
        modelContext.insert(foodItem)
        selectedFood = foodItem
        dismiss()
    }
    
    private func drillIntoVarieties(for ingredient: Ingredient) {
        do {
            varietyGenerator = try VarietyGenerator(ingredient: ingredient, modelContext: modelContext)
            generationState = .available
        } catch let error as GeneratorError {
            generationState = .unavailable(error.reason)
        } catch {
            generationState = .unavailable(.appleIntelligenceNotEnabled)
        }
    }
}
