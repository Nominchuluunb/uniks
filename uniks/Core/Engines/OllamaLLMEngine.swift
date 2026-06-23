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

/// A `URLSession`-like abstraction used by `OllamaLLMEngine` for network calls.
///
/// This protocol exists primarily to enable deterministic unit tests with a mock client.
protocol URLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

/// Parses raw input via a local Ollama server at `http://localhost:11434`.
actor OllamaLLMEngine: LocalLLMEngine {
    private static let defaultBaseURLString = "http://localhost:11434"

    private let baseURL: URL
    private let model: String
    private let session: URLSessionProtocol

    /// Creates an engine pointing at the given Ollama server.
    ///
    /// - Parameters:
    ///   - baseURL: The Ollama server URL. Defaults to `http://localhost:11434` if nil.
    ///   - model: The model name to use for generation. Defaults to `llama3.2:3b`.
    ///   - session: The network session used to perform requests. Defaults to `URLSession.shared`.
    init?(baseURL: URL? = nil, model: String = "llama3.2:3b", session: URLSessionProtocol = URLSession.shared) {
        guard let baseURL = baseURL ?? URL(string: Self.defaultBaseURLString) else {
            return nil
        }
        self.baseURL = baseURL
        self.model = model
        self.session = session
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

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaLLMEngineError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw OllamaLLMEngineError.noServerRunning
        }

        struct GenerateResponse: Decodable {
            let response: String
        }

        let generateResponse: GenerateResponse
        do {
            generateResponse = try JSONDecoder().decode(GenerateResponse.self, from: data)
        } catch {
            throw OllamaLLMEngineError.decodingFailed
        }

        let cleaned = generateResponse.response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw OllamaLLMEngineError.decodingFailed
        }

        do {
            return try JSONDecoder().decode(HabitParseResult.self, from: jsonData)
        } catch {
            throw OllamaLLMEngineError.decodingFailed
        }
    }

    /// Builds the prompt sent to the Ollama model.
    nonisolated private static func extractionPrompt(for rawInput: String) -> String {
        """
        Extract structured data from the following personal log entry.
        Respond with a single JSON object containing optional keys:
        category (string), value (number), unit (string), tags (array of strings), notes (string).

        Log entry: \(rawInput)
        """
    }
}
