//
//  HabitParseError.swift
//  uniks
//
//  Errors thrown when encoding or decoding parsed habit payloads.
//

enum HabitParseError: Error, Sendable {
    case encodingFailed
    case decodingFailed
}
