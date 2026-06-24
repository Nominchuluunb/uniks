# Spec: Dashboard Phase 2

**Date:** 2026-06-24  
**Scope:** v1.0, Phase 2  
**Status:** Approved for implementation

## Goal

Add a **Dashboard** tab that turns logged events into at-a-glance insights: category totals, recent trends, top tags, and daily activity.

## Requirements

1. **Dashboard tab**
   - Add a third tab in `ContentView` named **Dashboard**.
   - Display after the user has logged at least one event; show an empty state otherwise.

2. **Date range filter**
   - Segmented picker with options: **Today**, **Last 7 days**, **Last 30 days**, **All time**.
   - Default: **Last 7 days**.
   - All charts and totals update when the range changes.

3. **Charts / cards**
   - **Category totals:** sum of `HabitParseResult.value` per category. Show as a vertical bar chart or list of bars.
   - **7-day trend:** total value per day for the selected range (minimum 7 days).
   - **Top tags:** horizontal list of the most frequent tags with counts.
   - **Daily activity:** number of logged events per day for the selected range.

4. **Aggregation rules**
   - Only include events with state `.parsed`.
   - Only include events whose `createdAt` falls in the selected range.
   - If `value` is `nil`, count it as `0` for totals.
   - Tags are counted individually; a single event can contribute to multiple tags.

5. **Implementation approach**
   - Build a `DashboardViewModel` that queries SwiftData off the main thread and publishes aggregated results.
   - Keep charts simple using SwiftUI shapes/rectangles; no external charting library.
   - Add unit tests for aggregation logic with an in-memory SwiftData container.

## Files to create/modify

- Create: `uniks/UI/Dashboard/DashboardView.swift`
- Create: `uniks/UI/Dashboard/DashboardViewModel.swift`
- Create: `uniksTests/DashboardViewModelTests.swift`
- Modify: `uniks/ContentView.swift`

## Testing

- Unit tests for `DashboardViewModel`:
  - Category totals sum correctly.
  - Trend buckets values by day.
  - Top tags returns most frequent tags.
  - Daily activity counts events per day.
  - Date range filters events correctly.
- Manual verification:
  1. Log events with different categories, values, and tags.
  2. Open Dashboard tab → charts reflect the data.
  3. Change date range → charts update.
