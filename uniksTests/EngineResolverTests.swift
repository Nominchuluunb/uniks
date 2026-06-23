//
//  EngineResolverTests.swift
//  uniksTests
//
//  Unit tests for engine selection and fallback.
//

import Foundation
import Testing
@testable import uniks

struct EngineResolverTests {

    @Test func mockPreferenceReturnsMockEngine() async {
        let resolver = EngineResolver(preference: .mock)
        let engine = await resolver.resolve()

        #expect(engine is MockLLMEngine)
    }

    @Test func ollamaPreferenceReturnsOllamaOrMockEngine() async {
        let resolver = EngineResolver(preference: .ollama)
        let engine = await resolver.resolve()

        // Ollama is returned when initialization succeeds; Mock is the fallback when it fails.
        #expect(engine is OllamaLLMEngine || engine is MockLLMEngine)
    }

    #if targetEnvironment(simulator)
    @Test func mlxPreferenceFallsBackOnSimulator() async {
        let resolver = EngineResolver(preference: .mlx)
        let engine = await resolver.resolve()

        #expect(!(engine is MLXLLMEngine))
    }
    #else
    @Test func mlxPreferenceReturnsMLXEngineOnDevice() async {
        let resolver = EngineResolver(preference: .mlx)
        let engine = await resolver.resolve()

        #expect(engine is MLXLLMEngine)
    }
    #endif
}
