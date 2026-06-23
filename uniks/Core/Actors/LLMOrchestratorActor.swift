//
//  LLMOrchestratorActor.swift
//  uniks
//
//  Background network orchestration to a local Ollama/LM Studio endpoint.
//

import Foundation

/// Errors that can occur when communicating with a localhost LLM endpoint.
enum LLMOrchestratorError: Error, Sendable {
    case invalidEndpoint
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed
}

/// Actor that routes parsing requests to a localhost LLM server such as
/// Ollama (http://localhost:11434) or LM Studio.
actor LLMOrchestratorActor: LocalLLMEngine {
    private let endpoint: URL
    private let modelName: String
    private let urlSession: URLSession

    /// Default Ollama API endpoint.
    static let defaultEndpoint = URL(string: "http://localhost:11434/api/generate")

    init(
        endpoint: URL? = nil,
        modelName: String = "llama3.2:3b",
        urlSession: URLSession = .shared
    ) throws {
        guard let endpoint = endpoint ?? Self.defaultEndpoint else {
            throw LLMOrchestratorError.invalidEndpoint
        }
        self.endpoint = endpoint
        self.modelName = modelName
        self.urlSession = urlSession
    }

    /// Parses raw input by asking the local LLM to extract structured data.
    func parse(rawInput: String) async throws -> HabitParseResult {
        let prompt = Self.buildExtractionPrompt(for: rawInput)
        let requestBody: [String: Any] = [
            "model": modelName,
            "prompt": prompt,
            "stream": false,
            "format": "json",
            "options": [
                "temperature": 0.0
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMOrchestratorError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw LLMOrchestratorError.httpStatus(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseText = json["response"] as? String else {
            throw LLMOrchestratorError.decodingFailed
        }

        // The model may wrap the JSON in markdown fences; strip them.
        let cleaned = responseText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let cleanedData = cleaned.data(using: .utf8) else {
            throw LLMOrchestratorError.decodingFailed
        }

        return try JSONDecoder().decode(HabitParseResult.self, from: cleanedData)
    }

    private static func buildExtractionPrompt(for rawInput: String) -> String {
        """
        Extract structured information from the following user log entry.
        Return ONLY a JSON object with these fields, all optional except "tags" which defaults to []:
        {
          "category": "broad category such as fitness, sleep, hydration, mood, work",
          "value": numeric value as a number if present,
          "unit": unit of measurement if present,
          "tags": ["list", "of", "relevant", "tags"],
          "notes": "any additional context"
        }

        User entry: "\(rawInput)"
        """
    }
}
