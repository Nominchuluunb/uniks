//
//  HabitEventServiceTests.swift
//  uniksTests
//
//  Unit tests for the habit event ingestion service.
//

import Foundation
import SwiftData
import Testing
@testable import uniks

struct HabitEventServiceTests {

    @Test func logInsertsEventWithPendingState() async throws {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let parser = MockParsingActor()
        let fts = MockFTSService()
        let service = HabitEventService(container: container, parsingActor: parser, ftsService: fts)

        let eventID = try await service.log(rawInput: "Ran 5km")
        let parsedID = await parser.waitForParse()

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitEvent>(predicate: #Predicate { $0.id == eventID })
        let event = try #require(try context.fetch(descriptor).first)

        let containsParsedID = await parser.parsedEventIDs.contains(eventID)
        #expect(event.rawInput == "Ran 5km")
        #expect(event.state == .pending)
        #expect(parsedID == eventID)
        #expect(containsParsedID)
    }

    @Test func logIndexesRawInputForSearch() async throws {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let parser = MockParsingActor()
        let fts = MockFTSService()
        let service = HabitEventService(container: container, parsingActor: parser, ftsService: fts)

        let eventID = try await service.log(rawInput: "Drank 500ml water")
        let results = try await fts.search(query: "water")

        #expect(results.contains(eventID))
    }

    @Test func deleteRemovesEventAndIndex() async throws {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let parser = MockParsingActor()
        let fts = MockFTSService()
        let service = HabitEventService(container: container, parsingActor: parser, ftsService: fts)

        let eventID = try await service.log(rawInput: "Meditated")
        try await service.delete(eventID: eventID)

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitEvent>(predicate: #Predicate { $0.id == eventID })
        #expect(try context.fetch(descriptor).isEmpty)

        let results = try await fts.search(query: "Meditated")
        #expect(results.isEmpty)
    }

    @Test func deleteMissingEventIsSilent() async throws {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let parser = MockParsingActor()
        let fts = MockFTSService()
        let service = HabitEventService(container: container, parsingActor: parser, ftsService: fts)

        let unknownID = UUID()
        try await service.delete(eventID: unknownID)

        let parserIDs = await parser.parsedEventIDs
        let ftsIDs = await fts.indexedEventIDs
        #expect(parserIDs.isEmpty)
        #expect(ftsIDs.isEmpty)
    }

    @Test func updateSetsParsedPayloadAndState() async throws {
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
        let event = try #require(try context.fetch(descriptor).first)

        #expect(event.state == .parsed)
        #expect(event.parsedPayload()?.category == "fitness")
        #expect(event.parsedPayload()?.value == 5)
        #expect(event.parsedPayload()?.unit == "km")
        #expect(event.parsedPayload()?.tags == ["run"])
    }

    @Test func retryParsingSetsPendingAndTriggersParse() async throws {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let parser = MockParsingActor()
        let fts = MockFTSService()
        let service = HabitEventService(container: container, parsingActor: parser, ftsService: fts)

        let eventID = try await service.log(rawInput: "Ran 5km")
        try await service.update(eventID: eventID, payload: HabitParseResult())
        let initialParsedIDs = await parser.parsedEventIDs
        #expect(initialParsedIDs.contains(eventID))

        try await service.retryParsing(eventID: eventID)

        let context = ModelContext(container)
        let eventIDValue = eventID
        let descriptor = FetchDescriptor<HabitEvent>(
            predicate: #Predicate { $0.id == eventIDValue }
        )
        let event = try #require(try context.fetch(descriptor).first)

        #expect(event.state == .pending)
        _ = await parser.waitForParse()
        let retryParsedCount = await parser.parsedEventIDs.filter { $0 == eventID }.count
        #expect(retryParsedCount >= 2)
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
