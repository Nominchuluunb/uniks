//
//  FTSService.swift
//  uniks
//
//  Full-text search over raw HabitEvent inputs using SQLite FTS5.
//

import Foundation
import SwiftFTS

/// A lightweight document wrapper for indexing `HabitEvent.rawInput`.
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

/// Actor that manages FTS5 indexing and search for raw habit event inputs.
actor FTSService {
    private let databaseQueue: FTSDatabaseQueue
    private let indexer: SearchIndexer
    private let engine: SearchEngine

    /// Initializes the FTS service with an on-disk or in-memory database.
    /// - Parameter path: File URL for the FTS database. Pass `nil` for an in-memory index.
    init(path: URL? = nil) throws {
        if let path {
            databaseQueue = try FTSDatabaseQueue(path: path.path)
        } else {
            databaseQueue = try FTSDatabaseQueue.makeInMemory()
        }
        indexer = try SearchIndexer(databaseQueue: databaseQueue)
        engine = try SearchEngine(databaseQueue: databaseQueue)
    }

    /// Indexes a single event's raw input.
    func index(event: HabitEvent) async throws {
        let document = HabitEventFTSDocument(
            id: event.id.uuidString,
            rawInput: event.rawInput,
            metadata: .init(eventID: event.id.uuidString)
        )
        try await indexer.addItems([document])
    }

    /// Indexes multiple events.
    func index(events: [HabitEvent]) async throws {
        let documents = events.map {
            HabitEventFTSDocument(
                id: $0.id.uuidString,
                rawInput: $0.rawInput,
                metadata: .init(eventID: $0.id.uuidString)
            )
        }
        try await indexer.addItems(documents)
    }

    /// Searches raw inputs and returns matching `HabitEvent` identifiers.
    func search(query: String) async throws -> [UUID] {
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
    }

    /// Removes an event from the FTS index.
    func remove(eventID: UUID) async throws {
        try await indexer.removeItem(id: eventID.uuidString)
    }
}
