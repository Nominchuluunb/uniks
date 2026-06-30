//
//  ParsingPrompts.swift
//  uniks
//
//  Enhanced prompts for LLM-based parsing with few-shot examples and category taxonomy.
//

import Foundation

/// Centralized prompt templates for the NLP parsing pipeline.
/// Provides the system prompt, few-shot examples, and category taxonomy
/// used by both MLXLLMEngine and OllamaLLMEngine.
enum ParsingPrompts {

    /// The canonical categories the model should prefer.
    static let categoryTaxonomy: [String] = [
        "Fitness", "Sleep", "Hydration", "Reading", "Meditation",
        "Diet", "Caffeine", "Finance", "Health", "Mood",
        "Work", "Study", "Social", "Creative", "Transport",
        "Chores", "Skincare", "Supplements", "Journaling", "Other"
    ]

    /// The full system prompt with JSON schema, rules, and few-shot examples.
    static var systemPrompt: String {
        """
        You are a structured data extractor for a personal habit/event logger. \
        Extract information from a user's log entry and return ONLY valid JSON.

        ## Output Schema
        Return a single JSON object with these fields (all optional except confidence):
        {
          "category": "One of the canonical categories listed below",
          "value": <number if a quantitative measurement is present>,
          "unit": "<unit of measurement if present>",
          "tags": ["relevant", "contextual", "tags"],
          "notes": "any additional context or qualitative information",
          "confidence": <0.0 to 1.0 indicating how confident you are>
        }

        ## Canonical Categories (prefer these exact names):
        \(categoryTaxonomy.joined(separator: ", "))

        ## Rules:
        1. Use EXACTLY one of the canonical category names when possible.
        2. "value" must be a number (not a string). Extract the primary quantitative measurement.
        3. "unit" should be the abbreviated unit (km, min, hr, pages, cal, $, kg, L, etc.)
        4. "tags" should capture context: time of day, intensity, location, mood qualifiers. Max 5 tags.
        5. "notes" should capture qualitative details not covered by other fields.
        6. "confidence" should reflect how well the input maps to structured data:
           - 0.9+ for clear quantitative entries ("Ran 5km in 28min")
           - 0.7-0.9 for clear but less structured entries ("Had a great workout")
           - 0.5-0.7 for ambiguous entries that require interpretation
           - Below 0.5 for very unclear entries
        7. Return ONLY the JSON object. No markdown, no explanation, no preamble.

        ## Examples:

        Input: "Ran 5km in 28min, felt great"
        Output: {"category":"Fitness","value":5,"unit":"km","tags":["running","morning"],"notes":"28min, felt great","confidence":0.95}

        Input: "Slept 7.5 hours, woke up refreshed"
        Output: {"category":"Sleep","value":7.5,"unit":"hr","tags":["good quality"],"notes":"woke up refreshed","confidence":0.95}

        Input: "Drank 2L of water today"
        Output: {"category":"Hydration","value":2,"unit":"L","tags":["daily"],"notes":null,"confidence":0.95}

        Input: "Read 45 pages of Atomic Habits"
        Output: {"category":"Reading","value":45,"unit":"pages","tags":["non-fiction"],"notes":"Atomic Habits","confidence":0.93}

        Input: "Meditated for 15 minutes this morning"
        Output: {"category":"Meditation","value":15,"unit":"min","tags":["morning"],"notes":null,"confidence":0.95}

        Input: "Had eggs and toast for breakfast, ~400 cal"
        Output: {"category":"Diet","value":400,"unit":"cal","tags":["breakfast"],"notes":"eggs and toast","confidence":0.88}

        Input: "Spent $45 on groceries at Trader Joe's"
        Output: {"category":"Finance","value":45,"unit":"$","tags":["groceries"],"notes":"Trader Joe's","confidence":0.93}

        Input: "Feeling anxious about tomorrow's presentation"
        Output: {"category":"Mood","value":null,"unit":null,"tags":["anxious","work-related"],"notes":"about tomorrow's presentation","confidence":0.82}

        Input: "3 cups of coffee today, probably too much"
        Output: {"category":"Caffeine","value":3,"unit":"cups","tags":["excessive"],"notes":"probably too much","confidence":0.90}

        Input: "Worked 6 hours on the API refactor"
        Output: {"category":"Work","value":6,"unit":"hr","tags":["coding","focused"],"notes":"API refactor","confidence":0.92}

        Input: "Took vitamin D and omega-3"
        Output: {"category":"Supplements","value":null,"unit":null,"tags":["vitamin D","omega-3"],"notes":null,"confidence":0.85}

        Input: "Quick 20min yoga session before bed"
        Output: {"category":"Fitness","value":20,"unit":"min","tags":["yoga","evening","light"],"notes":"before bed","confidence":0.92}
        """
    }

    /// Builds the full prompt for a given raw input, optionally including user corrections.
    /// - Parameters:
    ///   - rawInput: The user's log entry to parse.
    ///   - corrections: Recent relevant user corrections to include as additional examples.
    /// - Returns: An array of message dictionaries for chat-style models.
    static func buildMessages(
        rawInput: String,
        corrections: [(input: String, result: HabitParseResult)] = []
    ) -> [[String: String]] {
        var messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]

        // Inject user corrections as additional few-shot examples
        for correction in corrections.prefix(5) {
            let json = (try? correction.result.toJSON()) ?? "{}"
            messages.append(["role": "user", "content": correction.input])
            messages.append(["role": "assistant", "content": json])
        }

        messages.append(["role": "user", "content": rawInput])
        return messages
    }

    /// Builds a single prompt string for non-chat models (e.g., Ollama generate endpoint).
    /// - Parameters:
    ///   - rawInput: The user's log entry to parse.
    ///   - corrections: Recent relevant user corrections to include as additional examples.
    /// - Returns: A single prompt string.
    static func buildPrompt(
        rawInput: String,
        corrections: [(input: String, result: HabitParseResult)] = []
    ) -> String {
        var prompt = systemPrompt + "\n\n"

        for correction in corrections.prefix(5) {
            let json = (try? correction.result.toJSON()) ?? "{}"
            prompt += "Input: \"\(correction.input)\"\nOutput: \(json)\n\n"
        }

        prompt += "Input: \"\(rawInput)\"\nOutput:"
        return prompt
    }
}
