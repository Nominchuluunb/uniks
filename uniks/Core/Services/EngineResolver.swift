//
//  EngineResolver.swift
//  uniks
//
//  Selects the active local LLM engine based on user preference and runtime availability.
//

import Foundation

/// Resolves the engine to use for parsing, applying fallback logic.
///
/// Preference order:
/// - If user prefers MLX, use MLX on device; on simulator fall back to Ollama, then Mock.
/// - If user prefers Ollama, try Ollama; fall back to Mock if initialization fails.
/// - If user prefers Mock, use Mock.
actor EngineResolver {
    private let preference: EnginePreference

    init(preference: EnginePreference = .current()) {
        self.preference = preference
    }

    /// Returns the best available engine for the current runtime.
    func resolve() async -> any LocalLLMEngine {
        switch preference {
        case .mlx:
            #if targetEnvironment(simulator)
            return await fallbackAfterMLX()
            #else
            return MLXLLMEngine()
            #endif
        case .ollama:
            if let engine = OllamaLLMEngine() {
                return engine
            }
            return MockLLMEngine(result: HabitParseResult())
        case .mock:
            return MockLLMEngine(result: HabitParseResult())
        }
    }

    #if targetEnvironment(simulator)
    private func fallbackAfterMLX() async -> any LocalLLMEngine {
        // On simulator, MLX is unavailable. Try Ollama; if it fails to initialize, return Mock.
        if let engine = OllamaLLMEngine() {
            return engine
        }
        return MockLLMEngine(result: HabitParseResult())
    }
    #endif
}
