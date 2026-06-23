># Testing Guide for Uniks

> Uniks uses Apple's **Swift Testing** framework exclusively. This guide explains how to run tests, mock dependencies, and test the local-first architecture.

## Testing Philosophy

- **Unit tests over UI tests.** Business logic lives in actors and services, which are easy to test in isolation.
- **Deterministic mocks.** The local LLM engine is always mocked in tests to avoid model downloads and GPU requirements.
- **In-memory databases.** SwiftData tests use in-memory `ModelContainer`s for speed and isolation.

## Running Tests

### In Xcode

1. Select the `uniks` scheme.
2. Choose **Product → Test** (`Cmd + U`).

### Command Line

```bash
xcodebuild test -project uniks.xcodeproj -scheme uniks -destination 'platform=macOS'
```

For iOS Simulator:

```bash
xcodebuild test -project uniks.xcodeproj -scheme uniks -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## Test File Layout

```
uniksTests/
├── MockLLMEngine.swift          # Deterministic mock engine
├── HabitEventTests.swift        # Model encode/decode and state tests
└── ParsingActorTests.swift      # State transition and parsing tests
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
@Test func parsingActorTransitionsPendingToParsed() async throws {
    let engine = MockLLMEngine(result: HabitParseResult(category: "fitness", value: 5, unit: "km", tags: ["run"], notes: nil))
    let container = try ModelContainer(for: HabitEvent.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)
    let actor = ParsingActor(engine: engine)
    
    let event = HabitEvent(rawInput: "Ran 5km")
    context.insert(event)
    try context.save()
    
    await actor.parseAndSave(event: event, context: context)
    
    #expect(event.state == .parsed)
    #expect(event.parsedPayloadJSON != nil)
}
```

## Simulator vs Device Testing

- **iOS Simulator:** MLX inference is unavailable. Tests use `MockLLMEngine` automatically.
- **Physical Device:** Integration tests can optionally load a real MLX model, but keep them lightweight.
- **CI:** All tests must pass with the mock engine on macOS and iOS Simulator.

## Test Categories

1. **Model Tests:** Validate `HabitEvent` encode/decode, state transitions, and JSON payload helpers.
2. **Actor Tests:** Validate `ParsingActor` behavior with success, failure, and concurrency scenarios.
3. **Service Tests:** Validate `FTSService` indexing and search.
4. **Engine Tests:** Validate `OllamaLLMEngine` request formatting and `MLXLLMEngine` model configuration.

## Testing Checklist

Before opening a pull request, ensure:

- [ ] All unit tests pass on macOS.
- [ ] All unit tests pass on iOS Simulator.
- [ ] New behavior has corresponding tests.
- [ ] No real LLM calls are made during tests unless explicitly marked as integration tests.
- [ ] SwiftLint passes.

## Debugging Tips

- Use `ModelContext` carefully across actors; prefer passing context into actor methods rather than sharing mutable state.
- For race-condition tests, use Swift Testing's task-based APIs or `TaskGroup`.
- If a test hangs, check for un-awaited `Task` or actor deadlock.

---

*Test like a user owns the data — because they do.*
