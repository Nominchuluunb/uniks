# Spec: Parsed Fields in Event Row

**Date:** 2026-06-24  
**Scope:** v1.0, Phase 1 polish  
**Status:** Approved for implementation

## Goal

Make the AI parsing visible and useful by displaying structured fields (category, value, unit, tags, notes) inside each event row when parsing succeeds.

## Requirements

1. **Event row layout**
   - Top line: the original `rawInput` as the primary text.
   - Second line: a compact row of parsed metadata chips:
     - Category pill (if present).
     - Value + unit pill (if either present).
     - Tag chips (if present).
     - Notes text (if present), truncated to one line.
   - Trailing edge: status badge and creation time.

2. **State-aware display**
   - `.pending`: show raw input + “Parsing…” status.
   - `.parsed`: show raw input + all available structured fields.
   - `.failed`: show raw input + a subtle error indicator; no parsed fields.

3. **Visual style**
   - Use system secondary colors and captions for metadata.
   - Keep the row height reasonable; metadata wraps onto a second line if needed.
   - No new custom colors or assets.

## Files to modify

- `uniks/UI/EventList/EventListView.swift` — rewrite `EventRow` to display parsed fields.

## Testing

- Unit tests: not required (pure UI change).
- Manual verification:
  1. Log an event with the mock engine (returns empty `HabitParseResult`) → row shows raw input + empty metadata.
  2. Log an event with a mock engine returning category/value/unit/tags → row shows all fields.
  3. A pending event shows the parsing status.
  4. A failed event shows the error state without metadata.
