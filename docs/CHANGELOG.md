# Changelog

All notable changes to Uniks are documented in this file.

## [Unreleased]

### Added — v2: Multi-Agent Pipeline & Feature Expansion

#### Multi-Agent Parsing Pipeline
- `HeuristicParser` — instant regex/pattern-based parsing (< 5ms) with category keyword dictionary and value+unit extraction.
- `ParsingPrompts` — enhanced system prompt with 12+ few-shot examples, category taxonomy, and confidence scoring.
- `JSONRepairService` — repairs malformed LLM JSON output (trailing commas, markdown fencing, unquoted keys).
- `ParseConfidence` enum — categorizes confidence into `.high`, `.medium`, `.low` with semantic colors.
- `EnrichmentActor` — background agent for category normalization (synonym dictionary), related event detection, and pattern analysis.
- `UserCorrection` model + `UserCorrectionsStore` — feedback loop where user edits improve future parsing.
- `ParsingPipeline` orchestrator — 5-stage pipeline (Heuristic → Corrections → LLM → Enrichment → Confidence) with per-stage cancellation and exponential backoff retry.
- New `HabitEventState` cases: `.heuristicParsed`, `.enriched` for progressive refinement.
- `enrichmentJSON` field on `HabitEvent` for storing enrichment metadata separately from parse results.
- `confidence` field on `HabitParseResult` for scoring parse quality.

#### UI/UX Polish
- `AnimationTokens` — standardized animation presets (.fast, .standard, .spring, .springBouncy, .entrance).
- `StaggeredAppear` modifier — sequential fade+slide entrance for list items and cards.
- `USkeletonView`, `USkeletonRow`, `USkeletonCard` — shimmer loading placeholders matching real content layout.
- `HapticEngine` — centralized iOS haptic feedback (light, medium, heavy, success, error, selection).
- `ThemePreference` — working system/light/dark theme picker persisted to UserDefaults.
- `UTabBar` — custom floating capsule tab bar for iOS with elevated FAB center button and hide-on-scroll.
- `DensityPreference` — macOS compact/comfortable layout density modes.
- `UBadge` updated with confidence-based color gradation (green/amber/red).

#### Power Features
- `UndoService` — actor-based undo/redo stack (20 actions) for create, delete, and edit operations.
- `UToast` + `ToastManager` — in-app notification system with success/error/undo variants and auto-dismiss.
- Bulk actions: `bulkDelete`, `bulkRetryParsing`, `bulkUpdateCategory` in `HabitEventService`.
- `CategoryManagementView` — rename, merge, custom colors, create custom categories.
- `CustomCategory` SwiftData model with keywords for heuristic parser integration.
- `ExportService` — JSON and CSV export with date range and category filters, `ExportDocument` for fileExporter.
- `ImportService` — JSON and CSV import with column mapping and duplicate detection.
- `ImportView` — file picker UI with format preview and result summary.
- `RecurringTemplate` SwiftData model — user-defined recurring habit templates.
- `NotificationService` — local notification scheduling with repeating triggers and "Log Now" action.
- `RecurringTemplateView` — CRUD interface for recurring templates with frequency and time settings.
- `ShareCardView` — renders events as beautiful gradient image cards for sharing via ImageRenderer.

#### Infrastructure
- `UniksSchemaV3` — added UserCorrection, CustomCategory, RecurringTemplate, enrichmentJSON to migration plan.
- `ParsingPipeline` replaces bare `ParsingActor` as the parsing actor in app entry point.
- Toast overlay and theme preference applied at root view level.
- Notification categories registered at app launch with reschedule-all.

### Changed

- Real streaming Gemma model download with progress, cancel, retry, resume, delete, and disk-space preflight.
- `ModelStore` actor for cached model containers (instant repeated inference).
- `ActiveModelPreference` persistence with auto-activation on download.
- `UButton`, `UProgressBar`, `USectionHeader`, `UModelCard`, `UEngineStatusBadge`, `UStatBox` shared components.
- Dashboard hero stat row (total events, current streak, top category).
- Dashboard streaks computation and insights generation.
- Global engine-status badge in macOS sidebar, iOS toolbar, and HUD.
- Inline parsed-chip preview in HUD after successful capture.
- **iOS Log tab** — Added a dedicated "Log" tab to the iOS tab bar so capture is one tap away from any screen.
- **Pull-to-refresh** — Event list and dashboard now refresh search results and aggregations on pull-down.
- **Search empty state** — Searching the event list now shows a distinct "No matches" state instead of the generic empty state.
- **Chart accessibility** — Dashboard and inspector charts now expose accessibility labels and values for VoiceOver.
- **Row accessibility** — Event rows and timeline rows are now combined accessibility elements with button traits.
- **Lint enforcement** — Added SwiftLint custom rules for hardcoded padding, stack spacing, font sizes, frame sizes, raw SF Symbols, literal colors, `DispatchQueue`, and `print`/`NSLog` of user data.

