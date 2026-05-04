//
//  IngredientListView.swift
//  Cooked
//
//  Created by David James on 18/04/2026.
//

import SwiftUI
import SwiftData
import FoundationModels

// MARK: - IngredientListView

struct IngredientListView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedFood: FoodItem?
    
    @State private var generator: IngredientGenerator
    @State private var expandedIngredients: Set<PersistentIdentifier> = []
    @State private var generatingVarieties: Set<PersistentIdentifier> = []
    @State private var generatorError: SystemLanguageModel.Availability?
    
    init(selectedFood: Binding<FoodItem?>, generator: IngredientGenerator) {
        _selectedFood = selectedFood
        _generator = State(initialValue: generator)
    }
    
    var body: some View {
        List {
            ForEach(generator.foodGroups, id: \.persistentModelID) { foodGroup in
                Section(header: Text(foodGroup.group.title)) {
                    ForEach(foodGroup.ingredients?.sorted() ?? [], id: \.persistentModelID) { ingredient in
                        IngredientRow(
                            ingredient: ingredient,
                            isExpanded: expandedIngredients.contains(ingredient.persistentModelID),
                            isGenerating: generatingVarieties.contains(ingredient.persistentModelID),
                            onToggle: { toggleExpanded(ingredient) },
                            onSelectVariety: { variety in selectVariety(variety, ingredient: ingredient, group: foodGroup) }
                        )
                    }
                }
            }
        }
        .navigationTitle("Ingredients")
        .task {
            await generator.generate()
        }
        .alert("Apple Intelligence", isPresented: .init(
            get: { generatorError?.isAvailable == false },
            set: { if !$0 { generatorError = nil } }
        )) {
            Button("OK", role: .cancel) { generatorError = nil }
        } message: {
            if case let .unavailable(error) = generatorError {
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
    }
    
    // MARK: - Actions
    
    private func toggleExpanded(_ ingredient: Ingredient) {
        let id = ingredient.persistentModelID
        if expandedIngredients.contains(id) {
            expandedIngredients.remove(id)
        } else {
            expandedIngredients.insert(id)
            // Only generate varieties if none exist yet and not already generating
            if /*ingredient.varieties?.isEmpty != false, */!generatingVarieties.contains(id) {
                Task {
                    do {
                        let varietyGenerator = try VarietyGenerator(
                            ingredient: ingredient,
                            modelContext: modelContext
                        )
                        generatingVarieties.insert(id)
                        await varietyGenerator.generate()
                        generatingVarieties.remove(id)
                    } catch let error as GeneratorError {
                        generatingVarieties.remove(id)
                        generatorError = .unavailable(error.reason)
                    } catch {
                        generatingVarieties.remove(id)
                        generatorError = .unavailable(.appleIntelligenceNotEnabled)
                    }
                }
            }
        }
    }
    
    private func selectVariety(_ variety: Variety, ingredient: Ingredient, group: FoodGroup) {
        let foodItem = FoodItem(group: group, ingredient: ingredient, variety: variety)
        modelContext.insert(foodItem)
        selectedFood = foodItem
        dismiss()
    }
}

// MARK: - Variety Chip

private struct VarietyChip: View {
    let variety: Variety
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text(variety.name.capitalized(with: .current))
                .font(.subheadline)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.tint.opacity(0.12), in: Capsule())
                .foregroundStyle(.tint)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(variety.name.capitalized(with: .current))
    }
}


// MARK: - Ingredient Row

private struct IngredientRow: View {
    let ingredient: Ingredient
    let isExpanded: Bool
    let isGenerating: Bool
    let onToggle: () -> Void
    let onSelectVariety: (Variety) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Ingredient header — tapping expands/collapses varieties
            Button(action: onToggle) {
                HStack {
                    Text(ingredient.name.capitalized(with: .current))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .contentShape(Rectangle()) // entire row is tappable to expand ingredient
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                isExpanded
                    ? "Collapse \(ingredient.name.capitalized(with: .current))"
                    : "Expand \(ingredient.name.capitalized(with: .current))"
            )
            .accessibilityAddTraits(.isButton)

            if isExpanded {
                let varieties = ingredient.varieties?.sorted() ?? []
                if !varieties.isEmpty || isGenerating {
                    FlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
                        ForEach(varieties, id: \.persistentModelID) { variety in
                            VarietyChip(variety: variety) {
                                onSelectVariety(variety)
                            }
                        }
                        if isGenerating {
                            ProgressView()
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.leading, 16)
                }
            }
        }
        .padding(.vertical, 2)
    }
}


