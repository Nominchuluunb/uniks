# Uniks v1.0 Roadmap and Architecture Design

**Date:** 2026-06-23  
**Status:** Draft — pending review  
**Author:** Chief Software Architect / AI Orchestration Advisor  
**Project:** [nominchuluunb/uniks](https://github.com/nominchuluunb/uniks)

---

## 1. Strategic Frame

### 1.1 Primary Goal

Ship **Uniks v1.0** on the App Store (macOS first, iOS second) as a privacy-first, local-AI personal event and habit logger. The v1.0 must include a working dashboard and core logging loop that a new user understands in under 60 seconds.

### 1.2 Success Criteria

- A first-time user can download the app, open it, type `Ran 5km in 28min`, and see the event appear in the event list and dashboard within seconds.
- No account, no cloud, and no telemetry are required for core functionality.
- Local AI parsing works well enough that users trust it (target: > 80% accuracy for common quantitative patterns).
- The codebase is clean, modular, and documented enough that autonomous AI agents can later work on issues without violating privacy or architecture rules.
- The app respects the non-negotiables in [`SOUL.md`](../../SOUL.md) and [`AI_RULES.md`](../../AI_RULES.md).

### 1.3 Development Model

**Spec-first, AI-augmented build.**

- The human acts as architect, product owner, and final reviewer.
- Every module is specified in `docs/superpowers/specs/` before implementation.
- The AI assistant implements, tests, and documents from the spec.
- No code is written without an approved spec.

This model is chosen because the project will later migrate from a single AI assistant (Phase A) to autonomous agents working from GitHub Issues (Phase D). Autonomous agents require clear specs, stable interfaces, and strong tests to work safely.

---

## 2. v1.0 Product Scope

### 2.1 Included in v1.0

| Feature | User Value | Notes |
|---|---|---|
| Global QuickInput HUD (macOS) / input sheet (iOS) | One-keystroke capture | The core interaction. Must feel instantaneous. |
| Natural-language event capture | Type like a human | Examples: `Ran 5km`, `Read 30 pages`, `Meditated 10min`. |
| Optimistic save + background parse | Never lose a thought | Raw event saved immediately; AI parsing happens asynchronously. |
| Event list with full-text search | Find past events | Powered by SwiftFTS over raw input. |
| Dashboard with 3–4 charts | Understand patterns | Category totals, 7-day trend, top tags, daily activity. |
| Settings | User control | Engine selection (MLX / Ollama / Mock), model choice, data export. |
| Manual event editing | Trust and correction | User can edit category, value, unit, tags, and notes when AI parsing fails or is wrong. |
| Onboarding (2 screens) | Learn the app | Explain the HUD hotkey and the privacy promise. |

### 2.2 Explicitly Deferred to v1.1 or Later

- CloudKit sync (even encrypted).
- Home screen / Lock screen widgets.
- Siri Shortcuts.
- Goals, reminders, and notifications.
- Advanced analytics (correlations, custom reports).
- Custom categories beyond auto-extracted ones.
- Apple Watch app.
- Import from third-party apps.

**Rationale:** A solo, part-time builder augmented by AI agents can ship a high-quality v1.0 only by locking scope. Each deferred item is a candidate for autonomous agents post-launch.

---

## 3. Technical Architecture

### 3.1 High-Level Diagram

```
┌─────────────────────────────────────┐
│ UI Layer (@MainActor)               │
│ QuickInputView, DashboardView,      │
│ EventListView, SettingsView         │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│ View Models (thin)                  │
│ InputViewModel, HabitListViewModel, │
│ DashboardViewModel, SettingsVM      │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│ Services (actors where appropriate) │
│ HabitEventService, FTSService,      │
│ SettingsService, ExportService      │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│ Actors                              │
│ ParsingActor                        │
└─────────────┬───────────────────────┘
              │
┌─────────────▼─────────────────────────────────┐
│ Engines (LocalLLMEngine protocol)             │
│ MLXLLMEngine │ OllamaLLMEngine │ MockEngine   │
└───────────────────────────────────────────────┘
              │
┌─────────────▼───────────────────────┐
│ Persistence                         │
│ SwiftData (HabitEvent) + SwiftFTS   │
└─────────────────────────────────────┘
```

### 3.2 Key Architectural Decisions

1. **Single canonical model: `HabitEvent`.**
   - `rawInput`: String, the exact text the user typed.
   - `state`: Enum — `.pending`, `.parsed`, `.failed`.
   - `parsedPayloadJSON`: Optional JSON string for extracted fields (category, value, unit, tags, notes).
   - `createdAt`: Date.
   - `updatedAt`: Date.
   - Rationale: A dynamic JSON payload avoids early schema migrations while the parsing schema stabilizes.

2. **`LocalLLMEngine` protocol.**
   - All NLP engines conform to a single protocol.
   - Engines are injected, never instantiated by UI code.
   - This enables testing, fallback logic, and future engine additions.

3. **`ParsingActor` owns all LLM calls.**
   - No engine is called from the main thread or from UI code.
   - The actor receives a `HabitEvent`, calls the engine, and updates the model state.

4. **`FTSService` actor owns search indexing.**
   - Keeps SQLite FTS5 index in sync with SwiftData inserts/updates.
   - Search queries run off the main thread.

5. **View models are thin.**
   - They call services and expose `@Published` state.
   - Business logic lives in actors and services.

6. **Strict concurrency checking.**
   - Enabled in build settings to enforce `AI_RULES.md` concurrency rules.

> **Note on `LLMOrchestratorActor`:** This placeholder was consolidated into `OllamaLLMEngine` during Phase 1. It no longer exists as a separate type. Post-v1.0 engine management (model caching, lifecycle) will be handled by a dedicated actor when needed.

### 3.3 Data Flow for a Typical Input

1. User opens QuickInput HUD and types `Ran 5km in 28min, felt great`.
2. ViewModel creates a `HabitEvent(rawInput: ...)` with state `.pending`.
3. `HabitEventService` inserts the event into SwiftData synchronously (optimistic save).
4. `HabitEventService` passes the event to `ParsingActor`.
5. `ParsingActor` calls the active `LocalLLMEngine`.
6. Engine returns a `HabitParseResult` (category, value, unit, tags, notes).
7. `ParsingActor` serializes the result to JSON, updates `parsedPayloadJSON`, and sets state to `.parsed`.
8. `FTSService` indexes the raw input in the background.
9. UI observes the change and updates the list and dashboard.

If parsing fails, the event remains saved with state `.failed` and the raw input is preserved.

### 3.4 Error Handling

- **Parsing errors:** Logged without personal data; event state set to `.failed`; user can retry manually.
- **Engine unavailability:** Gracefully fall back to the next available engine (MLX → Ollama → Mock).
- **Database errors:** Surface a non-blocking error banner; never crash on persistence failure.
- **Search errors:** Return empty results; log metadata only.

---

## 4. AI Agent Orchestration

### 4.1 Phase A: One Assistant, Spec-First (Now → v1.0)

1. For every new module or significant change, write a spec in `docs/superpowers/specs/`.
2. The human reviews and approves the spec before any code is written.
3. The AI assistant implements the spec, adds tests, runs SwiftLint, and creates a commit/PR.
4. The human reviews the implementation against the spec.
5. If the code drifts, either update the spec or rewrite the code. The spec is the source of truth.

### 4.2 Phase D: Autonomous Agents on Issues (Post-v1.0)

- Use GitHub Issues as the work queue.
- Require a `needs-spec` label until a spec is attached.
- Label issues by suitability:
  - `ai-friendly`: bounded, well-tested, no privacy-sensitive paths.
  - `human-required`: touches SwiftData models, network code, SOUL.md, or AI_RULES.md.
- Autonomous agents (e.g., GitHub Copilot) may only pick up `ai-friendly` issues.
- All autonomous PRs require human review before merge.

---

## 5. Open-Source Success Path

| Pillar | Actions |
|---|---|
| **Clarity** | README includes a 30-second GIF of the HUD. SOUL.md and AI_RULES.md are linked prominently. |
| **Trust** | Zero telemetry, reproducible builds, documented SQLite data format, built-in export. |
| **Contributor Onboarding** | `good first issue` labels, `CONTRIBUTING.md`, issue templates, code of conduct. |
| **Visibility** | Launch on Product Hunt, Hacker News, Reddit (r/selfhosted, r/QuantifiedSelf), Swift forums. |
| **Sustainability** | GitHub Sponsors or one-time App Store purchase. No subscription rent-seeking on user data. |
| **Governance** | Maintainer retains final say over SOUL.md and AI_RULES.md changes. Technical decisions can be delegated after v1.0. |

---

## 6. Tools & Infrastructure

| Layer | Tool | Purpose |
|---|---|---|
| IDE | Xcode 16+ | Build, debug, profile. |
| Language | Swift 6.0+ | Strict concurrency, modern SwiftData. |
| Lint | SwiftLint | Enforce style and catch prohibited patterns. |
| Testing | XCTest | Unit and integration tests. |
| CI | GitHub Actions | Build + test on macOS and iOS Simulator for every PR. |
| Distribution | TestFlight → App Store | Beta testing and public release. |
| Docs | Markdown in repo | Specs, runbooks, architecture decisions. |
| Community | GitHub Discussions (later Discord) | Support and contributor coordination. |
| Release | Fastlane or Xcode Cloud | Automate screenshots, metadata, upload. |

---

## 7. Implementation Roadmap

### Phase 0: Foundation (Weeks 1–2)

- [ ] Lock v1.0 scope and publish this design doc.
- [ ] Set up GitHub repo hygiene: issue templates, labels, CI skeleton, branch protection on `main`.
- [ ] Define the canonical data model:
  - `HabitEvent` (`@Model`) with `rawInput`, `state`, `parsedPayloadJSON`, `createdAt`, `updatedAt`.
  - `HabitParseResult` (Codable, Sendable) with `category`, `value`, `unit`, `tags`, `notes`.
  - JSON payload encode/decode helpers and schema version handling.
- [ ] Implement `ModelContainer` factory with WAL mode enabled.
- [ ] Add unit tests for model encode/decode and state transitions.
- [ ] Finalize `LocalLLMEngine` protocol and `MockLLMEngine`.
- [ ] Resolve and link SPM dependencies (`mlx-swift-lm`, `SwiftFTS`); remove no-op `#if canImport` guards once packages are linked.
- [ ] Verify clean build passes on macOS and iOS Simulator with SwiftLint and strict concurrency checking enabled.

### Phase 1: Core Loop (Weeks 3–5)

- [ ] Build QuickInput HUD for macOS (global hotkey) and input sheet for iOS.
- [ ] Implement optimistic save in `HabitEventService`.
- [ ] Wire `ParsingActor` → `MockLLMEngine` → `OllamaLLMEngine`.
- [ ] Build event list view with full-text search via `FTSService`.
- [ ] Add settings screen for engine/model selection.
- [ ] Add tests for the core loop and actor state transitions.

### Phase 2: Dashboard (Weeks 6–8)

- [ ] Define aggregation queries over `HabitEvent` (group by category, tag, date).
- [ ] Build dashboard view models.
- [ ] Implement four charts: category totals, 7-day trend, top tags, daily activity (events per day over the last 30 days).
- [ ] Add date-range filtering (today, last 7 days, last 30 days, all time).
- [ ] Add tests for aggregation logic and view model state.

### Phase 3: Polish & Ship (Weeks 9–10)

- [ ] Build two-screen onboarding flow.
- [ ] App icon, app metadata, App Store screenshots.
- [ ] Internal TestFlight build; fix bugs and latency issues.
- [ ] Optimize input path to < 80 ms perceived latency.
- [ ] Submit v1.0 to the App Store.

### Phase 4: Open-Source Growth (Ongoing)

- [ ] Public launch and community building.
- [ ] Migrate to autonomous agents for small, well-specified issues.
- [ ] Maintain a public v1.1 backlog (sync, widgets, shortcuts, etc.).

---

## 8. Risks & Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| MLX inference is slow or inaccurate on older Macs | High | Default to a small quantized model; allow Ollama fallback; benchmark early on target hardware. |
| JSON payload schema becomes unstable | Medium | Version the parsed payload schema; validate on decode; keep a typed `HabitParseResult` as the canonical interface. |
| Dashboard aggregation queries are slow | Medium | Pre-aggregate in memory on launch; run queries off main thread; cache results. |
| App Store rejects the app | Medium | Position as a personal notes/logger app; avoid medical/health claims; include privacy policy. |
| Scope creep delays v1.0 | High | Lock the feature list in this doc; every new idea goes to the v1.1 backlog. |
| AI agents introduce inconsistent patterns | Medium | Spec-first + mandatory human review + SwiftLint + CI gates. |
| Local LLM parsing is unreliable | High | Tight prompt engineering; deterministic output schema; allow user to edit parsed fields manually as a fallback. |

---

## 9. Next Steps

1. Review and approve this design document.
2. Invoke the `writing-plans` skill to create a detailed implementation plan for Phase 0.
3. Write per-module specs for the first sprint (data model, `ParsingActor`, `HabitEventService`).
4. Begin implementation with the AI assistant.

---

*Uniks — your life, your device, your rules.*
