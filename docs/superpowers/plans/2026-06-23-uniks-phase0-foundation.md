# Uniks Phase 0: Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish the canonical data model, persistence layer, local LLM engine abstraction, and build pipeline so the Uniks project compiles cleanly and all unit tests pass on macOS and iOS Simulator.

**Architecture:** A single SwiftData `@Model` (`HabitEvent`) stores raw input and a JSON-encoded parsed payload. A typed `HabitParseResult` provides the structured interface. `LocalLLMEngine` is a `Sendable` protocol abstracting MLX, Ollama, and mock engines. `ParsingActor` performs all NLP work off the main thread. SPM dependencies (`mlx-swift-examples`, `SwiftFTS`) are resolved and linked.

**Tech Stack:** Swift 6, SwiftData, Swift Testing, Xcode 16, SwiftLint, SPM, GitHub Actions.

---

## File Structure

| File | Responsibility |
|---|---|
| `uniks/Core/Models/HabitParseResult.swift` | Codable/Sendable structured parse result + JSON helpers. |
| `uniks/Core/Models/HabitEvent.swift` | SwiftData `@Model` for raw events, state, and payload accessors. |
| `uniks/Core/Models/HabitParseError.swift` | Errors for JSON encode/decode failures. |
| `uniks/Core/Services/ModelContainer+Factory.swift` | Canonical `ModelContainer` factory (in-memory and on-disk). |
| `uniks/Core/Protocols/LocalLLMEngine.swift` | Engine protocol. Already exists; verify and finalize. |
| `uniks/Core/Engines/MockLLMEngine.swift` | Deterministic mock engine. Already exists; verify. |
| `uniksTests/HabitEventTests.swift` | Tests for model init, state, payload round-trip. Already exists. |
| `uniksTests/HabitParseResultTests.swift` | Tests for JSON encode/decode helpers. New. |
| `uniksTests/ParsingActorTests.swift` | Tests for parsing actor state transitions. Already exists. |
| `scripts/add_spm_dependencies.rb` | Adds SPM dependencies to the Xcode project. Already exists. |
| `.swiftlint.yml` | Lint rules. Already exists. |

---

### Task 1: Define `HabitParseResult`

**Files:**
- Create: `uniks/Core/Models/HabitParseResult.swift`

- [ ] **Step 1: Write the file**

```swift
//
//  HabitParseResult.swift
//  uniks
//
//  Structured result extracted from a raw habit log entry.
//

import Foundation

/// A structured representation of a parsed habit event.
/// All fields are optional because natural-language input is open-ended.
struct HabitParseResult: Codable, Sendable, Equatable {
    var category: String?
    var value: Double?
    var unit: String?
    var tags: [String]?
    var notes: String?

    init(
        category: String? = nil,
        value: Double? = nil,
        unit: String? = nil,
        tags: [String]? = nil,
        notes: String? = nil
    ) {
        self.category = category
        self.value = value
        self.unit = unit
        self.tags = tags
        self.notes = notes
    }
}

extension HabitParseResult {
    /// Serializes the result to a JSON string.
    func toJSON() throws -> String {
        let data = try JSONEncoder().encode(self)
        guard let string = String(data: data, encoding: .utf8) else {
            throw HabitParseError.encodingFailed
        }
        return string
    }

    /// Deserializes a JSON string into a result.
    static func fromJSON(_ string: String) throws -> HabitParseResult {
        guard let data = string.data(using: .utf8) else {
            throw HabitParseError.decodingFailed
        }
        return try JSONDecoder().decode(HabitParseResult.self, from: data)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add uniks/Core/Models/HabitParseResult.swift
git commit -m "feat: add HabitParseResult model with JSON helpers"
```

---

### Task 2: Define `HabitParseError`

**Files:**
- Create: `uniks/Core/Models/HabitParseError.swift`

- [ ] **Step 1: Write the file**

```swift
//
//  HabitParseError.swift
//  uniks
//
//  Errors thrown when encoding or decoding parsed habit payloads.
//

import Foundation

enum HabitParseError: Error, Sendable {
    case encodingFailed
    case decodingFailed
}
```

- [ ] **Step 2: Commit**

```bash
git add uniks/Core/Models/HabitParseError.swift
git commit -m "feat: add HabitParseError"
```

---

### Task 3: Define `HabitEvent` SwiftData Model

**Files:**
- Create: `uniks/Core/Models/HabitEvent.swift`

- [ ] **Step 1: Write the file**

