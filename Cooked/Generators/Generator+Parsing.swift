//
//  Generator+Parsing.swift
//  Cooked
//
//  Created by David James on 14/05/2026.
//

import Foundation

/// Given a string, parse it into sub strings, in different ways.
protocol StringParsingStrategy {
    func splitString(_ string: String) -> [String]
    func cleanupSubstrings(_ substrings: [String]) -> [String]
}

/// Parse a delimited string into sub strings
struct DelimitedStringParsingStrategy: StringParsingStrategy {
    
    func splitString(_ string: String) -> [String] {
        string.split(separator: /\d+\.?|[,\n\-•*]+|\band\b/).map { String($0) }
    }
    
    func cleanupSubstrings(_ substrings: [String]) -> [String] {
        substrings.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: .punctuationCharacters)
                .trimmingCharacters(in: CharacterSet(charactersIn: "`"))
                .lowercased()
        }
    }
}

/// A string parser that takes a parsing strategy
struct StringParser<Strategy: StringParsingStrategy> {
    
    let strategy: Strategy
    
    func parseString(_ string: String) -> [String] {
        strategy.cleanupSubstrings(
            strategy.splitString(string)
        )
    }
}
