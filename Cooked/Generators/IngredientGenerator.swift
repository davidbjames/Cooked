//
//  IngredientGenerator.swift
//  Cooked
//
//  Created by David James on 09/04/2026.
//

import Foundation
import FoundationModels
import SwiftData


/// Observable view model responsible for generating a list of ingredients
@Observable
final class IngredientGenerator: Generator {
    
    private(set) var foodGroups: [FoodGroup] = []
    
    /// Track the currently generating group for UX
    private(set) var generatingGroup: FoodGroup.Group? = nil
    
    /// Generates ingredients for all food groups on demand.
    override func generate() async throws(GeneratorError) {
        try await super.generate()
        defer {
            generatingGroup = nil
        }
        prepareGroups()
        for group in FoodGroup.Group.allCases {
            if token.isCancelled {
                throw GeneratorError.cancelled
            }
            try await generateGroup(group)
        }
    }
    
    /// Generate ingredients for a single food group on demand.
    /// Replaces the generator's token before calling this to ensure the previous
    /// generation is cancelled without affecting this one.
    func generate(group: FoodGroup.Group) async throws(GeneratorError) {
        try await super.generate()
        defer {
            generatingGroup = nil
        }
        prepareGroups()
        try await generateGroup(group)
    }
    
    // MARK: - Internal

    /// Prepares `foodGroups` from the store if not already loaded.
    ///
    /// Safe to call before any read that depends on `foodGroups` being populated,
    /// e.g. before checking `hasIngredients` on the view model.
    func prepareGroupsIfNeeded() {
        guard foodGroups.isEmpty else { return }
        prepareGroups()
    }

    // MARK: - Private

    /// Clears and repopulates `foodGroups` from the store, de-duplicating any
    /// records left by previous incomplete runs.
    ///
    /// Safe to call multiple times — resets state before re-populating.
    private func prepareGroups() {
        foodGroups = []
        // De-duplicate any FoodGroup records that may exist from previous incomplete runs.
        // (#Unique constraints are not available with CloudKit-backed stores.)
        let allFetchedGroups = modelContext.fetchAll(FoodGroup.self)
        var seen = Set<FoodGroup.Group>()
        for foodGroup in allFetchedGroups {
            if seen.insert(foodGroup.group).inserted {
                foodGroups.append(foodGroup)
            } else {
                // Transfer any ingredients not already in the winner before deleting,
                // since the cascade delete rule would otherwise silently drop them.
                guard let winner = foodGroups.first(where: { $0.group == foodGroup.group }) else {
                    continue
                }
                let existingNames = Set(winner.getContainedNames())
                for ingredient in foodGroup.ingredients ?? [] {
                    if !existingNames.contains(ingredient.name) {
                        ingredient.foodGroup = winner   // re-parent the ingredient
                        if debug {
                            print("Re-parenting orphaned ingredient '\(ingredient.name)' to food group '\(foodGroup.name)' (before deleting duplicate food group)")
                        }
                    }
                }
                modelContext.delete(foodGroup)
            }
        }
        // Sort to canonical allCases order after the DB fetch, which returns records in
        // arbitrary order. The generation loop appends new groups in allCases order
        // already, so this one-time sort is sufficient.
        let allCases = FoodGroup.Group.allCases
        foodGroups.sort {
            let lhsIndex = allCases.firstIndex(of: $0.group) ?? Int.max
            let rhsIndex = allCases.firstIndex(of: $1.group) ?? Int.max
            return lhsIndex < rhsIndex
        }
    }
    
    /// Generate ingredients for one food group, finding or creating its `FoodGroup` record.
    private func generateGroup(_ group: FoodGroup.Group) async throws(GeneratorError) {
        
        // LEARNING: Prevent context window limits by using new sessions.
        // - create a new session and new instructions for each food group generation
        // - minimizes context window build up (max 4096 tokens).
        // - since it's not a "conversation" it works fine.
        // - doing it this way also ensures instructions (which have greater weight)
        //   can be tweaked here depending on type.
        // - you can also create a new session with reduced transcript (see wwdc video)
        
        // TODO: Create Profile settings view that can set this
        // Profile.current(in: modelContext).includeInternationalIngredients = true
        let includeInternationalIngredients = Profile.current(in: modelContext).includeInternationalIngredients
        
        let foodGroup: FoodGroup
        if let existing = foodGroups.first(where: { $0.group == group }) {
            foodGroup = existing
        } else {
            foodGroup = .init(group)
            foodGroups.append(foodGroup)
            modelContext.insert(foodGroup)
        }
        let existingIngredients: [String] = foodGroup.getContainedNames()
        let existingIngredientsString = existingIngredients.joined(separator: ", ")
        
        generatingGroup = group
        
        if debug {
            print("------------------------------")
        }
        
        let instructions = Instructions {
            "Your job is to a build list of food ingredients from the \(group.rawValue) food group."
            "Prefer foods that are common in \(Self.regionName)."
            if includeInternationalIngredients {
                "Also include foods from around the world."
            }
            "Do not include variety names. For example, include '\(group.exampleIngredient)' but do not include '\(group.exampleVariety)'."
            "Do not include spices."
            "Foods should only be those that are easily cooked. For example, '\(group.exampleCookableIngredient)' can be easily cooked, so include these types of foods. On the other hand, '\(group.exampleUncookableIngredient)' on its own cannot be easily cooked, so DO NOT include these types of foods. This is just an example. Follow this pattern."
            switch group {
            case .staple:
                "The definition of a 'staple' is generally carbohydrates, starchy or cereal foods."
                "When planning a meal, 'staple' foods are frequently used alongside proteins, dairy and vegetables."
                "Include potatoes as a 'staple', not a vegetable."
            case .protein:
                "Include dairy products in this food group."
            case .vegetable:
                "Do not include potatoes."
                "It is fine to include tomatoes, or other fruits that are commonly used as vegetables."
            }
            "Food names must always be lower cased."
            "Food names MUST NOT be repeated in the list. If you detect two successive and identical names, stop the generation immediately and return the results up to that point."
            // this ^^ doesn't actually work due to degenerate repetition problem
            "Use the most common pluralization. For example, '\(group.examplePluralizedIngredient)' is commonly pluralized, but '\(group.exampleNonPluralizedIngredient)' is not. This is just an example. Follow this pattern."
            if !existingIngredients.isEmpty {
                // LEARNING: use stronger wording so that instruction is honored
                "Exclusion list: \(existingIngredientsString). (DO NOT include any of these under any circumstances, including spelling variations and synonyms.)"
            }
        }
        if !existingIngredients.isEmpty && debug {
            print("Exclude:", existingIngredientsString, "(\(existingIngredients.count))")
        }
        
        try await generateIngredients(
            for: foodGroup,
            instructions: instructions,
            prompt: { numItems in
                .init {
                    "Create a comma-delimited list of \(numItems) food ingredients from the \(group.rawValue) food group. Include the list only. No repeats."
                }
            }
        )
    }
    
    override func makeDegenerateDetector() -> any DegenerateDetector {
        IngredientDegenerateRepetitionDetector(debug: debug)
    }
}
