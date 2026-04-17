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
    
    init(modelContext: ModelContext) throws {
        let tools = [any Tool]()
        var exclusions: String?
        let existingFoodGroups = modelContext.fetchAll(FoodGroup.self)
        let existingFoodNames = existingFoodGroups.getFoodNames()
        if !existingFoodNames.isEmpty {
            exclusions = "DO NOT include these ingredients: '" + existingFoodNames.keys.joined(separator: "', '") + "'"
        }
        let includeInternationalIngredients = Profile.current(in: modelContext).includeInternationalIngredients
        let instructions = Instructions {
            "Your job is to build lists of ingredients from food groups"
            "Prefer ingredients that are common in the current region '\(Self.regionName)'."
            if includeInternationalIngredients {
                "In addition to preferred ingredients, you may include alternative ingredients from around the world."
            }
            "Food ingredients should only be those that are easily cooked. For example, 'rice' can be cooked easily, so include these types of foods. However, 'wheat' on its own cannot be cooked easily, so do not include these types of foods. Though you may include 'flour' for baking or other types of food that have been processed to make cooking easier. This is just an example. Follow this pattern."
            // "Another example is 'oats' which as a grain is not normally used for cooking -- it would normally be 'rolled oats' or some other variety of oats when used for cooking. These are just examples. Follow this pattern."
            "Include potatoes as a staple - not a vegetable."
            "It's fine to include tomatoes as vegetables, or other fruits that are commonly used as vegetables."
            if let exclusions {
                exclusions
            }
            // "Always use the 'varietyExclusion' tool when generating varieties for an ingredient. For example, if generating 'rice' varieties, call the 'varietyExclusion' tool with ingredient 'rice' to get further instructions about which varieties to exclude."
        }
        try super.init(
            instructions: instructions,
            tools: tools,
            modelContext: modelContext
        )
//        let transcript = session.transcript
    }
    
    func generateIngredients() async {
        
        do {
            foodGroups = modelContext.fetchAll(FoodGroup.self)
            let foodNames = foodGroups.getFoodNames()
            if !foodNames.isEmpty {
                print("Existing food names:", foodNames.values.flatMap { $0 }.joined(separator: ", "))
            }
            let foodGroupKinds = FoodGroup.Kind.allCases.map(\.rawValue).joined(separator: ", ")
            let prompt = Prompt {
                "Create a list of ingredients from each food group: \(foodGroupKinds)"
            }
            // "".capitalized(with: .current)
            let stream = session.streamResponse(
                to: prompt,
                generating: [StandardFoodGroup].self,
                includeSchemaInPrompt: true,
                // "greedy" returns the statistically most likely response
                // which amounts to the same output for a given input, every time.
                options: GenerationOptions(sampling: .greedy)
            )
            // NOTE: _underscored variables indicate partially generated types
            for try await partialResponse in stream {
                let _foodGroups = partialResponse.content
                print("---------")
                for _foodGroup in _foodGroups {
                    guard
                        let kindKey = _foodGroup.kind,
                        let kind = FoodGroup.Kind(rawValue: kindKey)
                    else {
                        continue
                    }
                    print("FoodGroup:", kind.rawValue)
                    let foodGroup: FoodGroup
                    if let existing = foodGroups.first(where: { $0.kind == kind }) {
                        foodGroup = existing
                    } else {
                        foodGroup = FoodGroup(kind: kind)
                        foodGroups.append(foodGroup)
                        modelContext.insert(foodGroup)
                    }
                    
                    print("Ingredients:")
                    guard let _ingredients = _foodGroup.ingredients else {
                        continue
                    }
                    let ingredients = foodGroup.ingredients ?? []
                    for _ingredient in _ingredients {
                        let isRegional = _ingredient.isRegional ?? true
                        guard
                            let ingredientName = _ingredient.name,
                            !ingredientName.isEmpty
                        else {
                            continue
                        }
                        print("    ", ingredientName, "(regional: \(isRegional))")
                        guard !ingredients.contains(where: { $0.name == ingredientName }) else {
                            continue
                        }
                        let ingredient = Ingredient(name: ingredientName, isRegional: isRegional)
                        foodGroup.addIngredient(ingredient)
                    }
                }
            }
            // po foodGroups?.flatMap { $0.ingredients?.flatMap { $0.varieties?.map { $0.name } } }
        } catch let error as LanguageModelSession.GenerationError {
            self.error = error
            print("ERROR", error)
            // TODO: handle generation errors gracefully
            // switch error {
        } catch {
            self.error = error
            print("ERROR", error)
        }
    }
    
}

