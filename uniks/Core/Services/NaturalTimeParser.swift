//
//  NaturalTimeParser.swift
//  uniks
//
//  Parses relative time expressions from raw input to override event timestamps.
//

import Foundation

/// Extracts a relative time reference from natural language text.
/// Returns the resolved date and the cleaned input (with time phrase removed).
enum NaturalTimeParser {

    struct Result: Sendable {
        let resolvedDate: Date
        let cleanedInput: String
    }

    /// Attempts to extract a time reference. Returns nil if no time phrase found.
    static func parse(_ input: String, relativeTo now: Date = Date()) -> Result? {
        let lower = input.lowercased()
        let calendar = Calendar.current

        for (pattern, resolver) in patterns {
            if let range = lower.range(of: pattern, options: .regularExpression) {
                let match = String(lower[range])
                guard let resolved = resolver(match, now, calendar) else { continue }
                var cleaned = input
                if let inputRange = input.range(of: String(input[range]), options: .caseInsensitive) {
                    cleaned.removeSubrange(inputRange)
                }
                cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "  ", with: " ")
                if cleaned.isEmpty { cleaned = input }
                return Result(resolvedDate: resolved, cleanedInput: cleaned)
            }
        }
        return nil
    }

    // MARK: - Patterns

    private static let patterns: [(String, (String, Date, Calendar) -> Date?)] = [
        ("yesterday( morning| afternoon| evening| night)?", resolveYesterday),
        ("this morning", resolveThisMorning),
        ("this afternoon", resolveThisAfternoon),
        ("this evening", resolveThisEvening),
        ("last night", resolveLastNight),
        ("(\\d+) hours? ago", resolveHoursAgo),
        ("(\\d+) minutes? ago", resolveMinutesAgo),
        ("(\\d+) days? ago", resolveDaysAgo),
    ]

    private static func resolveYesterday(_ match: String, _ now: Date, _ cal: Calendar) -> Date? {
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: now)) else { return nil }
        if match.contains("morning") { return cal.date(bySettingHour: 8, minute: 0, second: 0, of: yesterday) }
        if match.contains("afternoon") { return cal.date(bySettingHour: 14, minute: 0, second: 0, of: yesterday) }
        if match.contains("evening") || match.contains("night") {
            return cal.date(bySettingHour: 20, minute: 0, second: 0, of: yesterday)
        }
        return cal.date(bySettingHour: 12, minute: 0, second: 0, of: yesterday)
    }

    private static func resolveThisMorning(_ match: String, _ now: Date, _ cal: Calendar) -> Date? {
        cal.date(bySettingHour: 8, minute: 0, second: 0, of: now)
    }

    private static func resolveThisAfternoon(_ match: String, _ now: Date, _ cal: Calendar) -> Date? {
        cal.date(bySettingHour: 14, minute: 0, second: 0, of: now)
    }

    private static func resolveThisEvening(_ match: String, _ now: Date, _ cal: Calendar) -> Date? {
        cal.date(bySettingHour: 19, minute: 0, second: 0, of: now)
    }

    private static func resolveLastNight(_ match: String, _ now: Date, _ cal: Calendar) -> Date? {
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: now) else { return nil }
        return cal.date(bySettingHour: 22, minute: 0, second: 0, of: yesterday)
    }

    private static func resolveHoursAgo(_ match: String, _ now: Date, _ cal: Calendar) -> Date? {
        guard let num = extractNumber(from: match) else { return nil }
        return cal.date(byAdding: .hour, value: -num, to: now)
    }

    private static func resolveMinutesAgo(_ match: String, _ now: Date, _ cal: Calendar) -> Date? {
        guard let num = extractNumber(from: match) else { return nil }
        return cal.date(byAdding: .minute, value: -num, to: now)
    }

    private static func resolveDaysAgo(_ match: String, _ now: Date, _ cal: Calendar) -> Date? {
        guard let num = extractNumber(from: match) else { return nil }
        guard let target = cal.date(byAdding: .day, value: -num, to: now) else { return nil }
        return cal.date(bySettingHour: 12, minute: 0, second: 0, of: target)
    }

    private static func extractNumber(from string: String) -> Int? {
        let digits = string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(digits)
    }
}
