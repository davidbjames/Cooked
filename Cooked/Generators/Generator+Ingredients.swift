//
//  Generator+Ingredients.swift
//  Cooked
//
//  Created by David James on 06/05/2026.
//

import Foundation
import SwiftData
import FoundationModels

extension Generator {
    
    /// Generate ingredients or varieties
    func generateIngredients<Container: IngredientContainer>(for container: Container, instructions: Instructions, prompt promptBuilder: (_ numItems: Int) -> Prompt) async throws(GeneratorError) {
        
        let session = LanguageModelSession(
            model: .init(guardrails: .permissiveContentTransformations),
            tools: configuration.tools,
            instructions: instructions
        )
        let settings = container.makeGenerationSettings()
        let numberOfItems = settings.numberOfItems
        let existingNames = container.getContainedNames()
        
        do {
            let response = try await session.respond(
                to: promptBuilder(numberOfItems),
                generating: String.self,
                includeSchemaInPrompt: false,
                options: settings.generationOptions
            )
            
            if token.isCancelled {
                throw GeneratorError.cancelled
            }
            if debug {
                print(response.content)
            }
            
            if #available(iOS 26.4, macOS 26.4, *) {
                let tokens = try await SystemLanguageModel.default.tokenCount(for: response.content)
                if debug {
                    print("Response tokens:", tokens)
                }
                if token.isCancelled {
                    throw GeneratorError.cancelled
                }
            }
            
            let splitLines = response.content.split(separator: /\d+\.?|[,\n\-•*]+|\band\b/)
            let trimmedLines = splitLines.map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: .punctuationCharacters)
                    .lowercased()
            }
            if debug {
                print("Responded with:", trimmedLines.count, "items")
            }
            
            var degenerateDetector = makeDegenerateDetector()
            
            for line in trimmedLines {
                
                guard !line.isEmpty else {
                    continue
                }
                guard !existingNames.contains(where: { $0 == line }) else {
                    if debug {
                        print("(skipping \(line) - already exists)")
                    }
                    continue
                }
                guard !degenerateDetector.isDegenerate(text: line) else {
                    break
                }
                
                let auditSession = LanguageModelSession(
                    model: .init(guardrails: .permissiveContentTransformations),
                    instructions: .init {
                        "Your job is to answer questions about food."
                        "A sentance-like phrase is never a type of food. For example: 'a kind of food' or 'a list of food varieties for potatoes' are not types of food."
                    }
                )
                do {
                    // The "is food" check handles situations where the model refuses to generate
                    // the response due to guardrail errors, in which case the string response
                    // may contain explanations which need to be filtered out.
                    // From the docs for permissiveContentTransformations:
                    //     "when the purpose of your instructions and prompts isn't to transform input
                    //      from a person, the model may still refuse to respond to potentially unsafe
                    //      prompts by generating an explanation"
                    let isFoodPrompt: Prompt
                    switch settings.kind {
                    case .ingredients:
                        isFoodPrompt = .init { "Is '\(line)' in the '\(container.name)' food group?" }
                    case .varieties:
                        isFoodPrompt = .init { "Is '\(line)' a variety of '\(container.name)'?" }
                    }
                    let isFood = try await auditSession.respond(
                        to: isFoodPrompt,
                        generating: Bool.self
                    )
                    if token.isCancelled {
                        throw GeneratorError.cancelled
                    }
                    guard isFood.content else {
                        if debug {
                            switch settings.kind {
                            case .ingredients:
                                print("(skipping \(line) - not a '\(container.name)' food)")
                            case .varieties:
                                print("(skipping \(line) - not a variety of '\(container.name)')")
                            }
                        }
                        continue
                    }
                    let isRegional = try await auditSession.respond(
                        to: "Is '\(line)' a common food in \(Self.regionName)?",
                        generating: Bool.self
                    )
                    if token.isCancelled {
                        throw GeneratorError.cancelled
                    }
                    if debug {
                        print(line, isRegional.content ? "(regional)" : "(NOT regional)")
                    }
                    switch settings.kind {
                    case .ingredients:
                        let ingredient = Ingredient(name: line, isRegional: isRegional.content)
                        container.addContained(ingredient)
                        // Save immediately so this Ingredient gets a permanent PersistentIdentifier.
                        // There was a problem in IngredientListView which uses these identifiers
                        // to manage expand/collapse state. Without getting the permanent id upfront
                        // (as we're doing here) the state was broken due to having temporary
                        // identifiers up until the point that SwiftData does the implicit save
                        // and assigns permanent ones. Being different ids, it was causing
                        // a view re-render.
                        try? modelContext.save()
                    case .varieties:
                        let variety = Variety(name: line, isRegional: isRegional.content)
                        container.addContained(variety)
                    }
                } catch let error as LanguageModelSession.GenerationError {
                    session.handleGenerationError(error)
                } catch let error as GeneratorError {
                    throw error
                } catch {
                    print("OTHER ERROR", error)
                }
            }
            
        } catch let error as LanguageModelSession.GenerationError {
            session.handleGenerationError(error)
        } catch let error as GeneratorError {
            throw error
        } catch {
            print("OTHER ERROR", error)
        }
    }
}
