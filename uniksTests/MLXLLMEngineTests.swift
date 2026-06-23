//
//  MLXLLMEngineTests.swift
//  uniksTests
//
//  Unit tests for the on-device MLX inference engine.
//  NOTE: These tests must be run on an iOS Simulator or macOS destination;
//  they cannot be executed on Linux because MLXLMCommon requires Apple platforms.
//

import Foundation
import Testing
@testable import uniks

struct MLXLLMEngineTests {

    #if targetEnvironment(simulator)
    @Test func parseThrowsNotAvailableOnSimulator() async {
        let engine = MLXLLMEngine()
        do {
            _ = try await engine.parse(rawInput: "test")
            Issue.record("Expected parse to throw notAvailableOnSimulator")
        } catch let error as MLXLLMEngineError {
            #expect(error == .notAvailableOnSimulator)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    #endif
}
