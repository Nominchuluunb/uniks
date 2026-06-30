//
//  OllamaLLMEngine.swift
//  uniks
//
//  Localhost Ollama/LM Studio parser for user-controlled LLM inference.
//

import Foundation

/// Errors that can occur when communicating with a localhost LLM endpoint.
enum OllamaLLMEngineError: Error, Sendable, Equatable {
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
    init?(
        endpoint: URL? = nil,
        modelName: String = "llama3.2:3b",
        urlSession: URLSessionProtocol = URLSession.shared
    ) {
        guard let endpoint = endpoint ?? Self.defaultEndpoint else {
            return nil
        }
        self.endpoint = endpoint
        self.modelName = modelName
        self.urlSession = urlSession
    }

    /// Parses raw input by asking the local LLM to extract structured data.
    func parse(rawInput: String) async throws -> HabitParseResult {
        let prompt = ParsingPrompts.buildPrompt(rawInput: rawInput)
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
        } catch let error as OllamaLLMEngineError {
            throw error
        } catch {
            throw OllamaLLMEngineError.decodingFailed
        }

        // Try JSON repair pipeline first
        if let repaired = JSONRepairService.repair(responseText) {
            return repaired
        }

        // Fallback: strip markdown and decode directly
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

}