```swift
//
//  HabitEvent.swift
//  uniks
//
//  Canonical SwiftData model for a logged habit or event.
//

import Foundation
import SwiftData

/// The persisted state of a habit event.
enum HabitEventState: String, Codable, Sendable {
    case pending
    case parsed
    case failed
}

/// A single user log entry.
///
/// The raw input is always preserved. Structured fields are stored as JSON
/// in `parsedPayloadJSON` so the schema can evolve without SwiftData migrations.
@Model
final class HabitEvent {
    @Attribute(.unique) var id: UUID
    var rawInput: String
    var stateRaw: String
    var parsedPayloadJSON: String?
    var createdAt: Date
    var updatedAt: Date

    init(rawInput: String, state: HabitEventState = .pending) {
        self.id = UUID()
        self.rawInput = rawInput
        self.stateRaw = state.rawValue
        self.parsedPayloadJSON = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

extension HabitEvent {
    /// The current parsing state, backed by `stateRaw`.
    var state: HabitEventState {
        get { HabitEventState(rawValue: stateRaw) ?? .pending }
        set {
            stateRaw = newValue.rawValue
            updatedAt = Date()
        }
    }

    /// Stores a structured parse result and transitions state to `.parsed`.
    /// On encoding failure, transitions to `.failed`.
    func setParsedPayload(_ payload: HabitParseResult) {
        do {
            parsedPayloadJSON = try payload.toJSON()
            state = .parsed
        } catch {
            parsedPayloadJSON = nil
            state = .failed
        }
    }

    /// Returns the decoded structured payload, if any.
    func parsedPayload() -> HabitParseResult? {
        guard let parsedPayloadJSON else { return nil }
        return try? HabitParseResult.fromJSON(parsedPayloadJSON)
    }
}
```

- [ ] **Step 2: Build to catch SwiftData errors**

Run:
```bash
xcodebuild -project uniks.xcodeproj -scheme uniks -destination 'platform=macOS' build
```

Expected: Build succeeds or errors are limited to missing imports/dependencies, not model errors.

- [ ] **Step 3: Commit**

```bash
git add uniks/Core/Models/HabitEvent.swift
git commit -m "feat: add HabitEvent SwiftData model"
```

---

### Task 4: Update `ModelContainer` Factory

**Files:**
- Modify: `uniks/Core/Services/ModelContainer+Factory.swift`

- [ ] **Step 1: Replace the file contents**

```swift
//
//  ModelContainer+Factory.swift
//  uniks
//
//  Centralized SwiftData container configuration with WAL optimization.
//

import Foundation
import SwiftData

extension ModelContainer {
    /// Creates the canonical SwiftData container for Uniks.
    /// - Parameter inMemory: When `true`, uses an in-memory store (useful for previews and tests).
    /// - Returns: A configured `ModelContainer` for `HabitEvent`.
    static func uniksContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([HabitEvent.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
```

> SwiftData uses WAL mode by default on iOS 17+ and macOS 14+. No extra configuration is required.

- [ ] **Step 2: Commit**

```bash
git add uniks/Core/Services/ModelContainer+Factory.swift
git commit -m "chore: finalize ModelContainer factory"
```

---

### Task 5: Verify `LocalLLMEngine` Protocol

**Files:**
- Modify: `uniks/Core/Protocols/LocalLLMEngine.swift`

- [ ] **Step 1: Ensure the file matches**

```swift
//
//  LocalLLMEngine.swift
//  uniks
//
//  Protocol abstraction for all local NLP parsing engines.
//

import Foundation

/// An engine that can parse a raw natural-language input into a structured
/// `HabitParseResult` without sending data to a remote server.
protocol LocalLLMEngine: Sendable {
    /// Parses the raw input asynchronously.
    /// - Parameter rawInput: The user's original text.
    /// - Returns: A structured parse result.
    func parse(rawInput: String) async throws -> HabitParseResult
}
```

- [ ] **Step 2: Commit if changed**

```bash
git diff --exit-code uniks/Core/Protocols/LocalLLMEngine.swift || git commit -m "chore: finalize LocalLLMEngine protocol"
```

---

### Task 6: Verify `MockLLMEngine`

**Files:**
- Modify: `uniks/Core/Engines/MockLLMEngine.swift`

- [ ] **Step 1: Ensure the file matches**

