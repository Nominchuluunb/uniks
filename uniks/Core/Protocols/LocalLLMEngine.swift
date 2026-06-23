//
//  LocalLLMEngine.swift
//  uniks
//
//  Protocol abstraction for all local NLP parsing engines.
//

/// An engine that can parse a raw natural-language input into a structured
/// `HabitParseResult` without sending data to a remote server.
protocol LocalLLMEngine: Sendable {
    /// Parses the raw input asynchronously.
    /// - Parameter rawInput: The user's original text.
    /// - Returns: A structured parse result.
    func parse(rawInput: String) async throws -> HabitParseResult
}
