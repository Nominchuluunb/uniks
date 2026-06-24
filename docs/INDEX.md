# Uniks Documentation Index

This file is the single source of truth for "where do I read about X?".

## Start here

- **New user or visitor** → [`README.md`](../README.md)
- **AI agent about to write code** → [`AGENTS.md`](../AGENTS.md) (mandatory, kept at repo root for discovery)
- **New human contributor** → [`SOUL.md`](../SOUL.md), then [`CONTRIBUTING.md`](../CONTRIBUTING.md)
- **Wondering what changed recently** → [`CHANGELOG.md`](CHANGELOG.md)

## Documentation map

| Topic | Doc | Why read it |
|-------|-----|-------------|
| Project values and non-negotiables | [`SOUL.md`](../SOUL.md) | Privacy-first, anti-SaaS, local-AI manifesto. |
| Agent operational rules | [`AGENTS.md`](../AGENTS.md) | Mandatory checklist before any AI writes or edits code. |
| Coding standards | [`AI_RULES.md`](../AI_RULES.md) | Concurrency, SwiftData, testing, prohibited patterns. |
| Human contributor workflow | [`CONTRIBUTING.md`](../CONTRIBUTING.md) | Branching, commits, PR template, CoC. |
| Testing strategy | [`TESTING.md`](../TESTING.md) | How to run and write tests, current test files. |
| Architecture | [`docs/ARCHITECTURE.md`](ARCHITECTURE.md) | Targets, layers, data flow, actors, engines. |
| Design system | [`docs/DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md) | Tokens, shared components, examples, anti-patterns. |
| Operations / commands | [`docs/OPERATIONS.md`](OPERATIONS.md) | Build, test, lint, screenshots, icon generation. |
| App Store screenshots | [`docs/screenshots/README.md`](screenshots/README.md) | How to capture screenshots. |
| Feature specs/plans | [`docs/superpowers/`](superpowers/) | Historical specs and phase plans. |

## Documentation is code

When you change code, update the relevant documentation before finishing:

- Architecture change → [`ARCHITECTURE.md`](ARCHITECTURE.md)
- UI, color, font, icon, or component change → [`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md)
- Test change → [`TESTING.md`](../TESTING.md)
- Build, release, screenshot, or operational change → [`OPERATIONS.md`](OPERATIONS.md)
- User-visible feature or behavior change → [`CHANGELOG.md`](CHANGELOG.md) and [`README.md`](../README.md) if needed
- Contributor process change → [`CONTRIBUTING.md`](../CONTRIBUTING.md)
- Agent workflow change → [`AGENTS.md`](../AGENTS.md)

Docs that drift out of date are bugs. If you spot stale documentation, fix it or file an issue.
