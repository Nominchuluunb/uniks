//
//  HabitParseError.swift
//  uniks
//
//  Errors thrown when encoding or decoding parsed habit payloads.
//

import Foundation

enum HabitParseError: Error, Sendable {
    case encodingFailed
    case decodingFailed
}
