//
//  HabitParseResultTests.swift
//  uniksTests
//
//  Unit tests for HabitParseResult encoding and decoding.
//

import Foundation
import Testing
@testable import uniks

struct HabitParseResultTests {

    @Test func encodesAndDecodesFullResult() throws {
        let result = HabitParseResult(
            category: "fitness",
            value: 5,
            unit: "km",
            tags: ["run", "morning"],
            notes: "steady pace"
        )

        let json = try result.toJSON()
        let decoded = try HabitParseResult.fromJSON(json)

        #expect(decoded == result)
    }

    @Test func encodesAndDecodesEmptyResult() throws {
        let result = HabitParseResult()

        let json = try result.toJSON()
        let decoded = try HabitParseResult.fromJSON(json)

        #expect(decoded.category == nil)
        #expect(decoded.value == nil)
        #expect(decoded.unit == nil)
        #expect(decoded.tags == nil)
        #expect(decoded.notes == nil)
    }

    @Test func decodingInvalidJSONThrows() {
        do {
            _ = try HabitParseResult.fromJSON("not valid json")
            Issue.record("Expected fromJSON to throw decodingFailed")
        } catch {
            #expect(error is HabitParseError)
        }
    }
}
