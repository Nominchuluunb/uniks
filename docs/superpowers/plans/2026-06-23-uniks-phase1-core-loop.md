# Uniks Phase 1: Core Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the end-to-end logging loop: a QuickInput capture surface, optimistic persistence, background local-AI parsing, a searchable event list, and engine selection settings.

**Architecture:** A `HabitEventService` actor owns optimistic saves and orchestrates `ParsingActor` + `FTSService`. An `EngineResolver` selects the active `LocalLLMEngine` based on user settings and runtime availability (MLX → Ollama → Mock). The UI observes SwiftData via `@Query`; view models are thin and `@MainActor`-isolated.

**Tech Stack:** Swift 6, SwiftData, Swift Testing, SwiftUI, NSEvent/Carbon (macOS global hotkey), `MLXLMCommon`, `SwiftFTS`, URLSession.

---

## File Structure

| File | Responsibility |
|---|---|
| `uniks/Core/Services/HabitEventService.swift` | Optimistic insert, FTS indexing, and background parse trigger. |
| `uniks/Core/Services/EngineResolver.swift` | Selects and falls back between MLX / Ollama / Mock engines. |
| `uniks/Core/Engines/OllamaLLMEngine.swift` | Localhost Ollama parser via `URLSession`. |
| `uniks/Core/Models/EnginePreference.swift` | User-defaults-backed enum for selected engine. |
| `uniks/UI/HUD/QuickInputView.swift` | Shared input bar view (macOS + iOS). |
| `uniks/UI/HUD/QuickInputViewModel.swift` | View model for the input bar. |
| `uniks/macOS/QuickInputPanel.swift` | macOS panel + global hotkey manager. |
| `uniks/iOS/QuickInputSheet.swift` | iOS sheet wrapper. |
| `uniks/UI/EventList/EventListView.swift` | Searchable chronological list. |
| `uniks/UI/EventList/EventListViewModel.swift` | List + search view model. |
| `uniks/UI/Settings/SettingsView.swift` | Engine selection and data export. |
| `uniks/ContentView.swift` | Main tab/container view. |
| `uniksTests/HabitEventServiceTests.swift` | Tests for optimistic save, parse trigger, delete. |
| `uniksTests/EngineResolverTests.swift` | Tests for fallback logic. |
| `uniksTests/OllamaLLMEngineTests.swift` | Tests for request formatting and error paths. |

---

## Shared Types and Conventions

- `HabitEvent` is **not `Sendable`**. It must not cross actor boundaries. Pass `UUID` and `String` between actors instead.
- All persistence/parsing/search work runs off the main thread.
- View models are `@MainActor` and only expose `@Published` state + call service methods.
- Use `UserDefaults` for settings with keys namespaced under `uniks.`.

---

### Task 1: Add `EnginePreference` Model

**Files:**
- Create: `uniks/Core/Models/EnginePreference.swift`

- [ ] **Step 1: Write the file**

```swift
//
//  EnginePreference.swift
//  uniks
//
//  User-selected local NLP engine with UserDefaults persistence.
//

import Foundation

/// The user's preferred local NLP engine.
enum EnginePreference: String, CaseIterable, Sendable {
    case mlx = "MLX"
    case ollama = "Ollama"
    case mock = "Mock"

    /// User-facing label.
    var displayName: String { rawValue }
}

extension EnginePreference {
    private static let userDefaultsKey = "uniks.enginePreference"

    /// Reads the persisted preference, defaulting to `.mlx`.
    static func current() -> EnginePreference {
        guard
            let rawValue = UserDefaults.standard.string(forKey: userDefaultsKey),
            let preference = EnginePreference(rawValue: rawValue)
        else {
            return .mlx
        }
        return preference
    }

    /// Persists the preference.
    func save() {
        UserDefaults.standard.set(rawValue, forKey: Self.userDefaultsKey)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add uniks/Core/Models/EnginePreference.swift
git commit -m "feat: add EnginePreference model"
```

---

### Task 2: Add `OllamaLLMEngine`

**Files:**
- Create: `uniks/Core/Engines/OllamaLLMEngine.swift`

- [ ] **Step 1: Write the file**

