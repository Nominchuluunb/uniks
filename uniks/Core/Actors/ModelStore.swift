//
//  ModelStore.swift
//  uniks
//
//  Caches loaded MLX model containers for instant repeated inference.
//

import Foundation
import MLXLMCommon

/// Protocol for model container loading, enabling mock injection in tests.
protocol ModelContainerLoading: Sendable {
    func load(modelID: String) async throws -> ModelContainer
}

/// Caches loaded `ModelContainer` instances so subsequent `parse()` calls
/// skip the expensive model-loading step entirely.
actor ModelStore {
    private var cache: [String: ModelContainer] = [:]
    private let loader: ModelContainerLoading

    init(loader: ModelContainerLoading = HuggingFaceModelContainerLoader()) {
        self.loader = loader
    }

    /// Returns a cached container or loads and caches it on first access.
    func container(for modelID: String) async throws -> ModelContainer {
        if let cached = cache[modelID] {
            return cached
        }
        let loaded = try await loader.load(modelID: modelID)
        cache[modelID] = loaded
        return loaded
    }

    /// Preloads a model into cache (call after download/on launch).
    func warmUp(_ modelID: String) async {
        _ = try? await container(for: modelID)
    }

    /// Removes a model from cache (call on delete).
    func evict(_ modelID: String) {
        cache[modelID] = nil
    }
}
