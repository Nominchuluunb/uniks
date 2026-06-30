//
//  LocalModelManagerTests.swift
//  uniksTests
//
//  Unit tests for local model management: catalog, status, download, cancel.
//

import Foundation
import Testing
@testable import uniks

/// Mock downloader that emits scripted progress and completes.
struct MockModelDownloader: ModelDownloaderProtocol {
    let shouldFail: Bool
    let progressSteps: [Double]

    init(shouldFail: Bool = false, progressSteps: [Double] = [0.0, 0.5, 1.0]) {
        self.shouldFail = shouldFail
        self.progressSteps = progressSteps
    }

    func download(
        modelID: String,
        progressContinuation: AsyncStream<ModelDownloadProgress>.Continuation
    ) async throws -> URL {
        for step in progressSteps {
            try Task.checkCancellation()
            let progress = ModelDownloadProgress(
                fractionCompleted: step,
                completedBytes: Int64(step * 600_000_000),
                totalBytes: 600_000_000,
                phase: .downloading
            )
            progressContinuation.yield(progress)
            try await Task.sleep(for: .milliseconds(10))
        }
        if shouldFail {
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        }
        return FileManager.default.temporaryDirectory
    }
}

struct LocalModelManagerTests {

    // MARK: - Catalog Integrity

    @Test func catalogContainsDefaultModel() {
        let defaultModel = LocalModel.allModels.first(where: \.isDefault)
        #expect(defaultModel != nil)
        #expect(defaultModel?.family == "Gemma")
    }

    @Test func allModelsHaveValidIDs() {
        for model in LocalModel.allModels {
            #expect(model.id.contains("/"))
            #expect(!model.name.isEmpty)
            #expect(model.estimatedSizeGB > 0)
        }
    }

    // MARK: - Status Display Text

    @Test func statusDisplayTextForEachState() {
        let notDownloaded = LocalModelStatus.notDownloaded
        #expect(notDownloaded.displayText == "Not downloaded")

        let queued = LocalModelStatus.queued
        #expect(queued.displayText == "Queued…")

        let progress = ModelDownloadProgress(
            fractionCompleted: 0.45,
            completedBytes: 312_000_000,
            totalBytes: 693_000_000,
            phase: .downloading
        )
        let downloading = LocalModelStatus.downloading(progress)
        #expect(downloading.displayText.contains("45%"))
        #expect(downloading.displayText.contains("312 MB"))

        let downloaded = LocalModelStatus.downloaded(size: 629_145_600)
        #expect(downloaded.displayText.contains("Downloaded"))

        let failed = LocalModelStatus.failed(message: "No internet")
        #expect(failed.displayText.contains("No internet"))
    }

    // MARK: - Cache Status Detection

    @Test func statusIsNotDownloadedWhenCacheMissing() async {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let manager = LocalModelManager(
            downloader: MockModelDownloader(),
            cacheDirectoryOverride: tempDir
        )

        await manager.refreshStatuses()
        let status = await manager.statuses[LocalModel.allModels[0].id]
        #expect(status == .notDownloaded)
    }

    @Test func statusIsDownloadedWithCorrectSize() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let model = LocalModel.allModels[0]
        let modelDir = tempDir.appendingPathComponent(model.cacheFolderName, isDirectory: true)
        try FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true)

        let data = Data(repeating: 0, count: 1_024)
        try data.write(to: modelDir.appendingPathComponent("model.safetensors"))

        let manager = LocalModelManager(
            downloader: MockModelDownloader(),
            cacheDirectoryOverride: tempDir
        )
        await manager.refreshStatuses()

        let status = await manager.statuses[model.id]
        #expect(status == .downloaded(size: 1_024))
    }

    @Test func statusIsNotDownloadedWhenWeightsMissing() async throws {
        // A partial download that fetched only metadata (no `.safetensors`
        // weights) must be treated as not downloaded.
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let model = LocalModel.allModels[0]
        let modelDir = tempDir.appendingPathComponent(model.cacheFolderName, isDirectory: true)
        try FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true)

        try Data(repeating: 0, count: 512).write(to: modelDir.appendingPathComponent("config.json"))
        try Data(repeating: 0, count: 512)
            .write(to: modelDir.appendingPathComponent("model.safetensors.index.json"))

        let manager = LocalModelManager(
            downloader: MockModelDownloader(),
            cacheDirectoryOverride: tempDir
        )
        await manager.refreshStatuses()

        let status = await manager.statuses[model.id]
        #expect(status == .notDownloaded)
    }

    // MARK: - Download Progress

    @Test func downloadEmitsProgressAndCompletes() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        // Create model dir so post-download check finds it
        let model = LocalModel.allModels[0]
        let modelDir = tempDir.appendingPathComponent(model.cacheFolderName, isDirectory: true)
        try FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true)
        try Data(repeating: 0, count: 512).write(to: modelDir.appendingPathComponent("model.safetensors"))

        let manager = LocalModelManager(
            downloader: MockModelDownloader(progressSteps: [0.0, 0.5, 1.0]),
            cacheDirectoryOverride: tempDir
        )

        let stream = await manager.download(model)
        var progressValues: [Double] = []
        for await progress in stream {
            progressValues.append(progress.fractionCompleted)
        }

        #expect(progressValues.contains(0.0))
        #expect(progressValues.contains(0.5))

        let finalStatus = await manager.statuses[model.id]
        #expect(finalStatus == .downloaded(size: 512))
    }

    // MARK: - Error Handling

    @Test func downloadFailureSetsFailedStatus() async {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let manager = LocalModelManager(
            downloader: MockModelDownloader(shouldFail: true),
            cacheDirectoryOverride: tempDir
        )

        let model = LocalModel.allModels[0]
        let stream = await manager.download(model)
        for await _ in stream {} // consume

        let status = await manager.statuses[model.id]
        if case .failed(let msg) = status {
            #expect(msg.contains("internet") || msg.contains("Internet"))
        } else {
            #expect(Bool(false), "Expected failed status")
        }
    }

    // MARK: - Cancel

    @Test func cancelDownloadSetsNotDownloaded() async {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let manager = LocalModelManager(
            downloader: MockModelDownloader(progressSteps: [0.0, 0.1, 0.2, 0.3, 0.4]),
            cacheDirectoryOverride: tempDir
        )

        let model = LocalModel.allModels[0]
        _ = await manager.download(model)

        // Cancel immediately
        await manager.cancelDownload(model)
        let status = await manager.statuses[model.id]
        #expect(status == .notDownloaded)
    }

    // MARK: - Delete

    @Test func deleteModelRemovesCacheAndStatus() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let model = LocalModel.allModels[0]
        let modelDir = tempDir.appendingPathComponent(model.cacheFolderName, isDirectory: true)
        try FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true)
        try Data(repeating: 0, count: 100).write(to: modelDir.appendingPathComponent("model.safetensors"))

        let manager = LocalModelManager(
            downloader: MockModelDownloader(),
            cacheDirectoryOverride: tempDir
        )
        await manager.refreshStatuses()
        #expect(await manager.statuses[model.id] == .downloaded(size: 100))

        await manager.deleteModel(model)
        #expect(await manager.statuses[model.id] == .notDownloaded)
        #expect(!FileManager.default.fileExists(atPath: modelDir.path))
    }
}
