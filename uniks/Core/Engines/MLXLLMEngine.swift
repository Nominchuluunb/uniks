//
//  MLXLLMEngine.swift
//  uniks
//
//  On-device Apple MLX inference engine. Requires a physical Apple Silicon device.
//

import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

/// Errors specific to the on-device MLX engine.
enum MLXLLMEngineError: Error, Sendable, Equatable {
    case notAvailableOnSimulator
    case outputEncodingFailed
}

/// On-device parser using Apple's MLX framework via `MLXLMCommon`.
/// This engine is only functional on physical Apple Silicon devices.
actor MLXLLMEngine: LocalLLMEngine {
    private let modelID: String

    /// Creates an MLX engine configured for the specified model.
    /// - Parameter modelID: The Hugging Face model identifier. Defaults to a small quantized instruct model.
    init(modelID: String = "mlx-community/Llama-3.2-3B-Instruct-4bit") {
        self.modelID = modelID
    }

    /// Parses raw natural-language input into a structured `HabitParseResult` using on-device MLX inference.
    /// - Parameter rawInput: The user's original text.
    /// - Returns: A structured parse result extracted from the model output.
    func parse(rawInput: String) async throws -> HabitParseResult {
        #if targetEnvironment(simulator)
        throw MLXLLMEngineError.notAvailableOnSimulator
        #else
        // Load the model container on first use. In production this should be
        // cached and managed by a dedicated ModelManager actor.
        let modelContainer = try await #huggingFaceLoadModelContainer(
            configuration: ModelConfiguration(id: modelID)
        )

        let stream = try await modelContainer.perform { context in
            let userInput = UserInput(messages: [
                ["role": "system", "content": Self.extractionSystemPrompt],
                ["role": "user", "content": rawInput]
            ])
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
        """
        You extract structured data from a user's personal log entry.
        Respond with a single JSON object containing optional keys:
        category, value (number), unit, tags (array of strings), notes.
        """
    }
}
