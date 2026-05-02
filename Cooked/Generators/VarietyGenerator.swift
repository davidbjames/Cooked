//
//  VarietyGenerator.swift
//  Cooked
//
//  Created by David James on 15/04/2026.
//

import FoundationModels
import SwiftData

@Observable
final class VarietyGenerator: Generator {
    
    let ingredient: Ingredient
    
    init(ingredient: Ingredient, modelContext: ModelContext) throws {
        
        self.ingredient = ingredient
        try super.init(modelContext: modelContext)
    }
    
    
    func generateVarieties() async {
        var exclusions: String?
        let existingVarieties = ingredient.varieties?.map { $0.name } ?? []
        if !existingVarieties.isEmpty {
            exclusions = "DO NOT include these varieties: '" + existingVarieties.joined(separator: "', '") + "'"
        }
        let includeInternationalIngredients = Profile.current(in: modelContext).includeInternationalIngredients
        let instructions = Instructions {
            "Your job is to build a list of food varieties for '\(ingredient.name)'."
            "Prefer varieties that are common in the current region '\(Self.regionName)'."
            if includeInternationalIngredients {
                "In addition to preferred varieties, you may include alternative varieties from other parts of the world."
            }
            "Food varieties should always include the full name, variety plus food name, e.g. 'russet potatoes'"
            "Food ingredient and variety names must always be lower cased, e.g. 'russet potatoes'."
            "Food varieties should not be repeated within the session."
            if let exclusions {
                exclusions
            }
        }
        print(instructions)
        let session = LanguageModelSession(
            model: .default,
            tools: [],
            instructions: instructions
        )
        do {
            let ingredientName = ingredient.name
            let prompt = Prompt {
                "Create a list of ONLY 3 varieties for the ingredient '\(ingredientName)'"
            }
            let stream = session.streamResponse(
                to: prompt,
                generating: [GeneratedVariety].self,
                includeSchemaInPrompt: true
//                options: .init(sampling: .greedy)
            )
            
            // NOTE: _underscored variables indicate partially generated types
            let varieties = ingredient.varieties ?? []
            for try await partialResponse in stream {
                let _varieties = partialResponse.content
                for _variety in _varieties {
                    guard
                        let varietyName = _variety.name,
                        !varietyName.isEmpty,
                        !varieties.contains(where: { $0.name == varietyName })
//                         ingredient.varieties?.contains(where: { $0.name == varietyName }) != true

                    else {
                        continue
                    }
                    let isRegional = _variety.isRegional ?? true
                    print("        ", varietyName, " (regional: \(isRegional))")
                    // If the last variety's name is a prefix of the new name,
                    // update it in place instead of appending
                    if
                        let lastVariety = varieties.last,
                        varietyName.hasPrefix(lastVariety.name) && varietyName != lastVariety.name
                    {
                        print("        * \(lastVariety.name) vs. \(varietyName)")
                        lastVariety.setName(varietyName)
                    } else {
                        let variety = Variety(name: varietyName, isRegional: isRegional)
                        ingredient.addVariety(variety)
                    }
                }
            }
        } catch let error as LanguageModelSession.GenerationError {
            self.error = error
            print("ERROR", error)
        } catch {
            self.error = error
            print("ERROR", error)
        }
    }
}
