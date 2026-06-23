//
//  OllamaLLMEngine.swift
//  uniks
//
//  Localhost Ollama parser for user-controlled LLM inference.
//

import Foundation

/// Errors thrown by the Ollama localhost engine.
enum OllamaLLMEngineError: Error, Sendable, Equatable {
    case invalidURL
    case noServerRunning
    case invalidResponse
    case decodingFailed
}

/// Parses raw input via a local Ollama server at `http://localhost:11434`.
actor OllamaLLMEngine: LocalLLMEngine {
    private static let defaultBaseURL = URL(string: "http://localhost:11434")!

    private let baseURL: URL
    private let model: String

    init(baseURL: URL = defaultBaseURL, model: String = "llama3.2:3b") {
        self.baseURL = baseURL
        self.model = model
    }

    /// Sends the raw input to the local Ollama server and decodes the generated JSON into a structured result.
    func parse(rawInput: String) async throws -> HabitParseResult {
        let url = baseURL.appendingPathComponent("api/generate")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "prompt": Self.extractionPrompt(for: rawInput),
            "stream": false,
            "format": "json"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaLLMEngineError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw OllamaLLMEngineError.noServerRunning
        }

        struct GenerateResponse: Decodable {
            let response: String
        }

        let generateResponse = try JSONDecoder().decode(GenerateResponse.self, from: data)
        let cleaned = generateResponse.response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw OllamaLLMEngineError.decodingFailed
        }

        return try JSONDecoder().decode(HabitParseResult.self, from: jsonData)
    }

    private static func extractionPrompt(for rawInput: String) -> String {
        """
        Extract structured data from the following personal log entry.
        Respond with a single JSON object containing optional keys:
        category (string), value (number), unit (string), tags (array of strings), notes (string).

        Log entry: \(rawInput)
        """
    }
}
