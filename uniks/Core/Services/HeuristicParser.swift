//
//  HeuristicParser.swift
//  uniks
//
//  Fast regex/pattern-based parser that produces instant best-guess results.
//  Runs synchronously in < 5ms. Used as Stage 1 of the multi-agent pipeline.
//

import Foundation

/// A pure, synchronous, Sendable struct that extracts structured data from raw
/// natural-language input using regex patterns and a category keyword dictionary.
/// Designed to run instantly (< 5ms) before the LLM pipeline starts.
struct HeuristicParser: Sendable {

    // MARK: - Public API

    /// Parses raw input using heuristic pattern matching.
    /// - Parameter rawInput: The user's original text.
    /// - Returns: A `HabitParseResult` with confidence score (typically 0.3–0.7).
    func parse(rawInput: String) -> HabitParseResult {
        let lower = rawInput.lowercased()
        let tokens = tokenize(lower)

        let category = extractCategory(from: tokens, rawLower: lower)
        let (value, unit) = extractValueAndUnit(from: rawInput)
        let tags = extractTags(from: tokens, category: category)
        let notes = extractNotes(from: rawInput, category: category, value: value, unit: unit)

        let confidence = computeConfidence(
            category: category, value: value, unit: unit, tags: tags
        )

        return HabitParseResult(
            category: category,
            value: value,
            unit: unit,
            tags: tags.isEmpty ? nil : tags,
            notes: notes,
            confidence: confidence
        )
    }

    // MARK: - Category Extraction

    /// Maps keywords to canonical categories.
    static let categoryKeywords: [String: [String]] = [
        "Fitness": [
            "ran", "run", "running", "jog", "jogged", "jogging",
            "walked", "walk", "walking", "hike", "hiked", "hiking",
            "swam", "swim", "swimming", "cycled", "cycle", "cycling",
            "biked", "bike", "biking", "workout", "exercise", "gym",
            "lift", "lifted", "lifting", "pushup", "pullup", "squat",
            "plank", "yoga", "stretch", "stretched", "sprint", "sprinted"
        ],
        "Sleep": [
            "slept", "sleep", "sleeping", "nap", "napped", "napping",
            "woke", "wakeup", "bedtime", "insomnia"
        ],
        "Hydration": [
            "drank", "drink", "drinking", "water", "hydration",
            "hydrated", "glass", "glasses", "bottle", "bottles"
        ],
        "Reading": [
            "read", "reading", "book", "pages", "chapter", "chapters",
            "article", "articles", "novel"
        ],
        "Meditation": [
            "meditated", "meditation", "meditate", "mindfulness",
            "breathwork", "breathing", "calm"
        ],
        "Diet": [
            "ate", "eat", "eating", "meal", "breakfast", "lunch",
            "dinner", "snack", "food", "calories", "cal", "kcal",
            "protein", "carbs", "fats"
        ],
        "Caffeine": [
            "coffee", "espresso", "latte", "cappuccino",
            "tea", "caffeine", "matcha"
        ],
        "Finance": [
            "spent", "spend", "spending", "bought", "buy", "buying",
            "paid", "pay", "payment", "cost", "price", "expense",
            "income", "earned", "salary", "invested", "investment"
        ],
        "Health": [
            "weight", "weighed", "bp", "blood pressure",
            "heart rate", "temperature", "symptom", "headache",
            "medicine", "medication", "pill", "vitamin", "supplement"
        ],
        "Mood": [
            "felt", "feeling", "mood", "happy", "sad", "anxious",
            "stressed", "calm", "angry", "frustrated", "grateful",
            "excited", "tired", "exhausted", "energetic", "motivated"
        ],
        "Work": [
            "worked", "work", "working", "meeting", "meetings",
            "project", "task", "tasks", "deadline", "presentation",
            "code", "coded", "coding", "wrote", "writing", "email"
        ],
        "Study": [
            "studied", "study", "studying", "learned", "learning",
            "lecture", "class", "course", "homework", "exam", "quiz",
            "practice", "practiced", "practicing"
        ],
        "Social": [
            "met", "meet", "meeting", "friends", "family",
            "call", "called", "chat", "chatted", "party",
            "hangout", "date", "dinner with"
        ],
        "Creative": [
            "drew", "draw", "drawing", "painted", "paint", "painting",
            "wrote", "write", "writing", "composed", "music",
            "played", "guitar", "piano", "sang", "singing"
        ],
        "Transport": [
            "drove", "drive", "driving", "car", "bus", "train",
            "flight", "flew", "commute", "commuted", "uber", "taxi"
        ],
        "Chores": [
            "cleaned", "clean", "cleaning", "laundry", "dishes",
            "cooked", "cook", "cooking", "grocery", "groceries",
            "shopping", "vacuum", "mop", "organize"
        ]
    ]

