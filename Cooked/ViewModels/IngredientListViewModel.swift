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

    /// Snapshot of the visible, sorted ingredients.
    ///
    /// This "stable array" drives the `ForEach` and `.onMove()`.
    /// It is _manually maintained and refreshed_ on food group change,
    /// `ingredients` count change and any "bulk" operation (hiding/moving).
    var displayedIngredients: [Ingredient] = []
    
    /// The current food group "picker".
    ///
    /// Changing this triggers a new ingredient generation task via `.task(id:)`.
    var selectedGroup: FoodGroup.Group = .staple
    
    /// Tracks edit mode (reorder and hiding).
    ///
    /// Bound to List via `\.editMode` for selection and drag handle activation.
    var editMode: EditMode = .inactive
    
    /// Selected edit mode ingredients.
    ///
    /// Passed as the List `selection` binding so multi-select is handled
    /// natively; cleared when edit mode exits or "Hide Selected" is invoked.
    var selectedIDs: Set<PersistentIdentifier> = []
    
    /// Ingredients (ids) currently generating varieties.
    ///
    /// Used by each `IngredientRow` to show a `ProgressView` spinner while
    /// generated varieties are streamed for that ingredient.
    var generatingVarieties: Set<PersistentIdentifier> = []
    
    /// The last error surfaced by either the ingredient or variety generator.
    ///
    /// May trigger an "Apple Intelligence" alert.
    var generatorError: GeneratorError?
    
    /// Cancellation token for the current ingredient generation task.
    ///
    /// Replaced with a fresh token each time generation starts so that
    /// stale streaming responses from a previous group are silently dropped.
    var ingredientGenerationToken: Generator.GenerationToken
    
    /// Cancellation token for the current variety-generation task.
    ///
    /// A single shared token is reused across sequential variety requests
    /// and cancelled whenever the user collapses a row, taps a variety,
    /// or enters edit mode.
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
    
    /// Whether the current food group is sorted alphabetically.
    var isAlphabetical: Bool {
        selectedFoodGroup?.order == .alphabetical
    }

    // MARK: - Ingredient List

    func refreshDisplayedIngredients() {
        guard let foodGroup = selectedFoodGroup else {
            displayedIngredients = []
            return
        }
        displayedIngredients = sortedIngredients(for: foodGroup)
    }

    private func sortedIngredients(for foodGroup: FoodGroup) -> [Ingredient] {
        let visible = foodGroup.ingredients?.filter { !$0.isHidden } ?? []
        switch foodGroup.order {
        case .stable:
            return visible
        case .alphabetical:
            return visible.sorted()
        case .custom:
            return visible.sorted { $0.sortOrder < $1.sortOrder }
        }
    }

    // MARK: - Actions

    func toggleAlphabetical() {
        selectedFoodGroup?.order = .alphabetical
        refreshDisplayedIngredients()
    }

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
                await runVarietyGeneration(for: ingredient)
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

    func hideSelected(expandedIngredients: inout Set<PersistentIdentifier>) {
        for ingredient in displayedIngredients where selectedIDs.contains(ingredient.persistentModelID) {
            hideIngredient(ingredient, expandedIngredients: &expandedIngredients)
        }
        refreshDisplayedIngredients()
        withAnimation {
            selectedIDs = []
            isEditing = false
        }
    }

    func moveIngredients(
        from source: IndexSet,
        to destination: Int
    ) {
        displayedIngredients.move(fromOffsets: source, toOffset: destination)
        for (index, ingredient) in displayedIngredients.enumerated() {
            ingredient.sortOrder = index
        }
        selectedFoodGroup?.order = .custom
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

    func runVarietyGeneration(for ingredient: Ingredient) async {
        let id = ingredient.persistentModelID
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
