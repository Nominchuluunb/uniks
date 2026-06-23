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

        await #expect(throws: MLXLLMEngineError.notAvailableOnSimulator) {
            _ = try await engine.parse(rawInput: "Drank 500ml water")
        }
    }
    #endif
}
