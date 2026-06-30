//
//  UserCorrectionsStore.swift
//  uniks
//
//  Manages user corrections for the feedback loop parsing stage.
//

import Foundation
import SwiftData

/// Actor that manages storage and retrieval of user corrections.
/// Used by the parsing pipeline to check if similar inputs have been
/// corrected before, improving future parse accuracy.
actor UserCorrectionsStore {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    /// Records a user correction.
    /// - Parameters:
    ///   - originalInput: The original raw input text.
    ///   - correctedPayload: The user-corrected parse result.
    func recordCorrection(originalInput: String, correctedPayload: HabitParseResult) async throws {
        let context = ModelContext(container)
        let correction = UserCorrection(originalInput: originalInput, correctedPayload: correctedPayload)
        context.insert(correction)
        try context.save()
    }

    /// Finds a matching correction for the given input using fuzzy matching.
    /// - Parameter rawInput: The new input to check against past corrections.
    /// - Returns: The corrected payload if a close match is found, nil otherwise.
    func findMatchingCorrection(for rawInput: String) async -> HabitParseResult? {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<UserCorrection>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        guard let corrections = try? context.fetch(descriptor) else { return nil }

        let normalizedInput = normalize(rawInput)

        for correction in corrections.prefix(100) {
            let normalizedOriginal = normalize(correction.originalInput)

            // Exact match after normalization
            if normalizedInput == normalizedOriginal {
                return correction.correctedPayload()
            }

            // Fuzzy match: check if similarity is high enough
            let similarity = jaccardSimilarity(normalizedInput, normalizedOriginal)
            if similarity > 0.75 {
                return correction.correctedPayload()
            }
        }

        return nil
    }

    /// Returns recent corrections relevant to the given input for few-shot injection.
    /// - Parameters:
    ///   - rawInput: The input to find related corrections for.
    ///   - limit: Maximum number of corrections to return.
    /// - Returns: Array of (input, result) pairs for prompt injection.
    func relevantCorrections(
        for rawInput: String,
        limit: Int = 5
    ) async -> [(input: String, result: HabitParseResult)] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<UserCorrection>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        guard let corrections = try? context.fetch(descriptor) else { return [] }

        let normalizedInput = normalize(rawInput)
        let inputTokens = Set(tokenize(normalizedInput))

        // Score corrections by relevance to current input
        var scored: [(correction: UserCorrection, score: Double)] = []
        for correction in corrections.prefix(50) {
            let corrTokens = Set(tokenize(normalize(correction.originalInput)))
            let intersection = inputTokens.intersection(corrTokens)
            let union = inputTokens.union(corrTokens)
            let score = union.isEmpty ? 0 : Double(intersection.count) / Double(union.count)
            if score > 0.2 {
                scored.append((correction, score))
            }
        }

        return scored
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .compactMap { item -> (input: String, result: HabitParseResult)? in
                guard let payload = item.correction.correctedPayload() else { return nil }
                return (item.correction.originalInput, payload)
            }
    }

    /// Returns the total number of stored corrections.
    func correctionCount() async -> Int {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<UserCorrection>()
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    /// Removes all stored corrections.
    func clearAll() async throws {
        let context = ModelContext(container)
        try context.delete(model: UserCorrection.self)
        try context.save()
    }

    // MARK: - Private Helpers

    private func normalize(_ text: String) -> String {
        text.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }

    private func tokenize(_ text: String) -> [String] {
        text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && $0.count > 2 }
    }

    private func jaccardSimilarity(_ a: String, _ b: String) -> Double {
        let tokensA = Set(tokenize(a))
        let tokensB = Set(tokenize(b))
        let intersection = tokensA.intersection(tokensB)
        let union = tokensA.union(tokensB)
        guard !union.isEmpty else { return 0 }
        return Double(intersection.count) / Double(union.count)
    }
}
