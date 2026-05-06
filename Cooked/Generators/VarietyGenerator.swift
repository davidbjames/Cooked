//
//  VarietyGenerator.swift
//  Cooked
//
//  Created by David James on 15/04/2026.
//

import Foundation
import FoundationModels
import SwiftData

@Observable
final class VarietyGenerator: Generator {
    
    let ingredient: Ingredient
    
    init(ingredient: Ingredient, modelContext: ModelContext, token: GenerationToken = .init()) throws {
        self.ingredient = ingredient
        try super.init(modelContext: modelContext, token: token)
    }
    
    override func generate() async throws(GeneratorError) {
        
        try await super.generate()
        
        let includeInternationalIngredients = Profile.current(in: modelContext).includeInternationalIngredients
        
        let ingredientName = ingredient.name

        let existingVarieties = ingredient.varieties?.map { $0.name } ?? []
        
        let instructions = Instructions {
            "Your job is to build a list of food varieties for '\(ingredientName)'."
            "Prefer varieties that are common in '\(Self.regionName)'."
            if includeInternationalIngredients {
                "Also include varieties from around the world."
            }
            "Varieties should always include the full name, variety plus food name, e.g. 'russet potatoes'."
            "Variety names must always be lower cased, e.g. 'russet potatoes'."
            "Varieties MUST not be repeated in the list."
            // TBD: pluralization comment similar to ingredients
            if !existingVarieties.isEmpty {
                "Exclusion list: \(existingVarieties.joined(separator: ", ")). (DO NOT include any of these under any circumstances, including spelling variations and synonyms.)"
            }
        }
        
        try await generateIngredients(
            for: ingredient,
            instructions: instructions,
            prompt: { numItems in
                .init {
                    "Create a comma-delimited list of \(numItems) varieties for '\(ingredientName)'. Include the list only. No repeats."
                }
            }
        )
    }
}
