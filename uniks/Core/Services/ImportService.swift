//
//  ImportService.swift
//  uniks
//
//  Imports events from JSON or CSV files with duplicate detection.
//

import Foundation
import SwiftData

/// Import result summary.
struct ImportResult: Sendable {
    let imported: Int
    let skipped: Int
    let failed: Int
}

/// Actor that handles data import operations.
actor ImportService {
    private let container: ModelContainer
    private let ftsService: any FTSServiceProtocol

    init(container: ModelContainer, ftsService: any FTSServiceProtocol) {
        self.container = container
        self.ftsService = ftsService
    }

    /// Imports events from JSON data.
    /// - Parameter data: JSON data matching the export schema.
    /// - Returns: Import result summary.
    func importJSON(_ data: Data) async throws -> ImportResult {
        let decoder = JSONDecoder()
        let events = try decoder.decode([ExportableEvent].self, from: data)
        return await importEvents(events)
    }

    /// Imports events from CSV data.
    /// - Parameters:
    ///   - data: CSV data with header row.
    ///   - columnMapping: Maps CSV column indices to field names. If nil, auto-detected from headers.
    /// - Returns: Import result summary.
    func importCSV(_ data: Data, columnMapping: [Int: String]? = nil) async throws -> ImportResult {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidEncoding
        }

        let rows = parseCSV(csvString)
        guard rows.count > 1 else { throw ImportError.emptyFile }

        let headers = rows[0]
        let mapping = columnMapping ?? autoDetectMapping(headers: headers)

        var events: [ExportableEvent] = []
        let isoFormatter = ISO8601DateFormatter()

        for row in rows.dropFirst() {
            guard row.count >= 2 else { continue }

            let rawInput = getValue(row: row, mapping: mapping, field: "rawInput") ?? ""
            guard !rawInput.isEmpty else { continue }

            let event = ExportableEvent(
                id: getValue(row: row, mapping: mapping, field: "id") ?? UUID().uuidString,
                rawInput: rawInput,
                state: getValue(row: row, mapping: mapping, field: "state") ?? "pending",
                category: getValue(row: row, mapping: mapping, field: "category"),
                value: getValue(row: row, mapping: mapping, field: "value").flatMap { Double($0) },
                unit: getValue(row: row, mapping: mapping, field: "unit"),
                tags: getValue(row: row, mapping: mapping, field: "tags")?
                    .components(separatedBy: ";")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty },
                notes: getValue(row: row, mapping: mapping, field: "notes"),
                confidence: getValue(row: row, mapping: mapping, field: "confidence").flatMap { Double($0) },
                createdAt: getValue(row: row, mapping: mapping, field: "createdAt")
                    ?? isoFormatter.string(from: Date()),
                updatedAt: getValue(row: row, mapping: mapping, field: "updatedAt")
                    ?? isoFormatter.string(from: Date())
            )
            events.append(event)
        }

        return await importEvents(events)
    }

    // MARK: - Private

    private func importEvents(_ exportables: [ExportableEvent]) async -> ImportResult {
        let context = ModelContext(container)
        let isoFormatter = ISO8601DateFormatter()

        // Get existing raw inputs for duplicate detection
        let descriptor = FetchDescriptor<HabitEvent>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let existingInputs = Set(existing.map { $0.rawInput.lowercased() })

        var imported = 0
        var skipped = 0
        var failed = 0

        for exportable in exportables {
            // Duplicate detection
            if existingInputs.contains(exportable.rawInput.lowercased()) {
                skipped += 1
                continue
            }

            let event = HabitEvent(rawInput: exportable.rawInput)

            // Restore timestamps
            if let created = isoFormatter.date(from: exportable.createdAt) {
                event.createdAt = created
            }
            if let updated = isoFormatter.date(from: exportable.updatedAt) {
                event.updatedAt = updated
            }

            // Restore parsed payload if available
            if exportable.category != nil || exportable.value != nil {
                let payload = HabitParseResult(
                    category: exportable.category,
                    value: exportable.value,
                    unit: exportable.unit,
                    tags: exportable.tags,
                    notes: exportable.notes,
                    confidence: exportable.confidence
                )
                event.setParsedPayload(payload)
            } else {
                event.state = HabitEventState(rawValue: exportable.state) ?? .pending
            }

            context.insert(event)

            do {
                try await ftsService.index(eventID: event.id, rawInput: event.rawInput)
                imported += 1
            } catch {
                failed += 1
            }
        }

        try? context.save()
        return ImportResult(imported: imported, skipped: skipped, failed: failed)
    }

    private func parseCSV(_ csvString: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false

        for char in csvString {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                currentRow.append(currentField)
                currentField = ""
            } else if char == "\n" && !inQuotes {
                currentRow.append(currentField)
                if !currentRow.allSatisfy({ $0.isEmpty }) {
                    rows.append(currentRow)
                }
                currentRow = []
                currentField = ""
            } else {
                currentField.append(char)
            }
        }

        // Handle last row
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            if !currentRow.allSatisfy({ $0.isEmpty }) {
                rows.append(currentRow)
            }
        }

        return rows
    }

    private func autoDetectMapping(headers: [String]) -> [Int: String] {
        var mapping: [Int: String] = [:]
        let knownFields = ["id", "rawinput", "state", "category", "value", "unit", "tags", "notes", "confidence", "createdat", "updatedat"]

        for (index, header) in headers.enumerated() {
            let normalized = header.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if knownFields.contains(normalized) {
                mapping[index] = normalized == "rawinput" ? "rawInput" :
                                 normalized == "createdat" ? "createdAt" :
                                 normalized == "updatedat" ? "updatedAt" : normalized
            }
        }
        return mapping
    }

    private func getValue(row: [String], mapping: [Int: String], field: String) -> String? {
        guard let index = mapping.first(where: { $0.value == field })?.key,
              index < row.count else {
            return nil
        }
        let value = row[index].trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

/// Import errors.
enum ImportError: Error, Sendable {
    case invalidEncoding
    case emptyFile
    case invalidFormat
}
