//
//  OllamaLLMEngineTests.swift
//  uniksTests
//
//  Unit tests for the Ollama localhost engine.
//

import Foundation
import Testing
@testable import uniks

actor MockURLSession: URLSessionProtocol {
    let responseData: Data
    let statusCode: Int

    init(responseData: Data, statusCode: Int) {
        self.responseData = responseData
        self.statusCode = statusCode
    }

    nonisolated func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let url = try request.url ?? #require(URL(string: "http://localhost:11434"))
        guard let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        ) else {
            throw URLError(.badServerResponse)
        }
        return (responseData, response)
    }
}

struct OllamaLLMEngineTests {

    @Test func parsesValidResponse() async throws {
        let ollamaResponse = try #require("""
        {"response": "{\\"category\\": \\"fitness\\", \\"value\\": 5.0, \\"unit\\": \\"km\\"}"}
        """.data(using: .utf8))
        let session = MockURLSession(responseData: ollamaResponse, statusCode: 200)
        let engine = try #require(OllamaLLMEngine(session: session))

        let result = try await engine.parse(rawInput: "Ran 5km")

        #expect(result.category == "fitness")
        #expect(result.value == 5.0)
        #expect(result.unit == "km")
    }

    @Test func throwsNoServerRunningForNon200Status() async throws {
        let session = MockURLSession(responseData: Data(), statusCode: 404)
        let engine = try #require(OllamaLLMEngine(session: session))

        await #expect(throws: OllamaLLMEngineError.noServerRunning) {
            try await engine.parse(rawInput: "Ran 5km")
        }
    }

    @Test func throwsDecodingFailedForInvalidJSON() async throws {
        let ollamaResponse = try #require("""
        {"response": "not valid json"}
        """.data(using: .utf8))
        let session = MockURLSession(responseData: ollamaResponse, statusCode: 200)
        let engine = try #require(OllamaLLMEngine(session: session))

        await #expect(throws: OllamaLLMEngineError.decodingFailed) {
            try await engine.parse(rawInput: "Ran 5km")
        }
    }
}
