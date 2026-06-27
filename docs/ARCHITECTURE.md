# Uniks Architecture

## Targets

- **`uniks`** — SwiftUI app for macOS and iOS.
- **`uniksTests`** — Swift Testing unit tests.

## High-level data flow

```
┌─────────────────────┐     ┌─────────────────────┐
│   UI / HUD          │────▶│   HabitEventService │
│   QuickInputView    │     │   (actor)           │
└─────────────────────┘     └─────────────────────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    ▼                 ▼                 ▼
           ┌─────────────┐   ┌──────────────┐   ┌──────────────┐
           │  SwiftData  │   │   FTSService │   │ ParsingActor │
           │  HabitEvent │   │   (FTS5)     │   │   (actor)    │
           └─────────────┘   └──────────────┘   └──────┬───────┘
                                                       │
                              ┌────────────────────────┼────────────────────────┐
                              ▼                        ▼                        ▼
                       ┌─────────────┐          ┌─────────────┐          ┌─────────────┐
                       │ MLXLLMEngine│          │OllamaEngine │          │ MockEngine  │
                       │  (device)   │          │ (localhost) │          │ (fallback)  │
                       └─────────────┘          └─────────────┘          └─────────────┘
```

The ingestion path is optimistic: the raw event is saved and indexed immediately, then parsed in the background.

## Layers

### UI (`uniks/UI/`)

| Path | Responsibility |
|------|----------------|
| `uniks/ContentView.swift` | Root container. iOS uses a `TabView` (Events, Dashboard, Log, Settings) where the Log tab opens the quick-input sheet. macOS uses a `NavigationSplitView` with `SidebarView`, `EventListView`, and `InspectorView`; Dashboard renders in the detail pane. |
| `uniks/UI/HUD/` | Quick-input HUD (shared `QuickInputView`, iOS sheet wrapper, macOS panel manager). |
| `uniks/UI/EventList/` | Searchable event list, event row metadata, event edit sheet. |
| `uniks/UI/Dashboard/` | Charts and aggregations from parsed events. |
| `uniks/UI/Settings/` | Engine selection preferences and local MLX model download status. |
| `uniks/UI/Onboarding/` | First-launch onboarding flow with welcome, setup, and local model downloading stages (`OnboardingView.swift`, `OnboardingSubviews.swift`). |
| `uniks/UI/DesignSystem/` | Tokens, typography, icons, and reusable view modifiers. |
| `uniks/UI/Shared/` | Shared components (`UCard`, `UChip`, `UBadge`, `UEmptyState`, `UFlowLayout`, `SidebarView`, `InspectorView`). |

UI views are `@MainActor` where needed. View models are thin; persistence and parsing are delegated to actors/services.

### Core / Models (`uniks/Core/Models/`)

- `HabitEvent` — canonical `@Model` object with `rawInput`, `state` (pending/parsed/failed), and a JSON payload column.
- `HabitParseResult` — structured parse output: category, value, unit, tags, notes.
- `EnginePreference` — user-selected engine (MLX, Ollama, Mock).
- `LocalModel` and `LocalModelStatus` — downloadable on-device models and their cache status.

The JSON payload column keeps the schema flexible; adding new parsed fields does not require a migration.

### Core / Actors (`uniks/Core/Actors/`)

- `ParsingActor` — background actor that fetches a pending event, runs the selected `LocalLLMEngine`, and updates state.
- `ParsingActorProtocol` — abstraction used by `HabitEventService` for testability.

### Core / Services (`uniks/Core/Services/`)

- `HabitEventService` — orchestrates optimistic save, FTS indexing, and background parsing.
- `FTSService` — SQLite FTS5 full-text index over `rawInput`.
- `LocalModelManager` — checks Hugging Face cache and downloads MLX models.
- `ModelContainer+Factory` — canonical SwiftData container configuration.
- `EngineResolver` — selects the concrete `LocalLLMEngine` based on preference and runtime.

### Core / Engines (`uniks/Core/Engines/`)

All engines conform to `LocalLLMEngine` (`uniks/Core/Protocols/LocalLLMEngine.swift`).

| Engine | Runtime | Package |
|--------|---------|---------|
| `MLXLLMEngine` | Physical Apple Silicon device only | `mlx-swift-lm` |
| `OllamaLLMEngine` | `http://localhost:11434` | `URLSession` |
| `MockLLMEngine` | Simulator, tests, fallback | deterministic result |

`EngineResolver.preferredEngine` applies fallback logic: on simulator, MLX falls back to Ollama then Mock; Ollama falls back to Mock; Mock always returns Mock.

### App entry point

`uniks/uniksApp.swift`:
1. Builds the SwiftData `ModelContainer`.
2. Resolves the preferred engine.
3. Builds `FTSService` (file-based, with in-memory fallback on error).
4. Builds `ParsingActor` and `HabitEventService`.
5. On macOS, creates and installs `QuickInputPanelManager` with a global `Cmd+Shift+U` hotkey.
6. Presents `ContentView`.

## Concurrency model

- `async/await` and Swift Structured Concurrency only.
- Heavy work (parsing, indexing, persistence, model loading) runs off the main thread in actors.
- UI state is updated on `@MainActor` or via `await MainActor.run`.
- `SWIFT_DEFAULT_ACTOR_ISOLATION = none` is set for the `uniks` and `uniksTests` targets to avoid main-actor-by-default breaking existing code.

## Build notes

- Macros require `-skipMacroValidation` on command-line builds.
- Code coverage must be disabled (`-enableCodeCoverage NO`) because `yyjson` fails to link with profiling instrumentation.
- See [`OPERATIONS.md`](OPERATIONS.md) for exact commands.

## Onboarding & Local Model Ingestion Flow

The first-launch onboarding flow (`OnboardingView`) is structured as a three-stage sequence:
1. **Welcome Stage**: Explains the natural language expressiveness features and includes terms/privacy compliance.
2. **Setup Stage**: Summarizes the on-device model download parameters.
3. **Downloading Stage**: Triggers the actual Hugging Face model download via `LocalModelManager.download(_:)` and shows download progress.

On-device models are downloaded from Hugging Face (`huggingface.co`) on first setup. No personal event data or parsing logs are sent to Hugging Face or any other remote service.

## Dependencies

In addition to Apple frameworks, Uniks links the following Swift packages:

- `mlx-swift-lm` — on-device MLX inference (`MLXLMCommon`, `MLXLLM`, `MLXHuggingFace`).
- `swift-huggingface` — Hugging Face Hub integration (`HuggingFace`).
- `swift-transformers` — tokenizers (`Tokenizers`).
- `SwiftFTS` — SQLite FTS5 full-text search.
