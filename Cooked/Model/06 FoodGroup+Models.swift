//
//  04 FoodGroup.swift
//  Cooked
//
//  Created by David James on 09/04/2026.
//

import SwiftData
import FoundationModels

// MARK: - Generated

@Generable
struct StandardFoodGroup: Equatable {
    
    @Guide(
        description: "Food group kind",
        .anyOf(
            FoodGroup.Kind.allCases.map(\.rawValue)
        )
    )
    let kind: String // < uses string to restrict ^
    
    @Guide(
        description: "A list of ingredients which are foods used in cooking",
        .minimumCount(Constants.generatedIngredientsCount.lowerBound),
        .maximumCount(Constants.generatedIngredientsCount.upperBound)
    )
    let ingredients: [GeneratedIngredient]
}

@Generable(description: "A food ingredient")
struct GeneratedIngredient: Equatable {
    
    @Guide(description: "The name of a food ingredient without variety")
    let name: String
    
    @Guide(description: "Is this a common food ingredient in the current region?")
    let isRegional: Bool
    // @Guide(
    //     description: "Varieties of food ingredients",
    //     .minimumCount(DataHelpers.varietyCount.lowerBound),
    //     .maximumCount(DataHelpers.varietyCount.upperBound)
    // )
    // let varieties: [Variety.GeneratedVariety]
}

@Generable
struct GeneratedVariety: Equatable {
    
    @Guide(description: "The name of a food variety, e.g. 'russet potatoes'.")
    let name: String
    
    @Guide(description: "Is this a common food variety in the current region?")
    let isRegional: Bool
}


// MARK: - Models

// NOTE: in maintaining these models, put properties in the schema namespaced model
// and everything else (methods, etc) in the extension.

// MARK: - FoodGroup

extension SchemaV1 {
    
    @Model
    final class FoodGroup {
        
        var kindKey: String = Kind.staple.rawValue
        
        @Relationship(deleteRule: .cascade, inverse: \Ingredient.foodGroup)
        var ingredients: [Ingredient]?
        
        @Relationship
        var foodItems: [FoodItem]?
        
        init(kind: Kind) {
            self.kindKey = kind.rawValue
        }
    }
}

extension FoodGroup {
    
    enum Kind: String, Hashable, Codable, CaseIterable {
        case staple
        case protein
        case vegetable
        
        var title: String {
            switch self {
            case .staple: "Staple Foods"
            case .protein: "Protein Foods"
            case .vegetable: "Vegetables"
            }
        }
    }
    
    var kind: Kind {
        get { Kind(rawValue: kindKey)! }
        set { kindKey = newValue.rawValue }
    }
    
    func addIngredient(_ ingredient: Ingredient) {
        if ingredients == nil {
            ingredients = []
        }
        ingredients?.append(ingredient)
    }
    
    // NOTE: do not override Equatable or Hashable implementations.
    // Use #Unique instead (if not using CloudKit).
    // If you need to check for value-based equality just create a custom
    // method such as isSameFood(as other:), etc.
}

// MARK: - Ingredient

extension SchemaV1 {
    
    @Model
    final class Ingredient {
        
        var name: String = "Food"
        var isRegional: Bool = true
        
        @Relationship(deleteRule: .cascade, inverse: \Variety.ingredient)
        var varieties: [Variety]?
        
        @Relationship
        var foodGroup: FoodGroup?
        
        @Relationship
        var foodItems: [FoodItem]?
        
        init(name: String, isRegional: Bool) {
            self.name = name
        }
    }
}

extension Ingredient {
    
    func addVariety(_ variety: Variety) {
        if varieties == nil {
            varieties = []
        }
        varieties?.append(variety)
    }
}

extension Ingredient: Comparable {
    
    static func < (lhs: Ingredient, rhs: Ingredient) -> Bool {
        lhs.name < rhs.name
    }
}

// MARK: - Variety

extension SchemaV1 {
    
    @Model
    final class Variety {
        
        var name: String = "Some Food"
        var isRegional: Bool = true
        
        // The difference between these two properties is
        // that the Ingredient is part of the food "databank"
        // but the [FoodItem] is part of the user's created
        // food items. They are two different models and
        // instances in the database so the user can both
        // select from a list of ingredients/varieties,
        // and also build food items for cooking.
        
        @Relationship
        var ingredient: Ingredient?
        
        @Relationship
        var foodItems: [FoodItem]?
        
        init(name: String, isRegional: Bool) {
            self.name = name
        }
    }
}

extension Variety {
    
    func setName(_ name: String) {
        self.name = name
    }
    func setRegional(_ isRegional: Bool?) {
        self.isRegional = isRegional ?? true
    }
}

extension Variety: Comparable {
    
    static func < (lhs: Variety, rhs: Variety) -> Bool {
        lhs.name < rhs.name
    }
}
