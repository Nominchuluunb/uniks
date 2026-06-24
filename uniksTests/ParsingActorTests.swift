//
//  ParsingActorTests.swift
//  uniksTests
//
//  Unit tests for background parsing state transitions.
//

import Foundation
import SwiftData
import Testing
@testable import uniks

struct ParsingActorTests {

    @Test func parsingActorTransitionsPendingToParsed() async throws {
        let engine = MockLLMEngine(
            result: HabitParseResult(
                category: "fitness",
                value: 5,
                unit: "km",
                tags: ["run"],
                notes: nil
            )
        )
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let actor = ParsingActor(container: container, engine: engine)

        let event = HabitEvent(rawInput: "Ran 5km")
        let context = ModelContext(container)
        context.insert(event)
        try context.save()

        await actor.parseAndSave(eventID: event.id)

        let eventID = event.id
        let descriptor = FetchDescriptor<HabitEvent>(predicate: #Predicate { $0.id == eventID })
        let fetched = try #require(try context.fetch(descriptor).first)

        #expect(fetched.state == .parsed)
        #expect(fetched.parsedPayloadJSON != nil)

        let payload = try #require(fetched.parsedPayload())
        #expect(payload.category == "fitness")
        #expect(payload.value == 5)
    }

    @Test func parsingActorTransitionsToFailedOnError() async throws {
        let engine = MockLLMEngine(result: HabitParseResult(), shouldFail: true)
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let actor = ParsingActor(container: container, engine: engine)

        let event = HabitEvent(rawInput: "Bad input")
        let context = ModelContext(container)
        context.insert(event)
        try context.save()

        await actor.parseAndSave(eventID: event.id)

        let eventID = event.id
        let descriptor = FetchDescriptor<HabitEvent>(predicate: #Predicate { $0.id == eventID })
        let fetched = try #require(try context.fetch(descriptor).first)

        #expect(fetched.state == .failed)
    }
}
