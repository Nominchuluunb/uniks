//
//  ExportService.swift
//  uniks
//
//  Exports events as JSON or CSV with date range and category filters.
//

import Foundation
import SwiftData

/// Supported export formats.
enum ExportFormat: String, CaseIterable, Sendable {
    case json = "JSON"
    case csv = "CSV"

    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        }
    }

    var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .csv: return "text/csv"
        }
    }
}

/// Export filter options.
struct ExportFilter: Sendable {
    var dateRange: DashboardDateRange = .allTime
    var category: String?
}

/// Serializable export record matching the event schema.
struct ExportableEvent: Codable, Sendable {
    let id: String
    let rawInput: String
    let state: String
    let category: String?
    let value: Double?
    let unit: String?
    let tags: [String]?
    let notes: String?
    let confidence: Double?
    let createdAt: String
    let updatedAt: String
}

/// Actor that handles data export operations.
actor ExportService {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    /// Exports events matching the filter in the specified format.
    /// - Parameters:
    ///   - format: The export format (JSON or CSV).
    ///   - filter: Date range and category filters.
    /// - Returns: The exported data as `Data`.
    func export(format: ExportFormat, filter: ExportFilter = ExportFilter()) async throws -> Data {
        let events = try fetchFilteredEvents(filter: filter)

        switch format {
        case .json:
            return try exportJSON(events)
        case .csv:
            return exportCSV(events)
        }
    }

    /// Returns the filename for the export.
    func filename(format: ExportFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        return "uniks-export-\(dateString).\(format.fileExtension)"
    }

    // MARK: - Private

    private func fetchFilteredEvents(filter: ExportFilter) throws -> [ExportableEvent] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitEvent>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let events = try context.fetch(descriptor)

        let isoFormatter = ISO8601DateFormatter()

        return events
            .filter { event in
                // Date range filter
                if let startDate = filter.dateRange.startDate {
                    guard event.createdAt >= startDate else { return false }
                }
                // Category filter
                if let category = filter.category {
                    guard event.parsedPayload()?.category?.lowercased() == category.lowercased() else {
                        return false
                    }
                }
                return true
            }
            .map { event in
                let payload = event.parsedPayload()
                return ExportableEvent(
                    id: event.id.uuidString,
                    rawInput: event.rawInput,
                    state: event.stateRaw,
                    category: payload?.category,
                    value: payload?.value,
                    unit: payload?.unit,
                    tags: payload?.tags,
                    notes: payload?.notes,
                    confidence: payload?.confidence,
                    createdAt: isoFormatter.string(from: event.createdAt),
                    updatedAt: isoFormatter.string(from: event.updatedAt)
                )
            }
    }

    private func exportJSON(_ events: [ExportableEvent]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(events)
    }

    private func exportCSV(_ events: [ExportableEvent]) -> Data {
        var csv = "id,rawInput,state,category,value,unit,tags,notes,confidence,createdAt,updatedAt\n"

        for event in events {
            let row = [
                event.id,
                csvEscape(event.rawInput),
                event.state,
                csvEscape(event.category ?? ""),
                event.value.map { String($0) } ?? "",
                csvEscape(event.unit ?? ""),
                csvEscape(event.tags?.joined(separator: "; ") ?? ""),
                csvEscape(event.notes ?? ""),
                event.confidence.map { String($0) } ?? "",
                event.createdAt,
                event.updatedAt
            ].joined(separator: ",")
            csv += row + "\n"
        }

        return csv.data(using: .utf8) ?? Data()
    }

    private func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}

// MARK: - File Document for Export

import SwiftUI
import UniformTypeIdentifiers

/// A simple document wrapper for file export via SwiftUI's fileExporter.
struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .commaSeparatedText] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
