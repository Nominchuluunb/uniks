# Changelog

All notable changes to Uniks are documented in this file.

## [Unreleased]

### Added

- **Micro-interactions & Animations** — Added `.interactiveScale()` springy press gestures, macOS card hover states, and breathing variable-color animations on `UBadge` during AI parsing.
- **Dynamic Chip Icons** — `UChip` now renders contextual icons (`folder`, `number`, `tag`) automatically to improve scannability of parsed logs.
- **Spotlight-Style HUD** — macOS floating panel is now fully borderless, transparent, glassmorphic (using `.ultraThinMaterial`), hides on click-away, and closes on pressing `Escape`.

### Changed

- **Premium UI Overhaul** — Refactored all screens (Events, Dashboard, Settings, Onboarding, HUD) to follow Apple's latest macOS 14/iOS 17 design aesthetics.
- **Swift Charts Dashboard** — Completely rewrote the manual dashboard charts using Apple's first-party `Swift Charts` framework (featuring gradient area fills, smooth Catmull-Rom interpolation, and custom dashed gridlines).
- **Rounded Typography & Gradients** — Shifted core design system tokens to use rounded system typography and modern brand gradient meshes.
- **Glassmorphic Cards** — Updated `UCard` and general cards to use dynamic SwiftUI material styles (`.regularMaterial`), custom separators, and high-fidelity elevation shadows.
- **iOS Sheet Detents** — Compacted the quick-input sheet on iOS using modern presentation height detents and custom drag indicators.
- **Onboarding Carousel** — Redesigned onboarding to feature gradient circular backings, expanding capsular slide indicators, and brand-gradient button shapes.


## 2026-06-24

### Added

- **Local model download** — `LocalModelManager` and Settings UI to download/check MLX model cache status.
- **App icon and metadata** — generated app icons, Fastlane metadata, and screenshot capture script.
- **Dashboard phase 2** — category totals, daily trend, top tags, and daily activity charts with date-range filter.
- **Onboarding flow** — two-screen first-launch flow explaining the hotkey and privacy promise.
- **Event edit/retry/delete** — tap an event to correct fields, retry parsing, or delete.

### Changed

- Parsed fields (category, value/unit, tags, notes) now render as chips in event rows.

## 2026-06-23

### Added

- **Core event loop** — optimistic save, background parsing, and FTS indexing.
- **macOS HUD** — global `Cmd+Shift+U` floating input panel.
- **iOS quick input sheet** — accessible from the `+` toolbar button.
- **Empty state** — friendly placeholder when no events exist.
- **Settings engine picker** — choose MLX, Ollama, or Mock engine.

### Changed

- Migrated MLX package from `mlx-swift-examples` to `mlx-swift-lm`.