    private func extractCategory(from tokens: [String], rawLower: String) -> String? {
        // Check custom categories first (stored in UserDefaults)
        if let custom = matchCustomCategory(tokens: tokens) {
            return custom
        }

        // Score each category by keyword matches
        var bestCategory: String?
        var bestScore = 0

        for (category, keywords) in Self.categoryKeywords {
            var score = 0
            for keyword in keywords {
                if keyword.contains(" ") {
                    // Multi-word keyword: check raw string
                    if rawLower.contains(keyword) {
                        score += 3
                    }
                } else if tokens.contains(keyword) {
                    score += 2
                } else if tokens.contains(where: { $0.hasPrefix(keyword) }) {
                    score += 1
                }
            }
            if score > bestScore {
                bestScore = score
                bestCategory = category
            }
        }

        return bestScore >= 2 ? bestCategory : nil
    }

    private func matchCustomCategory(tokens: [String]) -> String? {
        guard let data = UserDefaults.standard.data(forKey: "uniks.customCategories"),
              let customs = try? JSONDecoder().decode([CustomCategoryEntry].self, from: data) else {
            return nil
        }
        for custom in customs {
            for keyword in custom.keywords {
                if tokens.contains(keyword.lowercased()) {
                    return custom.name
                }
            }
        }
        return nil
    }

    // MARK: - Value & Unit Extraction

