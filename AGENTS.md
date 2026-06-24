> **Mandatory.** Read this file before writing or editing any code in this repository.

# Agent Instructions

## Must-read docs (in order)

1. [`SOUL.md`](SOUL.md) — project values and non-negotiables.
2. [`AI_RULES.md`](AI_RULES.md) — coding standards and prohibited patterns.
3. [`docs/INDEX.md`](docs/INDEX.md) — map of all documentation.
4. [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md) — the single design system all UI must use.
5. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — how the app is structured.
6. [`TESTING.md`](TESTING.md) — how to test.

## Top rules

1. **Design system is law.** All UI must use tokens and components from `uniks/UI/DesignSystem/` and `uniks/UI/Shared/`. Never implement custom styling inline. See [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md).
2. **Privacy first.** No outbound telemetry, no cloud LLM APIs, no logging of user data, no hardcoded secrets.
3. **Structured concurrency only.** Use `async/await` and actors. No `DispatchQueue.main.async`, no completion handlers.
4. **Local-first data.** Use SwiftData + FTS5. Dynamic JSON payload for parsed fields.
5. **Minimal changes.** Keep diffs focused and follow existing naming conventions.

## Before finishing any task

- [ ] I ran `swiftlint lint --config .swiftlint.yml --strict` and it passed.
- [ ] I ran the full test suite and it passed.

Test command:

```bash
xcodebuild test -project uniks.xcodeproj -scheme uniks -destination 'platform=macOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -skipMacroValidation -enableCodeCoverage NO
```

## Documentation is code

When your change touches any of these areas, update the corresponding doc before finishing:

- Architecture → [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- UI / design → [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md)
- Tests → [`TESTING.md`](TESTING.md)
- Build / ops → [`docs/OPERATIONS.md`](docs/OPERATIONS.md)
- User-visible feature → [`docs/CHANGELOG.md`](docs/CHANGELOG.md) and [`README.md`](README.md) if needed
- Contributor process → [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Agent workflow → this file

If you are unsure which doc to update, update [`docs/INDEX.md`](docs/INDEX.md) or ask.
