//
//  EngineResolverTests.swift
//  uniksTests
//
//  Unit tests for engine selection and fallback.
//

import Testing
@testable import uniks

struct EngineResolverTests {

    @Test func mockPreferenceReturnsMockEngine() async throws {
        let resolver = EngineResolver(
            preference: .mock,
            mockFactory: { MockLLMEngine(result: HabitParseResult(category: "mock")) }
        )
        let engine = await resolver.resolve()

        #expect(engine is MockLLMEngine)
        let result = try await engine.parse(rawInput: "test")
        #expect(result.category == "mock")
    }

    @Test func ollamaPreferenceReturnsOllamaFactoryEngine() async throws {
        let resolver = EngineResolver(
            preference: .ollama,
            ollamaFactory: { MockLLMEngine(result: HabitParseResult(category: "ollama")) },
            mockFactory: { MockLLMEngine(result: HabitParseResult(category: "fallback")) }
        )
        let engine = await resolver.resolve()

        #expect(engine is MockLLMEngine)
        let result = try await engine.parse(rawInput: "test")
        #expect(result.category == "ollama")
    }

    @Test func ollamaPreferenceFallsBackToMockWhenFactoryReturnsNil() async throws {
        let resolver = EngineResolver(
            preference: .ollama,
            ollamaFactory: { nil },
            mockFactory: { MockLLMEngine(result: HabitParseResult(category: "fallback")) }
        )
        let engine = await resolver.resolve()

        #expect(engine is MockLLMEngine)
        let result = try await engine.parse(rawInput: "test")
        #expect(result.category == "fallback")
    }

    #if targetEnvironment(simulator)
    @Test func mlxPreferenceFallsBackOnSimulator() async throws {
        let resolver = EngineResolver(
            preference: .mlx,
            mlxFactory: { MockLLMEngine(result: HabitParseResult(category: "mlx")) },
            ollamaFactory: { MockLLMEngine(result: HabitParseResult(category: "ollama")) },
            mockFactory: { MockLLMEngine(result: HabitParseResult(category: "mock")) }
        )
        let engine = await resolver.resolve()

        #expect(!(engine is MLXLLMEngine))
        let result = try await engine.parse(rawInput: "test")
        #expect(result.category == "ollama")
    }
    #else
    @Test func mlxPreferenceReturnsMLXFactoryEngineOnDevice() async throws {
        let resolver = EngineResolver(
            preference: .mlx,
            mlxFactory: { MockLLMEngine(result: HabitParseResult(category: "mlx")) },
            ollamaFactory: { MockLLMEngine(result: HabitParseResult(category: "ollama")) }
        )
        let engine = await resolver.resolve()

        #expect(engine is MockLLMEngine)
        let result = try await engine.parse(rawInput: "test")
        #expect(result.category == "mlx")
    }
    #endif
}