    /// Regex patterns for value+unit extraction.
    /// Ordered by specificity — more specific patterns first.
    private static let valueUnitPatterns: [(pattern: String, valueGroup: Int, unitGroup: Int)] = [
        // "5km in 28min" → value: 5, unit: km (take the first)
        (#"(\d+(?:\.\d+)?)\s*(km|mi|miles|m|meters|metres|lbs|lb|kg|kg|g|oz|l|ml|L|min|mins|minutes|hrs?|hours?|h|sec|seconds?|s|pages?|reps?|sets?|cal|kcal|steps?|cups?|glasses?|bottles?|mg|mcg|bpm|%)\b"#, 1, 2),
        // "$45" or "45$"
        (#"\$\s*(\d+(?:\.\d+)?)"#, 1, -1),
        (#"(\d+(?:\.\d+)?)\s*(?:dollars?|bucks?|usd)"#, 1, -1),
        // Standalone numbers with implicit context
        (#"(\d+(?:\.\d+)?)\s*(?:x|times)"#, 1, -1),
    ]

    private func extractValueAndUnit(from rawInput: String) -> (Double?, String?) {
        for entry in Self.valueUnitPatterns {
            guard let regex = try? NSRegularExpression(pattern: entry.pattern, options: .caseInsensitive) else {
                continue
            }
            let range = NSRange(rawInput.startIndex..., in: rawInput)
            guard let match = regex.firstMatch(in: rawInput, range: range) else {
                continue
            }

            let valueRange = match.range(at: entry.valueGroup)
            guard valueRange.location != NSNotFound,
                  let valueSwiftRange = Range(valueRange, in: rawInput) else {
                continue
            }
            let valueStr = String(rawInput[valueSwiftRange])
            guard let value = Double(valueStr) else { continue }

            var unit: String?
            if entry.unitGroup > 0 {
                let unitRange = match.range(at: entry.unitGroup)
                if unitRange.location != NSNotFound,
                   let unitSwiftRange = Range(unitRange, in: rawInput) {
                    unit = normalizeUnit(String(rawInput[unitSwiftRange]))
                }
            } else {
                // Dollar pattern
                if rawInput.contains("$") || rawInput.lowercased().contains("dollar") {
                    unit = "$"
                }
            }

            return (value, unit)
        }

        return (nil, nil)
    }

    /// Normalizes common unit abbreviations to canonical forms.
    private func normalizeUnit(_ raw: String) -> String {
        let lower = raw.lowercased()
        switch lower {
        case "km", "kilometers", "kilometres": return "km"
        case "mi", "miles", "mile": return "mi"
        case "m", "meters", "metres", "meter": return "m"
        case "min", "mins", "minutes", "minute": return "min"
        case "hr", "hrs", "hours", "hour", "h": return "hr"
        case "sec", "seconds", "second", "s": return "sec"
        case "kg", "kilograms", "kilogram": return "kg"
        case "lbs", "lb", "pounds", "pound": return "lb"
        case "g", "grams", "gram": return "g"
        case "oz", "ounces", "ounce": return "oz"
        case "l", "liters", "litres", "liter": return "L"
        case "ml", "milliliters", "millilitres": return "mL"
        case "cal", "kcal", "calories": return "cal"
        case "pages", "page": return "pages"
        case "reps", "rep": return "reps"
        case "sets", "set": return "sets"
        case "steps", "step": return "steps"
        case "cups", "cup": return "cups"
        case "glasses", "glass": return "glasses"
        case "bottles", "bottle": return "bottles"
        case "mg": return "mg"
        case "mcg": return "mcg"
        case "bpm": return "bpm"
        default: return raw
        }
    }

    // MARK: - Tag Extraction

    private func extractTags(from tokens: [String], category: String?) -> [String] {
        var tags: [String] = []

        // Time-of-day tags
        let timeKeywords = ["morning", "afternoon", "evening", "night", "early", "late"]
        for keyword in timeKeywords where tokens.contains(keyword) {
            tags.append(keyword)
        }

        // Intensity tags
        let intensityKeywords = ["easy", "hard", "intense", "light", "heavy", "moderate"]
        for keyword in intensityKeywords where tokens.contains(keyword) {
            tags.append(keyword)
        }

        // Feeling tags
        let feelingKeywords = ["great", "good", "bad", "terrible", "amazing", "tired", "energetic"]
        for keyword in feelingKeywords where tokens.contains(keyword) {
            tags.append(keyword)
        }

        // Location tags
        let locationKeywords = ["home", "gym", "park", "office", "outside", "indoor", "outdoor"]
        for keyword in locationKeywords where tokens.contains(keyword) {
            tags.append(keyword)
        }

        return Array(tags.prefix(5))
    }

    // MARK: - Notes Extraction

    private func extractNotes(from rawInput: String, category: String?, value: Double?, unit: String?) -> String? {
        // If we couldn't extract a category or value, the whole input is essentially a "note"
        guard category != nil || value != nil else { return nil }

        // Look for comma-separated qualifiers or parenthetical notes
        let lower = rawInput.lowercased()
        if let commaIndex = lower.firstIndex(of: ",") {
            let afterComma = String(rawInput[rawInput.index(after: commaIndex)...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !afterComma.isEmpty && afterComma.count > 3 {
                return afterComma
            }
        }

        return nil
    }

    // MARK: - Confidence Scoring

    private func computeConfidence(
        category: String?,
        value: Double?,
        unit: String?,
        tags: [String]
    ) -> Double {
        var score = 0.2 // Base confidence for heuristic

        if category != nil { score += 0.25 }
        if value != nil { score += 0.2 }
        if unit != nil { score += 0.1 }
        if !tags.isEmpty { score += 0.05 }

        // Cap heuristic confidence at 0.7 — LLM should always be able to improve
        return min(score, 0.7)
    }

    // MARK: - Tokenization

    private func tokenize(_ input: String) -> [String] {
        input.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }
}

// MARK: - Custom Category Entry (for UserDefaults storage)

/// Lightweight entry for custom user-defined categories stored in UserDefaults.
struct CustomCategoryEntry: Codable, Sendable {
    let name: String
    let keywords: [String]
}
