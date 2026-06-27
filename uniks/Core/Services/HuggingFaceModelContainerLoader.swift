//
//  HuggingFaceModelContainerLoader.swift
//  uniks
//
//  Loads MLX model containers from Hugging Face cache.
//

import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

/// Loads an MLX model container using the HuggingFace macro integration.
struct HuggingFaceModelContainerLoader: ModelContainerLoading {
    func load(modelID: String) async throws -> ModelContainer {
        let configuration = ModelConfiguration(id: modelID)
        return try await #huggingFaceLoadModelContainer(configuration: configuration)
    }
}
