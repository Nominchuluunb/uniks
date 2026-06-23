//
//  FTSServiceTests.swift
//  uniksTests
//
//  Unit tests for the full-text search service over raw habit inputs.
//

import Foundation
import Testing
@testable import uniks

struct FTSServiceTests {

    @Test func indexesAndFindsSingleEvent() async throws {
        let service = try FTSService()
        let eventID = UUID()

        try await service.index(eventID: eventID, rawInput: "Drank 500ml water")
        let results = try await service.search(query: "water")

        #expect(results.count == 1)
        #expect(results.first == eventID)
    }

    @Test func indexesAndFindsMultipleEvents() async throws {
        let service = try FTSService()
        let waterID = UUID()
        let runID = UUID()

        try await service.index(events: [
            (id: waterID, rawInput: "Drank 500ml water"),
            (id: runID, rawInput: "Ran 5km in the morning")
        ])

        let waterResults = try await service.search(query: "water")
        let runResults = try await service.search(query: "morning")

        #expect(waterResults.count == 1)
        #expect(waterResults.first == waterID)
        #expect(runResults.count == 1)
        #expect(runResults.first == runID)
    }

    @Test func searchReturnsEmptyArrayForNoMatch() async throws {
        let service = try FTSService()
        let eventID = UUID()

        try await service.index(eventID: eventID, rawInput: "Drank coffee")
        let results = try await service.search(query: "tea")

        #expect(results.isEmpty)
    }

    @Test func removeDeletesEventFromIndex() async throws {
        let service = try FTSService()
        let eventID = UUID()

        try await service.index(eventID: eventID, rawInput: "Meditated for 10 minutes")
        let indexedResults = try await service.search(query: "meditated")
        #expect(indexedResults.count == 1)

        try await service.remove(eventID: eventID)
        let results = try await service.search(query: "meditated")

        #expect(results.isEmpty)
    }
}