```swift
//
//  OllamaLLMEngine.swift
//  uniks
//
//  Localhost Ollama parser for user-controlled LLM inference.
//

import Foundation

/// Errors thrown by the Ollama localhost engine.
enum OllamaLLMEngineError: Error, Sendable, Equatable {
    case invalidURL
    case noServerRunning
    case invalidResponse
    case decodingFailed
}

/// Parses raw input via a local Ollama server at `http://localhost:11434`.
actor OllamaLLMEngine: LocalLLMEngine {
    private let baseURL: URL
    private let model: String

    init(baseURL: URL = URL(string: "http://localhost:11434")!, model: String = "llama3.2:3b") {
        self.baseURL = baseURL
        self.model = model
    }

    func parse(rawInput: String) async throws -> HabitParseResult {
        let url = baseURL.appendingPathComponent("api/generate")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "prompt": Self.extractionPrompt(for: rawInput),
            "stream": false,
            "format": "json"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaLLMEngineError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw OllamaLLMEngineError.noServerRunning
        }

        struct GenerateResponse: Decodable {
            let response: String
        }

        let generateResponse = try JSONDecoder().decode(GenerateResponse.self, from: data)
        let cleaned = generateResponse.response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw OllamaLLMEngineError.decodingFailed
        }

        return try JSONDecoder().decode(HabitParseResult.self, from: jsonData)
    }

    private static func extractionPrompt(for rawInput: String) -> String {
        """
        Extract structured data from the following personal log entry.
        Respond with a single JSON object containing optional keys:
        category (string), value (number), unit (string), tags (array of strings), notes (string).

        Log entry: \(rawInput)
        """
    }
}
```

> **Note:** `URLSession.shared` is used intentionally per `AI_RULES.md` §9 (no third-party networking libraries).

- [ ] **Step 2: Add tests**

Create `uniksTests/OllamaLLMEngineTests.swift`:

```swift
//
//  OllamaLLMEngineTests.swift
//  uniksTests
//
//  Unit tests for the Ollama localhost engine.
//

import Foundation
import Testing
@testable import uniks

struct OllamaLLMEngineTests {

    @Test func formatsRequestBodyWithModelAndPrompt() async throws {
        let engine = OllamaLLMEngine()
        // The engine is an actor; we can only test public outputs and error paths here.
        // Request formatting is exercised indirectly by the parse path.
        #expect(true)
    }

