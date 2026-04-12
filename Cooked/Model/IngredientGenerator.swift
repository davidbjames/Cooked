//
//  IngredientGenerator.swift
//  Cooked
//
//  Created by David James on 09/04/2026.
//

import Foundation
import FoundationModels

/// Observable view model responsible for generating a list of ingredients using a language model, organized by food groups. The generated ingredients are stored in the `foodGroups` property, which can be observed for changes to update the UI accordingly. The generation process takes into account the user's locale to prefer ingredients that are common in their region, while also allowing for international ingredients based on user settings.
@Observable
final class IngredientGenerator {
    
    var error: Error?
    
    private let session: LanguageModelSession
    
    private(set) var foodGroups: [FoodGroup] = []
    
    init() {
        let localeString = Locale.current.region?.identifier ?? "en_US"
        print("Locale:", localeString)
        let includeInternationalIngredients = false // <-- this will come from user setting (synced)
        let instructions = Instructions {
            "Prefer food ingredients that are common in the user's locale region: \"\(localeString)\"."
            if includeInternationalIngredients {
                "You may also include international ingredients common in other regions."
            }
            "Food ingredients should only be those that are easily cooked. For example, 'rice' can be cooked easily, so include these types of foods. However, 'wheat' on its own cannot be cooked easily, so do not include these types of foods. Though you may include 'flour' for baking or other types of food that have been processed to make cooking easier. Another example is 'oats' which as a grain is not normally used for cooking -- it would normally be 'rolled oats' or some other variety of oats when used for cooking. These are just examples. Follow this pattern."
            "Include potatoes as a staple - not a vegetable."
            "Food varieties should always include the full name, variety plus food name, e.g. 'russet potatoes'"
        }
        self.session = LanguageModelSession(
            tools: [],
            instructions: instructions
        )
    }
    
    func generateIngredients() async {
        do {
            let foodGroupKinds = FoodGroup.Kind.allCases.map(\.rawValue).joined(separator: ", ")
            let prompt = Prompt {
                "Create a list of ingredients from each food group: \(foodGroupKinds)"
            }
            let stream = session.streamResponse(
                to: prompt,
                generating: [FoodGroup.StandardFoodGroup].self,
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
                    }
                    
                    print("Ingredients:")
                    guard let _ingredients = _foodGroup.ingredients else {
                        continue
                    }
                    for _ingredient in _ingredients {
                        
                        guard let name = _ingredient.name, !name.isEmpty else {
                            continue
                        }
                        print("    ", name)
                        let ingredient: Ingredient
                        if let existing = foodGroup.ingredients?.first(where: { $0.name == name }) {
                            ingredient = existing
                        } else {
                            ingredient = Ingredient(name: name)
                            foodGroup.addIngredient(ingredient)
                        }
                                
                        guard let _varieties = _ingredient.varieties else {
                            continue
                        }
                        for _variety in _varieties {
                            
                            guard let varietyName = _variety.name, !varietyName.isEmpty else {
                                continue
                            }
                            print("        ", varietyName)
                            if let _ = ingredient.varieties?.first(where: { $0.name == varietyName }) {
                                // Already exists, update other properties if needed (not shown here since we only have name)
                                continue
                            } else {
                                // If the last variety's name is a prefix of the new name (partial → full),
                                // update it in place instead of appending
                                if
                                    let lastVariety = ingredient.varieties?.last,
                                    varietyName.hasPrefix(lastVariety.name) && varietyName != lastVariety.name
                                {
                                    lastVariety.setName(varietyName)
                                } else {
                                    let variety = Variety(name: varietyName)
                                    ingredient.addVariety(variety)
                                }
                            }
                        }
                    }
                }
            }
            print("****")
            // po foodGroups?.flatMap { $0.ingredients?.flatMap { $0.varieties?.map { $0.name } } }
        } catch {
            self.error = error
            print(error)
        }
    }
    
}

