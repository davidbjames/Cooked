//
//  FoodListView.swift
//  Cooked
//
//  Created by David James on 18/04/2026.
//

import SwiftUI
import SwiftData
import FoundationModels

struct FoodListView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedFood: FoodItem?
    
    @Query private var _foodItems: [FoodItem]
    @State private var search: String = ""

    var foodItems: [FoodItem] {
        let search = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !search.isEmpty else {
            return _foodItems.sorted { $0.name < $1.name }
        }
        return _foodItems
            .filter { item in
                item.name.lowercased().contains(search)
            }
            .sorted { $0.name < $1.name }
    }
    
    @State private var generationState: SystemLanguageModel.Availability?
    @State private var ingredientGenerator: IngredientGenerator?
    
    @State private var showIngredients = false
    @State private var showGeneratorError = false
    
    var body: some View {
        List {
            Section {
                ForEach(foodItems, id: \.persistentModelID) { item in
                    Button {
                        selectedFood = item
                        dismiss()
                    } label: {
                        HStack {
                            Text(item.name)
                            Spacer()
                            if item == selectedFood {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
            }
            Button {
                do {
                    ingredientGenerator = try IngredientGenerator(modelContext: modelContext)
                    generationState = .available
                    showIngredients = true
                } catch let error as GeneratorError {
                    generationState = .unavailable(error.reason)
                } catch {
                    generationState = .unavailable(.appleIntelligenceNotEnabled)
                }
            } label: {
                Label("New Ingredient", systemImage: "plus")
            }
        }
        .navigationTitle("Ingredient")
        .searchable(text: $search)
        .onSubmit(of: .search) {
            // Select first search and dismiss if user hits enter.
            guard let first = foodItems.first else {
                return
            }
            selectedFood = first
            dismiss()
        }
        .sheet(isPresented: $showIngredients) {
            if let ingredientGenerator {
                NavigationStack {
                    IngredientListView(selectedFood: _selectedFood, generator: ingredientGenerator)
                }
                .presentationDetents([.large])
            }
        }
        .alert("Oops", isPresented: $showGeneratorError) {
            Button("OK", role: .cancel) {}
        } message: {
            if case let .unavailable(error) = generationState {
                switch error {
                case .appleIntelligenceNotEnabled: Text("Apple Intelligence is not available. Please check that it is enabled in Settings and try again.")
                case .deviceNotEligible: Text("This device does not support Apple Intelligence. Please add your ingredient by hand.")
                case .modelNotReady: Text("Apple Intelligence is not currently available - please try again later. In the mean time you can add your ingredient by hand.")
                @unknown default:
                    fatalError()
                }
            }
        }
    }
}

struct IngredientListView: View {
    
    @Binding var selectedFood: FoodItem?
    
    @State var generator: IngredientGenerator
    
    var body: some View {
        LazyVStack {
            EmptyView()
        }
        .navigationTitle("Ingredients")
    }
}
