# Contributing to Uniks

Thank you for considering a contribution to Uniks. This project is a commons, and every contribution helps us build a privacy-first personal logger that users can trust.

## Before You Start

- Read [`SOUL.md`](SOUL.md) to understand the project's non-negotiables.
- Read [`AI_RULES.md`](AI_RULES.md) to understand coding standards.
- Read [`TESTING.md`](TESTING.md) to understand how we test.
- Read [`docs/INDEX.md`](docs/INDEX.md) to find deeper documentation for any topic.

## How to Contribute

1. **Open an issue first** for non-trivial changes, especially those touching privacy, data ownership, or architecture.
2. **Fork the repository** and create a feature branch:
   ```bash
   git checkout -b feat/your-feature-name
   ```
3. **Make your changes** following the conventions below.
4. **Add tests** for new behavior.
5. **Update documentation** that your change affects (see "Documentation is code" below).
6. **Run SwiftLint** and fix any warnings.
7. **Run tests** and ensure they pass.
8. **Open a pull request** with a clear description and references to any relevant issues.

## Branch Naming

```
feat/short-description
fix/short-description
docs/short-description
refactor/short-description
test/short-description
chore/short-description
```

## Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org):

```
feat: add optimistic save to HUD
fix: prevent main thread blocking during FTS indexing
docs: update ARCHITECTURE.md with engine resolver flow
test: add ParsingActor state transition tests
refactor: extract ModelContainer factory
chore: update SwiftLint rules
```

## Code Style

- Swift 6.0+ with strict concurrency checking enabled.
- `async/await` and `actor` isolation only — no completion handlers.
- `@MainActor` reserved for UI layers.
- All UI uses the shared design system in `uniks/UI/DesignSystem/` and `uniks/UI/Shared/`. See [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md).
- Run `swiftlint` before committing. Exact commands are in [`docs/OPERATIONS.md`](docs/OPERATIONS.md).

## Documentation is Code

A code change is not complete until the docs that describe it are accurate. Update the relevant files:

- Architecture change → [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- UI / design change → [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md)
- Test change → [`TESTING.md`](TESTING.md)
- Build / release / ops change → [`docs/OPERATIONS.md`](docs/OPERATIONS.md)
- User-visible feature → [`docs/CHANGELOG.md`](docs/CHANGELOG.md) and [`README.md`](README.md) if needed
- Contributor process → this file
- Agent workflow → [`AGENTS.md`](AGENTS.md)

## Pull Request Template

```markdown
## Summary
Brief description of the change.

## Motivation
Why is this change needed? Link to issue if applicable.

## Privacy Impact
Does this change affect user data, network usage, or telemetry? If yes, explain the safeguards.

## Testing
How was this tested? List test files or manual steps.

## Documentation
Which docs were updated? Link them.

## Checklist
- [ ] I have read SOUL.md and AI_RULES.md.
- [ ] I have added or updated tests.
- [ ] I have run SwiftLint.
- [ ] I have updated relevant documentation.
- [ ] No outbound network calls were added without explicit user opt-in.
```

## Review Process

- Maintainers will review PRs within a few days.
- Changes to [`SOUL.md`](SOUL.md) or [`AI_RULES.md`](AI_RULES.md) require maintainer approval and public discussion.
- We prioritize correctness, privacy, and maintainability over speed.

## Code of Conduct

- Be respectful and constructive.
- Assume good intent.
- Focus feedback on the code, not the person.

## License

By contributing to Uniks, you agree that your contributions will be licensed under the MIT License.

---

*Uniks — built by humans, for humans.*
