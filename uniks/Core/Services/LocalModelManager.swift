//
//  LocalModelManager.swift
//  uniks
//
//  Manages downloading, caching, and lifecycle of local LLM models.
//

import Foundation
import HuggingFace

/// Manages downloadable on-device LLM models with real streaming progress,
/// cancellation, retry, delete, and disk-space preflight.
actor LocalModelManager {
    private(set) var statuses: [String: LocalModelStatus] = [:]
    private var activeTasks: [String: Task<Void, Never>] = [:]
    private let downloader: ModelDownloaderProtocol
    private let cacheDirectoryOverride: URL?
    private let fileManager: FileManager

    /// Creates a manager with injected downloader (DI for testing).
    init(
        downloader: ModelDownloaderProtocol = HuggingFaceModelDownloader(),
        cacheDirectoryOverride: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.downloader = downloader
        self.cacheDirectoryOverride = cacheDirectoryOverride
        self.fileManager = fileManager
        for model in LocalModel.allModels {
            statuses[model.id] = .notDownloaded
        }
    }

    private var cacheDirectory: URL? {
        cacheDirectoryOverride ?? HubCache.default.cacheDirectory
    }

    // MARK: - Status Refresh

    /// Checks the cache for every built-in model and updates `statuses`.
    func refreshStatuses() {
        for model in LocalModel.allModels {
            // Don't overwrite active downloading/queued states
            if case .downloading = statuses[model.id] { continue }
            if case .queued = statuses[model.id] { continue }
            statuses[model.id] = cachedStatus(for: model)
        }
    }

    /// Returns the cached status for a model by inspecting the Hugging Face cache.
    private func cachedStatus(for model: LocalModel) -> LocalModelStatus {
        guard let cacheDirectory else { return .notDownloaded }
        let modelCacheURL = cacheDirectory.appendingPathComponent(model.cacheFolderName, isDirectory: true)
        guard fileManager.fileExists(atPath: modelCacheURL.path) else { return .notDownloaded }
        let size = directorySize(at: modelCacheURL)
        return size > 0 ? .downloaded(size: size) : .notDownloaded
    }

    // MARK: - Download

    /// Starts downloading a model and returns a stream of progress updates.
    /// Auto-activates the model on success.
    @discardableResult
    func download(_ model: LocalModel) -> AsyncStream<ModelDownloadProgress> {
        let (stream, continuation) = AsyncStream<ModelDownloadProgress>.makeStream()

        // Preflight: disk space check
        if let error = diskSpacePreflightError(for: model) {
            statuses[model.id] = .failed(message: error)
            continuation.finish()
            return stream
        }

        statuses[model.id] = .queued
        continuation.yield(ModelDownloadProgress(
            fractionCompleted: 0, completedBytes: 0, totalBytes: 0, phase: .queued
        ))

        let task = Task { [downloader] in
            do {
                try Task.checkCancellation()
                _ = try await downloader.download(
                    modelID: model.id,
                    progressContinuation: continuation
                )
                try Task.checkCancellation()
                let finalStatus = self.cachedStatus(for: model)
                self.statuses[model.id] = finalStatus
                // Auto-activate on success
                if finalStatus.isReady {
                    ActiveModelPreference.setActive(model.id)
                }
            } catch is CancellationError {
                self.statuses[model.id] = .notDownloaded
            } catch {
                let message = Self.userFriendlyError(error)
                self.statuses[model.id] = .failed(message: message)
            }
            continuation.finish()
            self.activeTasks[model.id] = nil
        }

        activeTasks[model.id] = task
        return stream
    }

    // MARK: - Cancel

    /// Cancels an in-progress download.
    func cancelDownload(_ model: LocalModel) {
        activeTasks[model.id]?.cancel()
        activeTasks[model.id] = nil
        statuses[model.id] = .notDownloaded
    }

    // MARK: - Delete

    /// Removes a downloaded model from the cache.
    func deleteModel(_ model: LocalModel) {
        activeTasks[model.id]?.cancel()
        activeTasks[model.id] = nil

        if let cacheDirectory {
            let modelCacheURL = cacheDirectory.appendingPathComponent(model.cacheFolderName, isDirectory: true)
            try? fileManager.removeItem(at: modelCacheURL)
        }
        statuses[model.id] = .notDownloaded

        // Clear active preference if this was the active model
        if ActiveModelPreference.current() == model.id {
            ActiveModelPreference.clear()
        }
    }

    // MARK: - Retry

    /// Retries a failed download (HubClient auto-resumes from partial cache).
    @discardableResult
    func retryDownload(_ model: LocalModel) -> AsyncStream<ModelDownloadProgress> {
        download(model)
    }

    // MARK: - Disk Space Preflight

    private func diskSpacePreflightError(for model: LocalModel) -> String? {
        guard let cacheDirectory else { return nil }
        let requiredBytes = Int64(model.estimatedSizeGB * 1.2 * 1_073_741_824)
        do {
            let values = try cacheDirectory.resourceValues(
                forKeys: [.volumeAvailableCapacityForImportantUsageKey]
            )
            guard let available = values.volumeAvailableCapacityForImportantUsage else {
                return nil
            }
            if available < requiredBytes {
                let needGB = String(format: "%.1f", model.estimatedSizeGB * 1.2)
                let haveGB = String(format: "%.1f", Double(available) / 1_073_741_824)
                return "Not enough disk space (need \(needGB) GB, have \(haveGB) GB)"
            }
        } catch {
            // Non-fatal: proceed with download attempt
        }
        return nil
    }

    // MARK: - Helpers

    private static func userFriendlyError(_ error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                return "No internet connection"
            case NSURLErrorTimedOut:
                return "Connection timed out"
            case NSURLErrorNetworkConnectionLost:
                return "Network connection lost"
            default:
                return "Network error: \(nsError.localizedDescription)"
            }
        }
        return error.localizedDescription
    }

    private func directorySize(at url: URL) -> UInt64 {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total: UInt64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                  values.isRegularFile == true,
                  let fileSize = values.fileSize else { continue }
            total += UInt64(fileSize)
        }
        return total
    }
}
