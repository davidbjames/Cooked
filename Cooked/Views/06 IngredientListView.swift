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
    @Binding var expandedIngredients: Set<PersistentIdentifier>
    @State private var generatingVarieties: Set<PersistentIdentifier> = []
    @State private var generatorError: SystemLanguageModel.Availability?
    @State private var ingredientToken = Generator.CancellationToken()
    @State private var varietyToken = Generator.CancellationToken()
    
    init(selectedFood: Binding<FoodItem?>, generator: IngredientGenerator, expandedIngredients: Binding<Set<PersistentIdentifier>>) {
        _selectedFood = selectedFood
        _generator = State(initialValue: generator)
        _expandedIngredients = expandedIngredients
    }
    
    var body: some View {
        List {
            ForEach(generator.foodGroups, id: \.persistentModelID) { foodGroup in
                Section(header:
                    HStack {
                        Text(foodGroup.group.title)
                        if generator.generatingGroup == foodGroup.group {
                            Spacer()
                            ProgressView()
                            Text("Generating")
                                .fontWeight(.regular)
                                .opacity(0.5)
                        }
                    }
                ) {
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
            do {
                try await generator.generate(cancellationToken: ingredientToken)
            } catch let error as GeneratorError {
                switch error {
                case .cancelled:
                    print("************* Cancel ingredient generation")
                case .availability(let reason):
                    generatorError = .unavailable(reason)
                }
            } catch {
                print(error)
            }
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
            ingredientToken.isCancelled = true
            guard !generatingVarieties.contains(id) else {
                return
            }
            Task {
                do {
                    let varietyGenerator = try VarietyGenerator(
                        ingredient: ingredient,
                        modelContext: modelContext
                    )
                    generatingVarieties.insert(id)
                    try await varietyGenerator.generate(cancellationToken: varietyToken)
                    generatingVarieties.remove(id)
                } catch let error as GeneratorError {
                    generatingVarieties.remove(id)
                    switch error {
                    case .cancelled:
                        print("************* Cancel variety generation for \(ingredient.name).")
                    case .availability(let reason):
                        generatorError = .unavailable(reason)
                    }
                } catch {
                    generatingVarieties.remove(id)
                }
            }
        }
    }
    
    private func selectVariety(_ variety: Variety, ingredient: Ingredient, group: FoodGroup) {
        varietyToken.isCancelled = true
        generatingVarieties.removeAll()
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
                // Unlike ingredients, varieties are not sorted so the
                // generating items remain stable for selection.
                let varieties = ingredient.varieties ?? []
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


