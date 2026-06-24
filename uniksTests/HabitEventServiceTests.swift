//
//  HabitEventServiceTests.swift
//  uniksTests
//
//  Unit tests for the habit event ingestion service.
//

import Foundation
import SwiftData
import XCTest
@testable import uniks

final class HabitEventServiceTests: XCTestCase {

    func testLogInsertsEventWithPendingState() async throws {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let parser = MockParsingActor()
        let fts = MockFTSService()
        let service = HabitEventService(container: container, parsingActor: parser, ftsService: fts)

        let eventID = try await service.log(rawInput: "Ran 5km")
        let parsedID = await parser.waitForParse()

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitEvent>(predicate: #Predicate { $0.id == eventID })
        let event = try XCTUnwrap(try context.fetch(descriptor).first)

        let containsParsedID = await parser.parsedEventIDs.contains(eventID)
        XCTAssertEqual(event.rawInput, "Ran 5km")
        XCTAssertEqual(event.state, .pending)
        XCTAssertEqual(parsedID, eventID)
        XCTAssertTrue(containsParsedID)
    }

    func testLogIndexesRawInputForSearch() async throws {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let parser = MockParsingActor()
        let fts = MockFTSService()
        let service = HabitEventService(container: container, parsingActor: parser, ftsService: fts)

        let eventID = try await service.log(rawInput: "Drank 500ml water")
        let results = try await fts.search(query: "water")

        XCTAssertTrue(results.contains(eventID))
    }

    func testDeleteRemovesEventAndIndex() async throws {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let parser = MockParsingActor()
        let fts = MockFTSService()
        let service = HabitEventService(container: container, parsingActor: parser, ftsService: fts)

        let eventID = try await service.log(rawInput: "Meditated")
        try await service.delete(eventID: eventID)

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitEvent>(predicate: #Predicate { $0.id == eventID })
        XCTAssertTrue(try context.fetch(descriptor).isEmpty)

        let results = try await fts.search(query: "Meditated")
        XCTAssertTrue(results.isEmpty)
    }

    func testDeleteMissingEventIsSilent() async throws {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let parser = MockParsingActor()
        let fts = MockFTSService()
        let service = HabitEventService(container: container, parsingActor: parser, ftsService: fts)

        let unknownID = UUID()
        try await service.delete(eventID: unknownID)

        let parserIDs = await parser.parsedEventIDs
        let ftsIDs = await fts.indexedEventIDs
        XCTAssertTrue(parserIDs.isEmpty)
        XCTAssertTrue(ftsIDs.isEmpty)
    }

    func testUpdateSetsParsedPayloadAndState() async throws {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let parser = MockParsingActor()
        let fts = MockFTSService()
        let service = HabitEventService(container: container, parsingActor: parser, ftsService: fts)

        let eventID = try await service.log(rawInput: "Ran 5km")
        let payload = HabitParseResult(category: "fitness", value: 5, unit: "km", tags: ["run"], notes: "")
        try await service.update(eventID: eventID, payload: payload)

        let context = ModelContext(container)
        let eventIDValue = eventID
        let descriptor = FetchDescriptor<HabitEvent>(
            predicate: #Predicate { $0.id == eventIDValue }
        )
        let event = try XCTUnwrap(try context.fetch(descriptor).first)

        XCTAssertEqual(event.state, .parsed)
        XCTAssertEqual(event.parsedPayload()?.category, "fitness")
        XCTAssertEqual(event.parsedPayload()?.value, 5)
        XCTAssertEqual(event.parsedPayload()?.unit, "km")
        XCTAssertEqual(event.parsedPayload()?.tags, ["run"])
    }

    func testRetryParsingSetsPendingAndTriggersParse() async throws {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let parser = MockParsingActor()
        let fts = MockFTSService()
        let service = HabitEventService(container: container, parsingActor: parser, ftsService: fts)

        let eventID = try await service.log(rawInput: "Ran 5km")
        try await service.update(eventID: eventID, payload: HabitParseResult())
        let initialParsedIDs = await parser.parsedEventIDs
        XCTAssertTrue(initialParsedIDs.contains(eventID))

        try await service.retryParsing(eventID: eventID)

        let context = ModelContext(container)
        let eventIDValue = eventID
        let descriptor = FetchDescriptor<HabitEvent>(
            predicate: #Predicate { $0.id == eventIDValue }
        )
        let event = try XCTUnwrap(try context.fetch(descriptor).first)

        XCTAssertEqual(event.state, .pending)
        _ = await parser.waitForParse()
        let retryParsedCount = await parser.parsedEventIDs.filter { $0 == eventID }.count
        XCTAssertGreaterThanOrEqual(retryParsedCount, 2)
    }
}

// MARK: - Mocks

private actor MockParsingActor: ParsingActorProtocol {
    private(set) var parsedEventIDs: [UUID] = []
    private var consumedCount = 0
    private var continuation: CheckedContinuation<UUID, Never>?

    func parseAndSave(eventID: UUID) async {
        self.parsedEventIDs.append(eventID)
        if let continuation = self.continuation {
            self.continuation = nil
            self.consumedCount += 1
            continuation.resume(returning: eventID)
        }
    }

    func waitForParse() async -> UUID {
        if self.consumedCount < self.parsedEventIDs.count {
            let eventID = self.parsedEventIDs[self.consumedCount]
            self.consumedCount += 1
            return eventID
        }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }
}

private actor MockFTSService: FTSServiceProtocol {
    private var index: [UUID: String] = [:]

    var indexedEventIDs: [UUID] {
        Array(self.index.keys)
    }

    func index(eventID: UUID, rawInput: String) async throws {
        self.index[eventID] = rawInput
    }

    func index(events: [(id: UUID, rawInput: String)]) async throws {
        for event in events {
            self.index[event.id] = event.rawInput
        }
    }

    func remove(eventID: UUID) async throws {
        self.index.removeValue(forKey: eventID)
    }

    func search(query: String) async throws -> [UUID] {
        let lowercasedQuery = query.lowercased()
        return self.index.compactMap { eventID, rawInput in
            rawInput.lowercased().contains(lowercasedQuery) ? eventID : nil
        }
    }
}
