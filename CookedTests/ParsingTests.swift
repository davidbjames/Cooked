//
//  ParsingTests.swift
//  CookedTests
//
//  Created by David James on 14/05/2026.
//

import Testing
@testable import Cooked

// MARK: - Tags

extension Tag {
    @Tag static var parsing: Self
}

// MARK: - Suite

@Suite(.tags(.parsing))
struct ParsingTests {

    let sut = StringParser(strategy: DelimitedStringParsingStrategy())

    // MARK: - Delimiter variants

    /// Verifies that a range of LLM delimiter styles all produce the same clean result.
    /// Each input represents a plausible format an LLM might return when asked for a
    /// "comma-delimited list" — they are often inconsistent.
    @Test(
        "Delimiter variants all parse to the same ingredients",
        arguments: [
            // 1. Comma-delimited — the requested format
            "chicken, beef, tofu, salmon",
            // 2. Newline-delimited — LLM uses line breaks instead
            "chicken\nbeef\ntofu\nsalmon",
            // 3. Bullet points (•)
            "• chicken\n• beef\n• tofu\n• salmon",
            // 4. Markdown dashes
            "- chicken\n- beef\n- tofu\n- salmon",
            // 5. Asterisks
            "* chicken\n* beef\n* tofu\n* salmon",
            // 6. Mixed commas and newlines
            "chicken, beef\ntofu, salmon",
        ]
    )
    func delimiterVariantsProduceSameIngredients(input: String) {
        let result = sut.parseString(input)
        #expect(result == ["chicken", "beef", "tofu", "salmon"])
    }

    // MARK: - Numbered list variants

    @Test("Numbered list with dots parses correctly")
    func numberedListWithDots() {
        let input = "1. chicken\n2. beef\n3. tofu\n4. salmon"
        let result = sut.parseString(input)
        #expect(result == ["chicken", "beef", "tofu", "salmon"])
    }

    @Test("Numbered list without dots parses correctly")
    func numberedListWithoutDots() {
        let input = "1 chicken\n2 beef\n3 tofu\n4 salmon"
        let result = sut.parseString(input)
        #expect(result == ["chicken", "beef", "tofu", "salmon"])
    }

    // MARK: - Quoting variants

    /// LLMs sometimes wrap ingredient names in quotes,
    /// perhaps because the original instructions used quoted examples.
    @Test(
        "Quoted ingredient names are stripped",
        arguments: [
            // Single quotes
            "'chicken', 'beef', 'tofu', 'salmon'",
            // Double quotes
            "\"chicken\", \"beef\", \"tofu\", \"salmon\"",
        ]
    )
    func quotedNamesAreStripped(input: String) {
        let result = sut.parseString(input)
        #expect(result == ["chicken", "beef", "tofu", "salmon"])
    }

    @Test("Backtick-wrapped names are stripped")
    func backtickWrappedNamesAreStripped() {
        let input = "`chicken`, `beef`, `tofu`, `salmon`"
        let result = sut.parseString(input)
        #expect(result == ["chicken", "beef", "tofu", "salmon"])
    }

    // MARK: - Casing & whitespace

    @Test("Mixed casing is lowercased")
    func mixedCasingIsLowercased() {
        let input = "Chicken, Beef, Tofu, Salmon"
        let result = sut.parseString(input)
        #expect(result == ["chicken", "beef", "tofu", "salmon"])
    }

    @Test("Extra whitespace around names is trimmed")
    func extraWhitespaceIsTrimmed() {
        let input = "  chicken ,  beef ,  tofu ,  salmon  "
        let result = sut.parseString(input)
        #expect(result == ["chicken", "beef", "tofu", "salmon"])
    }

    @Test("ALL CAPS ingredient names are lowercased")
    func allCapsIsLowercased() {
        let input = "CHICKEN, BEEF, TOFU, SALMON"
        let result = sut.parseString(input)
        #expect(result == ["chicken", "beef", "tofu", "salmon"])
    }

    // MARK: - Word delimiter: "and"

    @Test("'and' as a word delimiter splits correctly")
    func andWordDelimiterSplitsCorrectly() {
        let input = "chicken and beef and tofu and salmon"
        let result = sut.parseString(input)
        #expect(result == ["chicken", "beef", "tofu", "salmon"])
    }

    @Test("'and' inside a compound name is not split")
    func andInsideNameIsNotSplit() {
        // "candy" contains "and" but is not a standalone word boundary
        let input = "candy, bread"
        let result = sut.parseString(input)
        #expect(result == ["candy", "bread"])
    }

    // MARK: - Empty tokens / trailing delimiters

    @Test("Trailing comma does not produce empty token")
    func trailingCommaDoesNotProduceEmptyToken() {
        let input = "chicken, beef, tofu, salmon,"
        let result = sut.parseString(input)
        // The split regex won't produce a trailing empty string here —
        // verify no blank entries leak through.
        #expect(result.filter(\.isEmpty).isEmpty, "No empty strings should appear in result")
        #expect(result == ["chicken", "beef", "tofu", "salmon"])
    }

    @Test("Multiple consecutive delimiters produce no empty tokens")
    func multipleConsecutiveDelimitersProduceNoEmptyTokens() {
        let input = "chicken,, beef,,\n\ntofu,, salmon"
        let result = sut.parseString(input)
        #expect(result.filter(\.isEmpty).isEmpty, "No empty strings should appear in result")
        #expect(result == ["chicken", "beef", "tofu", "salmon"])
    }

    // MARK: - Single-item input

    @Test("Single ingredient without delimiter returns one-element array")
    func singleIngredientReturnsOneElement() {
        let input = "chicken"
        let result = sut.parseString(input)
        #expect(result == ["chicken"])
    }

    // MARK: - Mixed quoting and delimiter styles

    @Test("Bullet points with double-quoted names are parsed and stripped")
    func bulletPointsWithDoubleQuotedNames() {
        let input = "• \"chicken\"\n• \"beef\"\n• \"tofu\"\n• \"salmon\""
        let result = sut.parseString(input)
        #expect(result == ["chicken", "beef", "tofu", "salmon"])
    }

    @Test("Numbered list with single-quoted names are parsed and stripped")
    func numberedListWithSingleQuotedNames() {
        let input = "1. 'chicken'\n2. 'beef'\n3. 'tofu'\n4. 'salmon'"
        let result = sut.parseString(input)
        #expect(result == ["chicken", "beef", "tofu", "salmon"])
    }
}
