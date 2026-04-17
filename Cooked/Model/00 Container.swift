//
//  Container.swift
//  Cooked
//
//  Created by David James on 15/04/2026.
//

import SwiftData

// Schema changes as it relates to CloudKit:
// - new properties are fine - additive
// - removed properties - old field remains in CloudKit (ignored)
// - rename properties - creates new field, orphans old data
//   - use @Attribute(originalName: "oldPropName")
// - rename class - creates new record type entirely
//   - don't do this - instead create a local type alias e.g. typealias NewName = OldName
//     i.e. so that "OldName" remains forever the type in CloudKit
// - delete record type - NOT SUPPORTED
// - change field type - NOT SUPPORTED

// Rule: CloudKit schema is additive only. You can never rename or delete record types
// or fields in production. Plan your names carefully, or use the typealias pattern to
// decouple your Swift names from the CloudKit schema.

// Learning: plan your ERD carefully from the beginning

// See Copilot CloudKit RecordName chat for more info on this...
// (can also create versions and migration plans)

// MARK: - Schemas

// This is not used yet, except as a namespace for the first schema version
// (see extensions of this in model files)
enum SchemaV1: VersionedSchema {
    
    static let versionIdentifier: Schema.Version = .init(1, 0, 0)
    
    // NOTE: these
    static var models: [any PersistentModel.Type] {
        // Note: these are indented to reveal the hierarchy.
        [
            Profile.self,
            MealPlan.self,
                CookingItem.self,
                    FoodItem.self,
                        FoodGroup.self,
                        Ingredient.self,
                        Variety.self,
                    FoodVariable.self
        ]
    }
}

// MARK: - Aliases to support migration

typealias CurrentSchema = SchemaV1

typealias Profile = CurrentSchema.Profile
typealias MealPlan = CurrentSchema.MealPlan
typealias CookingItem = CurrentSchema.CookingItem
typealias FoodItem = CurrentSchema.FoodItem
typealias FoodGroup = CurrentSchema.FoodGroup
typealias Ingredient = CurrentSchema.Ingredient
typealias Variety = CurrentSchema.Variety
typealias FoodVariable = CurrentSchema.FoodVariable

// MARK: - ModelContainer

extension ModelContainer {
    
    // Shared ModelContainer configured for CloudKit sync and sharing
    static let sharedModelContainer: ModelContainer = {
        
        let schema = Schema(SchemaV1.models)
        
        // Configure CloudKit with sharing at initialization time.
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false, // stored in SQLite locally
            allowsSave: true,
            groupContainer: .automatic,
            cloudKitDatabase: .automatic // connects model with CloudKit
            // no need for local persistent store URL (e.g. when syncing with CoreData)
        )
        guard
            let modelContainer = try? ModelContainer(for: schema, configurations: [configuration])
        else {
            // CHECK: can this ever hit? How to handle gracefully if it can.
            preconditionFailure()
        }
        return modelContainer
    }()
    
}