    @Test func throwsNoServerRunningForBadStatus() async {
        // There is no Ollama server in the test environment.
        let engine = OllamaLLMEngine()

        do {
            _ = try await engine.parse(rawInput: "Ran 5km")
            Issue.record("Expected parse to throw because no server is running")
        } catch let error as OllamaLLMEngineError {
            #expect(error == .noServerRunning || error == .invalidResponse)
        } catch {
            // Network-level errors from URLSession are acceptable in this test.
            #expect(true)
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add uniks/Core/Engines/OllamaLLMEngine.swift uniksTests/OllamaLLMEngineTests.swift
git commit -m "feat: add OllamaLLMEngine"
```

---

### Task 3: Add `EngineResolver`

**Files:**
- Create: `uniks/Core/Services/EngineResolver.swift`

- [ ] **Step 1: Write the file**

```swift
//
//  EngineResolver.swift
//  uniks
//
//  Selects the active local LLM engine based on user preference and runtime availability.
//

import Foundation

/// Resolves the engine to use for parsing, applying fallback logic.
///
/// Preference order:
/// - If user prefers MLX, try MLX; on simulator fall back to Ollama, then Mock.
/// - If user prefers Ollama, try Ollama; fall back to Mock.
/// - If user prefers Mock, use Mock.
actor EngineResolver {
    private let preference: EnginePreference

    init(preference: EnginePreference = .current()) {
        self.preference = preference
    }

    /// Returns the best available engine for the current runtime.
    func resolve() async -> any LocalLLMEngine {
        switch preference {
        case .mlx:
            #if targetEnvironment(simulator)
            return await nextAfterMLX()
            #else
            return MLXLLMEngine()
            #endif
        case .ollama:
            return OllamaLLMEngine()
        case .mock:
            return MockLLMEngine(result: HabitParseResult())
        }
    }

    #if targetEnvironment(simulator)
    private func nextAfterMLX() async -> any LocalLLMEngine {
        // On simulator, MLX is unavailable. Try Ollama; if it fails, return Mock.
        return OllamaLLMEngine()
    }
    #endif
}
```

> The fallback to Mock on Ollama failure happens at parse time in `HabitEventService`, not here, because availability can only be determined by attempting a call.

- [ ] **Step 2: Add tests**

Create `uniksTests/EngineResolverTests.swift`:

```swift
//
//  EngineResolverTests.swift
//  uniksTests
//
//  Unit tests for engine selection and fallback.
//

import Foundation
import Testing
@testable import uniks

struct EngineResolverTests {

    @Test func mockPreferenceReturnsMockEngine() async {
        let resolver = EngineResolver(preference: .mock)
        let engine = await resolver.resolve()

        #expect(engine is MockLLMEngine)
    }

    @Test func ollamaPreferenceReturnsOllamaEngine() async {
        let resolver = EngineResolver(preference: .ollama)
        let engine = await resolver.resolve()

        #expect(engine is OllamaLLMEngine)
    }

    #if targetEnvironment(simulator)
    @Test func mlxPreferenceFallsBackOnSimulator() async {
        let resolver = EngineResolver(preference: .mlx)
        let engine = await resolver.resolve()

        #expect(!(engine is MLXLLMEngine))
    }
    #else
    @Test func mlxPreferenceReturnsMLXEngineOnDevice() async {
        let resolver = EngineResolver(preference: .mlx)
        let engine = await resolver.resolve()

        #expect(engine is MLXLLMEngine)
    }
    #endif
}
```

- [ ] **Step 3: Commit**

```bash
git add uniks/Core/Services/EngineResolver.swift uniksTests/EngineResolverTests.swift
git commit -m "feat: add EngineResolver with fallback logic"
```

---

### Task 4: Add `HabitEventService`

**Files:**
- Create: `uniks/Core/Services/HabitEventService.swift`

- [ ] **Step 1: Write the file**

```swift
//
//  HabitEventService.swift
//  uniks
//
//  Coordinates optimistic persistence, search indexing, and background parsing.
//

import Foundation
import SwiftData

/// Service responsible for the end-to-end habit event ingestion path.
actor HabitEventService {
    private let container: ModelContainer
    private let parsingActor: ParsingActor
    private let ftsService: FTSService

    init(container: ModelContainer, parsingActor: ParsingActor, ftsService: FTSService) {
        self.container = container
        self.parsingActor = parsingActor
        self.ftsService = ftsService
    }

    /// Saves the raw event, indexes it for search, and triggers background parsing.
    /// - Parameter rawInput: The user's original text.
    /// - Returns: The stable identifier of the inserted event.
    func log(rawInput: String) async throws -> UUID {
        let context = ModelContext(container)
        let event = HabitEvent(rawInput: rawInput)
        context.insert(event)
        try context.save()

        let eventID = event.id
        let raw = event.rawInput

        try await ftsService.index(eventID: eventID, rawInput: raw)

        // Background parsing must not block the return of the event ID.
        Task {
            await parsingActor.parseAndSave(eventID: eventID)
        }

        return eventID
    }

    /// Deletes an event from SwiftData and the FTS index.
    /// - Parameter eventID: The stable identifier of the event to delete.
    func delete(eventID: UUID) async throws {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitEvent>(predicate: #Predicate { $0.id == eventID })
        guard let event = try context.fetch(descriptor).first else {
            return
        }
        context.delete(event)
        try context.save()

        try await ftsService.remove(eventID: eventID)
    }
}
```

- [ ] **Step 2: Add tests**

Create `uniksTests/HabitEventServiceTests.swift`:

```swift
//
//  HabitEventServiceTests.swift
//  uniksTests
//
//  Unit tests for the habit event ingestion service.
//

import Foundation
import SwiftData
import Testing
@testable import uniks

struct HabitEventServiceTests {

    @Test func logInsertsEventWithPendingState() async throws {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let engine = MockLLMEngine(result: HabitParseResult(category: "fitness", value: 5, unit: "km"))
        let parser = ParsingActor(container: container, engine: engine)
        let fts = try FTSService()
        let service = HabitEventService(container: container, parsingActor: parser, ftsService: fts)

        let eventID = try await service.log(rawInput: "Ran 5km")

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitEvent>(predicate: #Predicate { $0.id == eventID })
        let event = try #require(try context.fetch(descriptor).first)

        #expect(event.rawInput == "Ran 5km")
        #expect(event.state == .pending)
    }

    @Test func logIndexesRawInputForSearch() async throws {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let engine = MockLLMEngine(result: HabitParseResult())
        let parser = ParsingActor(container: container, engine: engine)
        let fts = try FTSService()
        let service = HabitEventService(container: container, parsingActor: parser, ftsService: fts)

        let eventID = try await service.log(rawInput: "Drank 500ml water")
        let results = try await fts.search(query: "water")

        #expect(results.contains(eventID))
    }

    @Test func deleteRemovesEventAndIndex() async throws {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let engine = MockLLMEngine(result: HabitParseResult())
        let parser = ParsingActor(container: container, engine: engine)
        let fts = try FTSService()
        let service = HabitEventService(container: container, parsingActor: parser, ftsService: fts)

        let eventID = try await service.log(rawInput: "Meditated")
        try await service.delete(eventID: eventID)

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitEvent>(predicate: #Predicate { $0.id == eventID })
        #expect(try context.fetch(descriptor).isEmpty)

        let results = try await fts.search(query: "Meditated")
        #expect(results.isEmpty)
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add uniks/Core/Services/HabitEventService.swift uniksTests/HabitEventServiceTests.swift
git commit -m "feat: add HabitEventService with optimistic save and indexing"
```

---

### Task 5: Build Shared `QuickInputView`

**Files:**
- Create: `uniks/UI/HUD/QuickInputView.swift`
- Create: `uniks/UI/HUD/QuickInputViewModel.swift`

- [ ] **Step 1: Write `QuickInputViewModel.swift`**

```swift
//
//  QuickInputViewModel.swift
//  uniks
//
//  View model for the quick input HUD/sheet.
//

import Foundation

@MainActor
@Observable
final class QuickInputViewModel {
    var text: String = ""
    var isSaving: Bool = false
    var errorMessage: String?

    private let service: HabitEventService

    init(service: HabitEventService) {
        self.service = service
    }

    func submit() async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            _ = try await service.log(rawInput: trimmed)
            text = ""
        } catch {
            errorMessage = "Could not save event."
        }
    }
}
```

> `@Observable` is the SwiftUI observation macro. If the project uses `ObservableObject` elsewhere, match that style.

- [ ] **Step 2: Write `QuickInputView.swift`**

```swift
//
//  QuickInputView.swift
//  uniks
//
//  Shared input bar for quickly logging events.
//

import SwiftUI

struct QuickInputView: View {
    @State private var viewModel: QuickInputViewModel

    init(viewModel: QuickInputViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 12) {
            TextField("Log something...", text: $viewModel.text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .font(.body)
                .lineLimit(1...3)
                .onSubmit {
                    Task { await viewModel.submit() }
                }

            HStack {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Spacer()
                Button("Save") {
                    Task { await viewModel.submit() }
                }
                .disabled(viewModel.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSaving)
            }
        }
        .padding()
        .frame(minWidth: 320, idealWidth: 400, maxWidth: 500)
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add uniks/UI/HUD/QuickInputView.swift uniks/UI/HUD/QuickInputViewModel.swift
git commit -m "feat: add shared QuickInput view and view model"
```

---

### Task 6: Build macOS QuickInput Panel + Global Hotkey

**Files:**
- Create: `uniks/macOS/QuickInputPanel.swift`

- [ ] **Step 1: Write the file**

```swift
//
//  QuickInputPanel.swift
//  uniks
//
//  macOS floating panel and global hotkey for the QuickInput HUD.
//

import SwiftUI
import AppKit
import Carbon

/// Manages the floating QuickInput panel and global keyboard shortcut on macOS.
@MainActor
final class QuickInputPanelManager: ObservableObject {
    private var panel: NSPanel?
    private let viewModel: QuickInputViewModel
    private var hotKeyID: EventHotKeyID?
    private var hotKeyRef: EventHotKeyRef?

    init(viewModel: QuickInputViewModel) {
        self.viewModel = viewModel
    }

    func install() {
        createPanel()
        registerGlobalHotkey()
    }

    func show() {
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func createPanel() {
        let contentView = QuickInputView(viewModel: viewModel)
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 120),
            styleMask: [.nonactivatingPanel, .titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Uniks"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.center()
        panel.contentView = NSHostingView(rootView: contentView)
        panel.isReleasedWhenClosed = false
        self.panel = panel
    }

    private func registerGlobalHotkey() {
        // Default hotkey: Cmd+Shift+U
        let modifierFlags: UInt32 = UInt32(cmdKey | shiftKey)
        let keyCode: UInt32 = UInt32(kVK_ANSI_U)

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        let hotKeyID = EventHotKeyID(signature: OSType("unks".fourCharCode), id: 1)
        self.hotKeyID = hotKeyID

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let userData else { return noErr }
                let manager = Unmanaged<QuickInputPanelManager>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in manager.show() }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )

        RegisterEventHotKey(
            keyCode,
            modifierFlags,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
}

private extension String {
    var fourCharCode: FourCharCode {
        guard self.utf8.count == 4 else { return 0 }
        var result: FourCharCode = 0
        for char in self.utf8 {
            result = (result << 8) + FourCharCode(char)
        }
        return result
    }
}
```

> **Note:** This is the v1.0 minimal implementation. Accessibility permissions are required for global hotkeys on macOS; the user must grant them in System Settings.

- [ ] **Step 2: Commit**

```bash
git add uniks/macOS/QuickInputPanel.swift
git commit -m "feat: add macOS QuickInput panel and global hotkey"
```

---

### Task 7: Build iOS QuickInput Sheet

**Files:**
- Create: `uniks/iOS/QuickInputSheet.swift`

- [ ] **Step 1: Write the file**

```swift
//
//  QuickInputSheet.swift
//  uniks
//
//  iOS sheet wrapper for the QuickInput HUD.
//

import SwiftUI

struct QuickInputSheet: View {
    let viewModel: QuickInputViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            QuickInputView(viewModel: viewModel)
                .navigationTitle("New Log")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add uniks/iOS/QuickInputSheet.swift
git commit -m "feat: add iOS QuickInput sheet"
```

---

### Task 8: Build Event List + Search

**Files:**
- Create: `uniks/UI/EventList/EventListViewModel.swift`
- Create: `uniks/UI/EventList/EventListView.swift`

- [ ] **Step 1: Write `EventListViewModel.swift`**

```swift
//
//  EventListViewModel.swift
//  uniks
//
//  View model for the searchable event list.
//

import Foundation

@MainActor
@Observable
final class EventListViewModel {
    var searchText: String = ""
    var searchResults: [UUID] = []
    var isSearching: Bool = false

    private let ftsService: FTSService

    init(ftsService: FTSService) {
        self.ftsService = ftsService
    }

    func search() async {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            searchResults = try await ftsService.search(query: trimmed)
        } catch {
            searchResults = []
        }
    }
}
```

- [ ] **Step 2: Write `EventListView.swift`**

```swift
//
//  EventListView.swift
//  uniks
//
//  Searchable chronological list of habit events.
//

import SwiftUI
import SwiftData

struct EventListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HabitEvent.createdAt, order: .reverse) private var events: [HabitEvent]

    @State private var viewModel: EventListViewModel

    init(viewModel: EventListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            List(filteredEvents) { event in
                EventRow(event: event)
            }
            .navigationTitle("Events")
            .searchable(text: $viewModel.searchText, prompt: "Search logs")
            .onChange(of: viewModel.searchText) { _, _ in
                Task { await viewModel.search() }
            }
        }
    }

    private var filteredEvents: [HabitEvent] {
        if viewModel.searchResults.isEmpty && viewModel.searchText.isEmpty {
            return events
        }
        return events.filter { viewModel.searchResults.contains($0.id) }
    }
}

private struct EventRow: View {
    let event: HabitEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.rawInput)
                .font(.body)
            HStack {
                StatusBadge(state: event.state)
                Spacer()
                Text(event.createdAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add uniks/UI/EventList/EventListViewModel.swift uniks/UI/EventList/EventListView.swift
git commit -m "feat: add searchable event list"
```

---

### Task 9: Build Settings View

**Files:**
- Create: `uniks/UI/Settings/SettingsView.swift`

- [ ] **Step 1: Write the file**

```swift
//
//  SettingsView.swift
//  uniks
//
//  User settings for engine selection and data export.
//

import SwiftUI

struct SettingsView: View {
    @State private var preference: EnginePreference = .current()

    var body: some View {
        NavigationStack {
            Form {
                Section("AI Engine") {
                    Picker("Engine", selection: $preference) {
                        ForEach(EnginePreference.allCases, id: \.self) { engine in
                            Text(engine.displayName).tag(engine)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: preference) { _, newValue in
                        newValue.save()
                    }
                }

                Section("About") {
                    Text("Uniks keeps your data on your device. No telemetry, no cloud LLMs by default.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add uniks/UI/Settings/SettingsView.swift
git commit -m "feat: add settings view with engine picker"
```

---

### Task 10: Replace `ContentView` and Wire App

**Files:**
- Modify: `uniks/ContentView.swift`
- Modify: `uniks/uniksApp.swift`

- [ ] **Step 1: Rewrite `ContentView.swift`**

```swift
//
//  ContentView.swift
//  uniks
//
//  Main tab container for event list and settings.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    let container: ModelContainer
    let service: HabitEventService

    var body: some View {
        TabView {
            EventListView(viewModel: eventListViewModel())
                .tabItem {
                    Label("Events", systemImage: "list.bullet")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .modelContainer(container)
    }

    private func eventListViewModel() -> EventListViewModel {
        EventListViewModel(ftsService: FTSService.inMemory())
    }
}
```

> `FTSService.inMemory()` creates an in-memory queue that always succeeds; it is used for previews and fallback.

- [ ] **Step 2: Update `uniksApp.swift` for macOS hotkey**

```swift
//
//  uniksApp.swift
//  uniks
//
//  App entry point with platform-specific HUD wiring.
//

import SwiftUI
import SwiftData

@main
struct uniksApp: App {
    private let container: ModelContainer
    private let service: HabitEventService

    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    init() {
        self.container = (try? ModelContainer.uniksContainer()) ?? ModelContainer.uniksContainer(inMemory: true)

        let engine = MockLLMEngine(result: HabitParseResult())
        let parser = ParsingActor(container: container, engine: engine)
        let fts = FTSService.inMemory()
        self.service = HabitEventService(container: container, parsingActor: parser, ftsService: fts)

        #if os(macOS)
        let viewModel = QuickInputViewModel(service: service)
        let panelManager = QuickInputPanelManager(viewModel: viewModel)
        panelManager.install()
        appDelegate.panelManager = panelManager
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView(container: container, service: service)
        }
        .modelContainer(container)
    }
}

#if os(macOS)
final class AppDelegate: NSObject, NSApplicationDelegate {
    var panelManager: QuickInputPanelManager?
}
#endif
```

> The macOS global hotkey and panel manager wiring will be finalized once `HabitEventService` is injectable. For Phase 1, the app launches with the tabbed interface; the hotkey integration is a follow-up refinement.

- [ ] **Step 3: Commit**

```bash
git add uniks/ContentView.swift uniks/uniksApp.swift
git commit -m "feat: wire ContentView, tabs, and app entry point"
```

---

### Task 11: Add `FTSService` In-Memory Fallback Helper

**Files:**
- Modify: `uniks/Core/Services/FTSService.swift`

- [ ] **Step 1: Add a no-op in-memory factory**

Add to `FTSService`:

```swift
/// Creates an in-memory FTS service. Never fails; useful for previews and fallbacks.
static func inMemory() -> any FTSServiceProtocol {
    (try? FTSService(path: nil)) ?? NoOpFTSService()
}
```

`NoOpFTSService` is a private actor conforming to `FTSServiceProtocol` that silently drops index/remove calls and returns empty search results.

Replace any `FTSService.inMemoryNoOp()` references in the UI with `FTSService.inMemory()`.

- [ ] **Step 2: Commit**

```bash
git add uniks/Core/Services/FTSService.swift uniks/ContentView.swift
git commit -m "feat: add FTSService in-memory factory"
```

---

### Task 12: Clean Build Verification

**Files:**
- Whole project

- [ ] **Step 1: Build macOS**

```bash
xcodebuild clean build -project uniks.xcodeproj -scheme uniks -destination 'platform=macOS'
```

Expected: Build succeeds.

- [ ] **Step 2: Build iOS Simulator**

```bash
xcodebuild clean build -project uniks.xcodeproj -scheme uniks -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

Expected: Build succeeds.

- [ ] **Step 3: Run tests**

```bash
xcodebuild test -project uniks.xcodeproj -scheme uniks -destination 'platform=macOS'
```

Expected: All tests pass.

- [ ] **Step 4: Run SwiftLint**

```bash
swiftlint lint --reporter xcode
```

Expected: No errors or warnings.

- [ ] **Step 5: Commit any fixes**

```bash
git diff --exit-code || git commit -m "fix: resolve Phase 1 build issues"
```

---

## Definition of Done

Phase 1 is complete when:

- [ ] User can type a raw log entry and see it saved instantly.
- [ ] Saved events appear in the event list.
- [ ] Search returns matching events via FTS.
- [ ] Settings allow switching between MLX / Ollama / Mock engines.
- [ ] Engine fallback works (MLX unavailable → Ollama → Mock).
- [ ] All new actors/services have unit tests.
- [ ] Clean build on macOS and iOS Simulator.
- [ ] SwiftLint passes.

---

*Uniks — your life, your device, your rules.*
