># AI Rules for Uniks Contributors

> This document defines the coding standards and behavioral rules for AI agents and human contributors working on Uniks. Read [SOUL.md](SOUL.md) first.

## 1. Privacy-First Development

- **Never add outbound telemetry.** No analytics SDKs, no crash reporters that phone home, no A/B testing frameworks.
- **Never call cloud LLM APIs.** NLP must run via Apple MLX Swift on-device or via a user-controlled localhost endpoint.
- **Never log personal data.** Diagnostic logs must redact or omit `rawInput` and parsed payloads.
- **Never hardcode secrets.** No API keys, tokens, or certificates in source.

## 2. Concurrency Rules (Strict)

- Use `async/await` and Swift Structured Concurrency exclusively.
- **No completion handlers.** Refactor legacy closures to `async` functions.
- **No `DispatchQueue.main.async`.** Use `@MainActor` or `await MainActor.run` where necessary.
- Isolate long-running work in explicit `actor`s:
  - `ParsingActor` for NLP parsing.
  - `LLMOrchestratorActor` for localhost network calls.
  - `FTSService` for full-text indexing.
- Never block the main thread. Persistence, parsing, search, and model loading are background concerns.

## 3. SwiftData Rules

- Use native `@Model` macros.
- Prefer dynamic JSON payload columns for flexible parsed attributes to avoid schema migrations.
- Mark unique identifiers with `@Attribute(.unique)`.
- Use `@ModelActor` for background model context operations when appropriate.
- Configure WAL mode for low-latency writes.

## 4. UI Rules

- **Optimistic execution:** Save the raw event as `.pending` instantly; parse asynchronously.
- Keep UI transitions under **80 ms** for the input path.
- Use native SF Symbols and dynamic colors.
- Respect Apple HIG for visual density and scannability.
- `@MainActor` is for UI state only.

## 5. AI Engine Rules

- Default engine: `MLXLLMEngine` via `mlx-swift-examples`.
- Fallback engine: `OllamaLLMEngine` for `http://localhost:11434`.
- Simulator engine: `MockLLMEngine` returning deterministic JSON.
- All engines conform to `LocalLLMEngine` protocol.
- Model selection defaults to small quantized instruct models (e.g., Llama 3.2 3B 4-bit).

## 6. Testing Rules

- Use **Apple Swift Testing** framework only. No XCTest.
- Every actor and service must have unit tests with mocked dependencies.
- Use in-memory SwiftData containers for tests.
- Test state transitions, parsing results, and error paths.

## 7. Code Quality Rules

- Follow `.swiftlint.yml`.
- Prefer small, focused files and protocols.
- Use `Sendable` and `nonisolated` correctly.
- Document public APIs with Swift documentation comments.
- Keep view models thin; business logic belongs in actors and services.

## 8. Git Rules

- Conventional commits: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`.
- Branch from `main` using `feat/`, `fix/`, `docs/`, etc.
- No force-push to `main`.
- Keep commits atomic and reviewable.

## 9. Prohibited Patterns

The following are not allowed unless explicitly approved:

- `DispatchQueue.global` or `.main.async`.
- `NSLog` or `print` of user data.
- Third-party networking libraries (use `URLSession`).
- Third-party databases for primary persistence (use SwiftData).
- CloudKit without documented end-to-end encryption design.

## 10. When in Doubt

If a change conflicts with [SOUL.md](SOUL.md) or this document, open an issue and discuss it before writing code. Uniks is designed to be simple, private, and fast — guard those qualities above all.

---

*These rules protect the user. Follow them as law.*
