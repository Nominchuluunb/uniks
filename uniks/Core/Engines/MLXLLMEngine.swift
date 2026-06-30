//
//  MLXLLMEngine.swift
//  uniks
//
//  On-device Apple MLX inference engine using cached model containers.
//

import Foundation
import MLXLMCommon

/// Errors specific to the on-device MLX engine.
enum MLXLLMEngineError: Error, Sendable, Equatable {
    case notAvailableOnSimulator
    case outputEncodingFailed
}

/// On-device parser using Apple's MLX framework via `MLXLMCommon`.
/// Uses `ModelStore` for cached model loading — first parse loads the model,
/// subsequent parses are near-instant.
actor MLXLLMEngine: LocalLLMEngine {
    private let modelStore: ModelStore
    private let modelID: String

    /// Creates an MLX engine that reads from the active model preference.
    /// - Parameters:
    ///   - modelStore: The shared model cache.
    ///   - modelID: Override model ID. Defaults to `ActiveModelPreference.effectiveModelID()`.
    init(
        modelStore: ModelStore = ModelStore(),
        modelID: String? = nil
    ) {
        self.modelStore = modelStore
        self.modelID = modelID ?? ActiveModelPreference.effectiveModelID()
    }

    func parse(rawInput: String) async throws -> HabitParseResult {
        #if targetEnvironment(simulator)
        throw MLXLLMEngineError.notAvailableOnSimulator
        #else
        let modelContainer = try await modelStore.container(for: modelID)

        let messages = ParsingPrompts.buildMessages(rawInput: rawInput)

        let stream = try await modelContainer.perform { context in
            let userInput = UserInput(messages: messages)
            let input = try await context.processor.prepare(input: userInput)
            return try MLXLMCommon.generate(
                input: input,
                parameters: GenerateParameters(maxTokens: 256, temperature: 0.0),
                context: context
            )
        }

        var output = ""
        for try await event in stream {
            if case .chunk(let text) = event {
                output += text
            }
        }

        // Try JSON repair pipeline
        if let repaired = JSONRepairService.repair(output) {
            return repaired
        }

        // Fallback: direct decode
        let cleaned = output
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw MLXLLMEngineError.outputEncodingFailed
        }

        return try JSONDecoder().decode(HabitParseResult.self, from: data)
        #endif
    }

    private static var extractionSystemPrompt: String {
        ParsingPrompts.systemPrompt
    }
}
