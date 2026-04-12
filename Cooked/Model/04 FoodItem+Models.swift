//
//  04 FoodGroup.swift
//  Cooked
//
//  Created by David James on 09/04/2026.
//

import SwiftData
import FoundationModels

@Model
final class FoodGroup {
    
    // Unique constraints are not supported with CloudKit
    // #Unique<FoodGroup>([\.kindKey])
    
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
            description: "A list of ingredients which are foods that can easily be used in cooking",
            .count(3)
        )
        let ingredients: [Ingredient.FoodIngredient]
    }
    
    private(set) var kindKey: String = Kind.staple.rawValue
    
    var kind: Kind {
        get { Kind(rawValue: kindKey)! }
        set { kindKey = newValue.rawValue }
    }
    
    @Relationship(deleteRule: .cascade, inverse: \Ingredient.foodGroup)
    private(set) var ingredients: [Ingredient]?
    
    init(kind: Kind, ingredients: [Ingredient] = []) {
        self.kindKey = kind.rawValue
        self.ingredients = ingredients
    }
    
    init?(generated: StandardFoodGroup.PartiallyGenerated) {
        guard let kindString = generated.kind else {
            return nil
        }
        self.kindKey = kindString
        self.ingredients = generated.ingredients?.map { .init(generated: $0) }
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

@Model
final class Ingredient {
    
    // Unique constraints are not supported with CloudKit
    // #Unique<Ingredient>([\.name/*, \.foodGroup*/]) // unique in food group, not globally
    
    @Generable(description: "A food ingredient")
    struct FoodIngredient: Equatable {
        @Guide(description: "The name of a food ingredient without variety")
        let name: String
        @Guide(
            description: "Varieties of food ingredients",
            .count(3)
        )
        let varieties: [Variety.FoodVariety]
    }
    
    private(set) var name: String = "Food"
    
    @Relationship(deleteRule: .cascade, inverse: \Variety.ingredient)
    private(set) var varieties: [Variety]?
    
    @Relationship
    private(set) var foodGroup: FoodGroup?
    
    init(name: String, varieties: [Variety]? = nil) {
        self.name = name
        self.varieties = varieties
    }
    
    init(generated: FoodIngredient.PartiallyGenerated) {
        self.name = generated.name ?? "Food"
        self.varieties = generated.varieties?.map { .init(generated: $0) }
    }
    
    func addVariety(_ variety: Variety) {
        if varieties == nil {
            varieties = []
        }
        varieties?.append(variety)
    }
}


@Model
final class Variety {
    
    // Unique constraints are not supported with CloudKit
    // #Unique<Variety>([\.name/*, \.ingredient*/]) // unique within ingredient type, not globally
    
    @Generable
    struct FoodVariety: Equatable {
        @Guide(description: "The name of a food variety, e.g. 'russet potatoes'.")
        let name: String
    }
    
    private(set) var name: String = "Some Food"
    
    // The difference between these two properties is
    // that the Ingredient is part of the food "databank"
    // but the [FoodItem] is part of the user's created
    // food items. They are two different models and
    // instances in the database so the user can both
    // select from a list of ingredients/varieties,
    // and also build food items for cooking.

    @Relationship
    private(set) var ingredient: Ingredient?
    
    @Relationship
    private(set) var foodItems: [FoodItem]?
    
    init(name: String) {
        self.name = name
    }
    
    init(generated: FoodVariety.PartiallyGenerated) {
        self.name = generated.name ?? "Some Food"
    }
    
    func setName(_ name: String) {
        self.name = name
    }
}

