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
        let engine = MockLLMEngine(result: HabitParseResult(category: "fitness", value: 5, unit: "km"))
        let parser = ParsingActor(container: container, engine: engine)
        let fts = try FTSService()
        let service = HabitEventService(container: container, parsingActor: parser, ftsService: fts)

        let eventID = try await service.log(rawInput: "Ran 5km")

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitEvent>(predicate: #Predicate { $0.id == eventID })
        let event = try #require(try context.fetch(descriptor).first)

        #expect(event.rawInput == "Ran 5km")
        #expect(event.state == .pending)
    }

    @Test func logIndexesRawInputForSearch() async throws {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let engine = MockLLMEngine(result: HabitParseResult())
        let parser = ParsingActor(container: container, engine: engine)
        let fts = try FTSService()
        let service = HabitEventService(container: container, parsingActor: parser, ftsService: fts)

        let eventID = try await service.log(rawInput: "Drank 500ml water")
        let results = try await fts.search(query: "water")

        #expect(results.contains(eventID))
    }

    @Test func deleteRemovesEventAndIndex() async throws {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let engine = MockLLMEngine(result: HabitParseResult())
        let parser = ParsingActor(container: container, engine: engine)
        let fts = try FTSService()
        let service = HabitEventService(container: container, parsingActor: parser, ftsService: fts)

        let eventID = try await service.log(rawInput: "Meditated")
        try await service.delete(eventID: eventID)

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitEvent>(predicate: #Predicate { $0.id == eventID })
        #expect(try context.fetch(descriptor).isEmpty)

        let results = try await fts.search(query: "Meditated")
        #expect(results.isEmpty)
    }
}
