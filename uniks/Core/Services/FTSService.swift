//
//  FTSService.swift
//  uniks
//
//  Full-text search over raw HabitEvent inputs using SQLite FTS5.
//

import Foundation

#if canImport(SwiftFTS)
import SwiftFTS
#endif

/// A lightweight document wrapper for indexing `HabitEvent.rawInput`.
#if canImport(SwiftFTS)
struct HabitEventFTSDocument: FullTextSearchable {
    struct Metadata: Codable, Sendable {
        let eventID: String
    }

    let id: String
    let rawInput: String
    let metadata: Metadata?

    var indexItemID: String { id }
    var indexText: String { rawInput }
    var indexMetadata: Metadata? { metadata }
}
#endif

/// Actor that manages FTS5 indexing and search for raw habit event inputs.
actor FTSService {
    #if canImport(SwiftFTS)
    private let databaseQueue: FTSDatabaseQueue
    private let indexer: SearchIndexer
    private let engine: SearchEngine
    #endif

    /// Initializes the FTS service with an on-disk or in-memory database.
    /// - Parameter path: File URL for the FTS database. Pass `nil` for an in-memory index.
    init(path: URL? = nil) throws {
        #if canImport(SwiftFTS)
        if let path {
            databaseQueue = try FTSDatabaseQueue(path: path.path)
        } else {
            databaseQueue = try FTSDatabaseQueue.makeInMemory()
        }
        indexer = try SearchIndexer(databaseQueue: databaseQueue)
        engine = SearchEngine(databaseQueue: databaseQueue)
        #else
        // SwiftFTS is not linked; the service becomes a no-op.
        #endif
    }

    /// Indexes a single event's raw input.
    func index(event: HabitEvent) async throws {
        #if canImport(SwiftFTS)
        let document = HabitEventFTSDocument(
            id: event.id.uuidString,
            rawInput: event.rawInput,
            metadata: .init(eventID: event.id.uuidString)
        )
        try await indexer.addItems([document])
        #endif
    }

    /// Indexes multiple events.
    func index(events: [HabitEvent]) async throws {
        #if canImport(SwiftFTS)
        let documents = events.map {
            HabitEventFTSDocument(
                id: $0.id.uuidString,
                rawInput: $0.rawInput,
                metadata: .init(eventID: $0.id.uuidString)
            )
        }
        try await indexer.addItems(documents)
        #endif
    }

    /// Searches raw inputs and returns matching `HabitEvent` identifiers.
    func search(query: String) async throws -> [UUID] {
        #if canImport(SwiftFTS)
        let results: [HabitEventFTSDocument] = try await engine.search(
            query: query,
            factory: { item in
                HabitEventFTSDocument(
                    id: item.id,
                    rawInput: item.text,
                    metadata: try? item.metadata()
                )
            }
        )
        return results.compactMap { UUID(uuidString: $0.id) }
        #else
        return []
        #endif
    }

    /// Removes an event from the FTS index.
    func remove(eventID: UUID) async throws {
        #if canImport(SwiftFTS)
        try await indexer.removeItem(id: eventID.uuidString)
        #endif
    }
}
