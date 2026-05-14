//
//  CookedTests.swift
//  CookedTests
//
//  Created by David James on 29/01/2026.
//

import Testing
import SwiftData
@testable import Cooked

struct CookedTests {

    let container: ModelContainer
    let context: ModelContext

    init() throws {
        let schema = Schema(CurrentSchema.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    /// Verifies the IngredientContainer behaviour that IngredientGenerator relies on.
    @Test
    func ingredientContainerBehavior() throws {

        // addContained(_:) correctly appends ingredients to a FoodGroup
        let foodGroup = FoodGroup(.protein)
        context.insert(foodGroup)

        let chicken = Ingredient(name: "chicken", isRegional: true)
        let tofu = Ingredient(name: "tofu", isRegional: false)
        context.insert(chicken)
        context.insert(tofu)

        foodGroup.addContained(chicken)
        foodGroup.addContained(tofu)

        // getContainedNames() reflects inserted ingredients
        let names = foodGroup.getContainedNames()
        #expect(names.sorted() == ["chicken", "tofu"])

        // containsName(_:) correctly identifies present and absent names
        #expect(foodGroup.containsName("chicken") == true)
        #expect(foodGroup.containsName("broccoli") == false)

        // makeGenerationSettings() reports the right group, kind, and existing count
        let settings = foodGroup.makeGenerationSettings()
        #expect(settings.group == .protein)
        #expect(settings.kind == .ingredients)
        #expect(settings.existingCount == 2)
    }

}
