//
//  JSONRepairService.swift
//  uniks
//
//  Repairs common JSON formatting issues from LLM output before decoding.
//

import Foundation

/// Attempts to repair malformed JSON output from local LLM models.
/// Handles common issues: markdown fencing, trailing commas, unquoted keys,
/// truncated output, and BOM characters.
enum JSONRepairService: Sendable {

    /// Attempts to clean and repair JSON text into a valid HabitParseResult.
    /// - Parameter rawOutput: The raw text output from an LLM engine.
    /// - Returns: A decoded `HabitParseResult` if repair succeeds, nil otherwise.
    static func repair(_ rawOutput: String) -> HabitParseResult? {
        let cleaned = cleanOutput(rawOutput)

        // Try direct decode first
        if let result = decode(cleaned) {
            return result
        }

        // Try extracting JSON from surrounding text
        if let extracted = extractJSON(from: cleaned), let result = decode(extracted) {
            return result
        }

        // Try fixing common issues
        let fixed = fixCommonIssues(cleaned)
        if let result = decode(fixed) {
            return result
        }

        // Last resort: try extracting just the JSON object
        if let braceExtracted = extractBraceContent(from: rawOutput), let result = decode(braceExtracted) {
            return result
        }

        return nil
    }

    // MARK: - Cleaning Steps

    /// Strips markdown fences, BOM, and whitespace.
    private static func cleanOutput(_ output: String) -> String {
        var text = output

        // Remove BOM
        text = text.replacingOccurrences(of: "\u{FEFF}", with: "")

        // Remove markdown code fences
        text = text.replacingOccurrences(of: "```json", with: "")
        text = text.replacingOccurrences(of: "```JSON", with: "")
        text = text.replacingOccurrences(of: "```", with: "")

        // Remove leading/trailing whitespace and newlines
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove any text before the first {
        if let braceIndex = text.firstIndex(of: "{") {
            text = String(text[braceIndex...])
        }

        // Remove any text after the last }
        if let braceIndex = text.lastIndex(of: "}") {
            text = String(text[...braceIndex])
        }

        return text
    }

    /// Extracts a JSON object substring from mixed text.
    private static func extractJSON(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else {
            return nil
        }
        guard start < end else { return nil }
        return String(text[start...end])
    }

    /// Extracts content between first { and last } handling nested braces.
    private static func extractBraceContent(from text: String) -> String? {
        var depth = 0
        var startIndex: String.Index?
        var endIndex: String.Index?

        for (index, char) in text.enumerated() {
            let strIndex = text.index(text.startIndex, offsetBy: index)
            if char == "{" {
                if depth == 0 {
                    startIndex = strIndex
                }
                depth += 1
            } else if char == "}" {
                depth -= 1
                if depth == 0 {
                    endIndex = strIndex
                    break
                }
            }
        }

        guard let start = startIndex, let end = endIndex else { return nil }
        return String(text[start...end])
    }

    /// Fixes common JSON formatting issues.
    private static func fixCommonIssues(_ text: String) -> String {
        var fixed = text

        // Fix trailing commas before } or ]
        fixed = fixed.replacingOccurrences(
            of: #",\s*([}\]])"#,
            with: "$1",
            options: .regularExpression
        )

        // Fix single quotes used instead of double quotes
        // Only do this if there are no double quotes (to avoid breaking valid JSON)
        if !fixed.contains("\"") && fixed.contains("'") {
            fixed = fixed.replacingOccurrences(of: "'", with: "\"")
        }

        // Fix unquoted keys: word: → "word":
        fixed = fixed.replacingOccurrences(
            of: #"(?<=[\{,])\s*(\w+)\s*:"#,
            with: " \"$1\":",
            options: .regularExpression
        )

        // Fix null written as None or undefined
        fixed = fixed.replacingOccurrences(of: ": None", with: ": null")
        fixed = fixed.replacingOccurrences(of: ": undefined", with: ": null")
        fixed = fixed.replacingOccurrences(of: ":None", with: ":null")

        // Fix True/False (Python-style booleans)
        fixed = fixed.replacingOccurrences(of: ": True", with: ": true")
        fixed = fixed.replacingOccurrences(of: ": False", with: ": false")

        return fixed
    }

    /// Attempts JSON decoding.
    private static func decode(_ text: String) -> HabitParseResult? {
        guard let data = text.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(HabitParseResult.self, from: data)
    }
}
