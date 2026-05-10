//
//  IngredientListViewModel.swift
//  Cooked
//
//  Created by David James on 18/04/2026.
//

import SwiftUI
import SwiftData

// MARK: - IngredientListViewModel

@Observable
@MainActor
final class IngredientListViewModel {

    // MARK: - Dependencies

    // Note: the generator is implicitly observable through its properties
    // even though it's marked as let here (i.e. "explicity not observable").
    // Model context is already non-observable as a let constant.
    // Other props are vars and so participate in observable changes.
    // You would use @ObservationIgnored only with *vars* you don't want observed.
    
    let generator: IngredientGenerator
    let modelContext: ModelContext

    // MARK: - State

    var displayedIngredients: [Ingredient] = []
    var selectedGroup: FoodGroup.Group = .staple
    var editMode: EditMode = .inactive
    var selectedIDs: Set<PersistentIdentifier> = []
    var generatingVarieties: Set<PersistentIdentifier> = []
    var generatorError: GeneratorError?
    var ingredientGenerationToken: Generator.GenerationToken
    var varietyGenerationToken: Generator.GenerationToken?

    // MARK: - Init

    init(generator: IngredientGenerator, modelContext: ModelContext) {
        self.generator = generator
        self.modelContext = modelContext
        self.ingredientGenerationToken = generator.token
    }

    // MARK: - Computed

    var isEditing: Bool {
        get { editMode.isEditing }
        set { editMode = newValue ? .active : .inactive }
    }

    var selectedFoodGroup: FoodGroup? {
        generator.foodGroups.first { $0.group == selectedGroup }
    }

    // MARK: - Ingredient List

    func refreshDisplayedIngredients(ingredientOrderCustomised: Bool) {
        guard let foodGroup = selectedFoodGroup else {
            displayedIngredients = []
            return
        }
        displayedIngredients = sortedIngredients(for: foodGroup, ingredientOrderCustomised: ingredientOrderCustomised)
    }

    private func sortedIngredients(for foodGroup: FoodGroup, ingredientOrderCustomised: Bool) -> [Ingredient] {
        let visible = foodGroup.ingredients?.filter { !$0.isHidden } ?? []
        if ingredientOrderCustomised {
            return visible.sorted { $0.sortOrder < $1.sortOrder }
        } else {
            return visible.sorted()
        }
    }

    // MARK: - Actions

    func toggleExpanded(_ ingredient: Ingredient, expandedIngredients: inout Set<PersistentIdentifier>) {
        let id = ingredient.persistentModelID
        if expandedIngredients.contains(id) {
            expandedIngredients.remove(id)
        } else {
            expandedIngredients.insert(id)
            ingredientGenerationToken.isCancelled = true
            guard !generatingVarieties.contains(id) else {
                return
            }
            Task {
                do {
                    if varietyGenerationToken == nil {
                        varietyGenerationToken = .init()
                    }
                    let varietyGenerator = try VarietyGenerator(
                        ingredient: ingredient,
                        modelContext: modelContext,
                        token: varietyGenerationToken!
                    )
                    generatingVarieties.insert(id)
                    try await varietyGenerator.generate()
                    generatingVarieties.remove(id)
                } catch let error as GeneratorError {
                    generatingVarieties.remove(id)
                    generatorError = error
                } catch {
                    generatingVarieties.remove(id)
                }
            }
        }
    }

    func hideIngredient(_ ingredient: Ingredient, expandedIngredients: inout Set<PersistentIdentifier>) {
        ingredient.visibilityState = IngredientVisibility.hidden.rawValue
        expandedIngredients.remove(ingredient.persistentModelID)
    }

    func hideVariety(_ variety: Variety) {
        variety.visibilityState = IngredientVisibility.hidden.rawValue
    }

    func hideSelected(expandedIngredients: inout Set<PersistentIdentifier>, ingredientOrderCustomised: Bool) {
        for ingredient in displayedIngredients where selectedIDs.contains(ingredient.persistentModelID) {
            hideIngredient(ingredient, expandedIngredients: &expandedIngredients)
        }
        refreshDisplayedIngredients(ingredientOrderCustomised: ingredientOrderCustomised)
        withAnimation {
            selectedIDs = []
            isEditing = false
        }
    }

    func moveIngredients(
        from source: IndexSet,
        to destination: Int,
        ingredientOrderCustomised: inout Bool
    ) {
        displayedIngredients.move(fromOffsets: source, toOffset: destination)
        for (index, ingredient) in displayedIngredients.enumerated() {
            ingredient.sortOrder = index
        }
        ingredientOrderCustomised = true
    }

    func cancelCurrentGeneration(expandedIngredients: inout Set<PersistentIdentifier>) {
        ingredientGenerationToken.isCancelled = true
        generator.token.isCancelled = true
        varietyGenerationToken?.isCancelled = true
        generatingVarieties.removeAll()
        expandedIngredients.removeAll()
    }

    func selectVariety(
        _ variety: Variety?,
        ingredient: Ingredient,
        group: FoodGroup,
        onSelect: (FoodItem) -> Void
    ) {
        guard let varietyGenerationToken else {
            print("**** Variety generation cancellation token does not exist on variety selection")
            return
        }
        varietyGenerationToken.isCancelled = true
        generatingVarieties.removeAll()
        let foodItem = FoodItem(group: group, ingredient: ingredient, variety: variety)
        modelContext.insert(foodItem)
        onSelect(foodItem)
    }

    // MARK: - Generation Task

    func runIngredientGeneration() async {
        let oldToken = generator.token
        generator.token = Generator.GenerationToken()
        ingredientGenerationToken = generator.token
        oldToken.isCancelled = true
        do {
            try await generator.generate(group: selectedGroup)
        } catch {
            generatorError = error
        }
    }
}
