//
//  LocalModelManagerTests.swift
//  uniksTests
//
//  Unit tests for local model cache-status detection.
//

import Foundation
import Testing
@testable import uniks

@MainActor
struct LocalModelManagerTests {

    @Test func statusIsNotDownloadedWhenCacheMissing() async {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let manager = LocalModelManager(cacheDirectoryOverride: tempDir)

        let model = LocalModel(id: "test/missing", name: "Missing", estimatedSizeGB: 1.0)
        let status = await manager.status(for: model)

        #expect(status == .notDownloaded)
    }

    @Test func statusIsDownloadedWithCorrectSize() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let model = LocalModel(id: "test/present", name: "Present", estimatedSizeGB: 1.0)
        let modelDir = tempDir.appendingPathComponent(model.cacheFolderName, isDirectory: true)
        try FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true)

        let data = Data(repeating: 0, count: 1_024)
        let fileURL = modelDir.appendingPathComponent("config.json")
        try data.write(to: fileURL)

        let manager = LocalModelManager(cacheDirectoryOverride: tempDir)
        let status = await manager.status(for: model)

        #expect(status == .downloaded(size: 1_024))
    }

    @Test func refreshStatusesUpdatesAllModels() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let manager = LocalModelManager(cacheDirectoryOverride: tempDir)

        // Pre-seed the cache for the first built-in model.
        let model = LocalModel.allModels[0]
        let modelDir = tempDir.appendingPathComponent(model.cacheFolderName, isDirectory: true)
        try FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true)
        try Data(repeating: 0, count: 100).write(to: modelDir.appendingPathComponent("file.bin"))

        await manager.refreshStatuses()

        #expect(await manager.statuses[model.id] == .downloaded(size: 100))

        let otherModel = LocalModel.allModels[1]
        #expect(await manager.statuses[otherModel.id] == .notDownloaded)
    }
}