```swift
//
//  MockLLMEngine.swift
//  uniks
//
//  Deterministic local LLM engine for previews, simulator, and tests.
//

import Foundation

/// A deterministic engine that returns a fixed result or throws on demand.
/// Useful for SwiftUI previews, simulator builds, and unit tests.
struct MockLLMEngine: LocalLLMEngine {
    let result: HabitParseResult
    let shouldFail: Bool

    init(result: HabitParseResult, shouldFail: Bool = false) {
        self.result = result
        self.shouldFail = shouldFail
    }

    func parse(rawInput: String) async throws -> HabitParseResult {
        if shouldFail {
            throw MockLLMError.intentional
        }
        return result
    }
}

enum MockLLMError: Error, Sendable {
    case intentional
}
```

- [ ] **Step 2: Commit if changed**

```bash
git diff --exit-code uniks/Core/Engines/MockLLMEngine.swift || git commit -m "chore: finalize MockLLMEngine"
```

---

### Task 7: Add `HabitParseResult` JSON Helper Tests

**Files:**
- Create: `uniksTests/HabitParseResultTests.swift`

- [ ] **Step 1: Write the file**

```swift
//
//  HabitParseResultTests.swift
//  uniksTests
//
//  Unit tests for HabitParseResult encoding and decoding.
//

import Foundation
import Testing
@testable import uniks

struct HabitParseResultTests {

    @Test func encodesAndDecodesFullResult() throws {
        let result = HabitParseResult(
            category: "fitness",
            value: 5,
            unit: "km",
            tags: ["run", "morning"],
            notes: "steady pace"
        )

        let json = try result.toJSON()
        let decoded = try HabitParseResult.fromJSON(json)

        #expect(decoded == result)
    }

    @Test func encodesAndDecodesEmptyResult() throws {
        let result = HabitParseResult()

        let json = try result.toJSON()
        let decoded = try HabitParseResult.fromJSON(json)

        #expect(decoded.category == nil)
        #expect(decoded.value == nil)
        #expect(decoded.unit == nil)
        #expect(decoded.tags == nil)
        #expect(decoded.notes == nil)
    }

    @Test func decodingInvalidJSONThrows() {
        do {
            _ = try HabitParseResult.fromJSON("not valid json")
            Issue.record("Expected fromJSON to throw decodingFailed")
        } catch {
            #expect(error is HabitParseError)
        }
    }
}
```

- [ ] **Step 2: Run the new test**

Run:
```bash
xcodebuild test -project uniks.xcodeproj -scheme uniks -destination 'platform=macOS' -only-testing uniksTests/HabitParseResultTests
```

Expected: All three tests pass.

- [ ] **Step 3: Commit**

```bash
git add uniksTests/HabitParseResultTests.swift
git commit -m "test: add HabitParseResult JSON helper tests"
```

---

### Task 8: Run Existing Model and Actor Tests

**Files:**
- Test: `uniksTests/HabitEventTests.swift`
- Test: `uniksTests/ParsingActorTests.swift`

- [ ] **Step 1: Run model tests**

```bash
xcodebuild test -project uniks.xcodeproj -scheme uniks -destination 'platform=macOS' -only-testing uniksTests/HabitEventTests
```

Expected: `eventInitializesWithPendingState`, `payloadRoundTripsThroughJSONColumn`, and `stateCanBeMutated` pass.

- [ ] **Step 2: Run actor tests**

```bash
xcodebuild test -project uniks.xcodeproj -scheme uniks -destination 'platform=macOS' -only-testing uniksTests/ParsingActorTests
```

Expected: `parsingActorTransitionsPendingToParsed` and `parsingActorTransitionsToFailedOnError` pass.

- [ ] **Step 3: Commit if any fixes were needed**

```bash
git diff --exit-code || git commit -m "fix: resolve test failures from Phase 0 model work"
```

---

### Task 9: Wire SPM Dependencies

**Files:**
- Modify: `uniks.xcodeproj/project.pbxproj` (via script)
- Modify: `uniks/Core/Engines/MLXLLMEngine.swift`
- Modify: `uniks/Core/Services/FTSService.swift`

- [ ] **Step 1: Run the dependency script**

```bash
ruby scripts/add_spm_dependencies.rb
```

Expected output includes:
```
Added package reference: mlx-swift-examples
  Added product MLXLMCommon to uniks
  Added product MLXLMCommon to uniksTests
Added package reference: SwiftFTS
  Added product SwiftFTS to uniks
  Added product SwiftFTS to uniksTests
Project saved.
```

- [ ] **Step 2: Open the project in Xcode and resolve packages**

In Xcode:
1. Open `uniks.xcodeproj`.
2. Select **File → Add Package Dependencies** if needed, or wait for automatic resolution.
3. Verify `MLXLMCommon` and `SwiftFTS` appear under Package Dependencies.

