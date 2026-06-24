# Spec: Event Edit and Retry

**Date:** 2026-06-24  
**Scope:** v1.0, Phase 1 polish  
**Status:** Approved for implementation

## Goal

Allow users to correct AI parsing mistakes or fill in fields when parsing fails. Tapping an event opens an edit sheet where the user can change category, value, unit, tags, and notes, or retry AI parsing.

## Requirements

1. **Tap to edit**
   - Tapping any row in `EventListView` opens a sheet with the event details.

2. **Editable fields**
   - Category: text field.
   - Value: number field (optional).
   - Unit: text field.
   - Tags: comma-separated text field.
   - Notes: multi-line text field.

3. **Actions**
   - **Save**: writes the edited payload back to the event, sets state to `.parsed`, and dismisses.
   - **Retry Parsing**: sets state back to `.pending` and asks `ParsingActor` to re-parse the raw input.
   - **Delete**: removes the event from SwiftData and the FTS index, then dismisses.

4. **Visual states**
   - Pending events show a disabled “Parsing…” indicator.
   - Failed events show a subtle warning and highlight the Retry action.

5. **No functional changes to other modules**
   - `HabitEvent` already supports `setParsedPayload(_:)`.
   - `HabitEventService` gains `update(eventID:payload:)` and `retryParsing(eventID:)`.

## Files to create/modify

- Create: `uniks/UI/EventList/EventEditView.swift`
- Modify: `uniks/Core/Services/HabitEventService.swift`
- Modify: `uniks/UI/EventList/EventListView.swift`

## Testing

- Unit tests:
  - `HabitEventService` updates an event’s payload and state.
  - `HabitEventService` retry sets state to `.pending` and triggers the parsing actor.
  - `HabitEventService` delete still works.
- Manual verification:
  1. Log an event with the mock engine.
  2. Tap the event → edit sheet opens.
  3. Fill category/value/unit/tags/notes and save → row updates in the list.
  4. Tap a failed event → retry → state returns to `.pending` then `.parsed`/`.failed`.
  5. Delete an event → it disappears from the list.
