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

    @Test func throwsWhenNoServerIsRunning() async {
        let engine = OllamaLLMEngine()
        do {
            _ = try await engine.parse(rawInput: "Ran 5km")
            Issue.record("Expected parse to throw")
        } catch is OllamaLLMEngineError {
            #expect(true)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