### Changed

- Standardized on Gemma models (Gemma 3 1B QAT 4-bit default, Gemma 2 2B quality option) replacing Llama 3.2.
- Onboarding wired to real download (fake timer removed), with error/retry/skip escape hatches.
- Settings model management rebuilt with `UModelCard` and real progress binding.
- `MLXLLMEngine` now uses `ModelStore` for cached containers (no reload per parse).
- `EngineResolver` reads `ActiveModelPreference` for active model selection.
- **Premium UI Overhaul** — Refactored all screens (Events, Dashboard, Settings, Onboarding, HUD) to follow Apple's latest macOS 14/iOS 17 design aesthetics.
- **Swift Charts Dashboard** — Completely rewrote the manual dashboard charts using Apple's first-party `Swift Charts` framework (featuring gradient area fills, smooth Catmull-Rom interpolation, and custom dashed gridlines).
- **Rounded Typography & Gradients** — Shifted core design system tokens to use rounded system typography and modern brand gradient meshes.
- **Glassmorphic Cards** — Updated `UCard` and general cards to use dynamic SwiftUI material styles (`.regularMaterial`), custom separators, and high-fidelity elevation shadows.
- **iOS Sheet Detents** — Compacted the quick-input sheet on iOS using modern presentation height detents and custom drag indicators.
- **Onboarding Carousel** — Redesigned onboarding to feature gradient circular backings, expanding capsular slide indicators, and brand-gradient button shapes.

### Fixed / Cleanup

- **macOS Dashboard placeholder** — Replaced the confusing "General Overview" placeholder list with a `ContentUnavailableView` and kept the real dashboard in the detail pane.
- **Design-token drift** — Removed remaining hardcoded corner radii in onboarding, event list, sidebar, and HUD views; replaced custom card backgrounds with `.cardStyle()`.
- **Hardcoded spacing cleanup** — Replaced all hardcoded numeric `spacing:` and `.padding()` values in `uniks/` with `CGFloat.spacing(_:)` tokens.
- **Settings consistency** — macOS Settings now uses `Form` sections like iOS, unifying the cross-platform experience.
- **Docs** — Expanded `AI_RULES.md` with UI, concurrency, type-safety, and antipattern guidance; added "Spacing and sizing rules" and "Button guidelines" to `docs/DESIGN_SYSTEM.md`.
- **Micro-interactions & Animations** — Added `.interactiveScale()` springy press gestures, macOS card hover states, and breathing variable-color animations on `UBadge` during AI parsing.

### Fixed / Cleanup

- Fixed iOS Simulator build by platform-guarding `QuickInputPanel.swift` and `MeshBackground`.
- Removed placeholder Settings sections (dictation hotkey, microphone, instant transcript, etc.).
- Removed deterministic "AI Confidence" score from `InspectorView`.
- Removed personal `SavedFilter` hardcoding from the macOS sidebar.
- Replaced `SidebarView` polling timer with `UserDefaults` change observation.
- Converted `EngineResolver` from an actor to a value type.
- Migrated remaining `XCTest` files to Swift Testing.
- Added Hugging Face model-download disclosure to onboarding, Settings, and docs.
- Moved `.premiumTextFieldStyle()` into the design system.
- **Design-system cleanup** — removed all remaining inline `.system(size:)` fonts, raw SF Symbol strings, and literal colors from views; centralized them in `DesignTokens.swift`, `Typography.swift`, and `Icons.swift`.
- **Dynamic Chip Icons** — `UChip` now renders contextual icons (`folder`, `number`, `tag`) automatically to improve scannability of parsed logs.
- **Spotlight-Style HUD** — macOS floating panel is now fully borderless, transparent, glassmorphic (using `.ultraThinMaterial`), hides on click-away, and closes on pressing `Escape`.


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
