//
//  UndoService.swift
//  uniks
//
//  Manages an undo/redo stack for event actions.
//

import Foundation
import SwiftData

/// Represents an undoable event action.
enum UndoableAction: Sendable {
    case create(eventID: UUID, rawInput: String)
    case delete(eventID: UUID, rawInput: String, payloadJSON: String?, createdAt: Date)
    case edit(eventID: UUID, oldPayloadJSON: String?, newPayloadJSON: String?)
}

/// Actor managing the undo/redo stack for event operations.
/// Stack depth: 20 actions maximum.
actor UndoService {
    private let container: ModelContainer
    private let ftsService: any FTSServiceProtocol
    private var undoStack: [UndoableAction] = []
    private var redoStack: [UndoableAction] = []
    private let maxStackSize = 20

    init(container: ModelContainer, ftsService: any FTSServiceProtocol) {
        self.container = container
        self.ftsService = ftsService
    }

    /// Records an action for potential undo.
    func record(_ action: UndoableAction) {
        undoStack.append(action)
        if undoStack.count > maxStackSize {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }

    /// Whether undo is available.
    var canUndo: Bool { !undoStack.isEmpty }

    /// Whether redo is available.
    var canRedo: Bool { !redoStack.isEmpty }

    /// Undoes the last action. Returns a description of what was undone.
    @discardableResult
    func undo() async throws -> String? {
        guard let action = undoStack.popLast() else { return nil }

        let context = ModelContext(container)

        switch action {
        case .create(let eventID, _):
            // Undo create → delete the event
            let id = eventID
            let descriptor = FetchDescriptor<HabitEvent>(
                predicate: #Predicate { $0.id == id }
            )
            if let event = try? context.fetch(descriptor).first {
                context.delete(event)
                try context.save()
                try? await ftsService.remove(eventID: eventID)
            }
            redoStack.append(action)
            return "Event creation undone"

        case .delete(let eventID, let rawInput, let payloadJSON, let createdAt):
            // Undo delete → recreate the event
            let event = HabitEvent(rawInput: rawInput)
            event.id = eventID
            event.createdAt = createdAt
            event.parsedPayloadJSON = payloadJSON
            event.state = payloadJSON != nil ? .parsed : .pending
            context.insert(event)
            try context.save()
            try? await ftsService.index(eventID: eventID, rawInput: rawInput)
            redoStack.append(action)
            return "Deletion undone"

        case .edit(let eventID, let oldPayloadJSON, _):
            // Undo edit → restore old payload
            let id = eventID
            let descriptor = FetchDescriptor<HabitEvent>(
                predicate: #Predicate { $0.id == id }
            )
            if let event = try? context.fetch(descriptor).first {
                event.parsedPayloadJSON = oldPayloadJSON
                event.state = oldPayloadJSON != nil ? .parsed : .pending
                event.updatedAt = Date()
                try context.save()
            }
            redoStack.append(action)
            return "Edit undone"
        }
    }

    /// Redoes the last undone action.
    @discardableResult
    func redo() async throws -> String? {
        guard let action = redoStack.popLast() else { return nil }

        let context = ModelContext(container)

        switch action {
        case .create(let eventID, let rawInput):
            // Redo create → re-insert the event
            let event = HabitEvent(rawInput: rawInput)
            event.id = eventID
            context.insert(event)
            try context.save()
            try? await ftsService.index(eventID: eventID, rawInput: rawInput)
            undoStack.append(action)
            return "Event re-created"

        case .delete(let eventID, _, _, _):
            // Redo delete → delete again
            let id = eventID
            let descriptor = FetchDescriptor<HabitEvent>(
                predicate: #Predicate { $0.id == id }
            )
            if let event = try? context.fetch(descriptor).first {
                context.delete(event)
                try context.save()
                try? await ftsService.remove(eventID: eventID)
            }
            undoStack.append(action)
            return "Event deleted again"

        case .edit(let eventID, _, let newPayloadJSON):
            // Redo edit → apply new payload again
            let id = eventID
            let descriptor = FetchDescriptor<HabitEvent>(
                predicate: #Predicate { $0.id == id }
            )
            if let event = try? context.fetch(descriptor).first {
                event.parsedPayloadJSON = newPayloadJSON
                event.state = newPayloadJSON != nil ? .parsed : .pending
                event.updatedAt = Date()
                try context.save()
            }
            undoStack.append(action)
            return "Edit re-applied"
        }
    }
}
