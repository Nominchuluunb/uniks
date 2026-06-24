//
//  FTSService.swift
//  uniks
//
//  Full-text search over raw HabitEvent inputs using SQLite FTS5.
//

import Foundation
// SwiftFTS is not yet Sendable-annotated; @preconcurrency keeps actor isolation clean.
@preconcurrency import SwiftFTS

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

/// Protocol abstraction for full-text indexing services so callers can depend
/// on a capability rather than a concrete type.
protocol FTSServiceProtocol: Sendable {
    /// Indexes a single event's raw input.
    func index(eventID: UUID, rawInput: String) async throws

    /// Indexes multiple events' raw inputs.
    func index(events: [(id: UUID, rawInput: String)]) async throws

    /// Searches raw inputs and returns matching event identifiers.
    func search(query: String) async throws -> [UUID]

    /// Removes an event from the FTS index.
    func remove(eventID: UUID) async throws
}

/// Actor that manages FTS5 indexing and search for raw habit event inputs.
actor FTSService: FTSServiceProtocol {
    private let databaseQueue: FTSDatabaseQueue
    private let indexer: SearchIndexer
    private let engine: SearchEngine

    /// Initializes the FTS service with an on-disk or in-memory database.
    /// - Parameter path: File URL for the FTS database. Pass `nil` for an in-memory index.
    init(path: URL? = nil) throws {
        if let path {
            self.databaseQueue = try FTSDatabaseQueue(path: path.path)
        } else {
            self.databaseQueue = try FTSDatabaseQueue.makeInMemory()
        }
        self.indexer = try SearchIndexer(databaseQueue: self.databaseQueue)
        self.engine = SearchEngine(databaseQueue: self.databaseQueue)
    }

    /// Creates an in-memory FTS service. Never fails; useful for previews and fallbacks.
    static func inMemory() -> any FTSServiceProtocol {
        (try? FTSService(path: nil)) ?? NoOpFTSService()
    }

    /// Closes the underlying FTS database queue.
    /// Call this when the service is no longer needed to release resources.
    func close() {
        self.databaseQueue.close()
    }

    /// Indexes a single event's raw input.
    /// - Parameters:
    ///   - eventID: The unique identifier of the event.
    ///   - rawInput: The raw text to index.
    func index(eventID: UUID, rawInput: String) async throws {
        let document = Self.document(eventID: eventID, rawInput: rawInput)
        try await self.indexer.addItems([document])
    }

    /// Indexes multiple events' raw inputs.
    /// - Parameter events: A tuple array of event identifiers and raw inputs.
    func index(events: [(id: UUID, rawInput: String)]) async throws {
        let documents = events.map { Self.document(eventID: $0.id, rawInput: $0.rawInput) }
        try await self.indexer.addItems(documents)
    }

    /// Searches raw inputs and returns matching `HabitEvent` identifiers.
    /// - Parameter query: The search query text.
    /// - Returns: The identifiers of events whose raw input matches the query.
    func search(query: String) async throws -> [UUID] {
        let results: [HabitEventFTSDocument] = try await self.engine.search(
            query: query,
            factory: { item in
                HabitEventFTSDocument(
                    id: item.id,
                    rawInput: item.text,
                    metadata: try item.metadata()
                )
            }
        )
        return results.compactMap { UUID(uuidString: $0.id) }
    }

    /// Removes an event from the FTS index.
    /// - Parameter eventID: The unique identifier of the event to remove.
    func remove(eventID: UUID) async throws {
        try await self.indexer.removeItem(id: eventID.uuidString)
    }

    // MARK: - Private helpers

    private static func document(eventID: UUID, rawInput: String) -> HabitEventFTSDocument {
        HabitEventFTSDocument(
            id: eventID.uuidString,
            rawInput: rawInput,
            metadata: .init(eventID: eventID.uuidString)
        )
    }
}

// MARK: - No-op fallback

private actor NoOpFTSService: FTSServiceProtocol {
    func index(eventID: UUID, rawInput: String) async throws {}
    func index(events: [(id: UUID, rawInput: String)]) async throws {}
    func search(query: String) async throws -> [UUID] { [] }
    func remove(eventID: UUID) async throws {}
}
