//
//  MLXLLMEngine.swift
//  uniks
//
//  On-device Apple MLX inference engine. Requires a physical Apple Silicon device.
//

import Foundation
import MLXLMCommon

/// Errors specific to the on-device MLX engine.
enum MLXLLMEngineError: Error, Sendable {
    case notAvailableOnSimulator
    case modelNotLoaded
    case generationFailed(Error)
}

/// On-device parser using Apple's MLX framework via `MLXLMCommon`.
/// This engine is only functional on physical Apple Silicon devices.
actor MLXLLMEngine: LocalLLMEngine {
    private let modelID: String

    init(modelID: String = "mlx-community/Llama-3.2-3B-Instruct-4bit") {
        self.modelID = modelID
    }

    func parse(rawInput: String) async throws -> HabitParseResult {
        #if targetEnvironment(simulator)
        throw MLXLLMEngineError.notAvailableOnSimulator
        #else
        // Load the model container on first use. In production this should be
        // cached and managed by a dedicated ModelManager actor.
        let modelContainer = try await LLMModel.load(
            configuration: ModelConfiguration(id: modelID)
        )
        let model = modelContainer.model

        let messages: [[String: String]] = [
            ["role": "system", "content": Self.extractionSystemPrompt],
            ["role": "user", "content": rawInput]
        ]

        let prompt = try model.applyChatTemplate(messages: messages)
        let stream = try await model.generate(
            prompt: prompt,
            maxTokens: 256
        )

        var output = ""
        for try await token in stream {
            output += token
        }

        let cleaned = output
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw MLXLLMEngineError.modelNotLoaded
        }

        return try JSONDecoder().decode(HabitParseResult.self, from: data)
        #endif
    }

    private static var extractionSystemPrompt: String {
        """
        You extract structured data from a user's personal log entry.
        Respond with a single JSON object containing optional keys:
        category, value (number), unit, tags (array of strings), notes.
        """
    }
}
