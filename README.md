# Uniks

> Premium, open-source, ultra-low-latency personal event and habit logger for macOS and iOS.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: macOS | iOS](https://img.shields.io/badge/Platform-macOS%20%7C%20iOS-lightgrey.svg)]()
[![Swift: 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)]()

## What is Uniks?

Uniks is a privacy-first personal logger. Open the HUD, type a natural sentence like:

```
Ran 5km in 28min, felt great
```

Uniks instantly saves the raw event and, in the background, extracts structured data — category, value, unit, tags, notes — using a local on-device language model. No cloud. No telemetry. No waiting.

## Core Values

- **Privacy-First:** Zero outbound telemetry. Your data never leaves your device unless you explicitly enable encrypted CloudKit sync.
- **Local AI:** NLP parsing runs via Apple MLX Swift on-device, or via a localhost endpoint you control (Ollama / LM Studio).
- **Ultra-Low Latency:** Input path targets < 80 ms response time.
- **Open Source:** Fully auditable, community-driven, anti-SaaS.

## Architecture Overview

```
┌──────────────┐     ┌─────────────────┐     ┌──────────────────┐
│   UI/HUD     │────▶│  Optimistic UI  │────▶│   SwiftData      │
│ QuickInputBar│     │  Save Pending   │     │   HabitEvent     │
└──────────────┘     └─────────────────┘     └──────────────────┘
                                                        │
                                                        ▼
                                               ┌──────────────────┐
                                               │  ParsingActor    │
                                               │  (background)    │
                                               └──────────────────┘
                                                        │
                          ┌─────────────────────────────┼─────────────────────────────┐
                          ▼                             ▼                             ▼
                   ┌─────────────┐              ┌─────────────┐              ┌─────────────┐
                   │ MLXLLMEngine│              │OllamaEngine │              │ MockEngine  │
                   │  (device)   │              │ (localhost) │              │ (simulator) │
                   └─────────────┘              └─────────────┘              └─────────────┘
```

- **SwiftData** stores canonical events with a dynamic JSON payload column to avoid schema migrations.
- **SwiftFTS** provides full-text search over raw input via SQLite FTS5.
- **Swift Charts** powers the Dashboard visualizations.
- **Swift Testing** is used for all unit tests.

## Requirements

- macOS 14+ / iOS 17+
- Xcode 16+
- Swift 6.0+ with strict concurrency
- Physical Apple Silicon device for MLX inference (simulator uses MockEngine)

## First-Time Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Nominchuluunb/uniks.git
   cd uniks
   ```
2. Install the `xcodeproj` Ruby gem:
   ```bash
   gem install xcodeproj
   ```
3. Link the required SPM packages:
   ```bash
   ruby scripts/add_spm_dependencies.rb
   ```
   > **Note:** Ruby is required. macOS includes a system Ruby, though you may need to install it via Homebrew or a Ruby version manager on newer systems.
4. Open `uniks.xcodeproj` in Xcode and let it resolve packages.

## Build Instructions

In Xcode:
1. Select the `uniks` target.
2. Choose a physical device, the iOS Simulator, or the My Mac destination.
3. Build and run (`Cmd + R`).

> **Note:** On the iOS Simulator, the MLX engine is automatically replaced by a deterministic mock engine because MLX requires Metal GPU support.

## Local LLM Setup (Optional)

If you prefer a larger localhost model:

1. Install [Ollama](https://ollama.com).
2. Pull a small instruct model:
   ```bash
   ollama pull llama3.2:3b
   ```
3. In Uniks settings, switch the engine to **Ollama (localhost)**.

## Testing

Run the test suite on macOS:

```bash
xcodebuild test -project uniks.xcodeproj -scheme uniks -destination 'platform=macOS'
```

Run the test suite on the iOS Simulator:

```bash
xcodebuild test -project uniks.xcodeproj -scheme uniks -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

> **Note:** MLX-related tests run only on Apple platforms (macOS, iOS Simulator, or physical device) and cannot run on Linux because `MLXLMCommon` requires Apple frameworks.

See [TESTING.md](TESTING.md) for detailed testing strategy.

## Contributing

We welcome contributors who share our privacy-first values. Please read [CONTRIBUTING.md](CONTRIBUTING.md) and [AI_RULES.md](AI_RULES.md) before opening a pull request.

## License

Uniks is released under the MIT License. See [LICENSE](LICENSE) for details.

---

*Uniks — your life, your device, your rules.*
