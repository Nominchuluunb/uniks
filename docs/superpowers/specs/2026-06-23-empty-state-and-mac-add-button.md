# Spec: Empty State and macOS Add Button

**Date:** 2026-06-23  
**Scope:** v1.0, Phase 1 polish  
**Status:** Approved for implementation

## Goal

Make the app usable without prior knowledge of the global hotkey. When the event list is empty, show a helpful empty state. On macOS, also expose a **+** toolbar button that opens the same QuickInput panel as `Cmd + Shift + U`.

## Requirements

1. **Empty state view**
   - Visible only when the filtered event list is empty.
   - Shows a friendly illustration/icon and title.
   - Subtitle is platform-aware:
     - macOS: *“Press Cmd + Shift + U or click + to log your first event.”*
     - iOS: *“Tap + to log your first event.”*

2. **macOS toolbar add button**
   - Add a `ToolbarItem(placement: .primaryAction)` with a `+` icon.
   - Clicking it opens the `QuickInputPanel` managed by `AppDelegate`.
   - The existing iOS `+` button behavior remains unchanged (presents `QuickInputSheet`).

3. **No functional changes**
   - Does not change `HabitEventService`, `ParsingActor`, or engine logic.
   - Does not change the global hotkey behavior.

## Files to modify

- `uniks/ContentView.swift` — add macOS toolbar button and pass a panel-show callback.
- `uniks/UI/EventList/EventListView.swift` — add empty state view.
- `uniks/uniksApp.swift` — expose a way for `ContentView` to trigger `panelManager.show()`.

## Testing

- Unit tests: not required (pure UI change).
- Manual verification:
  1. Launch on macOS with an empty database → empty state appears.
  2. Click **+** → QuickInput panel opens.
  3. Save an event → empty state disappears and event appears in list.
  4. Delete all events → empty state reappears.

## Open questions

- None.
