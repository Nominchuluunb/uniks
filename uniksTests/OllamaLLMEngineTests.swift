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
    let response: URLResponse

    init(responseData: Data, response: URLResponse) {
        self.responseData = responseData
        self.response = response
    }

    nonisolated func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        _ = request
        return (responseData, response)
    }
}

struct OllamaLLMEngineTests {

    @Test func parsesValidResponse() async throws {
        let url = try #require(URL(string: "http://localhost:11434/api/generate"))
        let ollamaResponse = try #require("""
        {"response": "{\\"category\\": \\"fitness\\", \\"value\\": 5.0, \\"unit\\": \\"km\\"}"}
        """.data(using: .utf8))
        let response = try #require(HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))
        let session = MockURLSession(responseData: ollamaResponse, response: response)
        let engine = try #require(OllamaLLMEngine(endpoint: url, urlSession: session))

        let result = try await engine.parse(rawInput: "Ran 5km")

        #expect(result.category == "fitness")
        #expect(result.value == 5.0)
        #expect(result.unit == "km")
    }

    @Test func throwsHttpStatusForNon2xxResponse() async throws {
        let url = try #require(URL(string: "http://localhost:11434/api/generate"))
        let response = try #require(HTTPURLResponse(
            url: url,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        ))
        let session = MockURLSession(responseData: Data(), response: response)
        let engine = try #require(OllamaLLMEngine(endpoint: url, urlSession: session))

        await #expect(throws: OllamaLLMEngineError.httpStatus(404)) {
            try await engine.parse(rawInput: "Ran 5km")
        }
    }

    @Test func throwsInvalidResponseForNonHTTPResponse() async throws {
        let url = try #require(URL(string: "http://localhost:11434/api/generate"))
        let response = URLResponse(
            url: url,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
        let session = MockURLSession(responseData: Data(), response: response)
        let engine = try #require(OllamaLLMEngine(endpoint: url, urlSession: session))

        await #expect(throws: OllamaLLMEngineError.invalidResponse) {
            try await engine.parse(rawInput: "Ran 5km")
        }
    }

    @Test func throwsDecodingFailedForInvalidJSON() async throws {
        let url = try #require(URL(string: "http://localhost:11434/api/generate"))
        let ollamaResponse = try #require("""
        {"response": "not valid json"}
        """.data(using: .utf8))
        let response = try #require(HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))
        let session = MockURLSession(responseData: ollamaResponse, response: response)
        let engine = try #require(OllamaLLMEngine(endpoint: url, urlSession: session))

        await #expect(throws: OllamaLLMEngineError.decodingFailed) {
            try await engine.parse(rawInput: "Ran 5km")
        }
    }
}
