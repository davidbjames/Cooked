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
        if debug {
            print(settings)
        }
        
        let numberOfItems = settings.numberOfItems
        
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
            
            if response.content.hasPrefix("000") {
                // Handle error response 000000..
                switch settings.kind {
                case .ingredients:
                    break // TBD
                case .varieties:
                    let variety = Variety(name: container.name, isRegional: true)
                    container.addContained(variety)
                    return
                }
            }
            
            // LEARNING:
            // Foundation Models is inconsistent even with clear instructions.
            // For example: If you provide the response content with:
            // Instructions: "Your job is to answer questions about this text:" (content)
            // Prompt: "Does this text include a language model error?"
            // or variations thereof, or the inverse:
            // Prompt: "Is this text a list of foods?"
            // it provides completely inconsistent results, with or without
            // permissiveContentTransformations. It's either completely random
            // or overly restrictive.
            
            switch settings.kind {
            case .ingredients:
                break
            case .varieties:
                guard container.about.isEmpty else {
                    break
                }
                // During variety generation, stream the ingredient's "about" description.
                // This is done before the "audit" checks below because we know
                // by this point that the *ingredient* (the varieties' "container")
                // has already been validated, so we can go ahead and update its about.
                
                // This is done in a task so it doesn't block variety generation.
                // In practice it's already pretty fast and will finish before varieties
                // generate in most cases, but at least it doesn't block that process.
                Task { [weak token, weak container] in
                    guard let token, let container else {
                        return
                    }
                    let descriptionSession = LanguageModelSession(
                        model: .init(guardrails: .permissiveContentTransformations),
                        instructions: .init {
                            "Your job is to answer questions about food."
                        }
                    )
                    let descriptionStream = descriptionSession.streamResponse(
                        to: "Give a one-sentence description of '\(container.name)' as a food ingredient.",
                        generating: String.self
                    )
                    for try await partialDescription in descriptionStream {
                        if token.isCancelled {
                            // Note: since tasks don't propogage errors we can't throw
                            // the cancellation at this point, so just stop the process,
                            // reset the about and return. The error will get thrown below.
                            container.about = ""
                            return
                        }
                        let about = partialDescription.content
                        container.about = about
                    }
                    if debug {
                        print(container.name, "description:", container.about)
                    }
                }
            }

            let parser = Parser(strategy: DelimitedStringParsingStrategy())
            let lines = parser.parse(response.content)
            
            if debug {
                print("Responded with:", lines.count, "items")
            }
            
            var degenerateDetector = makeDegenerateDetector()
            
            for line in lines {
                
                guard !line.isEmpty else {
                    continue
                }
                guard !degenerateDetector.isDegenerate(text: line) else {
                    break
                }
                guard !container.containsName(line) else {
                    if debug {
                        print("(skipping \(line) - already exists)")
                    }
                    continue
                }
                
                let auditSession = LanguageModelSession(
                    model: .init(guardrails: .permissiveContentTransformations),
                    instructions: .init {
                        "Your job is to answer questions about food."
                        "A sentance or part of a sentance is NEVER a type of food. For example: 'a kind of food' or 'a list of food varieties for potatoes' or similar phrases are NOT types of food."
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
            switch settings.kind {
            case .ingredients:
                break
            case .varieties:
                // If there are still no varieties, add the base ingredient
                // as a variety so the list is not empty.
                if container.isEmpty {
                    let variety = Variety(name: container.name, isRegional: true)
                    container.addContained(variety)
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
