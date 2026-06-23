//
//  HabitEventServiceTests.swift
//  uniksTests
//
//  Unit tests for the habit event ingestion service.
//

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

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitEvent>(predicate: #Predicate { $0.id == eventID })
        let event = try #require(try context.fetch(descriptor).first)

        #expect(event.rawInput == "Ran 5km")
        #expect(event.state == .pending)
        #expect(await parser.parsedEventIDs.contains(eventID))
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

        #expect(await parser.parsedEventIDs.isEmpty)
        #expect(await fts.indexedEventIDs.isEmpty)
    }
}

// MARK: - Mocks

private actor MockParsingActor: ParsingActorProtocol {
    private(set) var parsedEventIDs: [UUID] = []

    func parseAndSave(eventID: UUID) async {
        parsedEventIDs.append(eventID)
    }
}

private actor MockFTSService: FTSServiceProtocol {
    private var index: [UUID: String] = [:]

    var indexedEventIDs: [UUID] {
        Array(index.keys)
    }

    func index(eventID: UUID, rawInput: String) async throws {
        index[eventID] = rawInput
    }

    func remove(eventID: UUID) async throws {
        index.removeValue(forKey: eventID)
    }

    func search(query: String) async throws -> [UUID] {
        let lowercasedQuery = query.lowercased()
        return index.compactMap { eventID, rawInput in
            rawInput.lowercased().contains(lowercasedQuery) ? eventID : nil
        }
    }
}
