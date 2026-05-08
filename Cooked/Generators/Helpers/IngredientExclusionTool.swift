//
//  IngredientExclusionTool.swift
//  Cooked
//
//  Created by David James on 15/04/2026.
//

import FoundationModels

// TBD: this tool was not used

// NOTE: Tools can be either struct or class
// Use class if you want to hold custom state, for example, the call method may use this
// to append/update based on what happens in that call method. For example,
// to track something and prevent repeated logic in subsequent call methods.
// (see Foundation Models learnings for examples)

final class IngredientExclusionTool: Tool {
    
    let name: String = "ingredientExclusion"
    let description: String = "Exclude certain food ingredients."
    
    let exclusionList: [String: [String]]
    init(exclusionList: [String : [String]]) {
        self.exclusionList = exclusionList
    }
    
    @Generable
    struct Arguments {
        @Guide(description: "The name of the food ingredient (e.g. 'rice', 'potatoes').")
        let ingredient: String
    }
    
    func call(arguments: Arguments) async throws -> IngredientExclusionList {
        let ingredient = arguments.ingredient
        if let exclusions = exclusionList[ingredient], !exclusions.isEmpty {
//            let instructions = """
//            For ingredient '\(arguments.ingredient)' there are these varieties that should be avoided:
//            '\(exclusions)'
//            """
            let list = IngredientExclusionList(ingredient: ingredient, excludedVarieties: exclusions)
            print("Exclusions for \(ingredient):", list)
            return list
        } else {
            print("No Exclusions for:", ingredient)
            return .init(ingredient: ingredient)
        }
    }
}

struct IngredientExclusionList: PromptRepresentable {
    
    let ingredient: String
    let excludedVarieties: [String]
    
    var promptRepresentation: Prompt {
        .init {
            if !excludedVarieties.isEmpty {
                "DO NOT include the following \(ingredient) varieties:"
                "'\(excludedVarieties.joined(separator: "', '"))'"
            } else {
                "" // good enough?
            }
        }
    }
    init(ingredient: String, excludedVarieties: [String] = []) {
        self.ingredient = ingredient
        self.excludedVarieties = excludedVarieties
    }
}
