//
//  HuggingFaceModelDownloader.swift
//  uniks
//
//  Concrete model downloader using HuggingFace HubClient with real progress reporting.
//

import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

/// Downloads MLX models from Hugging Face with streaming progress.
struct HuggingFaceModelDownloader: ModelDownloaderProtocol {

    func download(
        modelID: String,
        progressContinuation: AsyncStream<ModelDownloadProgress>.Continuation
    ) async throws -> URL {
        progressContinuation.yield(ModelDownloadProgress(
            fractionCompleted: 0,
            completedBytes: 0,
            totalBytes: 0,
            phase: .downloading
        ))

        let configuration = ModelConfiguration(id: modelID)

        let container = try await LLMModelFactory.shared.loadContainer(
            from: #hubDownloader(),
            using: #huggingFaceTokenizerLoader(),
            configuration: configuration
        ) { progress in
            let update = ModelDownloadProgress(
                fractionCompleted: progress.fractionCompleted,
                completedBytes: progress.completedUnitCount,
                totalBytes: progress.totalUnitCount,
                phase: .downloading
            )
            progressContinuation.yield(update)
        }

        // Signal verifying/loading phase
        progressContinuation.yield(ModelDownloadProgress(
            fractionCompleted: 1.0,
            completedBytes: 0,
            totalBytes: 0,
            phase: .verifying
        ))

        // Container loaded successfully; return the cache directory
        _ = container
        let cacheDir = HubCache.default.cacheDirectory
        let modelCacheURL = cacheDir.appendingPathComponent(
            "models--\(modelID.replacingOccurrences(of: "/", with: "--"))",
            isDirectory: true
        )
        return modelCacheURL
    }
}
