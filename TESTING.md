># Testing Guide for Uniks

> Uniks uses **Swift Testing**. This guide explains how to run tests, mock dependencies, and test the local-first architecture.

## Testing Philosophy

- **Unit tests over UI tests.** Business logic lives in actors and services, which are easy to test in isolation.
- **Deterministic mocks.** The local LLM engine is always mocked in tests to avoid model downloads and GPU requirements.
- **In-memory databases.** SwiftData tests use in-memory `ModelContainer`s for speed and isolation.

## Running Tests

### In Xcode

1. Select the `uniks` scheme.
2. Choose **Product → Test** (`Cmd + U`).

### Command Line

Recommended macOS command:

```bash
xcodebuild test -project uniks.xcodeproj -scheme uniks -destination 'platform=macOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -skipMacroValidation -enableCodeCoverage NO
```

For iOS Simulator:

```bash
xcodebuild test -project uniks.xcodeproj -scheme uniks -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -skipMacroValidation -enableCodeCoverage NO
```

`-enableCodeCoverage NO` is required because `yyjson` fails to link with profiling instrumentation.

See [`docs/OPERATIONS.md`](docs/OPERATIONS.md) for more commands.

## Test File Layout

```
uniksTests/
├── DashboardViewModelTests.swift   # Dashboard aggregation logic
├── DesignSystemTests.swift         # Token and component sanity tests
├── EngineResolverTests.swift       # Engine selection fallback logic
├── FTSServiceTests.swift           # Full-text indexing and search
├── HabitEventServiceTests.swift    # Optimistic save/update/delete
├── HabitEventTests.swift           # Model encode/decode and state tests
├── HabitParseResultTests.swift     # Parse result encoding/decoding
├── LocalModelManagerTests.swift    # Model cache status
├── MLXLLMEngineTests.swift         # MLX engine configuration
├── OllamaLLMEngineTests.swift      # Ollama request/response handling
└── ParsingActorTests.swift         # State transition and parsing tests
```

## Mocking the LLM Engine

```swift
import Testing
@testable import uniks

struct MockLLMEngine: LocalLLMEngine {
    let result: HabitParseResult
    let shouldFail: Bool

    func parse(rawInput: String) async throws -> HabitParseResult {
        if shouldFail { throw MockError.intentional }
        return result
    }
}

enum MockError: Error {
    case intentional
}
```

## Testing SwiftData State Transitions

```swift
import Testing
import SwiftData
@testable import uniks

struct ParsingActorTests {

    @Test func transitionsPendingToParsed() async throws {
        let engine = MockLLMEngine(
            result: HabitParseResult(
                category: "fitness",
                value: 5,
                unit: "km",
                tags: ["run"],
                notes: nil
            )
        )
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let context = ModelContext(container)
        let actor = ParsingActor(container: container, engine: engine)

        let event = HabitEvent(rawInput: "Ran 5km")
        context.insert(event)
        try context.save()

        await actor.parseAndSave(eventID: event.id)

        #expect(event.state == .parsed)
        #expect(event.parsedPayloadJSON != nil)
    }
}
```

## Simulator vs Device Testing

- **iOS Simulator:** MLX inference is unavailable. Tests use `MockLLMEngine` automatically.
- **Physical Device:** Integration tests can optionally load a real MLX model, but keep them lightweight.
- **CI:** All tests must pass with the mock engine on macOS and iOS Simulator.

## Test Categories

1. **Model Tests:** Validate `HabitEvent` encode/decode, state transitions, and JSON payload helpers.
2. **Actor Tests:** Validate `ParsingActor` behavior with success, failure, and concurrency scenarios.
3. **Service Tests:** Validate `HabitEventService` and `FTSService` indexing, search, and deletion.
4. **Engine Tests:** Validate `OllamaLLMEngine` request formatting and `MLXLLMEngine` model configuration.
5. **ViewModel Tests:** Validate `DashboardViewModel` aggregations and filters.
6. **Design System Tests:** Validate tokens and shared components.

## Testing Checklist

Before opening a pull request, ensure:

- [ ] All unit tests pass on macOS.
- [ ] All unit tests pass on iOS Simulator.
- [ ] New behavior has corresponding tests.
- [ ] No real LLM calls are made during tests unless explicitly marked as integration tests.
- [ ] SwiftLint passes.
- [ ] Relevant docs (this file, `docs/ARCHITECTURE.md`, `docs/OPERATIONS.md`) are updated if testing strategy changed.

## Debugging Tips

- Use `ModelContext` carefully across actors; prefer passing context into actor methods rather than sharing mutable state.
- For race-condition tests, use `TaskGroup` or structured concurrency patterns.
- If a test hangs, check for un-awaited `Task` or actor deadlock.

---

*Test like a user owns the data — because they do.*
