//
//  MockLLMEngine.swift
//  uniks
//
//  Deterministic local LLM engine for previews, simulator, and tests.
//

import Foundation

/// A deterministic engine that returns a fixed result or throws on demand.
/// Useful for SwiftUI previews, simulator builds, and unit tests.
struct MockLLMEngine: LocalLLMEngine {
    let result: HabitParseResult
    let shouldFail: Bool

    init(result: HabitParseResult, shouldFail: Bool = false) {
        self.result = result
        self.shouldFail = shouldFail
    }

    func parse(rawInput: String) async throws -> HabitParseResult {
        if shouldFail {
            throw MockLLMError.intentional
        }
        return result
    }
}

enum MockLLMError: Error, Sendable {
    case intentional
}