- [ ] **Step 3: Rewrite `MLXLLMEngine.swift` without conditional imports**

Replace the entire file with:

```swift
//
//  MLXLLMEngine.swift
//  uniks
//
//  On-device Apple MLX inference engine. Requires a physical Apple Silicon device.
//

import Foundation
import MLXLMCommon

/// Errors specific to the on-device MLX engine.
enum MLXLLMEngineError: Error, Sendable {
    case notAvailableOnSimulator
    case modelNotLoaded
    case generationFailed(Error)
}

/// On-device parser using Apple's MLX framework via `MLXLMCommon`.
/// This engine is only functional on physical Apple Silicon devices.
actor MLXLLMEngine: LocalLLMEngine {
    private let modelID: String

    init(modelID: String = "mlx-community/Llama-3.2-3B-Instruct-4bit") {
        self.modelID = modelID
    }

    func parse(rawInput: String) async throws -> HabitParseResult {
        #if targetEnvironment(simulator)
        throw MLXLLMEngineError.notAvailableOnSimulator
        #else
        // Load the model container on first use. In production this should be
        // cached and managed by a dedicated ModelManager actor.
        let modelContainer = try await LLMModel.load(
            configuration: ModelConfiguration(id: modelID)
        )
        let model = modelContainer.model

        let messages: [[String: String]] = [
            ["role": "system", "content": Self.extractionSystemPrompt],
            ["role": "user", "content": rawInput]
        ]

        let prompt = try model.applyChatTemplate(messages: messages)
        let stream = try await model.generate(
            prompt: prompt,
            maxTokens: 256
        )

        var output = ""
        for try await token in stream {
            output += token
        }

        let cleaned = output
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw MLXLLMEngineError.modelNotLoaded
        }

        return try JSONDecoder().decode(HabitParseResult.self, from: data)
        #endif
    }

    private static var extractionSystemPrompt: String {
        """
        You extract structured data from a user's personal log entry.
        Respond with a single JSON object containing optional keys:
        category, value (number), unit, tags (array of strings), notes.
        """
    }
}
```

- [ ] **Step 4: Rewrite `FTSService.swift` without conditional imports**

Replace the entire file with:

```swift
//
//  FTSService.swift
//  uniks
//
//  Full-text search over raw HabitEvent inputs using SQLite FTS5.
//

import Foundation
import SwiftFTS

/// A lightweight document wrapper for indexing `HabitEvent.rawInput`.
struct HabitEventFTSDocument: FullTextSearchable {
    struct Metadata: Codable, Sendable {
        let eventID: String
    }

    let id: String
    let rawInput: String
    let metadata: Metadata?

    var indexItemID: String { id }
    var indexText: String { rawInput }
    var indexMetadata: Metadata? { metadata }
}

/// Actor that manages FTS5 indexing and search for raw habit event inputs.
actor FTSService {
    private let databaseQueue: FTSDatabaseQueue
    private let indexer: SearchIndexer
    private let engine: SearchEngine

    /// Initializes the FTS service with an on-disk or in-memory database.
    /// - Parameter path: File URL for the FTS database. Pass `nil` for an in-memory index.
    init(path: URL? = nil) throws {
        if let path {
            databaseQueue = try FTSDatabaseQueue(path: path.path)
        } else {
            databaseQueue = try FTSDatabaseQueue.makeInMemory()
        }
        indexer = try SearchIndexer(databaseQueue: databaseQueue)
        engine = try SearchEngine(databaseQueue: databaseQueue)
    }

    /// Indexes a single event's raw input.
    func index(event: HabitEvent) async throws {
        let document = HabitEventFTSDocument(
            id: event.id.uuidString,
            rawInput: event.rawInput,
            metadata: .init(eventID: event.id.uuidString)
        )
        try await indexer.addItems([document])
    }

    /// Indexes multiple events.
    func index(events: [HabitEvent]) async throws {
        let documents = events.map {
            HabitEventFTSDocument(
                id: $0.id.uuidString,
                rawInput: $0.rawInput,
                metadata: .init(eventID: $0.id.uuidString)
            )
        }
        try await indexer.addItems(documents)
    }

    /// Searches raw inputs and returns matching `HabitEvent` identifiers.
    func search(query: String) async throws -> [UUID] {
        let results: [HabitEventFTSDocument] = try await engine.search(
            query: query,
            factory: { item in
                HabitEventFTSDocument(
                    id: item.id,
                    rawInput: item.text,
                    metadata: try? item.metadata()
                )
            }
        )
        return results.compactMap { UUID(uuidString: $0.id) }
    }

    /// Removes an event from the FTS index.
    func remove(eventID: UUID) async throws {
        try await indexer.removeItem(id: eventID.uuidString)
    }
}
```

