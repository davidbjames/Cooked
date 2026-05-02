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
    
    @ObservationIgnored
    private var session: LanguageModelSession!
    
    init(ingredient: Ingredient, modelContext: ModelContext) throws {
        self.ingredient = ingredient
        try super.init(modelContext: modelContext)
    }
    
    func generateVarieties() async {
        let existingVarieties = ingredient.varieties?.map { $0.name } ?? []
        var exclusions: String?
        if !existingVarieties.isEmpty {
            exclusions = "Exclusion list: \(existingVarieties.joined(separator: ", ")). (DO NOT include any of these under any circumstances, including spelling variations and synonyms.)"
        }
        let includeInternationalIngredients = Profile.current(in: modelContext).includeInternationalIngredients
        let ingredientName = ingredient.name
        let group = ingredient.foodGroup?.group

        let instructions = Instructions {
            "Your job is to build a list of food varieties for '\(ingredientName)'."
            "Prefer varieties that are common in the current region '\(Self.regionName)'."
            if includeInternationalIngredients {
                "In addition to preferred varieties, you may include alternative varieties from other parts of the world."
            }
            "Food varieties should always include the full name, variety plus food name, e.g. 'russet potatoes'."
            "Food ingredient and variety names must always be lower cased, e.g. 'russet potatoes'."
            "Food varieties should not be repeated in the list."
            if let exclusions {
                exclusions
            }
        }

        session = LanguageModelSession(
            model: .init(guardrails: .permissiveContentTransformations),
            tools: [],
            instructions: instructions
        )

        let settings = GenerationSettings(
            group: group ?? .vegetable,
            kind: .varieties,
            existingCount: existingVarieties.count
        )
        print(settings)

        let numVarieties = settings.numberOfItems

        let prompt = Prompt {
            "Create a comma-delimited list of \(numVarieties) varieties for '\(ingredientName)'. Include the list only. No repeats."
        }

        do {
            let response = try await session.respond(
                to: prompt,
                generating: String.self,
                includeSchemaInPrompt: false,
                options: settings.generationOptions
            )

            print(response.content)

            // Parsing
            let splitLines = response.content.split(separator: /\d+\.?|[,\n\-•*]+|\band\b/)
            let trimmedLines = splitLines.map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
                  .trimmingCharacters(in: .punctuationCharacters)
                  .lowercased()
            }
            print("Responded with:", trimmedLines.count, "items")

            // Post-generation audit and variety build
            for line in trimmedLines {
                guard !line.isEmpty else { continue }
                guard ingredient.varieties?.contains(where: { $0.name == line }) != true else {
                    print("(skipping \(line) - already exists)")
                    continue
                }
                let auditSession = LanguageModelSession(
                    model: .init(guardrails: .permissiveContentTransformations),
                    instructions: "Your job is to answer questions about food."
                )
                let isVariety = try await auditSession.respond(
                    to: "Is '\(line)' a variety of '\(ingredientName)'?",
                    generating: Bool.self
                )
                guard isVariety.content else {
                    print("(skipping \(line) - not a variety of '\(ingredientName)')")
                    continue
                }
                let isRegional = try await auditSession.respond(
                    to: "Is '\(line)' a common variety in \(Self.regionName)?",
                    generating: Bool.self
                )
                print(line, isRegional.content ? "(regional)" : "(NOT regional)")
                let variety = Variety(name: line, isRegional: isRegional.content)
                ingredient.addVariety(variety)
            }

        } catch let error as LanguageModelSession.GenerationError {
            self.error = error
            print("GENERATION ERROR", error)
            switch error {
            case .rateLimited(let context):
                print(context)
            default:
                break
            }
            if let session {
                print("------ TRANSCRIPT ------")
                print(session.transcript)
                print("------------------------")
            }
        } catch {
            self.error = error
            print("OTHER ERROR", error)
        }
    }
}
