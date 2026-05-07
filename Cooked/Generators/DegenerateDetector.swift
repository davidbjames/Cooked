//
//  DegenerateDetector.swift
//  Cooked
//
//  Created by David James on 06/05/2026.
//


protocol DegenerateDetector {
    mutating func isDegenerate(text: String) -> Bool
}

struct NonDegenerateDetector: DegenerateDetector {
    mutating func isDegenerate(text: String) -> Bool {
        false
    }
}

struct IngredientDegenerateRepetitionDetector: DegenerateDetector {
    
    var lastPrefix: String? = nil
    var consecutivePrefixCount = 0
    let maxConsecutivePrefix = 2
    let debug: Bool
    
    mutating func isDegenerate(text: String) -> Bool {
        // Detect degenerate repetition (e.g. "rye crackers", "rye rolls", "rye bread"
        // or "rye", "rye", "rye")
        let prefix = text.split(separator: " ").first.map(String.init) ?? text
        if prefix == lastPrefix {
            consecutivePrefixCount += 1
            if consecutivePrefixCount >= maxConsecutivePrefix {
                if debug {
                    print("(stopping - degenerate repetition detected on '\(prefix)')")
                }
                return true
            }
        } else {
            lastPrefix = prefix
            consecutivePrefixCount = 1
        }
        return false
    }
}
