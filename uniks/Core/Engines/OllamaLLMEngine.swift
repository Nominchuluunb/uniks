//
//  OllamaLLMEngine.swift
//  uniks
//
//  Localhost Ollama/LM Studio parser for user-controlled LLM inference.
//

import Foundation

/// Errors that can occur when communicating with a localhost LLM endpoint.
enum OllamaLLMEngineError: Error, Sendable, Equatable {
    case invalidEndpoint
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed
}

/// A `URLSession`-like abstraction used by `OllamaLLMEngine` for network calls.
///
/// This protocol exists primarily to enable deterministic unit tests with a mock client.
protocol URLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

/// Parses raw input via a local Ollama or LM Studio server.
actor OllamaLLMEngine: LocalLLMEngine {
    private let endpoint: URL
    private let modelName: String
    private let urlSession: URLSessionProtocol

    /// Default Ollama API endpoint.
    static let defaultEndpoint = URL(string: "http://localhost:11434/api/generate")

    /// Creates an engine pointing at the given localhost LLM endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: The server URL. Defaults to `http://localhost:11434/api/generate` if nil.
    ///   - modelName: The model name to use for generation. Defaults to `llama3.2:3b`.
    ///   - urlSession: The network session used to perform requests. Defaults to `URLSession.shared`.
    init(
        endpoint: URL? = nil,
        modelName: String = "llama3.2:3b",
        urlSession: URLSessionProtocol = URLSession.shared
    ) throws {
        guard let endpoint = endpoint ?? Self.defaultEndpoint else {
            throw OllamaLLMEngineError.invalidEndpoint
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
            throw OllamaLLMEngineError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw OllamaLLMEngineError.httpStatus(httpResponse.statusCode)
        }

        let responseText: String
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let text = json["response"] as? String else {
                throw OllamaLLMEngineError.decodingFailed
            }
            responseText = text
        } catch is OllamaLLMEngineError {
            throw error
        } catch {
            throw OllamaLLMEngineError.decodingFailed
        }

        // The model may wrap the JSON in markdown fences; strip them.
        let cleaned = responseText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let cleanedData = cleaned.data(using: .utf8) else {
            throw OllamaLLMEngineError.decodingFailed
        }

        do {
            return try JSONDecoder().decode(HabitParseResult.self, from: cleanedData)
        } catch {
            throw OllamaLLMEngineError.decodingFailed
        }
    }

    /// Builds the prompt sent to the local LLM.
    private static nonisolated func buildExtractionPrompt(for rawInput: String) -> String {
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
