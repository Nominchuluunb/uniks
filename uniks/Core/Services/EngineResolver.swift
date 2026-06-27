//
//  EngineResolver.swift
//  uniks
//
//  Selects the active local LLM engine based on user preference and runtime availability.
//

/// Resolves the engine to use for parsing, applying fallback logic.
///
/// When MLX is preferred, reads `ActiveModelPreference` to configure the engine.
/// Falls back through Ollama → Mock if MLX is unavailable (e.g., simulator, no model downloaded).
struct EngineResolver {
    private let preference: EnginePreference
    private let modelStore: ModelStore
    private let mlxFactory: @Sendable (ModelStore, String) -> any LocalLLMEngine
    private let ollamaFactory: @Sendable () -> (any LocalLLMEngine)?
    private let mockFactory: @Sendable () -> any LocalLLMEngine

    init(
        preference: EnginePreference = .current(),
        modelStore: ModelStore = ModelStore(),
        mlxFactory: @escaping @Sendable (ModelStore, String) -> any LocalLLMEngine = { store, id in
            MLXLLMEngine(modelStore: store, modelID: id)
        },
        ollamaFactory: @escaping @Sendable () -> (any LocalLLMEngine)? = { OllamaLLMEngine() },
        mockFactory: @escaping @Sendable () -> any LocalLLMEngine = { MockLLMEngine(result: HabitParseResult()) }
    ) {
        self.preference = preference
        self.modelStore = modelStore
        self.mlxFactory = mlxFactory
        self.ollamaFactory = ollamaFactory
        self.mockFactory = mockFactory
    }

    /// Synchronously resolves the best engine. Used where `await` is unavailable (e.g., `App.init`).
    static nonisolated func preferredEngine(
        for preference: EnginePreference,
        modelStore: ModelStore = ModelStore(),
        mlxFactory: @escaping @Sendable (ModelStore, String) -> any LocalLLMEngine = { store, id in
            MLXLLMEngine(modelStore: store, modelID: id)
        },
        ollamaFactory: @escaping @Sendable () -> (any LocalLLMEngine)? = { OllamaLLMEngine() },
        mockFactory: @escaping @Sendable () -> any LocalLLMEngine = { MockLLMEngine(result: HabitParseResult()) }
    ) -> any LocalLLMEngine {
        switch preference {
        case .mlx:
            #if targetEnvironment(simulator)
            return ollamaFactory() ?? mockFactory()
            #else
            let modelID = ActiveModelPreference.effectiveModelID()
            return mlxFactory(modelStore, modelID)
            #endif
        case .ollama:
            return ollamaFactory() ?? mockFactory()
        case .mock:
            return mockFactory()
        }
    }

    /// Returns the best available engine for the current runtime.
    nonisolated func resolve() async -> any LocalLLMEngine {
        Self.preferredEngine(
            for: preference,
            modelStore: modelStore,
            mlxFactory: mlxFactory,
            ollamaFactory: ollamaFactory,
            mockFactory: mockFactory
        )
    }
}
