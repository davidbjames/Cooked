//
//  Generator+Parsing.swift
//  Cooked
//
//  Created by David James on 14/05/2026.
//

import Foundation

// MARK: - Parsing Strategies

/// Given a chunk of data, parse it into sub parts, in different ways.
protocol ParsingStrategy {
    associatedtype Chunk
    func splitChunk(_ chunk: Chunk) -> [Chunk]
    func cleanupChunks(_ chunks: [Chunk]) -> [Chunk]
}

/// Parse a delimited string into sub strings
struct DelimitedStringParsingStrategy: ParsingStrategy {
    
    func splitChunk(_ string: String) -> [String] {
        string.split(separator: /\d+\.?|[,\n\-•–*—·]+|\band\b/).map { String($0) }
    }
    
    func cleanupChunks(_ string: [String]) -> [String] {
        string.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: .punctuationCharacters)
                .trimmingCharacters(in: CharacterSet(charactersIn: "`"))
                .lowercased()
        }
    }
}

// MARK: - Parser

/// A generic parser that takes a parsing strategy
struct Parser<S: ParsingStrategy> {
    
    let strategy: S
    
    func parse(_ chunk: S.Chunk) -> [S.Chunk] {
        strategy.cleanupChunks(
            strategy.splitChunk(chunk)
        )
    }
}
