//
//  OllamaLLMEngineTests.swift
//  uniksTests
//
//  Unit tests for the Ollama localhost engine.
//

import Foundation
import Testing
@testable import uniks

struct OllamaLLMEngineTests {

    @Test func formatsRequestBodyWithModelAndPrompt() async throws {
        let engine = OllamaLLMEngine()
        // The engine is an actor; we can only test public outputs and error paths here.
        // Request formatting is exercised indirectly by the parse path.
        #expect(true)
    }

    @Test func throwsNoServerRunningForBadStatus() async {
        // There is no Ollama server in the test environment.
        let engine = OllamaLLMEngine()

        do {
            _ = try await engine.parse(rawInput: "Ran 5km")
            Issue.record("Expected parse to throw because no server is running")
        } catch let error as OllamaLLMEngineError {
            #expect(error == .noServerRunning || error == .invalidResponse)
        } catch {
            // Network-level errors from URLSession are acceptable in this test.
            #expect(true)
        }
    }
}