- [ ] **Step 5: Build to verify**

```bash
xcodebuild -project uniks.xcodeproj -scheme uniks -destination 'platform=macOS' build
```

Expected: Build succeeds with no new warnings from the engine or service files.

- [ ] **Step 6: Commit**

```bash
git add uniks.xcodeproj/project.pbxproj uniks/Core/Engines/MLXLLMEngine.swift uniks/Core/Services/FTSService.swift
git commit -m "chore: link MLXLMCommon and SwiftFTS SPM dependencies"
```

---

### Task 10: Run SwiftLint and Fix Warnings

**Files:**
- All modified `.swift` files

- [ ] **Step 1: Run SwiftLint**

```bash
swiftlint lint --reporter xcode
```

If `swiftlint` is not installed:
```bash
brew install swiftlint
```

- [ ] **Step 2: Fix all warnings and errors**

Common issues to watch for:
- Line length > 120 characters.
- Trailing whitespace.
- Force unwraps or force casts.
- Missing MARK comments in large files.

- [ ] **Step 3: Commit**

```bash
git commit -am "style: resolve SwiftLint warnings"
```

---

### Task 11: Verify Clean Build on macOS and iOS Simulator

**Files:**
- Whole project

- [ ] **Step 1: Clean build macOS**

```bash
xcodebuild clean test -project uniks.xcodeproj -scheme uniks -destination 'platform=macOS'
```

Expected: Build succeeds and all tests pass.

- [ ] **Step 2: Clean build iOS Simulator**

```bash
xcodebuild clean test -project uniks.xcodeproj -scheme uniks -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

Expected: Build succeeds and all tests pass. MLX engine will throw `notAvailableOnSimulator` at runtime, which is correct.

- [ ] **Step 3: Commit if any final fixes were needed**

```bash
git diff --exit-code || git commit -m "fix: resolve cross-platform build issues"
```

---

### Task 12: Update README Build Instructions (If Needed)

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Review the Build Instructions section**

Ensure it still matches the project state. If the SPM dependency script is now required before first build, add:

```markdown
### First-Time Setup

1. Clone the repo.
2. Run `ruby scripts/add_spm_dependencies.rb` to link required packages.
3. Open `uniks.xcodeproj` and let Xcode resolve packages.
4. Build and run.
```

- [ ] **Step 2: Commit if changed**

```bash
git diff --exit-code README.md || git commit -m "docs: update build instructions for SPM dependencies"
```

---

## Self-Review

### Spec Coverage

| Spec Requirement | Implementing Task |
|---|---|
| Define `HabitEvent` | Task 3 |
| Define `HabitParseResult` | Task 1 |
| JSON payload helpers | Tasks 1, 3 |
| `ModelContainer` factory with WAL | Task 4 |
| Unit tests for encode/decode and state transitions | Tasks 7, 8 |
| `LocalLLMEngine` protocol | Task 5 |
| `MockLLMEngine` | Task 6 |
| Resolve and link SPM dependencies | Task 9 |
| Clean build on macOS and iOS Simulator | Task 11 |

### Placeholder Scan

- No `TBD`, `TODO`, or vague steps.
- Every task includes exact file paths.
- Every code step includes actual code.
- Every test step includes the exact command and expected outcome.

### Type Consistency

- `HabitParseResult.toJSON()` and `HabitParseResult.fromJSON(_:)` match across Task 1 and Task 3.
- `HabitEvent.setParsedPayload(_:)` and `HabitEvent.parsedPayload()` match the existing tests in `uniksTests/HabitEventTests.swift`.
- `ParsingActor.parseAndSave(eventID:)` signature matches the existing `ParsingActorTests.swift`.

---

## Definition of Done

Phase 0 is complete when:

- [ ] `HabitEvent`, `HabitParseResult`, and `HabitParseError` are defined and compile.
- [ ] `HabitEventTests`, `HabitParseResultTests`, and `ParsingActorTests` all pass on macOS.
- [ ] The project builds cleanly on iOS Simulator.
- [ ] `swiftlint lint` reports no errors or warnings.
- [ ] SPM dependencies (`MLXLMCommon`, `SwiftFTS`) are linked and the `#if canImport` guards are removed.
- [ ] All changes are committed with conventional commit messages.

---

*Uniks — your life, your device, your rules.*
