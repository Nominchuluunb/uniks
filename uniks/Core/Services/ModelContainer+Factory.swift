//
//  ModelContainer+Factory.swift
//  uniks
//
//  Centralized SwiftData container configuration.
//

import Foundation
import SwiftData

extension ModelContainer {
    /// Creates the canonical SwiftData container for Uniks.
    /// - Parameter inMemory: When `true`, uses an in-memory store (useful for previews and tests).
    /// - Returns: A configured `ModelContainer` for all Uniks models.
    static func uniksContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: UniksSchemaV3.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: UniksMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            // In-memory stores have nothing to recover from — surface the error.
            guard !inMemory else { throw error }

            // The on-disk store could not be opened or migrated to the current
            // schema (e.g. it predates the versioned schema or was written by an
            // incompatible build, producing SwiftData error 134504 "unknown model
            // version"). Rather than crash-loop on launch, move the incompatible
            // store aside so it is preserved for manual recovery, then create a
            // fresh store at the current schema version.
            try relocateIncompatibleStore(at: configuration.url)
            return try ModelContainer(
                for: schema,
                migrationPlan: UniksMigrationPlan.self,
                configurations: [configuration]
            )
        }
    }

    /// Moves an unreadable/unmigratable store and its SQLite sidecar files aside,
    /// renaming them with a timestamped `.incompatible-*` suffix. Non-destructive:
    /// the original data is retained on disk for manual inspection or recovery.
    private static func relocateIncompatibleStore(at storeURL: URL) throws {
        let fileManager = FileManager.default
        let directory = storeURL.deletingLastPathComponent()
        let storeName = storeURL.lastPathComponent
        let stamp = Int(Date().timeIntervalSince1970)

        // SwiftData/SQLite persists the store plus -wal and -shm sidecar files.
        for suffix in ["", "-wal", "-shm"] {
            let source = directory.appendingPathComponent(storeName + suffix)
            guard fileManager.fileExists(atPath: source.path) else { continue }
            let destination = directory.appendingPathComponent(
                "\(storeName)\(suffix).incompatible-\(stamp)"
            )
            try fileManager.moveItem(at: source, to: destination)
        }
    }
}
