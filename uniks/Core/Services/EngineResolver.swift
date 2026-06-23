//
//  EngineResolver.swift
//  uniks
//
//  Selects the active local LLM engine based on user preference and runtime availability.
//

/// Resolves the engine to use for parsing, applying fallback logic.
///
/// Preference order:
/// - If user prefers MLX, use MLX on device; on simulator fall back to Ollama, then Mock.
/// - If user prefers Ollama, try Ollama; fall back to Mock if initialization fails.
/// - If user prefers Mock, use Mock.
actor EngineResolver {
    private let preference: EnginePreference
    private let mlxFactory: @Sendable () -> any LocalLLMEngine
    private let ollamaFactory: @Sendable () -> (any LocalLLMEngine)?
    private let mockFactory: @Sendable () -> any LocalLLMEngine

    init(
        preference: EnginePreference = .current(),
        mlxFactory: @escaping @Sendable () -> any LocalLLMEngine = { MLXLLMEngine() },
        ollamaFactory: @escaping @Sendable () -> (any LocalLLMEngine)? = { OllamaLLMEngine() },
        mockFactory: @escaping @Sendable () -> any LocalLLMEngine = { MockLLMEngine(result: HabitParseResult()) }
    ) {
        self.preference = preference
        self.mlxFactory = mlxFactory
        self.ollamaFactory = ollamaFactory
        self.mockFactory = mockFactory
    }

    /// Synchronously resolves the best engine for a preference. Used where `await` is unavailable (e.g., `App.init`).
    static nonisolated func preferredEngine(
        for preference: EnginePreference,
        mlxFactory: @escaping @Sendable () -> any LocalLLMEngine = { MLXLLMEngine() },
        ollamaFactory: @escaping @Sendable () -> (any LocalLLMEngine)? = { OllamaLLMEngine() },
        mockFactory: @escaping @Sendable () -> any LocalLLMEngine = { MockLLMEngine(result: HabitParseResult()) }
    ) -> any LocalLLMEngine {
        switch preference {
        case .mlx:
            #if targetEnvironment(simulator)
            return ollamaFactory() ?? mockFactory()
            #else
            return mlxFactory()
            #endif
        case .ollama:
            return ollamaFactory() ?? mockFactory()
        case .mock:
            return mockFactory()
        }
    }

    /// Returns the best available engine for the current runtime.
    func resolve() async -> any LocalLLMEngine {
        Self.preferredEngine(
            for: preference,
            mlxFactory: mlxFactory,
            ollamaFactory: ollamaFactory,
            mockFactory: mockFactory
        )
    }
}
