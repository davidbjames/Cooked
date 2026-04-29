//
//  GenerationSettings.swift
//  Cooked
//
//  Created by David James on 16/04/2026.
//

import FoundationModels

struct GenerationSettings {
    
    enum Kind: String {
        case ingredients, varieties
    }
    let group: FoodGroup.Group
    let kind: Kind
    let existingCount: Int
    
    /// Number of items to attempt to generate
    var numberOfItems: Int {
        itemIncrement * multiplier
    }
    /// Options needed for this generation
    var generationOptions: GenerationOptions {
        .init(
            // LEARNING: Sampling Modes.
            // Sampling modes: Greedy, Random Top-K sampling, Random Top-P "nucleus" sampling.
            // Here, I use Greedy sampling for the first increment of items to get the most
            // obvious ones and than after that use Top-P sampling (aka "nucleus sampling")
            // with a probability threshold for more result possibilities as the exclusion list grows.
            // Greedy obviously doesn't work for subsequent repeats because the results are deterministic
            // and come out the same everytime. Also Top-K is not the best for the use-case because as the
            // exclusion list grows you run out of probable results.
            // Top-P is fundamentally better suited to a growing exclusion list scenario than other sampling.
            // NOTE: the Top-P threshold increases based on existing ingredients in order to provide
            // results going from more probable expected results (spiky/high confidence) to broader possible
            // results (flatter/less probable/lower confidence). This later sampling will provide
            // more obscure ingredients (which is OK since it's the user's choice to generate more).
            // See "Understanding Food Groups for Meal Planning" chat about this.
            sampling: samplingMode,
            // Temperature affects the probability distribution
            // 0-1 / 1 = no adjustment / <1 make distribution sharper for more stable responses (smaller probability pools)
            temperature: nil,
            // LEARNING: Repetition Loops.
            // Since response tokens influence subsequent tokens, it's possible to get in a
            // "degenerate repetition loop" where the sampling falls into a "self-reinforcing cycle"
            // when a previous item/token influences the model to repeat that item/token ad infinitum.
            // The solution is to cap the max response tokens (and also to remove duplicates).
            maximumResponseTokens: maximumResponseTokens
        )
    }
    
    // Private API
    
    /// Given an ingredient or variety what is the approximate
    /// number of tokens needed to represent it?
    private var estimatedItemTokenCount: Int {
        switch kind {
        case .ingredients: 5
        case .varieties: 6 // TBD
        }
    }
    /// Maximum tokens
    private var maximumResponseTokens: Int {
        numberOfItems * estimatedItemTokenCount
    }
    /// Number of items for a single increment.
    /// This is used to determine number of items generated
    /// but also probability breaks.
    private var itemIncrement: Int {
        switch kind {
        case .ingredients:
            switch group {
            case .staple: 5
            case .protein: 8
            case .vegetable: 10
            }
        case .varieties:
            5 // TBD
        }
    }
    /// Sample from more and more possible results to increase
    /// likelhood of getting diverse results from previously.
    private var multiplier: Int {
        switch existingCount {
        case ...itemIncrement: 2
        case ...(itemIncrement * 2): 3
        case ...(itemIncrement * 3): 4
        default: 5 // late, many exclusions, cast a wide net
        }
    }
    /// Value between 0 and 1 indicating the cumulative probabilty
    /// from a pool of tokens (large for uncertain and small when confident)
    /// that are selected from, providing more natural results.
    /// Given the use of exclusion lists from previous generations
    /// in order to make new generations, this increases the returned
    /// threshold incrementally providing more exploratory/obscure results (later).
    private var probabilityThreshold: Double {
        switch existingCount {
        case ...(itemIncrement): 0.75 // very-early, most common ingredients (not used - greedy)
        case ...(itemIncrement * 2): 0.86 // early, common ingredients
        case ...(itemIncrement * 3): 0.93 // mid, exploratory
        default: 1.0 // late, very exploratory/obscure
        }
    }
    /// Sampling mode to use for current count
    private var samplingMode: GenerationOptions.SamplingMode {
        switch existingCount {
        case ...itemIncrement: .greedy // initially greedy for more obvious results
        default: .random(probabilityThreshold: probabilityThreshold)
        }
    }
}

extension GenerationSettings: CustomStringConvertible {
    
    var description: String {
        var result = [
            "Generation Settings: \(group.rawValue) \(kind)",
            "    Existing Items:  \(existingCount)",
            "    Number of Items: \(numberOfItems)",
            "    Max Tokens:      \(maximumResponseTokens)"
        ]
        if samplingMode == .greedy {
            result.append("    Greedy Sampling")
        } else {
            result.append("    Top-P Threshold: \(probabilityThreshold)")
        }
        return result.joined(separator: "\n")
    }
}
