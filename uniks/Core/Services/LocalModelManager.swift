//
//  LocalModelManager.swift
//  uniks
//
//  Manages downloading and cache-status checking for local LLM models.
//

import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

/// Manages downloadable on-device LLM models.
///
/// This actor isolates all download and cache-check state so the UI can observe
/// status updates safely.
actor LocalModelManager {
    private(set) var statuses: [String: LocalModelStatus] = [:]
    private let cacheDirectoryOverride: URL?

    /// Creates a manager with all built-in models marked as `.notDownloaded`.
    /// - Parameter cacheDirectoryOverride: Optional cache directory for testing.
    init(cacheDirectoryOverride: URL? = nil) {
        self.cacheDirectoryOverride = cacheDirectoryOverride
        for model in LocalModel.allModels {
            statuses[model.id] = .notDownloaded
        }
    }

    private var cacheDirectory: URL? {
        cacheDirectoryOverride ?? HubCache.default.cacheDirectory
    }

    /// Checks the cache for every built-in model and updates `statuses`.
    func refreshStatuses() {
        for model in LocalModel.allModels {
            statuses[model.id] = status(for: model)
        }
    }

    /// Returns the current download status for a model by inspecting the Hugging Face cache.
    /// - Parameter model: The model to check.
    /// - Returns: `.downloaded(size:)` if the cache folder exists and has content,
    ///            otherwise `.notDownloaded`.
    func status(for model: LocalModel) -> LocalModelStatus {
        guard let cacheDirectory else {
            return .notDownloaded
        }

        let modelCacheURL = cacheDirectory
            .appendingPathComponent(model.cacheFolderName, isDirectory: true)

        guard FileManager.default.fileExists(atPath: modelCacheURL.path) else {
            return .notDownloaded
        }

        let size = directorySize(at: modelCacheURL)
        return size > 0 ? .downloaded(size: size) : .notDownloaded
    }

    /// Downloads a model and updates its status.
    /// - Parameter model: The model to download.
    /// - Note: This method performs network I/O and may take minutes for larger models.
    func download(_ model: LocalModel) async {
        statuses[model.id] = .downloading

        do {
            _ = try await #huggingFaceLoadModelContainer(
                configuration: ModelConfiguration(id: model.id)
            )
            statuses[model.id] = status(for: model)
        } catch {
            statuses[model.id] = .notDownloaded
        }
    }

    /// Recursively calculates the total size of a directory in bytes.
    private func directorySize(at url: URL) -> UInt64 {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var total: UInt64 = 0
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                  resourceValues.isRegularFile == true,
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            total += UInt64(fileSize)
        }
        return total
    }
}

extension LocalModelStatus {
    /// A user-facing description of the status.
    var displayText: String {
        switch self {
        case .notDownloaded:
            return "Not downloaded"
        case .downloading:
            return "Downloading…"
        case .downloaded(let size):
            return "Downloaded · \(Self.formattedSize(size))"
        }
    }

    private static func formattedSize(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        if gb < 0.1 {
            return String(format: "%.0f MB", Double(bytes) / 1_048_576)
        }
        return String(format: "%.1f GB", gb)
    }
}
