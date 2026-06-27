//
//  ModelDownloader.swift
//  uniks
//
//  Protocol abstraction for model download implementations.
//

import Foundation

/// Abstraction for downloading model weights, enabling mock injection in tests.
protocol ModelDownloaderProtocol: Sendable {
    /// Downloads model weights and reports progress via the continuation.
    /// - Parameters:
    ///   - modelID: The Hugging Face model identifier.
    ///   - progressContinuation: Continuation to send `ModelDownloadProgress` updates.
    /// - Returns: The local URL of the downloaded model directory.
    func download(
        modelID: String,
        progressContinuation: AsyncStream<ModelDownloadProgress>.Continuation
    ) async throws -> URL
}
