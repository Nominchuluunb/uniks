//
//  HabitEventTests.swift
//  uniksTests
//
//  Unit tests for the HabitEvent model and payload helpers.
//

import Foundation
import Testing
@testable import uniks

struct HabitEventTests {

    @Test func eventInitializesWithPendingState() {
        let event = HabitEvent(rawInput: "Drank 500ml water")

        #expect(event.rawInput == "Drank 500ml water")
        #expect(event.state == .pending)
        #expect(event.parsedPayloadJSON == nil)
    }

    @Test func payloadRoundTripsThroughJSONColumn() throws {
        let event = HabitEvent(rawInput: "Ran 5km")
        let result = HabitParseResult(
            category: "fitness",
            value: 5,
            unit: "km",
            tags: ["run", "morning"],
            notes: "steady pace"
        )

        event.setParsedPayload(result)

        #expect(event.parsedPayloadJSON != nil)
        let decoded = try #require(event.parsedPayload())
        #expect(decoded.category == "fitness")
        #expect(decoded.value == 5)
        #expect(decoded.unit == "km")
        #expect(decoded.tags == ["run", "morning"])
        #expect(decoded.notes == "steady pace")
    }

    @Test func stateCanBeMutated() {
        let event = HabitEvent(rawInput: "Slept 8 hours")
        event.state = .parsed

        #expect(event.state == .parsed)
    }
}
