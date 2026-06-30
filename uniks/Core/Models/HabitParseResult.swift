//
//  HabitParseResult.swift
//  uniks
//
//  Structured result extracted from a raw habit log entry.
//

import Foundation

/// A structured representation of a parsed habit event.
/// All fields are optional because natural-language input is open-ended.
struct HabitParseResult: Codable, Sendable, Equatable {
    var category: String?
    var value: Double?
    var unit: String?
    var tags: [String]?
    var notes: String?
    var confidence: Double?

    init(
        category: String? = nil,
        value: Double? = nil,
        unit: String? = nil,
        tags: [String]? = nil,
        notes: String? = nil,
        confidence: Double? = nil
    ) {
        self.category = category
        self.value = value
        self.unit = unit
        self.tags = tags
        self.notes = notes
        self.confidence = confidence
    }
}

extension HabitParseResult {
    /// Serializes the result to a JSON string.
    func toJSON() throws -> String {
        let data = try JSONEncoder().encode(self)
        guard let string = String(data: data, encoding: .utf8) else {
            throw HabitParseError.encodingFailed
        }
        return string
    }

    /// Deserializes a JSON string into a result.
    static func fromJSON(_ string: String) throws -> HabitParseResult {
        guard let data = string.data(using: .utf8) else {
            throw HabitParseError.decodingFailed
        }
        do {
            return try JSONDecoder().decode(HabitParseResult.self, from: data)
        } catch {
            throw HabitParseError.decodingFailed
        }
    }
}
