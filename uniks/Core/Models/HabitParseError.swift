//
//  HabitParseError.swift
//  uniks
//
//  Errors thrown when encoding or decoding parsed habit payloads.
//

enum HabitParseError: Error, Sendable, Equatable {
    case encodingFailed
    case decodingFailed
}
